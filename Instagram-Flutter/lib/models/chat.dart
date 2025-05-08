import 'message.dart';

class Chat {
  final int chatId;
  final UserSummary otherUser;
  final DateTime? lastMessageTime;
  final String? lastMessageContent;
  final int? lastMessageSenderId;
  final bool hasUnreadMessages;
  final List<Message> recentMessages;

  Chat({
    required this.chatId,
    required this.otherUser,
    this.lastMessageTime,
    this.lastMessageContent,
    this.lastMessageSenderId,
    required this.hasUnreadMessages,
    this.recentMessages = const [],
  });

  // Helper method to determine if a message was sent by the current user
  bool isMessageFromMe(Message message, int currentUserId) {
    return message.senderId.toString() == currentUserId.toString();
  }

  // Helper method to determine if a message was sent by the other user
  bool isMessageFromOther(Message message, int currentUserId) {
    return message.senderId.toString() == otherUser.userId.toString();
  }

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      chatId: json['chatId'],
      otherUser: UserSummary.fromJson(json['otherUser']),
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.parse(json['lastMessageTime']).toUtc()
          : null,
      lastMessageContent: json['lastMessageContent'],
      lastMessageSenderId: json['lastMessageSenderId'],
      hasUnreadMessages: json['hasUnreadMessages'] ?? false,
      recentMessages: json['recentMessages'] != null
          ? (json['recentMessages'] as List)
              .map((messageJson) => Message.fromJson(messageJson))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'otherUser': otherUser.toJson(),
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'lastMessageContent': lastMessageContent,
      'lastMessageSenderId': lastMessageSenderId,
      'hasUnreadMessages': hasUnreadMessages,
      'recentMessages': recentMessages.map((message) => message.toJson()).toList(),
    };
  }
}

class UserSummary {
  final int userId;
  final String username;
  final String? profilePicture;
  final String? name;

  UserSummary({
    required this.userId,
    required this.username,
    this.profilePicture,
    this.name,
  });

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      userId: json['userId'],
      username: json['username'],
      profilePicture: json['profilePicture'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'profilePicture': profilePicture,
      'name': name,
    };
  }
} 