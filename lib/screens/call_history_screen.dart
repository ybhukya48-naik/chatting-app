import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/call_record.dart';
import 'package:intl/intl.dart';

class CallHistoryScreen extends StatelessWidget {
  const CallHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for now
    final List<CallRecord> calls = [
      CallRecord(
        id: '1',
        partnerId: 'p1',
        partnerName: 'My Love ❤️',
        type: CallType.video,
        status: CallStatus.received,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        duration: const Duration(minutes: 15, seconds: 30),
      ),
      CallRecord(
        id: '2',
        partnerId: 'p1',
        partnerName: 'My Love ❤️',
        type: CallType.voice,
        status: CallStatus.outgoing,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        duration: const Duration(minutes: 5),
      ),
      CallRecord(
        id: '3',
        partnerId: 'p1',
        partnerName: 'My Love ❤️',
        type: CallType.video,
        status: CallStatus.missed,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];

    if (calls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call_end_rounded, size: 60, color: Colors.white10),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Call History',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your call logs will appear here',
              style: TextStyle(color: Colors.white24, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: calls.length,
      itemBuilder: (context, index) {
        final call = calls[index];
        final isMissed = call.status == CallStatus.missed;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isMissed ? AppTheme.errorColor.withValues(alpha: 0.1) : AppTheme.accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  call.type == CallType.video ? Icons.videocam_rounded : Icons.call_rounded,
                  color: isMissed ? AppTheme.errorColor : AppTheme.accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      call.partnerName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: isMissed ? TextDecoration.none : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          call.status == CallStatus.outgoing
                              ? Icons.call_made_rounded
                              : call.status == CallStatus.received
                                  ? Icons.call_received_rounded
                                  : Icons.call_missed_rounded,
                          size: 14,
                          color: isMissed ? AppTheme.errorColor : AppTheme.successColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${DateFormat('MMM d, h:mm a').format(call.timestamp)}${call.duration != null ? ' • ${call.duration!.inMinutes}m ${call.duration!.inSeconds % 60}s' : ''}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  call.type == CallType.video ? Icons.videocam_outlined : Icons.call_outlined,
                  color: Colors.white38,
                  size: 22,
                ),
                onPressed: () {},
              ),
            ],
          ),
        );
      },
    );
  }
}
