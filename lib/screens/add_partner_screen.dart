import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/contact.dart';
import '../services/connection_service.dart';

class AddPartnerScreen extends StatefulWidget {
  const AddPartnerScreen({super.key});

  @override
  State<AddPartnerScreen> createState() => _AddPartnerScreenState();
}

class _AddPartnerScreenState extends State<AddPartnerScreen> {
  final TextEditingController _codeController = TextEditingController();
  final ConnectionService _connectionService = ConnectionService();
  String _myConnectionCode = 'Loading...';
  
  bool _isSearching = false;
  Contact? _foundPartner;
  String _requestStatus = 'none'; // none, searching, found, sent, waiting

  @override
  void initState() {
    super.initState();
    _loadMyCode();
  }

  Future<void> _loadMyCode() async {
    try {
      final code = await _connectionService.getConnectionCode().timeout(const Duration(seconds: 10));
      if (mounted) {
        setState(() {
          _myConnectionCode = code;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _myConnectionCode = 'Error loading code';
        });
        _showErrorSnackBar('Failed to load connection code. Please check your connection.');
      }
    }
  }

  void _searchPartner() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _isSearching = true;
      _requestStatus = 'searching';
      _foundPartner = null;
    });

    try {
      // Add a small delay to make the UI feel "high-end" and give Firebase time
      await Future.delayed(const Duration(milliseconds: 800));
      
      final partner = await _connectionService.searchPartner(code)
          .timeout(const Duration(seconds: 15)); // Increased timeout

      if (mounted) {
        setState(() {
          _isSearching = false;
          if (partner != null) {
            _requestStatus = 'found';
            _foundPartner = partner;
          } else {
            _requestStatus = 'none';
            _showErrorSnackBar('No device found with this code. Please check and try again.');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _requestStatus = 'none';
        });
        _showErrorSnackBar(e.toString().contains('Timeout') 
            ? 'Connection timed out. Please check your internet and try again.' 
            : 'Search failed. Please try again later.');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  StreamSubscription? _statusSubscription;

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _sendRequest() async {
    if (_foundPartner == null) return;

    setState(() {
      _requestStatus = 'sent';
    });

    await _connectionService.sendRequest(_foundPartner!, _myConnectionCode);

    if (mounted) {
      setState(() {
        _requestStatus = 'waiting';
      });

      // Listen for acceptance
      _statusSubscription = _connectionService.listenForRequestStatus(_foundPartner!.id).listen((status) async {
        if (status == 'accepted' && mounted) {
          // Success! Clear the request and return the partner
          await _connectionService.clearRequest(_foundPartner!.id);
          if (mounted) {
            Navigator.pop(context, _foundPartner);
          }
        }
      });
      
      // Still keep a timeout to not wait forever
      Future.delayed(const Duration(minutes: 2), () {
        if (mounted && _requestStatus == 'waiting') {
           _statusSubscription?.cancel();
           setState(() {
             _requestStatus = 'none';
           });
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Request timed out.')),
           );
        }
      });
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _myConnectionCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code copied to clipboard!'), duration: Duration(seconds: 1)),
    );
  }

  void _shareCode() {
    if (_myConnectionCode == 'Loading...') return;
    Share.share(
      'Connect with me on Couple Chat! My connection code is: $_myConnectionCode',
      subject: 'Couple Chat Connection Code',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Connect Devices'),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentColor.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.secondaryAccent.withValues(alpha: 0.1),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  if (_requestStatus == 'none' || _requestStatus == 'searching') ...[
                    _buildSectionHeader('Your Connection Code', 'Share this with your partner to link devices.'),
                    const SizedBox(height: 20),
                    _buildMyCodeCard(),
                    const SizedBox(height: 40),
                    _buildSectionHeader('Link a Partner', 'Enter the code displayed on your partner\'s device.'),
                    const SizedBox(height: 20),
                    _buildSearchInput(),
                  ],
                  
                  if (_isSearching) ...[
                    const SizedBox(height: 60),
                    Center(child: Column(
                        children: [
                          const CircularProgressIndicator(
                            color: AppTheme.accentColor,
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Searching for partner...',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_requestStatus == 'found') ...[
                    const SizedBox(height: 40),
                    _buildPartnerFoundCard(),
                  ],

                  if (_requestStatus == 'sent' || _requestStatus == 'waiting') ...[
                    const SizedBox(height: 80),
                    _buildRequestPendingState(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildMyCodeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.glassDecoration.copyWith(
        gradient: LinearGradient(
          colors: [AppTheme.accentColor.withValues(alpha: 0.15), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentColor.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: QrImageView(
              data: _myConnectionCode,
              version: QrVersions.auto,
              size: 160.0,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'YOUR UNIQUE KEY',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _copyToClipboard,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _myConnectionCode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.copy_all_rounded, color: AppTheme.accentColor, size: 24),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _shareCode,
            icon: const Icon(Icons.ios_share_rounded, size: 20),
            label: const Text('SHARE ACCESS CODE', style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput() {
    return Container(
      decoration: AppTheme.glassDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 2),
            decoration: InputDecoration(
              hintText: 'COUPLE-XXXX',
              prefixIcon: const Icon(Icons.link_rounded, color: AppTheme.accentColor),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search_rounded, color: AppTheme.accentColor),
                onPressed: _searchPartner,
              ),
            ),
            onSubmitted: (_) => _searchPartner(),
          ),
          const SizedBox(height: 16),
          const Text(
            'The code is case-sensitive and unique to each device.',
            style: TextStyle(color: Colors.white24, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerFoundCard() {
    if (_foundPartner == null) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.glassDecoration.copyWith(
        border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Text(
                _foundPartner!.name[0].toUpperCase(),
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _foundPartner!.name,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          if (_foundPartner!.phoneNumber != null) ...[
            const SizedBox(height: 8),
            Text(
              _foundPartner!.phoneNumber!,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
            ),
          ],
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _sendRequest,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: AppTheme.accentColor,
              elevation: 8,
              shadowColor: AppTheme.accentColor.withValues(alpha: 0.5),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_rounded),
                SizedBox(width: 12),
                Text('SEND CONNECTION REQUEST'),
              ],
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _requestStatus = 'none'),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestPendingState() {
    return Center(
      child: Column(
        children: [
          const Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  color: AppTheme.accentColor,
                  strokeWidth: 2,
                ),
              ),
              Icon(Icons.favorite_rounded, color: AppTheme.accentColor, size: 50),
            ],
          ),
          const SizedBox(height: 40),
          const Text(
            'Request Sent!',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Waiting for ${_foundPartner?.name ?? 'your partner'} to accept the request on their device...',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 16, height: 1.5),
            ),
          ),
          const SizedBox(height: 60),
          OutlinedButton(
            onPressed: () => setState(() => _requestStatus = 'none'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white38,
              side: const BorderSide(color: Colors.white10),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );
  }
}
