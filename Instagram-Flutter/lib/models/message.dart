class Message {
  final int? messageId;
  final String content;
  final int senderId;
  final String senderUsername;
  final String? senderProfilePicture;
  final int receiverId;
  final DateTime createdAt;
  final bool read;

  Message({
    this.messageId,
    required this.content,
    required this.senderId,
    required this.senderUsername,
    this.senderProfilePicture,
    required this.receiverId,
    required this.createdAt,
    required this.read,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      messageId: json['messageId'],
      content: json['content'],
      senderId: json['senderId'],
      senderUsername: json['senderUsername'],
      senderProfilePicture: json['senderProfilePicture'],
      receiverId: json['receiverId'],
      createdAt: DateTime.parse(json['createdAt']),
      read: json['read'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'content': content,
      'senderId': senderId,
      'senderUsername': senderUsername,
      'senderProfilePicture': senderProfilePicture,
      'receiverId': receiverId,
      'createdAt': createdAt.toIso8601String(),
      'read': read,
    };
  }
} 