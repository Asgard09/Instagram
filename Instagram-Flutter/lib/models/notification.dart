class NotificationModel{
  final int id;
  final String type;
  final String message;
  final int fromUserId;
  final String fromUsername;
  final String? fromUserProfilePicture;
  final int? postId;
  final String? postImageUrl;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.message,
    required this.fromUserId,
    required this.fromUsername,
    this.fromUserProfilePicture,
    this.postId,
    this.postImageUrl,
    required this.createdAt,
    required this.isRead,
    this.readAt
  });

  /*Note
  * Create object from JSON
  */
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Handle fromUser object
    final fromUser = json['fromUser'] as Map<String, dynamic>?;
    final fromUserId = fromUser?['userId'] ?? json['fromUserId'] ?? 0;
    final fromUsername = fromUser?['username'] ?? json['fromUsername'] ?? '';
    final fromUserProfilePicture = fromUser?['profilePicture'] ?? json['fromUserProfilePicture'];
    
    // Handle post object
    final post = json['post'] as Map<String, dynamic>?;
    final postId = post?['postId'] ?? json['postId'];
    final postImageUrl = post?['imageUrl'] ?? json['postImageUrl'];
    
    return NotificationModel(
      id: json['id'] ?? 0,
      type: json['type']?.toString() ?? '',
      message: json['message'] ?? '',
      fromUserId: fromUserId is int ? fromUserId : int.tryParse(fromUserId.toString()) ?? 0,
      fromUsername: fromUsername.toString(),
      fromUserProfilePicture: fromUserProfilePicture?.toString(),
      postId: postId is int ? postId : (postId != null ? int.tryParse(postId.toString()) : null),
      postImageUrl: postImageUrl?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'message': message,
      'fromUserId': fromUserId,
      'fromUsername': fromUsername,
      'fromUserProfilePicture': fromUserProfilePicture,
      'postId': postId,
      'postImageUrl': postImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    int? id,
    String? type,
    String? message,
    int? fromUserId,
    String? fromUsername,
    String? fromUserProfilePicture,
    int? postId,
    String? postImageUrl,
    DateTime? createdAt,
    bool? isRead,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      message: message ?? this.message,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUsername: fromUsername ?? this.fromUsername,
      fromUserProfilePicture: fromUserProfilePicture ?? this.fromUserProfilePicture,
      postId: postId ?? this.postId,
      postImageUrl: postImageUrl ?? this.postImageUrl,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
    );
  }
}