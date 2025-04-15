class Post {
  final dynamic id;
  final String caption;
  final String? content;
  final String? imageBase64;
  final List<String>? imageUrls;
  final dynamic userId;
  final DateTime? createdAt;

  Post({
    this.id,
    required this.caption,
    this.content,
    this.imageBase64,
    this.imageUrls,
    required this.userId,
    this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['postId'] ?? json['id'],
      caption: json['caption'] ?? '',
      content: json['content'],
      imageBase64: json['imageBase64'],
      imageUrls: json['imageUrls'] != null 
        ? List<String>.from(json['imageUrls']) 
        : (json['imageUrl'] != null ? [json['imageUrl']] : null),
      userId: json['user'] != null ? json['user']['userId'] : json['userId'],
      createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt']) 
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caption': caption,
      'content': content,
      'imageBase64': imageBase64,
      'userId': userId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
} 