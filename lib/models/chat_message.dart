class ChatMessage {
  final String text;
  final DateTime timestamp;
  final bool isUser;
  final bool isRead;
  final String? attachmentUrl;
  final String? attachmentType;
  final String? id;

  ChatMessage({
    required this.text,
    required this.timestamp,
    required this.isUser,
    this.isRead = false,
    this.attachmentUrl,
    this.attachmentType,
    this.id,
  });

  // Новые методы для создания сообщений
  factory ChatMessage.fromUser(String text) {
    return ChatMessage(
      text: text,
      timestamp: DateTime.now(),
      isUser: true,
    );
  }

  factory ChatMessage.fromDriver(String text) {
    return ChatMessage(
      text: text,
      timestamp: DateTime.now(),
      isUser: false,
    );
  }

  // Геттер для проверки, является ли сообщение от водителя
  bool get isFromDriver => !isUser;

  ChatMessage markAsRead() {
    return ChatMessage(
      text: text,
      timestamp: timestamp,
      isUser: isUser,
      isRead: true,
      attachmentUrl: attachmentUrl,
      attachmentType: attachmentType,
      id: id,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isUser': isUser,
      'isRead': isRead,
      'attachmentUrl': attachmentUrl,
      'attachmentType': attachmentType,
      'id': id,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      text: map['text'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      isUser: map['isUser'] ?? false,
      isRead: map['isRead'] ?? false,
      attachmentUrl: map['attachmentUrl'],
      attachmentType: map['attachmentType'],
      id: map['id'],
    );
  }

  // Преобразование из формата базы данных
  factory ChatMessage.fromDatabase(Map<String, dynamic> data) {
    return ChatMessage(
      id: data['id'],
      text: data['text'] ?? '',
      timestamp: data['timestamp'] != null
          ? DateTime.parse(data['timestamp'])
          : DateTime.now(),
      isUser: data['is_from_user'] ?? false,
      isRead: data['is_read'] ?? false,
      attachmentUrl: data['attachment_url'],
      attachmentType: data['attachment_type'],
    );
  }

  // Преобразование в формат для базы данных
  Map<String, dynamic> toDatabase(String driverId) {
    return {
      'driver_id': driverId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'is_from_user': isUser,
      'is_read': isRead,
      'attachment_url': attachmentUrl,
      'attachment_type': attachmentType,
    };
  }
}
