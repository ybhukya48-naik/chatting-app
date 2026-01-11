import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/call_screen.dart';
import '../services/connection_service.dart';

class IncomingCallDialog extends StatelessWidget {
  final Map<String, dynamic> callData;
  final ConnectionService connectionService = ConnectionService();

  IncomingCallDialog({super.key, required this.callData});

  @override
  Widget build(BuildContext context) {
    final bool isVideo = callData['isVideo'] ?? false;
    final String callerName = callData['callerName'] ?? 'Partner';
    final String callerId = callData['callerId'] ?? '';
    final String chatId = callData['chatId'] ?? '';

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isVideo ? 'Incoming Video Call' : 'Incoming Voice Call',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.accentColor, width: 2),
              ),
              child: const CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.surfaceDark,
                child: Icon(Icons.person_rounded, size: 60, color: Colors.white24),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCallAction(
                  icon: Icons.close_rounded,
                  color: Colors.redAccent,
                  onPressed: () async {
                    Navigator.pop(context);
                    await connectionService.endCall(callerId);
                  },
                ),
                _buildCallAction(
                  icon: isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                  color: AppTheme.successColor,
                  onPressed: () async {
                    Navigator.pop(context);
                    await connectionService.updateCallStatus(callerId, 'accepted');
                    
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CallScreen(
                            channelName: chatId,
                            isOutgoing: false,
                            isVideo: isVideo,
                            partnerName: callerName,
                            partnerId: callerId,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
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
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: 32),
      ),
    );
  }
}
