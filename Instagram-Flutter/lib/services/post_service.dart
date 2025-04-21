import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/post.dart';
import 'dart:io';

// This class is responsible for all post-related API calls
class PostService {
  // Direct IP address - used for both web and mobile
  final String baseUrl = 'http://192.168.1.103:8080/api';

  // Method to create post with proper handling for both file paths and blob URLs
  Future<Post?> createPost(String imagePath, String caption, String token) async {
    try {
      print('Creating post with image from path: $imagePath');
      
      // Handle blob URLs or http URLs (web or any platform)
      if (imagePath.startsWith('blob:') || imagePath.startsWith('http')) {
        if (imagePath.startsWith('blob:')) {
          try {
            // For blob URLs, fetch the actual content and convert to base64
            final response = await http.get(Uri.parse(imagePath));
            if (response.statusCode != 200) {
              print('Failed to fetch image from blob URL: ${response.statusCode}');
              return null;
            }
            
            final bytes = response.bodyBytes;
            final base64Image = base64Encode(bytes);
            
            // Determine content type from response headers or default to jpeg
            String contentType = response.headers['content-type'] ?? 'image/jpeg';
            String imageType = contentType.split('/').last;
            
            final base64String = 'data:$contentType;base64,$base64Image';
            
            // Send the data URL to the server
            return await _sendPostWithImage(base64String, caption, token);
          } catch (e) {
            print('Error processing blob URL: $e');
            return null;
          }
        } else {
          // For direct http/https URLs, let the server handle it
          return await _sendPostWithImage(imagePath, caption, token);
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

  // Helper method to send post creation request
  Future<Post?> _sendPostWithImage(String imageData, String caption, String token) async {
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
        'imageBase64': imageData
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
  }

  // Separate method that will be implemented by native mobile platforms
  Future<Post?> _createMobilePost(String imagePath, String caption, String token) async {
    try {
      print('Reading file from: $imagePath');
      
      // Read the file and convert to base64
      final file = File(imagePath);
      if (!await file.exists()) {
        print('File does not exist: $imagePath');
        return null;
      }
      
      final bytes = await file.readAsBytes();
      print('Read ${bytes.length} bytes from file');
      
      final base64Image = base64Encode(bytes);
      print('Encoded to base64 string of length: ${base64Image.length}');

      // Add appropriate data URL prefix based on file extension
      String imageType = 'jpeg';
      if (imagePath.toLowerCase().endsWith('.png')) {
        imageType = 'png';
      } else if (imagePath.toLowerCase().endsWith('.gif')) {
        imageType = 'gif';
      } else if (imagePath.toLowerCase().endsWith('.webp')) {
        imageType = 'webp';
      }

      final base64String = 'data:image/$imageType;base64,$base64Image';
      print('Created data URL with type: $imageType');

      // Use the helper method to send the request
      return await _sendPostWithImage(base64String, caption, token);
    } catch (e) {
      print('Error in _createMobilePost: $e');
      return null;
    }
  }

  Future<List<Post>> getPosts(String token) async {
    try {
      print('Fetching posts from: $baseUrl/posts');
      final response = await http.get(
        Uri.parse('$baseUrl/posts'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('Posts response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('Raw posts response: ${response.body}');
        List<dynamic> data = json.decode(response.body);
        print('Decoded ${data.length} posts');
        return data.map((json) => Post.fromJson(json)).toList();
      } else {
        print('Failed to get posts: ${response.statusCode}');
        print('Error response: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error getting posts: $e');
      return [];
    }
  }
} 