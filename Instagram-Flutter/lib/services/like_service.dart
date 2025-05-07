import 'dart:convert';
import 'package:http/http.dart' as http;

class LikeService {
  final String baseUrl = 'http://192.168.1.6:8080/api';

  // Like a post
  Future<bool> likePost(String token, int postId) async {
    try {
      print('Liking post: $postId');
      final response = await http.post(
        Uri.parse('$baseUrl/likes/post/$postId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('Like response status: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error liking post: $e');
      return false;
    }
  }

  // Unlike a post
  Future<bool> unlikePost(String token, int postId) async {
    try {
      print('Unliking post: $postId');
      final response = await http.delete(
        Uri.parse('$baseUrl/likes/post/$postId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('Unlike response status: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error unliking post: $e');
      return false;
    }
  }

  // Check if user has liked a post
  Future<bool> hasLiked(String token, int postId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/likes/check/post/$postId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['liked'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking like status: $e');
      return false;
    }
  }

  // Get like count for a post
  Future<int> getLikeCount(String token, int postId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/likes/count/post/$postId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error getting like count: $e');
      return 0;
    }
  }
} 