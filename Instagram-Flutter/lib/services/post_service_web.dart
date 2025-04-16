import 'package:flutter/foundation.dart';
import '../models/post.dart';
import 'post_service.dart';  // Add import for PostService class

// Web stub implementation - this is used only in web environment
// It contains stub implementations for mobile-specific features

// Extension to add web-safe implementations to the PostService class
extension WebPostService on PostService {
  // Stub implementation for _mobileImplementation from post_service.dart
  Future<Post?> _mobileImplementation(String imagePath, String caption, String token, String baseUrl) async {
    throw UnsupportedError('Cannot use mobile file implementation on web');
  }
} 