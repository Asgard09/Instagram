// This file is only imported on mobile platforms
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/post.dart';
import 'post_service.dart';

// Extend the PostService class to add mobile-specific functionality
extension MobilePostService on PostService {
  // Override the _createMobilePost method for mobile platforms
  Future<Post?> _createMobilePost(String imagePath, String caption, String token) async {
    // We can safely use dart:io here since this file is only included in mobile builds
    try {
      // Read image file as bytes and convert to base64
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      
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
      
      // Create JSON request body
      final requestBody = {
        'caption': caption,
        'content': caption,
        'imageBase64': base64String
      };
      
      // Send request as JSON
      final response = await http.post(
        Uri.parse('$baseUrl/posts'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
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
    } catch (e) {
      print('Error in mobile implementation: $e');
      return null;
    }
  }
} 