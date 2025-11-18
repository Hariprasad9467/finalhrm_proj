import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:io';
import 'package:flutter/foundation.dart';

typedef IncomingCallCallback = void Function(String fromId, Map signal);
typedef RemoteStreamCallback = void Function(MediaStream stream);
typedef LocalStreamCallback = void Function(MediaStream stream);

class CallManager {
  late IO.Socket socket;
  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  MediaStream? get localStream => _localStream;

  final String serverUrl;
  final String currentUserId;

  IncomingCallCallback? onIncomingCall;
  RemoteStreamCallback? onRemoteStream;
  LocalStreamCallback? onLocalStream;
  VoidCallback? onCallEnded;

  String? _currentTarget;
  String? currentRoomId;

  // 🔴 Queue to store early ICE candidates
  final List<RTCIceCandidate> _pendingCandidates = [];
  bool _isAnswering = false;

  CallManager({required this.serverUrl, required this.currentUserId});

  // ✅ Initialize socket connection
  Future<void> init() async {
    socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'autoConnect': true,
      'forceNew': true,
    });

    socket.onConnect((_) {
      socket.emit('join', currentUserId);
      debugPrint('✅ Connected to socket as $currentUserId');
    });

    // ✅ Incoming call
    socket.on('incoming-call', (data) {
      try {
        final from = data['from'] as String;
        final signal = Map<String, dynamic>.from(data['signal'] ?? {});
        onIncomingCall?.call(from, signal);
      } catch (e) {
        debugPrint('⚠ incoming-call parse error: $e');
      }
    });

    // 🔴 NEW: Listen for call acceptance (caller side)
    socket.on('call-accepted-by-receiver', (data) async {
      try {
        debugPrint('✅ Call accepted by ${data['from']}');
        final isVideo = data['isVideo'] == true;

        // NOW start media and send offer
        if (_currentTarget != null) {
          await _startMediaAndCreateOffer(
            targetId: _currentTarget!,
            isVideo: isVideo,
          );
        }
      } catch (e) {
        debugPrint('⚠ Error after call accepted: $e');
      }
    });

    // 🔴 WebRTC Offer Handler
    socket.on('offer', (data) async {
      try {
        debugPrint('📥 Received offer from ${data['from']}');
        _isAnswering = true;
        _pendingCandidates.clear();

        final from = data['from'] as String;
        final offerMap = Map<String, dynamic>.from(data['offer'] ?? {});
        final roomId = data['roomId'] as String?;

        if (roomId != null) currentRoomId = roomId;
        _currentTarget = from;

        final sdp = offerMap['sdp'] as String?;
        final type = offerMap['type'] as String?;
        final isVideo = offerMap['isVideo'] == true;

        if (sdp != null && type != null) {
          // 🔴 CRITICAL: Setup peer connection FIRST
          await _setupReceiverPeerConnection(from, isVideo);

          // Set remote description
          await _pc!.setRemoteDescription(RTCSessionDescription(sdp, type));
          debugPrint('✅ Remote description set (offer)');

          // 🔴 Process pending candidates AFTER peer connection ready
          if (_pendingCandidates.isNotEmpty) {
            debugPrint(
              '📦 Adding ${_pendingCandidates.length} pending candidates',
            );
            for (var candidate in _pendingCandidates) {
              try {
                await _pc!.addCandidate(candidate);
              } catch (e) {
                debugPrint('⚠ Error adding pending candidate: $e');
              }
            }
            _pendingCandidates.clear();
          }

          // Create and send answer
          final answer = await _pc!.createAnswer({
            'offerToReceiveAudio': true,
            'offerToReceiveVideo': isVideo,
          });
          await _pc!.setLocalDescription(answer);

          socket.emit('answer', {
            'to': from,
            'from': currentUserId,
            'answer': {'sdp': answer.sdp, 'type': answer.type},
            'roomId': roomId,
          });
          debugPrint('📤 Answer sent to $from');

          _isAnswering = false;
        }
      } catch (e) {
        debugPrint('⚠ offer handler error: $e');
        _isAnswering = false;
      }
    });

    // 🔴 WebRTC Answer Handler
    socket.on('answer', (data) async {
      try {
        debugPrint('📥 Received answer from ${data['from']}');
        final answerMap = Map<String, dynamic>.from(data['answer'] ?? {});
        final sdp = answerMap['sdp'] as String?;
        final type = answerMap['type'] as String?;

        if (sdp != null && type != null && _pc != null) {
          // 🔴 FIX: Check signaling state before setting remote description
          if (_pc!.signalingState ==
              RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
            await _pc!.setRemoteDescription(RTCSessionDescription(sdp, type));
            debugPrint('✅ Remote description set (answer)');

            // 🔴 Process pending candidates after answer
            if (_pendingCandidates.isNotEmpty) {
              debugPrint(
                '📦 Adding ${_pendingCandidates.length} pending candidates',
              );
              for (var candidate in _pendingCandidates) {
                try {
                  await _pc!.addCandidate(candidate);
                } catch (e) {
                  debugPrint('⚠ Error adding pending candidate: $e');
                }
              }
              _pendingCandidates.clear();
            }
          } else {
            debugPrint(
              '⚠ Cannot set remote description, wrong state: ${_pc!.signalingState}',
            );
          }
        }
      } catch (e) {
        debugPrint('⚠ answer handler error: $e');
      }
    });

    // ✅ Call accepted (OLD - kept for compatibility)
    socket.on('call-accepted', (data) async {
      try {
        final signal = Map<String, dynamic>.from(data as Map);
        final sdp = signal['sdp'] as String?;
        final type = signal['type'] as String?;
        if (sdp != null && type != null && _pc != null) {
          if (_pc!.signalingState ==
              RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
            await _pc!.setRemoteDescription(RTCSessionDescription(sdp, type));
          }
        }
      } catch (e) {
        debugPrint('⚠ call-accepted error: $e');
      }
    });

    // ✅ Call rejected
    socket.on('call-rejected', (data) {
      debugPrint('ℹ Received call-rejected: $data');
      onCallEnded?.call();
      _cleanupPeer();
    });

    // ✅ Call ended remotely
    socket.on('call-ended', (data) {
      debugPrint('ℹ Received call-ended: $data');
      onCallEnded?.call();
      _cleanupPeer();
    });

    // 🔴 ICE Candidate Handler with Queueing
    socket.on('ice-candidate', (data) async {
      try {
        debugPrint('📥 Received ice-candidate');
        final candMap = data['candidate'];

        if (candMap == null) {
          debugPrint('⚠ Candidate null, skipping');
          return;
        }

        final candidateStr = candMap['candidate'] as String?;
        final sdpMid = candMap['sdpMid'] as String?;
        final sdpMLineIndex = candMap['sdpMLineIndex'];
        final sdpIndex = sdpMLineIndex is int
            ? sdpMLineIndex
            : int.tryParse('$sdpMLineIndex');

        if (candidateStr == null || candidateStr.isEmpty) {
          debugPrint('⚠ Empty candidate string');
          return;
        }

        final candidate = RTCIceCandidate(candidateStr, sdpMid, sdpIndex);

        // 🔴 CRITICAL FIX: Queue candidates if peer connection not ready
        if (_pc == null || _isAnswering) {
          debugPrint('📦 Queueing candidate (PC not ready yet)');
          _pendingCandidates.add(candidate);
        } else {
          try {
            await _pc!.addCandidate(candidate);
            debugPrint('✅ ICE candidate added immediately');
          } catch (e) {
            debugPrint('⚠ Error adding candidate: $e');
          }
        }
      } catch (e) {
        debugPrint('⚠ ice-candidate error: $e');
      }
    });

    socket.onDisconnect((_) {
      debugPrint('⚠ Socket disconnected');
    });
  }

  // 🔴 NEW: Setup peer connection for receiver (when offer arrives)
  Future<void> _setupReceiverPeerConnection(String fromId, bool isVideo) async {
    _currentTarget = fromId;

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': isVideo
          ? {
              'facingMode': 'user',
              'width': {'ideal': 1280},
              'height': {'ideal': 720},
            }
          : false,
    });

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        await Helper.setSpeakerphoneOn(true);
      } catch (e) {
        debugPrint('⚠ Speaker setup error: $e');
      }
    }

    debugPrint(
      '🔈 Local audio tracks: ${_localStream?.getAudioTracks().length}',
    );
    if (isVideo) {
      debugPrint(
        '🎥 Local video tracks: ${_localStream?.getVideoTracks().length}',
      );
    }

    onLocalStream?.call(_localStream!);

    _pc = await _createPeerConnection(isVideo, fromId);

    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        await _pc!.addTrack(track, _localStream!);
        debugPrint(
          '➕ Added local ${track.kind} track, enabled=${track.enabled}',
        );
      }
    }
  }

  /// 🔴 Create Peer Connection with TURN servers
  Future<RTCPeerConnection> _createPeerConnection(
    bool isVideo,
    String targetId,
  ) async {
    final configuration = <String, dynamic>{
      'iceServers': [
        {
          'urls': [
            'stun:stun.l.google.com:19302',
            'stun:stun1.l.google.com:19302',
          ],
        },
        {
          'urls': 'turn:openrelay.metered.ca:80',
          'username': 'openrelayproject',
          'credential': 'openrelayproject',
        },
        {
          'urls': 'turn:openrelay.metered.ca:443',
          'username': 'openrelayproject',
          'credential': 'openrelayproject',
        },
        {
          'urls': 'turn:openrelay.metered.ca:443?transport=tcp',
          'username': 'openrelayproject',
          'credential': 'openrelayproject',
        },
      ],
      'sdpSemantics': 'unified-plan',
    };

    final pc = await createPeerConnection(configuration);

    // 🔴 ICE connection state logging
    pc.onIceConnectionState = (RTCIceConnectionState state) {
      debugPrint('🔄 ICE connection state: $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        debugPrint('❌ ICE connection failed');
      }
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
        debugPrint('✅ ICE connection established');
      }
    };

    pc.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint('🔗 PeerConnection state: $state');
    };

    pc.onIceGatheringState = (RTCIceGatheringState state) {
      debugPrint('📡 ICE gathering state: $state');
    };

    // 🔴 ICE candidate emission
    pc.onIceCandidate = (RTCIceCandidate? c) {
      if (c != null && c.candidate != null && c.candidate!.isNotEmpty) {
        debugPrint('🧊 Sending ICE candidate to $targetId');
        socket.emit('ice-candidate', {
          'to': targetId,
          'candidate': {
            'candidate': c.candidate,
            'sdpMid': c.sdpMid,
            'sdpMLineIndex': c.sdpMLineIndex,
          },
        });
      }
    };

    // 🔴 FIXED: Track handling - Safe for Web
    pc.onTrack = (RTCTrackEvent event) {
      debugPrint(
        '📹 onTrack: kind=${event.track.kind}, streams=${event.streams.length}, enabled=${event.track.enabled}',
      );

      if (event.streams.isNotEmpty) {
        final stream = event.streams.first;
        final audioTracks = stream.getAudioTracks().length;
        final videoTracks = stream.getVideoTracks().length;
        debugPrint('✅ Remote stream: audio=$audioTracks, video=$videoTracks');
        onRemoteStream?.call(stream);
      } else {
        debugPrint('⚠ onTrack but no streams - will receive in next event');
      }
    };

    return pc;
  }

  /// ✅ Create room (for group call)
  void createRoom(String targetId) {
    currentRoomId = "room_${DateTime.now().millisecondsSinceEpoch}";
    socket.emit("create-room", {
      'roomId': currentRoomId,
      'creator': currentUserId,
      'target': targetId,
      'isVideo': true,
    });
    debugPrint("🏠 Room created: $currentRoomId by $currentUserId");
  }

  /// ✅ Invite another participant into an existing room
  void inviteParticipant({
    required String targetId,
    required String? roomId,
    required bool isVideo,
  }) {
    if (roomId == null) {
      debugPrint("⚠ No active room to invite into");
      return;
    }

    socket.emit("add-participant", {
      'roomId': roomId,
      'from': currentUserId,
      'target': targetId,
      'isVideo': isVideo,
    });
    debugPrint("👥 Invited $targetId to room $roomId");
  }

  /// 🔴 FIXED: Start a call - Don't capture media until accepted
  Future<void> startCall({
    required String targetId,
    required bool isVideo,
  }) async {
    _currentTarget = targetId;
    _pendingCandidates.clear();

    // 🔴 CRITICAL FIX: Don't get media here, wait for accept
    currentRoomId = "room_${DateTime.now().millisecondsSinceEpoch}";

    debugPrint('📞 Initiating call to $targetId (waiting for accept)');

    // Send call-user to show incoming call popup
    socket.emit('call-user', {
      'target': targetId,
      'from': currentUserId,
      'signal': {'isVideo': isVideo, 'roomId': currentRoomId},
    });

    debugPrint('✅ Call initiation sent (no media yet)');
  }

  /// 🔴 NEW: Start media ONLY after receiver accepts
  Future<void> _startMediaAndCreateOffer({
    required String targetId,
    required bool isVideo,
  }) async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': isVideo
          ? {
              'facingMode': 'user',
              'width': {'ideal': 1280},
              'height': {'ideal': 720},
            }
          : false,
    });

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        await Helper.setSpeakerphoneOn(true);
      } catch (e) {
        debugPrint('⚠ Speaker setup error: $e');
      }
    }

    debugPrint(
      '🔈 Local audio tracks: ${_localStream?.getAudioTracks().length}',
    );
    if (isVideo) {
      debugPrint(
        '🎥 Local video tracks: ${_localStream?.getVideoTracks().length}',
      );
    }

    onLocalStream?.call(_localStream!);

    _pc = await _createPeerConnection(isVideo, targetId);

    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        await _pc!.addTrack(track, _localStream!);
        debugPrint(
          '➕ Added local ${track.kind} track, enabled=${track.enabled}',
        );
      }
    }

    final offer = await _pc!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': isVideo,
    });
    await _pc!.setLocalDescription(offer);

    debugPrint('📤 Sending offer to $targetId');

    socket.emit('offer', {
      'to': targetId,
      'from': currentUserId,
      'offer': {'sdp': offer.sdp, 'type': offer.type, 'isVideo': isVideo},
      'roomId': currentRoomId,
    });

    debugPrint('✅ Offer sent with media');
  }

  /// 🔴 FIXED: Answer a call - Ensure video enabled
  Future<void> answerCall({required String fromId, required Map signal}) async {
    _currentTarget = fromId;
    _pendingCandidates.clear();
    final isVideo = signal['isVideo'] == true;

    debugPrint('📞 Answering call from $fromId, video=$isVideo');

    // 🔴 CRITICAL: Get media with correct video setting
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': isVideo
          ? {
              'facingMode': 'user',
              'width': {'ideal': 1280},
              'height': {'ideal': 720},
            }
          : false,
    });

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        await Helper.setSpeakerphoneOn(true);
      } catch (e) {
        debugPrint('⚠ Speaker setup error: $e');
      }
    }

    debugPrint(
      '🔈 Local audio tracks: ${_localStream?.getAudioTracks().length}',
    );
    if (isVideo) {
      debugPrint(
        '🎥 Local video tracks: ${_localStream?.getVideoTracks().length}',
      );
    }

    onLocalStream?.call(_localStream!);

    _pc = await _createPeerConnection(isVideo, fromId);

    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        await _pc!.addTrack(track, _localStream!);
        debugPrint(
          '➕ Added local ${track.kind} track, enabled=${track.enabled}',
        );
      }
    }

    if (signal['roomId'] != null) {
      currentRoomId = signal['roomId'];
      debugPrint("📦 Joined existing room: $currentRoomId");
    }

    final remoteSdp = signal['sdp'] as String?;
    final remoteType = signal['type'] as String?;

    // 🔴 FIX: Only set remote description if offer exists
    if (remoteSdp != null && remoteType != null) {
      await _pc!.setRemoteDescription(
        RTCSessionDescription(remoteSdp, remoteType),
      );
      debugPrint('✅ Remote description set from signal');

      // Create answer
      final answer = await _pc!.createAnswer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': isVideo,
      });
      await _pc!.setLocalDescription(answer);

      debugPrint('📤 Sending answer to $fromId');

      socket.emit('answer', {
        'to': fromId,
        'from': currentUserId,
        'answer': {'sdp': answer.sdp, 'type': answer.type},
        'roomId': currentRoomId,
      });

      socket.emit('answer-call', {
        'to': fromId,
        'signal': {'sdp': answer.sdp, 'type': answer.type},
      });

      debugPrint(
        '✅ Answer sent with ${isVideo ? "video+audio" : "audio only"}',
      );
    } else {
      // 🔴 NEW: No offer yet, notify caller to send offer
      debugPrint('📢 Notifying caller that call is accepted');
      socket.emit('call-accepted-by-receiver', {
        'to': fromId,
        'from': currentUserId,
        'isVideo': isVideo,
      });
    }
  }

  /// ✅ End call
  void endCall({String? forceTargetId}) {
    try {
      final to = forceTargetId ?? _currentTarget;
      if (to != null && socket.connected) {
        socket.emit('end-call', {'to': to, 'from': currentUserId});
        debugPrint('📞 Emitted end-call to $to');
      } else {
        debugPrint('⚠ No target for end-call');
      }
    } catch (e) {
      debugPrint('⚠ endCall error: $e');
    }
    onCallEnded?.call();
    _cleanupPeer();
  }

  /// ✅ Reject incoming call
  void rejectCall(String toId) {
    try {
      socket.emit('reject-call', {'to': toId, 'from': currentUserId});
    } catch (e) {
      debugPrint('⚠ rejectCall emit error: $e');
    }
    onCallEnded?.call();
    _cleanupPeer();
  }

  /// ✅ Cleanup peer connection and streams
  void _cleanupPeer() {
    try {
      _pc?.close();
    } catch (_) {}
    try {
      _localStream?.getTracks().forEach((t) => t.stop());
      _localStream?.dispose();
    } catch (_) {}
    _pc = null;
    _localStream = null;
    _currentTarget = null;
    _pendingCandidates.clear();
    _isAnswering = false;
    debugPrint('🧹 Peer cleaned up');
  }

  /// ✅ Dispose
  void dispose() {
    _cleanupPeer();
    try {
      socket.disconnect();
      socket.dispose();
    } catch (_) {}
  }
}

