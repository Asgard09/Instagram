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
    // Handle fromUser object - it could be a Map or just an int (userId)
    dynamic fromUserData = json['fromUser'];
    int fromUserId;
    String fromUsername;
    String? fromUserProfilePicture;
    
    if (fromUserData is Map<String, dynamic>) {
      // fromUser is an object
      fromUserId = fromUserData['userId'] ?? 0;
      fromUsername = fromUserData['username'] ?? '';
      fromUserProfilePicture = fromUserData['profilePicture'];
    } else if (fromUserData is int) {
      // fromUser is just the userId
      fromUserId = fromUserData;
      fromUsername = json['fromUsername'] ?? '';
      fromUserProfilePicture = json['fromUserProfilePicture'];
    } else {
      // Fallback to direct fields
      fromUserId = json['fromUserId'] ?? 0;
      fromUsername = json['fromUsername'] ?? '';
      fromUserProfilePicture = json['fromUserProfilePicture'];
    }
    
    // Handle post object - it could be a Map or just an int (postId)
    dynamic postData = json['post'];
    int? postId;
    String? postImageUrl;
    
    if (postData is Map<String, dynamic>) {
      // post is an object
      postId = postData['postId'];
      postImageUrl = postData['imageUrl'];
    } else if (postData is int) {
      // post is just the postId
      postId = postData;
      postImageUrl = json['postImageUrl'];
    } else {
      // Fallback to direct fields
      postId = json['postId'];
      postImageUrl = json['postImageUrl'];
    }
    
    return NotificationModel(
      id: json['id'] ?? 0,
      type: json['type']?.toString() ?? '',
      message: json['message'] ?? '',
      fromUserId: fromUserId,
      fromUsername: fromUsername,
      fromUserProfilePicture: fromUserProfilePicture,
      postId: postId,
      postImageUrl: postImageUrl,
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