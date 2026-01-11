import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/message.dart';

import '../config/app_config.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  IO.Socket? socket;
  final _messageController = StreamController<List<Message>>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();
  final List<Message> _messages = [];
  String? _currentChatId;

  Stream<List<Message>> get messagesStream => _messageController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  bool get isConnected => socket?.connected ?? false;

  void connect(String chatId) {
    if (_currentChatId == chatId && socket?.connected == true) return;
    
    _currentChatId = chatId;
    _messages.clear();

    String serverUrl;
    
    if (AppConfig.isProduction) {
      serverUrl = AppConfig.productionBackendUrl;
    } else {
      if (kIsWeb) {
        serverUrl = AppConfig.localBackendUrl;
      } else if (Platform.isAndroid) {
        // Automatically distinguish between emulator and physical device if possible
        // For simplicity, we use the configured IP or emulator URL
        serverUrl = AppConfig.localAndroidDeviceUrl; 
      } else if (Platform.isWindows) {
        serverUrl = AppConfig.localBackendUrl;
      } else {
        serverUrl = AppConfig.localBackendUrl;
      }
    }
    
    print('Attempting to connect to WebSocket at: $serverUrl');

    socket = IO.io(serverUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .enableAutoConnect()
      .setReconnectionAttempts(15)
      .setReconnectionDelay(1000)
      .setQuery({
        'platform': kIsWeb ? 'web' : Platform.operatingSystem,
        'chatId': chatId,
      })
      .build());

    print('Connecting to $serverUrl ...');
    socket!.connect();

    socket!.onConnect((_) {
      print('Connected to WebSocket server');
      _connectionStatusController.add(true);
      if (_currentChatId != null) {
        socket!.emit('join_chat', _currentChatId);
      }
    });

    socket!.on('previous_messages', (data) {
      if (data is List) {
        _messages.clear();
        for (var item in data) {
          // We don't know the current user ID here, so we'll set it in the UI
          _messages.add(Message.fromMap(Map<String, dynamic>.from(item)));
        }
        _messageController.add(List.from(_messages));
      }
    });

    socket!.on('receive_message', (data) {
      final message = Message.fromMap(Map<String, dynamic>.from(data));
      // Avoid duplicate messages on reconnect
      if (!_messages.any((m) => m.id == message.id)) {
        _messages.add(message);
        _messageController.add(List.from(_messages));
      }
    });

    socket!.onReconnect((_) {
      print('Reconnected to WebSocket server');
      if (_currentChatId != null) {
        socket!.emit('join_chat', _currentChatId);
      }
    });

    socket!.onDisconnect((_) {
      print('Disconnected from WebSocket server');
      _connectionStatusController.add(false);
    });
    
    socket!.onConnectError((err) {
      print('Connect Error: $err');
      _connectionStatusController.add(false);
    });
    
    socket!.onError((err) {
      print('Error: $err');
      _connectionStatusController.add(false);
    });
  }

  void syncProfile(String id, String name, String phone) {
    if (socket?.connected == true) {
      socket!.emit('sync_profile', {
        'id': id,
        'name': name,
        'phone': phone,
      });
    } else {
      // Connect first if not connected
      connect(''); 
      // Wait for connect to sync (or retry)
      socket!.onConnect((_) {
        socket!.emit('sync_profile', {
          'id': id,
          'name': name,
          'phone': phone,
        });
      });
    }
  }

  void sendMessage(String chatId, Message message) {
    if (socket?.connected == true) {
      socket!.emit('send_message', {
        'chatId': chatId,
        'message': message.toMap(),
      });
    } else {
      print('Socket not connected. Cannot send message.');
    }
  }

  void dispose() {
    socket?.disconnect();
    socket?.dispose();
    _messageController.close();
    _connectionStatusController.close();
  }
}
