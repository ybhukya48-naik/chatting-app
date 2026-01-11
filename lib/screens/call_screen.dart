import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../services/connection_service.dart';

import '../config/app_config.dart';

class CallScreen extends StatefulWidget {
  final String channelName;
  final bool isOutgoing;
  final bool isVideo;
  final String partnerName;
  final String partnerId;

  const CallScreen({
    super.key,
    required this.channelName,
    required this.isOutgoing,
    required this.isVideo,
    required this.partnerName,
    required this.partnerId,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  static const String appId = AppConfig.agoraAppId; 
  
  int? _remoteUid;
  bool _localUserJoined = false;
  bool _isMuted = false;
  bool _isCameraOff = false;
  RtcEngine? _engine;
  final ConnectionService _connectionService = ConnectionService();
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    try {
      // retrieve permissions
      await [Permission.microphone, Permission.camera].request();

      //create the engine
      _engine = createAgoraRtcEngine();
      final engine = _engine!;
      
      await engine.initialize(const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint("local user ${connection.localUid} joined");
            if (!_isDisposed && mounted) {
              setState(() {
                _localUserJoined = true;
              });
            }
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint("remote user $remoteUid joined");
            if (!_isDisposed && mounted) {
              setState(() {
                _remoteUid = remoteUid;
              });
            }
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            debugPrint("remote user $remoteUid left channel");
            if (!_isDisposed && mounted) {
              setState(() {
                _remoteUid = null;
              });
              _onEndCall();
            }
          },
          onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
            debugPrint('[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token');
          },
        ),
      );

      if (widget.isVideo) {
        await engine.enableVideo();
        await engine.startPreview();
      } else {
        await engine.disableVideo();
      }

      await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await engine.joinChannel(
        token: '', // Replace with your real token if using one
        channelId: widget.channelName,
        uid: 0,
        options: const ChannelMediaOptions(),
      );
    } catch (e) {
      debugPrint("Error initializing Agora: $e");
      if (!_isDisposed && mounted) {
        _onEndCall();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _dispose();
    super.dispose();
  }

  Future<void> _dispose() async {
    if (_engine != null) {
      await _engine!.leaveChannel();
      await _engine!.release();
      _engine = null;
    }
  }

  void _onToggleMute() {
    if (_engine == null) return;
    setState(() {
      _isMuted = !_isMuted;
    });
    _engine!.muteLocalAudioStream(_isMuted);
  }

  void _onToggleCamera() {
    if (_engine == null) return;
    setState(() {
      _isCameraOff = !_isCameraOff;
    });
    _engine!.muteLocalVideoStream(_isCameraOff);
  }

  void _onSwitchCamera() {
    if (_engine == null) return;
    _engine!.switchCamera();
  }

  void _onEndCall() async {
    await _connectionService.endCall(widget.partnerId);
    if (mounted) {
      Navigator.pop(context);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          // Remote Video (Full Screen)
          Positioned.fill(child: _remoteVideo()),
          
          // Local Video (Small Overlay)
          if (widget.isVideo)
            Positioned(    
              top: MediaQuery.of(context).padding.top + 20,
              right: 20,
              child: Container(
                width: 120,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _localUserJoined && !_isCameraOff && _engine != null
                      ? AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: _engine!,
                            canvas: const VideoCanvas(uid: 0),
                          ),
                        )
                      : Container(
                          color: AppTheme.surfaceDark,
                          child: const Icon(Icons.videocam_off_rounded, color: Colors.white24, size: 32),
                        ),
                ),
              ),
            ),

          // User Info (Top Center)
          Positioned(
            top: MediaQuery.of(context).padding.top + 40,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.partnerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _remoteUid != null ? "CONNECTED" : (widget.isOutgoing ? "CALLING..." : "INCOMING..."),
                    style: TextStyle(
                      color: _remoteUid != null ? AppTheme.successColor : AppTheme.accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Toolbar (Glassmorphism)
          _buildToolbar(),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Positioned(
      bottom: 40,
      left: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCallAction(
              icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
              color: _isMuted ? AppTheme.errorColor : Colors.white24,
              onPressed: _onToggleMute,
            ),
            if (widget.isVideo) ...[
              _buildCallAction(
                icon: _isCameraOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                color: _isCameraOff ? AppTheme.errorColor : Colors.white24,
                onPressed: _onToggleCamera,
              ),
              _buildCallAction(
                icon: Icons.flip_camera_ios_rounded,
                color: Colors.white24,
                onPressed: _onSwitchCamera,
              ),
            ],
            _buildCallAction(
              icon: Icons.call_end_rounded,
              color: AppTheme.errorColor,
              onPressed: _onEndCall,
              isLarge: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallAction({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isLarge = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(isLarge ? 18 : 14),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: isLarge ? 32 : 24,
        ),
      ),
    );
  }

  Widget _remoteVideo() {
    if (_remoteUid != null && _engine != null) {
      if (widget.isVideo) {
        return AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: _engine!,
            canvas: VideoCanvas(uid: _remoteUid),
            connection: RtcConnection(channelId: widget.channelName),
          ),
        );
      } else {
        return Container(
          color: AppTheme.backgroundDark,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentColor.withValues(alpha: 0.2),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.partnerName[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                "Voice Calling...",
                style: TextStyle(color: Colors.white54, fontSize: 18, letterSpacing: 1),
              ),
            ],
          ),
        );
      }
    } else {
      return Container(
        color: AppTheme.backgroundDark,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.accentColor),
            const SizedBox(height: 24),
            Text(
              widget.isOutgoing ? "Waiting for partner..." : "Connecting...",
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      );
    }
  }
}
