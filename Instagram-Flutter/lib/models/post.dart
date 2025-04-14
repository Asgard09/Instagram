class Post {
  final String? id;
  final String caption;
  final String imageBase64;
  final String userId;
  final DateTime? createdAt;

  Post({
    this.id,
    required this.caption,
    required this.imageBase64,
    required this.userId,
    this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      caption: json['caption'],
      imageBase64: json['imageBase64'],
      userId: json['userId'],
      createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt']) 
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caption': caption,
      'imageBase64': imageBase64,
      'userId': userId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
} 