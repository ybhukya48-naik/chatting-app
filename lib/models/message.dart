
enum MessageType { text, image, video }

class Message {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isMe;
  final MessageType type;
  final bool isEncrypted;
  final bool isRead;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isMe,
    this.type = MessageType.text,
    this.isEncrypted = false,
    this.isRead = false,
  });

  // Simple simulation of encryption by hashing the text if not me
  String get displayMessage => isEncrypted && !isMe ? "🔐 Encrypted message" : text;

  Map<String, dynamic> toMap() => {
        'id': id,
        'senderId': senderId,
        'text': text,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'type': type.index,
        'isEncrypted': isEncrypted,
        'isRead': isRead,
      };

  factory Message.fromMap(Map<String, dynamic> map, {String? currentUserId}) => Message(
        id: map['id'] ?? '',
        senderId: map['senderId'] ?? '',
        text: map['text'] ?? '',
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
        isMe: currentUserId != null && map['senderId'] == currentUserId,
        type: MessageType.values[map['type'] ?? 0],
        isEncrypted: map['isEncrypted'] ?? false,
        isRead: map['isRead'] ?? false,
      );

  Map<String, dynamic> toJson() => toMap();

  factory Message.fromJson(Map<String, dynamic> json) => Message.fromMap(json);

  Message copyWith({
    String? id,
    String? senderId,
    String? text,
    DateTime? timestamp,
    bool? isMe,
    MessageType? type,
    bool? isEncrypted,
    bool? isRead,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isMe: isMe ?? this.isMe,
      type: type ?? this.type,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      isRead: isRead ?? this.isRead,
    );
  }
}
