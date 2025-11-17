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

  // Queue to store early ICE candidates
  final List<RTCIceCandidate> _pendingCandidates = [];
  bool _isAnswering = false;

  CallManager({required this.serverUrl, required this.currentUserId});

  // Initialize socket connection
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

    // Incoming call
    socket.on('incoming-call', (data) {
      try {
        final from = data['from'] as String;
        final signal = Map<String, dynamic>.from(data['signal'] ?? {});
        onIncomingCall?.call(from, signal);
      } catch (e) {
        debugPrint('⚠ incoming-call parse error: $e');
      }
    });

    // Offer handler
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
          // Setup peer connection first
          await _setupReceiverPeerConnection(from, isVideo);

          // Set remote description
          await _pc!.setRemoteDescription(RTCSessionDescription(sdp, type));
          debugPrint('✅ Remote description set (offer)');

          // Process pending candidates
          if (_pendingCandidates.isNotEmpty) {
            debugPrint('📦 Adding ${_pendingCandidates.length} pending candidates');
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

    // Answer handler
    socket.on('answer', (data) async {
      try {
        debugPrint('📥 Received answer from ${data['from']}');
        final answerMap = Map<String, dynamic>.from(data['answer'] ?? {});
        final sdp = answerMap['sdp'] as String?;
        final type = answerMap['type'] as String?;

        if (sdp != null && type != null && _pc != null) {
          await _pc!.setRemoteDescription(RTCSessionDescription(sdp, type));
          debugPrint('✅ Remote description set (answer)');

          // Process pending candidates after answer
          if (_pendingCandidates.isNotEmpty) {
            debugPrint('📦 Adding ${_pendingCandidates.length} pending candidates');
            for (var candidate in _pendingCandidates) {
              try {
                await _pc!.addCandidate(candidate);
              } catch (e) {
                debugPrint('⚠ Error adding pending candidate: $e');
              }
            }
            _pendingCandidates.clear();
          }
        }
      } catch (e) {
        debugPrint('⚠ answer handler error: $e');
      }
    });

    // Backwards-compatible call accepted
    socket.on('call-accepted', (data) async {
      try {
        final signal = Map<String, dynamic>.from(data as Map);
        final sdp = signal['sdp'] as String?;
        final type = signal['type'] as String?;
        if (sdp != null && type != null && _pc != null) {
          await _pc!.setRemoteDescription(RTCSessionDescription(sdp, type));
        }
      } catch (e) {
        debugPrint('⚠ call-accepted error: $e');
      }
    });

    // Rejection / end
    socket.on('call-rejected', (data) {
      debugPrint('ℹ Received call-rejected: $data');
      onCallEnded?.call();
      _cleanupPeer();
    });

    socket.on('call-ended', (data) {
      debugPrint('ℹ Received call-ended: $data');
      onCallEnded?.call();
      _cleanupPeer();
    });

    // ICE candidate with queueing
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
        final sdpIndex = sdpMLineIndex is int ? sdpMLineIndex : int.tryParse('$sdpMLineIndex');

        if (candidateStr == null || candidateStr.isEmpty) {
          debugPrint('⚠ Empty candidate string');
          return;
        }

        final candidate = RTCIceCandidate(candidateStr, sdpMid, sdpIndex);

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

  // Setup peer connection for receiver (when offer arrives)
  Future<void> _setupReceiverPeerConnection(String fromId, bool isVideo) async {
    _currentTarget = fromId;

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': isVideo ? {'facingMode': 'user'} : false,
    });

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        await Helper.setSpeakerphoneOn(true);
      } catch (e) {
        debugPrint('⚠ Speaker setup error: $e');
      }
    }

    debugPrint('🔈 Local audio tracks: ${_localStream?.getAudioTracks().length}');
    if (isVideo) {
      debugPrint('🎥 Local video tracks: ${_localStream?.getVideoTracks().length}');
    }

    onLocalStream?.call(_localStream!);

    _pc = await _createPeerConnection(isVideo, fromId);

    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        await _pc!.addTrack(track, _localStream!);
        debugPrint('➕ Added local track: ${track.kind}');
      }
    }
  }

  /// Create Peer Connection with TURN servers
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

    // ICE / connection logs
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

    // NOTE: removed manual addTransceiver block because it's unsupported on many platforms.
    debugPrint("🎯 Using auto track handling (no manual transceiver)");

    // Improved onTrack handler (safe fallback)
    pc.onTrack = (RTCTrackEvent event) {
      try {
        debugPrint(
          '📹 onTrack: kind=${event.track.kind}, streams=${event.streams.length}, enabled=${event.track.enabled}',
        );

        if (event.streams.isNotEmpty) {
          final remoteStream = event.streams.first;
          debugPrint(
              '✅ onTrack: using provided stream (audio=${remoteStream.getAudioTracks().length}, video=${remoteStream.getVideoTracks().length})');
          onRemoteStream?.call(remoteStream);
        } else {
          // fallback: create a MediaStream via createLocalMediaStream and add the track
          try {
            createLocalMediaStream('remote-${DateTime.now().millisecondsSinceEpoch}')
                .then((ms) {
              try {
                ms.addTrack(event.track);
                debugPrint('✅ onTrack: created stream via createLocalMediaStream and added track (fallback)');
                onRemoteStream?.call(ms);
              } catch (e) {
                debugPrint('⚠ Error adding track to created stream: $e');
              }
            }).catchError((e) {
              debugPrint('⚠ createLocalMediaStream error: $e');
            });
          } catch (e) {
            debugPrint('⚠ onTrack fallback error: $e');
          }
        }
      } catch (e) {
        debugPrint('⚠ onTrack handler error: $e');
      }
    };

    // onAddStream fallback (older implementations)
    try {
      pc.onAddStream = (MediaStream stream) {
        try {
          debugPrint('📥 onAddStream: audio=${stream.getAudioTracks().length}, video=${stream.getVideoTracks().length}');
          onRemoteStream?.call(stream);
        } catch (e) {
          debugPrint('⚠ onAddStream inner error: $e');
        }
      };
    } catch (e) {
      debugPrint('ℹ onAddStream not supported on this platform: $e');
    }

    // ICE candidate emission
    pc.onIceCandidate = (c) {
      try {
        if (c == null || c.candidate == null) return;

        socket.emit('ice-candidate', {
          'to': targetId,
          'candidate': {
            'candidate': c.candidate,
            'sdpMid': c.sdpMid,
            'sdpMLineIndex': c.sdpMLineIndex,
          }
        });
      } catch (e) {
        debugPrint('⚠ onIceCandidate error: $e');
      }
    };

    return pc;
  }

  /// Create room (group call)
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

  /// Invite participant to existing room
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

  /// Start a call (caller)
  Future<void> startCall({
    required String targetId,
    required bool isVideo,
  }) async {
    _currentTarget = targetId;
    _pendingCandidates.clear();

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': isVideo ? {'facingMode': 'user'} : false,
    });

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        await Helper.setSpeakerphoneOn(true);
      } catch (e) {
        debugPrint('⚠ Speaker setup error: $e');
      }
    }

    debugPrint('🔈 Local audio tracks: ${_localStream?.getAudioTracks().length}');
    if (isVideo) {
      debugPrint('🎥 Local video tracks: ${_localStream?.getVideoTracks().length}');
    }

    onLocalStream?.call(_localStream!);

    _pc = await _createPeerConnection(isVideo, targetId);

    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        await _pc!.addTrack(track, _localStream!);
        debugPrint('➕ Added local track: ${track.kind}');
      }
    }

    currentRoomId = "room_${DateTime.now().millisecondsSinceEpoch}";

    // Create offer
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

    // compatibility emit
    socket.emit('call-user', {
      'target': targetId,
      'from': currentUserId,
      'signal': {
        'sdp': offer.sdp,
        'type': offer.type,
        'isVideo': isVideo,
        'roomId': currentRoomId,
      },
    });

    debugPrint('✅ Offer and call-user sent');
  }

  /// Answer a call (receiver)
  Future<void> answerCall({required String fromId, required Map signal}) async {
    _currentTarget = fromId;
    _pendingCandidates.clear();
    final isVideo = signal['isVideo'] == true;

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': isVideo ? {'facingMode': 'user'} : false,
    });

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        await Helper.setSpeakerphoneOn(true);
      } catch (e) {
        debugPrint('⚠ Speaker setup error: $e');
      }
    }

    debugPrint('🔈 Local audio tracks: ${_localStream?.getAudioTracks().length}');
    onLocalStream?.call(_localStream!);

    _pc = await _createPeerConnection(isVideo, fromId);

    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        await _pc!.addTrack(track, _localStream!);
      }
    }

    // Save room ID if provided
    if (signal['roomId'] != null) {
      currentRoomId = signal['roomId'];
      debugPrint("📦 Joined existing room: $currentRoomId");
    }

    final remoteSdp = signal['sdp'] as String?;
    final remoteType = signal['type'] as String?;
    if (remoteSdp != null && remoteType != null) {
      await _pc!.setRemoteDescription(RTCSessionDescription(remoteSdp, remoteType));
      debugPrint('✅ Remote description set from signal');
    }

    // Create and send answer
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

    // compatibility emit
    socket.emit('answer-call', {
      'to': fromId,
      'signal': {'sdp': answer.sdp, 'type': answer.type},
    });

    debugPrint('✅ Answer sent');
  }

  /// End call
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

  /// Reject incoming call
  void rejectCall(String toId) {
    try {
      socket.emit('reject-call', {'to': toId, 'from': currentUserId});
    } catch (e) {
      debugPrint('⚠ rejectCall emit error: $e');
    }
    onCallEnded?.call();
    _cleanupPeer();
  }

  /// Cleanup peer connection and streams
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

  /// Dispose
  void dispose() {
    _cleanupPeer();
    try {
      socket.disconnect();
      socket.dispose();
    } catch (_) {}
  }
}