import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          _buildMyStatus(),
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 32, 8, 16),
            child: Text('RECENT UPDATES', 
              style: TextStyle(
                color: AppTheme.accentColor, 
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.5,
              )
            ),
          ),
          _buildPartnerStatus(),
          const SizedBox(height: 100),
        ],
      ),
      floatingActionButton: _buildFloatingActions(),
    );
  }

  Widget _buildMyStatus() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
              ),
              child: const CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white10,
                child: Icon(Icons.person_rounded, color: Colors.white24, size: 32),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
        title: const Text('My Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
        subtitle: Text('Share a moment with your partner', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13)),
      ),
    );
  }

  Widget _buildPartnerStatus() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppTheme.primaryGradient,
          ),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.backgroundDark,
            ),
            child: const CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.surfaceDark,
              child: Icon(Icons.person_rounded, color: Colors.white, size: 28),
            ),
          ),
        ),
        title: const Text('My Love ❤️', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
        subtitle: Text('Just now', style: TextStyle(color: AppTheme.accentColor.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w500)),
        onTap: () {},
      ),
    );
  }

  Widget _buildFloatingActions() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          onPressed: () {},
          backgroundColor: AppTheme.surfaceDark,
          mini: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.edit_rounded, color: Colors.white70, size: 20),
        ),
        const SizedBox(height: 16),
        Container(
          height: 60,
          width: 60,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppTheme.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentColor,
                blurRadius: 15,
                spreadRadius: -5,
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () {},
            backgroundColor: Colors.transparent,
            elevation: 0,
            shape: const CircleBorder(),
            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }
}
