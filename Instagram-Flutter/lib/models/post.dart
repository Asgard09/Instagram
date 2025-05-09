class Post {
  final dynamic id;
  final String caption;
  final String? displayCaption; // Caption with "with username" format
  final String? content;
  final String? imageBase64;
  final List<String>? imageUrls;
  final dynamic userId;
  final String? username;
  final DateTime? createdAt;
  final List<String>? taggedPeople;

  Post({
    this.id,
    required this.caption,
    this.displayCaption,
    this.content,
    this.imageBase64,
    this.imageUrls,
    required this.userId,
    this.username,
    this.createdAt,
    this.taggedPeople,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    // Debug: Print the full JSON response
    print('Post JSON: ${json.toString()}');
    
    // Extract user information
    String? username;
    dynamic userId;
    
    // Handle different formats of user data
    if (json['user'] != null) {
      var user = json['user'];
      print('User object found: $user');
      
      // Check if user is a Map or just a userId reference
      if (user is Map) {
        userId = user['userId'];
        username = user['username'];
      } else {
        userId = user;
      }
      print('Extracted username: $username');
    } else {
      userId = json['userId'];
      print('No user object found, userId: $userId');
    }
    
    // Try to get username from nested entities
    if (username == null && json.containsKey('username')) {
      username = json['username'];
      print('Found username at top level: $username');
    }
    
    return Post(
      id: json['postId'] ?? json['id'],
      caption: json['caption'] ?? '',
      displayCaption: json['displayCaption'] ?? json['caption'] ?? '',
      content: json['content'],
      imageBase64: json['imageBase64'],
      imageUrls: json['imageUrls'] != null 
        ? List<String>.from(json['imageUrls']) 
        : (json['imageUrl'] != null ? [json['imageUrl']] : null),
      userId: userId,
      username: username,
      createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt']) 
        : null,
      taggedPeople: json['taggedPeople'] != null
        ? List<String>.from(json['taggedPeople'])
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caption': caption,
      'displayCaption': displayCaption,
      'content': content,
      'imageBase64': imageBase64,
      'userId': userId,
      'username': username,
      'createdAt': createdAt?.toIso8601String(),
      'taggedPeople': taggedPeople,
    };
  }
} 