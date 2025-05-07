class Message {
  final int? messageId;
  final String content;
  final int senderId;
  final String senderUsername;
  final String? senderProfilePicture;
  final int receiverId;
  final DateTime createdAt;
  bool isRead;

  Message({
    this.messageId,
    required this.content,
    required this.senderId,
    required this.senderUsername,
    this.senderProfilePicture,
    required this.receiverId,
    required this.createdAt,
    required this.isRead,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    // Check the shape of the JSON for debugging
    print('Message JSON: $json');
    
    // Handle both read and isRead fields for compatibility
    bool messageIsRead = false;
    if (json.containsKey('isRead')) {
      messageIsRead = json['isRead'] ?? false;
    } else if (json.containsKey('read')) {
      messageIsRead = json['read'] ?? false;
    }
    
    return Message(
      messageId: json['messageId'],
      content: json['content'],
      senderId: json['senderId'],
      senderUsername: json['senderUsername'],
      senderProfilePicture: json['senderProfilePicture'],
      receiverId: json['receiverId'],
      createdAt: DateTime.parse(json['createdAt']),
      isRead: messageIsRead,
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
      'isRead': isRead,
    };
  }
} 