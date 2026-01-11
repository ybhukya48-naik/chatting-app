import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/contact.dart';
import '../services/connection_service.dart';
import '../services/storage_service.dart';
import '../screens/chat_screen.dart';

class ConnectionRequestDialog extends StatelessWidget {
  final Map<String, dynamic> request;
  final ConnectionService connectionService = ConnectionService();
  final StorageService storageService = StorageService();

  ConnectionRequestDialog({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final String fromCode = request['fromCode'] ?? 'Unknown';

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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_add_rounded,
                color: AppTheme.accentColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Connection Request',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(color: Colors.white60, fontSize: 14),
                children: [
                  const TextSpan(text: 'Someone with code '),
                  TextSpan(
                    text: fromCode,
                    style: const TextStyle(
                      color: AppTheme.accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: ' wants to connect with you.'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'DECLINE',
                      style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await connectionService.acceptRequest(request);
                      
                      final newContact = Contact(
                        id: request['fromId'] ?? '',
                        name: 'Partner ($fromCode)',
                        status: 'Online',
                        isOnline: true,
                        encryptionKey: request['encryptionKey'] ?? '',
                      );
                      
                      await storageService.savePartner(newContact);
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Connection accepted!')),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(partner: newContact),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'ACCEPT',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
