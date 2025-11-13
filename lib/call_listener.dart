// lib/call_listener.dart
import 'package:flutter/material.dart';
import 'call_manager.dart';
//import 'call_popup.dart';
import 'audio_call_page.dart';

class CallListener extends StatefulWidget {
  final Widget child;
  final String currentUserId;

  const CallListener({super.key, required this.child, required this.currentUserId});

  @override
  State<CallListener> createState() => _CallListenerState();
}

class _CallListenerState extends State<CallListener> {
  late CallManager _callManager;

  @override
  void initState() {
    super.initState();
    _callManager = CallManager(serverUrl: 'http://localhost:5000', currentUserId: widget.currentUserId);

    _callManager.onIncomingCall = (fromId, signal) {
      final isVideo = signal['isVideo'] == true;
      _showIncoming(fromId, isVideo, signal);
    };

    _callManager.onCallEnded = () {
      if (Navigator.canPop(context)) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
    };

    _callManager.init();

    _callManager.socket.on('call-ended', (data) {
    if (Navigator.canPop(context)) {
      Navigator.popUntil(context, (route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caller ended the call')),
      );
    }
  });
  }

  void _showIncoming(String fromId, bool isVideo, Map signal) {
  if (!mounted) return;

  Navigator.push(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => Scaffold(
        backgroundColor: Colors.black.withOpacity(0.9),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isVideo ? Icons.videocam : Icons.call, size: 90, color: Colors.deepPurple),
              const SizedBox(height: 20),
              Text('$fromId is calling...', style: const TextStyle(color: Colors.white, fontSize: 20)),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ✅ Reject button
                  ElevatedButton.icon(
                      icon: const Icon(Icons.call_end),
                      label: const Text("Reject"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () {
                        _callManager.rejectCall(fromId);
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                    ),
                    const SizedBox(width: 20),
                    // ✅ Accept button
                    ElevatedButton.icon(
                      icon: const Icon(Icons.call),
                      label: const Text("Accept"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () {
                        Navigator.pop(context); // close popup
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AudioCallPage(
                              currentUserId: widget.currentUserId,
                              targetUserId: fromId,
                              isCaller: false,
                              isVideo: isVideo,
                              offerSignal: signal, // ✅ important
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  @override
  void dispose() {
    _callManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}