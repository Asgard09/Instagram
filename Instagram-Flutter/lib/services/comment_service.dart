import 'dart:convert';
import 'package:http/http.dart' as http;

class CommentService {
  // Base URL for API
  final String baseUrl = 'http://172.22.98.43:8080/api';

  // Get comment count for a post
  Future<int> getCommentCount(String token, int postId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/comments/countFromPost/$postId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // The response is directly a long number
        return int.parse(response.body);
      }
      return 0;
    } catch (e) {
      print('Error getting comment count: $e');
      return 0;
    }
  }
} 