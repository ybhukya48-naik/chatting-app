import 'package:flutter/material.dart';
import 'add_partner_screen.dart';
import '../widgets/chat_list_item.dart';
import '../theme/app_theme.dart';
import '../models/contact.dart';
import '../services/storage_service.dart';

class ChatListScreen extends StatefulWidget {
  final String searchQuery;
  const ChatListScreen({super.key, this.searchQuery = ''});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final StorageService _storageService = StorageService();
  List<Contact> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void didUpdateWidget(ChatListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      _filterContacts(widget.searchQuery);
    }
  }

  Future<void> _loadContacts() async {
    final contacts = await _storageService.loadPartners();
    if (mounted) {
      setState(() {
        _contacts = contacts;
        _isLoading = false;
        _filterContacts(widget.searchQuery);
      });
    }
  }

  List<Contact> _filteredContacts = [];

  void _filterContacts(String query) {
    setState(() {
      _filteredContacts = _contacts
          .where((contact) =>
              contact.name.toLowerCase().contains(query.toLowerCase()) ||
              (contact.phoneNumber?.contains(query) ?? false))
          .toList();
    });
  }

  Future<void> _navigateToAddPartner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPartnerScreen()),
    );

    if (result != null && result is Contact) {
      await _loadContacts(); // Reload contacts from storage
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection request sent to ${result.name}!'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.backgroundDark,
              AppTheme.surfaceDark,
              AppTheme.backgroundDark.withBlue(20),
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: _buildSearchBar(),
            ),
            _isLoading
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: AppTheme.accentColor)),
                  )
                : _contacts.isEmpty
                    ? _buildEmptyState()
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final contact = _filteredContacts[index];
                              return ChatListItem(contact: contact);
                            },
                            childCount: _filteredContacts.length,
                          ),
                        ),
                      ),
          ],
        ),
      ),
      floatingActionButton: _buildPremiumFAB(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('MESSAGES', 
              style: TextStyle(
                fontWeight: FontWeight.w900, 
                letterSpacing: 2,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            Text('You have ${_contacts.length} active chats', 
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.5),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        background: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentColor.withValues(alpha: 0.3),
                    AppTheme.backgroundDark,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: -20,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentColor.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              top: 50,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.5), width: 2),
                ),
                child: const CircleAvatar(
                  radius: 25,
                  backgroundColor: AppTheme.surfaceDark,
                  child: Icon(Icons.person_outline, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        decoration: AppTheme.glassDecoration,
        child: TextField(
          onChanged: _filterContacts,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search conversations...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            prefixIcon: const Icon(Icons.search, color: Colors.white38),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite_rounded, size: 80, color: AppTheme.accentColor),
              ),
              const SizedBox(height: 32),
              const Text(
                'Connect Your Partner',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Add your soulmate to start sharing your private moments securely.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _navigateToAddPartner,
                icon: const Icon(Icons.link_rounded),
                label: const Text('LINK PARTNER NOW'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                  backgroundColor: AppTheme.accentColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: _navigateToAddPartner,
        backgroundColor: Colors.transparent,
        elevation: 0,
        highlightElevation: 0,
        label: const Text('ADD PARTNER', 
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        icon: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}
