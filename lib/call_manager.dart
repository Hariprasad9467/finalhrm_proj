import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
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
  String? currentRoomId; // ✅ For group calls

  CallManager({
    required this.serverUrl,
    required this.currentUserId,
  });

  // ✅ Initialize socket connection
  Future<void> init() async {
    socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
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

    // ✅ Call accepted
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

    // ✅ ICE candidates
    socket.on('ice-candidate', (data) async {
      try {
        final cand = Map<String, dynamic>.from(data['candidate'] ?? {});
        final candidate = RTCIceCandidate(
          cand['candidate'] as String?,
          cand['sdpMid'] as String?,
          cand['sdpMLineIndex'] as int?,
        );
        if (_pc != null) await _pc!.addCandidate(candidate);
      } catch (e) {
        debugPrint('⚠ ice-candidate parse error: $e');
      }
    });

    socket.onDisconnect((_) {
      debugPrint('⚠ Socket disconnected');
    });
  }

  /// ✅ Create Peer Connection
  Future<RTCPeerConnection> _createPeerConnection(
    bool isVideo,
    String targetId,
  ) async {
    final configuration = <String, dynamic>{
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'}
      ]
    };

    final pc = await createPeerConnection(configuration);

    // Handle ICE candidates
    pc.onIceCandidate = (RTCIceCandidate c) {
      if (c.candidate != null) {
        socket.emit('ice-candidate', {
          'to': targetId,
          'candidate': {
            'candidate': c.candidate,
            'sdpMid': c.sdpMid,
            'sdpMLineIndex': c.sdpMLineIndex,
          }
        });
      }
    };

    // Handle remote tracks
    pc.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        final stream = event.streams.first;
        debugPrint('🎥 Remote track added (${event.track.kind})');
        onRemoteStream?.call(stream);
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

  /// ✅ Start a call (caller)
  Future<void> startCall({
    required String targetId,
    required bool isVideo,
  }) async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': isVideo,
    });
    onLocalStream?.call(_localStream!);

    _pc = await _createPeerConnection(isVideo, targetId);

    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        await _pc!.addTrack(track, _localStream!);
      }
    }

    // ✅ Create room for group call
    createRoom(targetId);

    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);

    socket.emit('call-user', {
      'target': targetId,
      'from': currentUserId,
      'signal': {
        'sdp': offer.sdp,
        'type': offer.type,
        'isVideo': isVideo,
        'roomId': currentRoomId,
      }
    });
  }

  /// ✅ Answer a call (receiver)
  Future<void> answerCall({
    required String fromId,
    required Map signal,
  }) async {
    _currentTarget = fromId;
    final isVideo = signal['isVideo'] == true;

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': isVideo,
    });

    onLocalStream?.call(_localStream!);

    _pc = await _createPeerConnection(isVideo, fromId);

    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        await _pc!.addTrack(track, _localStream!);
      }
    }

    // ✅ Save room ID if provided
    if (signal['roomId'] != null) {
      currentRoomId = signal['roomId'];
      debugPrint("📦 Joined existing room: $currentRoomId");
    }

    final remoteSdp = signal['sdp'] as String?;
    final remoteType = signal['type'] as String?;
    if (remoteSdp != null && remoteType != null) {
      await _pc!.setRemoteDescription(
        RTCSessionDescription(remoteSdp, remoteType),
      );
    }

    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);

    socket.emit('answer-call', {
      'to': fromId,
      'signal': {'sdp': answer.sdp, 'type': answer.type},
    });
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
    currentRoomId = null;
  }

  /// ✅ Dispose
  void dispose() {
    try {
      socket.dispose();
    } catch (e) {
      debugPrint('⚠ Socket dispose error: $e');
    }
  }
}