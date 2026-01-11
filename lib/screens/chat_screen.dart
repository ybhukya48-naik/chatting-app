import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import '../services/connection_service.dart';
import '../services/websocket_service.dart';
import '../widgets/chat_bubble.dart';
import '../theme/app_theme.dart';
import 'call_screen.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  final Contact partner;
  final String? chatId;

  const ChatScreen({
    super.key, 
    required this.partner,
    this.chatId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ConnectionService _connectionService = ConnectionService();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  
  String? _myId;
  String? _chatId;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _connectionSubscription;
  List<Message> _messages = [];
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _chatId = widget.chatId;
    _initChat();
  }

  Future<void> _initChat() async {
    final myId = await _connectionService.getDeviceId();
    if (!mounted) return;
    
    setState(() {
      _myId = myId;
    });
    
    if (_chatId == null) {
      // Generate chatId if not provided (e.g., from partner search)
      final ids = [myId, widget.partner.id]..sort();
      _chatId = 'chat_${ids.join("_")}';
    }

    // Listen for messages
    _messageSubscription = _chatService.getMessages(_chatId!).listen((messages) {
      if (mounted) {
        setState(() {
          _messages = messages.map((m) {
            // Update isMe based on senderId
            return Message(
              id: m.id,
              senderId: m.senderId,
              text: m.text,
              timestamp: m.timestamp,
              isMe: m.senderId == myId,
              type: m.type,
              isEncrypted: m.isEncrypted,
              isRead: m.isRead,
            );
          }).toList();
        });

        _scrollToBottom();
      }
    });

    // Listen for connection status
    final webSocketService = WebSocketService();
    _isConnected = webSocketService.isConnected;
    _connectionSubscription = webSocketService.connectionStatusStream.listen((connected) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
        });
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Request permissions
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (status.isPermanentlyDenied) {
          openAppSettings();
          return;
        }
        if (!status.isGranted) return;
      } else {
        if (Platform.isAndroid) {
          // For Android 13+ (API 33+), we need READ_MEDIA_IMAGES
          // For older versions, we need READ_EXTERNAL_STORAGE
          final status = await Permission.photos.request();
          if (!status.isGranted) {
            // Fallback for older Android
            await Permission.storage.request();
          }
        }
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Compress to save space/bandwidth
      );
      
      if (image != null) {
        // In a real app, we would upload to Firebase Storage and send the URL
        // For this high-end UI version, we'll send a message with the local path
        // and a special type so the bubble knows to show an image icon/placeholder
        final message = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: _myId!,
          text: '[Photo]',
          timestamp: DateTime.now(),
          isMe: true,
          type: MessageType.image,
        );

        await _chatService.sendMessage(_chatId!, message);
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _sendMessage() {
    _sendMessageWithText(_messageController.text.trim());
  }

  void _sendMessageWithText(String text) {
    if (text.isEmpty || _myId == null || _chatId == null) return;

    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: _myId!,
      text: text,
      timestamp: DateTime.now(),
      isMe: true,
    );

    _chatService.sendMessage(_chatId!, message);
    if (text == _messageController.text.trim()) {
      _messageController.clear();
    }
    
    _scrollToBottom();
  }

  void _startCall(bool isVideo) async {
    if (_chatId == null || _myId == null) return;

    // Get my name from preferences
    final prefs = await SharedPreferences.getInstance();
    final myName = prefs.getString('user_name') ?? 'Partner';

    // Send call notification to Firebase
    await _connectionService.sendCallNotification(
      partnerId: widget.partner.id,
      chatId: _chatId!,
      isVideo: isVideo,
      callerName: myName,
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallScreen(
            channelName: _chatId!,
            isOutgoing: true,
            isVideo: isVideo,
            partnerName: widget.partner.name,
            partnerId: widget.partner.id,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -100,
            child: _buildGlow(AppTheme.accentColor.withValues(alpha: 0.08), 300),
          ),
          Positioned(
            bottom: 100,
            left: -150,
            child: _buildGlow(AppTheme.accentColor.withValues(alpha: 0.05), 400),
          ),
          
          Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return ChatBubble(message: _messages[index]);
                  },
                ),
              ),
              _buildMessageInput(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 100,
            spreadRadius: 50,
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 15, left: 10, right: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.8),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 5),
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient,
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.surfaceDark,
                  child: Text(
                    widget.partner.name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (widget.partner.isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.successColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.surfaceDark, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.partner.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  !_isConnected 
                    ? 'Connecting...' 
                    : (widget.partner.isOnline ? 'Online' : 'Offline'),
                  style: TextStyle(
                    fontSize: 12, 
                    color: !_isConnected 
                      ? AppTheme.accentColor 
                      : (widget.partner.isOnline ? AppTheme.successColor : Colors.white.withValues(alpha: 0.3)),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.videocam_rounded, color: AppTheme.accentColor),
            onPressed: () => _startCall(true),
          ),
          IconButton(
            icon: const Icon(Icons.call_rounded, color: AppTheme.accentColor),
            onPressed: () => _startCall(false),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 30),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: IconButton(
              icon: const Icon(Icons.add_rounded, color: Colors.white70),
              onPressed: () => _showAttachmentOptions(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentItem(Icons.image_rounded, 'Gallery', Colors.purple, () => _pickImage(ImageSource.gallery)),
                _buildAttachmentItem(Icons.camera_alt_rounded, 'Camera', Colors.blue, () => _pickImage(ImageSource.camera)),
                _buildAttachmentItem(Icons.insert_drive_file_rounded, 'Document', Colors.orange, () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
