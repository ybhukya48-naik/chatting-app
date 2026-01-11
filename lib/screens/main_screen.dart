import 'package:flutter/material.dart';
import 'chat_list_screen.dart';
import 'status_screen.dart';
import 'call_history_screen.dart';
import 'settings_screen.dart';
import '../theme/app_theme.dart';
import '../services/connection_service.dart';
import '../services/websocket_service.dart';
import '../widgets/incoming_call_dialog.dart';
import '../widgets/connection_request_dialog.dart';
import 'dart:async';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ConnectionService _connectionService = ConnectionService();
  StreamSubscription? _requestSubscription;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription? _callSubscription;
  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _checkUserData();
    _listenForIncomingRequests();
    _listenForIncomingCalls();
  }

  Future<void> _checkUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name');
    final phone = prefs.getString('user_phone_number');

    if (name != null && phone != null) {
      // Sync with WebSocket server
      final myId = await _connectionService.getDeviceId();
      WebSocketService().syncProfile(myId, name, phone);
    }
  }

  void _showSetupDialog() {
    // Onboarding is now handled by RegisterScreen
  }

  @override
  void dispose() {
    _tabController.dispose();
    _requestSubscription?.cancel();
    _callSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _listenForIncomingCalls() {
    _callSubscription = _connectionService.listenForIncomingCalls().listen((callData) {
      if (callData != null && callData['status'] == 'ringing') {
        _showIncomingCallDialog(callData);
      }
    });
  }

  void _showIncomingCallDialog(Map<String, dynamic> callData) {
    if (_isDialogOpen) return;
    _isDialogOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => IncomingCallDialog(callData: callData),
    ).then((_) => _isDialogOpen = false);
  }

  void _listenForIncomingRequests() {
    _requestSubscription = _connectionService.listenForRequests().listen((requests) {
      if (requests.isNotEmpty) {
        final pendingRequest = requests.firstWhere(
          (r) => r['status'] == 'pending',
          orElse: () => {},
        );
        if (pendingRequest.isNotEmpty) {
          _showIncomingRequestDialog(pendingRequest);
        }
      }
    });
  }

  void _showIncomingRequestDialog(Map<String, dynamic> request) {
    if (_isDialogOpen) return;
    _isDialogOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConnectionRequestDialog(request: request),
    ).then((_) => _isDialogOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentColor.withValues(alpha: 0.1),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      ChatListScreen(searchQuery: _searchController.text),
                      const StatusScreen(),
                      const CallHistoryScreen(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Custom Floating Bottom Bar
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _isSearching 
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Search conversations...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    border: InputBorder.none,
                    filled: false,
                  ),
                  onChanged: (_) => setState(() {}),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Messages',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.successColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Secure Connection Active',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          ),
          _buildAppBarAction(
            icon: _isSearching ? Icons.close : Icons.search_rounded,
            onTap: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchController.clear();
              });
            },
          ),
          const SizedBox(width: 12),
          _buildAppBarAction(
            icon: Icons.settings_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarAction({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBottomItem(0, Icons.chat_bubble_rounded, 'Chats'),
                _buildBottomItem(1, Icons.favorite_rounded, 'Soul'),
                _buildBottomItem(2, Icons.call_rounded, 'Calls'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomItem(int index, IconData icon, String label) {
    final isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () => setState(() => _tabController.index = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.accentColor : Colors.white.withValues(alpha: 0.4),
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
