enum Gender { MALE, FEMALE, OTHER, PREFER_NOT_TO_SAY }

class User {
  final int? userId;
  final String username;
  final String? email;
  String? profilePicture;
  String? bio;
  String? name;
  Gender? gender;
  final DateTime? createdAt;

  User({
    this.userId,
    required this.username,
    this.email,
    this.profilePicture,
    this.bio,
    this.name,
    this.gender,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    String? genderStr = json['gender'];
    Gender? gender;
    
    if (genderStr != null) {
      try {
        gender = Gender.values.firstWhere(
          (e) => e.toString().split('.').last == genderStr,
          orElse: () => Gender.PREFER_NOT_TO_SAY,
        );
      } catch (_) {
        gender = Gender.PREFER_NOT_TO_SAY;
      }
    }

    return User(
      userId: json['userId'],
      username: json['username'] ?? '',
      email: json['email'],
      profilePicture: json['profilePicture'],
      bio: json['bio'],
      name: json['name'],
      gender: gender,
      createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt']) 
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'profilePicture': profilePicture,
      'bio': bio,
      'name': name,
      'gender': gender?.toString().split('.').last,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  // Create a copy with updated fields
  User copyWith({
    int? userId,
    String? username,
    String? email,
    String? profilePicture,
    String? bio,
    String? name,
    Gender? gender,
    DateTime? createdAt,
  }) {
    return User(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      profilePicture: profilePicture ?? this.profilePicture,
      bio: bio ?? this.bio,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 