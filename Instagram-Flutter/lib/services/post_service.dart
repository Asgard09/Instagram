import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/post.dart';

// This class is responsible for all post-related API calls
class PostService {
  // Direct IP address - used for both web and mobile
  final String baseUrl = 'http://192.168.1.4:8080/api';

  // Method to create post with proper handling for both file paths and blob URLs
  Future<Post?> createPost(String imagePath, String caption, String token) async {
    try {
      print('Creating post with image from path: $imagePath');
      
      // Handle blob URLs or http URLs (web or any platform)
      if (imagePath.startsWith('blob:') || imagePath.startsWith('http')) {
        // Send the URL directly to the server
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
        // For mobile platforms with a file path, we need to convert to base64
        // This will only work on mobile, as web doesn't have File access
        try {
          // We need to handle mobile file access
          // This code path is only run on mobile, so we can safely import dart:io in a separate file
          return await _createMobilePost(imagePath, caption, token);
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

  // Separate method that will be implemented by native mobile platforms
  Future<Post?> _createMobilePost(String imagePath, String caption, String token) async {
    // This is a stub that will be overridden when compiling for mobile
    // For web, this will never be called due to the kIsWeb check above
    throw UnsupportedError('Mobile file operations not supported on this platform');
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