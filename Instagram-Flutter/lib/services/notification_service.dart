import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:practice_widgets/models/notification.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
class NotificationService{
  String baseUrl = 'http://192.168.100.23:8080/api';
  static const String _unreadCountKey = 'unread_notification_count';
  static const String _lastFetchKey = 'last_notification_fetch';

  Future<List<NotificationModel>> getNotifications(String token) async{
    try{
      if (kDebugMode) {
        print('NotificationService: Attempting to fetch notifications from: $baseUrl/notifications');
        print('NotificationService: Using token: ${token.substring(0, 20)}...');
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10)); // Add timeout

      if (kDebugMode) {
        print('NotificationService: Response status code: ${response.statusCode}');
        print('NotificationService: Response headers: ${response.headers}');
        if (response.statusCode != 200) {
          print('NotificationService: Response body: ${response.body}');
        }
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (kDebugMode) {
          print('NotificationService: Successfully fetched ${data.length} notifications');
          // Log first notification structure for debugging
          if (data.isNotEmpty) {
            print('NotificationService: First notification structure: ${data[0]}');
          }
        }
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      } else {
        if (kDebugMode) {
          print('NotificationService: Failed to fetch notifications. Status: ${response.statusCode}, Body: ${response.body}');
        }
        throw Exception('Failed to fetch notifications: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: Error fetching notifications: $e');
        print('NotificationService: Error type: ${e.runtimeType}');
      }
      
      // Check if it's a network connectivity issue
      if (e.toString().contains('ClientException') || e.toString().contains('network error')) {
        throw Exception('Network error: Unable to connect to server at $baseUrl. Please check your internet connection and server status.');
      }
      
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  Future<List<NotificationModel>> getUnreadNotifications(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/unread'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch unread notifications: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching unread notifications: $e');
      throw Exception('Failed to fetch unread notifications: $e');
    }
  }

  Future<int> getUnreadNotificationCount(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/count'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final count = data['unreadCount'] as int;
        await _saveUnreadCountLocally(count);
        return count;
      } else {
        throw Exception('Failed to fetch unread count: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching unread count: $e');
      // Return cached count if available
      return await _getLocalUnreadCount();
    }
  }

  Future<void> _saveUnreadCountLocally(int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_unreadCountKey, count);
      await prefs.setInt(_lastFetchKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error saving unread count locally: $e');
    }
  }

  Future<int> _getLocalUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_unreadCountKey) ?? 0;
    } catch (e) {
      print('Error getting local unread count: $e');
      return 0;
    }
  }

  Future<DateTime?> getLastFetchTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastFetchKey);
      return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
    } catch (e) {
      print('Error getting last fetch time: $e');
      return null;
    }
  }

  // Get cached unread count (for immediate UI updates)
  Future<int> getCachedUnreadCount() async {
    return await _getLocalUnreadCount();
  }

}