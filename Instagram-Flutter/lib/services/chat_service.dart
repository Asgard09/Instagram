import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/chat.dart';
import '../models/message.dart';

class ChatService {
  // Server base URL
  String get _baseUrl {
    if (kIsWeb) {
      return 'http://192.168.1.5:8080';
    } else {
      return 'http://192.168.1.5:8080';
    }
  }

  // Get all chats for current user
  Future<List<Chat>> getUserChats(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/chats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> chatListJson = json.decode(response.body);
        return chatListJson.map((chatJson) => Chat.fromJson(chatJson)).toList();
      } else {
        throw Exception('Failed to load chats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading chats: $e');
    }
  }

  // Get a specific chat by ID
  Future<Chat> getChatById(int chatId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/chats/$chatId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return Chat.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load chat: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading chat: $e');
    }
  }

  // Get or create a chat with another user
  Future<Chat> getOrCreateChat(int otherUserId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/chats/with/$otherUserId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return Chat.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to get or create chat: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating chat: $e');
    }
  }

  // Send a message via HTTP
  Future<Message> sendMessage(
      int receiverId, String content, String token) async {
    try {
      print('Sending HTTP message to receiverId: $receiverId, content: $content');
      print('Using token: ${token.substring(0, 20)}...');
      
      final requestBody = {
        'receiverId': receiverId,
        'content': content,
      };
      print('Request body: ${json.encode(requestBody)}');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/chats/message'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return Message.fromJson(json.decode(response.body));
      } else if (response.statusCode == 403) {
        print('Authorization error - token may be expired or invalid');
        throw Exception('Failed to send message: ${response.statusCode} - Authorization failed');
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending message: $e');
      throw Exception('Error sending message: $e');
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(int chatId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/chats/$chatId/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark messages as read: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error marking messages as read: $e');
    }
  }

  // Get unread message count
  Future<int> getUnreadMessageCount(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/chats/unread/count'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] as int;
      } else {
        throw Exception('Failed to get unread count: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting unread count: $e');
    }
  }
} 