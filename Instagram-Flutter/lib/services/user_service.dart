import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/user.dart';

class UserService {
  final String baseUrl = 'http://192.168.1.97:8080/api';

  // Get the current user's profile
  Future<User?> getCurrentUser(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        return User.fromJson(responseJson);
      } else {
        print('Failed to get user profile: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Update user's bio
  Future<User?> updateBio(String bio, String token) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/bio'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'bio': bio,
        }),
      );

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        return User.fromJson(responseJson);
      } else {
        print('Failed to update bio: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error updating bio: $e');
      return null;
    }
  }

  // Update user's full profile information
  Future<User?> updateProfile({
    required String token,
    String? username,
    String? name,
    String? bio,
    Gender? gender,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          if (username != null) 'username': username,
          if (name != null) 'name': name,
          if (bio != null) 'bio': bio,
          if (gender != null) 'gender': gender.toString().split('.').last,
        }),
      );

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        return User.fromJson(responseJson);
      } else {
        print('Failed to update profile: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error updating profile: $e');
      return null;
    }
  }

  // Update profile image
  Future<User?> updateProfileImage(String imagePath, String token) async {
    try {
      print('Starting profile image update with path: $imagePath');
      
      // Handle blob/URL paths and file paths differently
      if (imagePath.startsWith('blob:') || imagePath.startsWith('http')) {
        print('Using web image URL: $imagePath');
        
        // For web platform with blob URLs
        if (imagePath.startsWith('blob:')) {
          // Blob URLs should be fetched and converted to base64 first
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
          
          // Now send the data URL to the server
          return await _sendProfileImageUpdate(base64String, token);
        } else {
          // For direct http/https URLs, let the server handle it
          return await _sendProfileImageUpdate(imagePath, token);
        }
      } else {
        // For file path on mobile
        if (kIsWeb) {
          throw UnsupportedError('Cannot use File API on web with local path');
        }

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

        // Send the request
        return await _sendProfileImageUpdate(base64String, token);
      }
    } catch (e) {
      print('Error updating profile image: $e');
      return null;
    }
  }
  
  // Helper method to send profile image update request
  Future<User?> _sendProfileImageUpdate(String imageData, String token) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/profile-image'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'imageBase64': imageData,
      }),
    );

    print('Response status: ${response.statusCode}');
    String responseBodyPreview = response.body.length > 100 
        ? response.body.substring(0, 100) + '...' 
        : response.body;
    print('Response body preview: $responseBodyPreview');
    
    if (response.statusCode == 200) {
      final responseJson = json.decode(response.body);
      final user = User.fromJson(responseJson);
      print('Updated user profile picture: ${user.profilePicture}');
      return user;
    } else {
      print('Failed to update profile image: ${response.statusCode}');
      return null;
    }
  }

  // Get a user's profile by username
  Future<User?> getUserByUsername(String username, String token) async {
    try {
      print('Fetching user profile for username: $username');
      
      final response = await http.get(
        Uri.parse('$baseUrl/users/by-username/$username'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('Response status for $username profile: ${response.statusCode}');
      
      // Print readable preview of response
      if (response.body.length > 200) {
        print('Response preview: ${response.body.substring(0, 200)}...');
      } else {
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        try {
          final responseJson = json.decode(response.body);
          print('Successfully parsed JSON for user: $username');
          
          if (responseJson is Map<String, dynamic>) {
            // Clean up the posts field if it exists and is corrupted
            if (responseJson.containsKey('posts') && 
                (responseJson['posts'] == null || 
                 responseJson['posts'] is String || 
                 (responseJson['posts'] is String && responseJson['posts'].contains(']]}')))) {
              print('Removing corrupted posts field from user data');
              responseJson.remove('posts');
            }
            
            return User.fromJson(responseJson);
          } else {
            print('Unexpected response format for $username: not a JSON object');
            return null;
          }
        } catch (jsonError) {
          print('JSON parsing error for $username: $jsonError');
          print('Trying to extract user data from raw response...');
          
          // Attempt to extract basic user info if JSON is corrupted
          try {
            // Create a minimal user object with just the username
            return User(
              username: username,
              // Add other fields if we can safely extract them
            );
          } catch (e) {
            print('Failed to create fallback user object: $e');
            return null;
          }
        }
      } else {
        print('Failed to get user profile for $username: ${response.statusCode}');
        if (response.statusCode == 404) {
          print('User not found');
        }
        return null;
      }
    } catch (e) {
      print('Error getting user profile for $username: $e');
      return null;
    }
  }
} 