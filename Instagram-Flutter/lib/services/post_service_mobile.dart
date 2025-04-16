import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/post.dart';
import 'post_service.dart';  // Add import for PostService class

// This file should only be imported in the mobile environment
// It contains the actual implementation for file handling

// Extension to add mobile implementation to the PostService class
extension MobilePostService on PostService {
  // Actual implementation for _mobileImplementation from post_service.dart
  Future<Post?> _mobileImplementation(String imagePath, String caption, String token, String baseUrl) async {
    if (kIsWeb) {
      throw UnsupportedError('Cannot use mobile file implementation on web');
    }
    
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
  }
} 