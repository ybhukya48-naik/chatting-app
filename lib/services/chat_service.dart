import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/message.dart';
import 'websocket_service.dart';

class ChatService {
  final _database = FirebaseDatabase.instance.ref();
  final _webSocketService = WebSocketService();

  // Switch to WebSocket stream
  Stream<List<Message>> getMessages(String chatId) {
    // Connect to WebSocket server for this chat
    _webSocketService.connect(chatId);
    return _webSocketService.messagesStream;
    
    /* Original Firebase Implementation:
    return _database.child('chats/$chatId/messages').onValue.map((event) {
      final messages = <Message>[];
      final snapshotValue = event.snapshot.value;
      
      if (snapshotValue != null) {
        if (snapshotValue is Map) {
          snapshotValue.forEach((key, value) {
            if (value is Map) {
              messages.add(Message.fromMap(Map<String, dynamic>.from(value)));
            }
          });
        } else if (snapshotValue is List) {
          for (var value in snapshotValue) {
            if (value is Map) {
              messages.add(Message.fromMap(Map<String, dynamic>.from(value)));
            }
          }
        }
        
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }
      return messages;
    });
    */
  }

  Future<void> sendMessage(String chatId, Message message) async {
    // Send via WebSocket - The backend will now persist this to Neon DB
    _webSocketService.sendMessage(chatId, message);
    
    // Update last message in Firebase for the chat list (optional/UI helper)
    await _database.child('chats/$chatId/lastMessage').set({
      'text': message.text,
      'timestamp': ServerValue.timestamp,
      'senderId': message.senderId,
    });
  }

  Future<void> markAsRead(String chatId, String messageId) async {
    // Simple implementation for now
  }
}
