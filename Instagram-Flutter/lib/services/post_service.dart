import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/post.dart';

// Import mobile implementation only on non-web platforms
import 'post_service_mobile.dart' if (dart.library.html) 'post_service_web.dart';

class PostService {
  // Direct IP address - used for both web and mobile
  final String baseUrl = 'http://192.168.1.4:8080/api';

  // Method to create post with proper handling for both file paths and blob URLs
  Future<Post?> createPost(String imagePath, String caption, String token) async {
    try {
      print('Creating post with image from path: $imagePath');
      
      // Handle blob URLs for web platform
      if (imagePath.startsWith('blob:') || imagePath.startsWith('http')) {
        // For web platform with blob URLs, send the URL directly to the server
        final response = await http.post(
          Uri.parse('$baseUrl/posts'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({
            'caption': caption,
            'content': caption,
            'imageUrl': imagePath // Send as URL, not base64
          }),
        );
        
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseJson = json.decode(response.body);
          print('Decoded response: $responseJson');
          return Post.fromJson(responseJson);
        } else {
          print('Failed to create post: ${response.statusCode}');
          return null;
        }
      } else if (!kIsWeb) {
        // For mobile platforms, handle file path
        try {
          // Import dart:io directly in the implementation
          // This is only executed on mobile platforms
          return await _createPostFromFile(imagePath, caption, token);
        } catch (e) {
          print('Error processing image file: $e');
          return null;
        }
      } else {
        print('Unsupported image path format in web: $imagePath');
        return null;
      }
    } catch (e) {
      print('Error creating post: $e');
      return null;
    }
  }

  // This method is only called on mobile platforms
  Future<Post?> _createPostFromFile(String imagePath, String caption, String token) async {
    if (kIsWeb) return null;
    
    // Use a separate function that imports dart:io
    // This won't be executed on web platforms
    return await _mobileImplementation(imagePath, caption, token, baseUrl);
  }
  
  // This is implemented in post_service_mobile.dart (for native) or post_service_web.dart (for web)
  // Using extension methods
  Future<Post?> _mobileImplementation(String imagePath, String caption, String token, String baseUrl);

  Future<List<Post>> getPosts(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Post.fromJson(json)).toList();
      } else {
        print('Failed to get posts: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting posts: $e');
      return [];
    }
  }
} 