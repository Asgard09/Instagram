import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/post.dart';

// Conditionally import for platform detection
import 'platform_helper.dart';

class PostService {
  // For emulators/simulators use localhost, for physical devices use your computer's IP
  final String _localhost = 'localhost:8080';
  final String _networkIp = '192.168.1.4:8080'; // Your specific IP address
  
  String get baseUrl {
    if (kIsWeb) {
      // Web always uses the actual server address where the page is served from
      return 'http://192.168.1.4:8080/api';
    } else {
      // Defer to platform helper for native platforms
      return PlatformHelper.getBaseUrl(_localhost, _networkIp);
    }
  }

  // Method to create post with proper handling for both file paths and blob URLs
  Future<Post?> createPost(String imagePath, String caption, String token) async {
    try {
      print('Creating post with image from path: $imagePath');
      
      // Handle blob URLs for web platform
      if (imagePath.startsWith('blob:') || imagePath.startsWith('http')) {
        if (kIsWeb) {
          // For web platform with blob URLs, send the URL directly to the server
          // The server will need to handle this specially
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
        } else {
          // For mobile platforms with a URL, we need to download the image first
          print('URL-based upload not supported on mobile yet');
          return null;
        }
      } else {
        // Handle file path (mobile platforms)
        try {
          if (kIsWeb) {
            // Web can't access File API the same way
            return null;
          }
          
          // Import dart:io only when needed (not available in web)
          return await PlatformHelper.createPostFromFile(
            imagePath,
            caption,
            token,
            baseUrl
          );
        } catch (e) {
          print('Error processing image file: $e');
          return null;
        }
      }
    } catch (e) {
      print('Error creating post: $e');
      return null;
    }
  }

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