class Notification{
  final String type;
  final String message;
  final int fromUserId;
  final String fromUsername;
  final String? fromUserProfilePicture;
  final int? postId;
  final String? postImageUrl;
  final DateTime createdAt;
  final bool isRead;

  Notification({
    required this.type,
    required this.message,
    required this.fromUserId,
    required this.fromUsername,
    this.fromUserProfilePicture,
    this.postId,
    this.postImageUrl,
    required this.createdAt,
    required this.isRead,
  });

  /*Note
  * Create object from JSON
  */
  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      type: json['type'] ?? '',
      message: json['message'] ?? '',
      fromUserId: json['fromUserId'] ?? 0,
      fromUsername: json['fromUsername'] ?? '',
      fromUserProfilePicture: json['fromUserProfilePicture'],
      postId: json['postId'],
      postImageUrl: json['postImageUrl'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
    );
  }
}