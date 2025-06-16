import 'dart:convert';

import 'package:practice_widgets/models/notification.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
class NotificationService{
  String baseUrl = 'http://192.168.100.23:8080/api';
  static const String _unreadCountKey = 'unread_notification_count';
  static const String _lastFetchKey = 'last_notification_fetch';

  Future<List<NotificationModel>> getNotifications(String token) async{
    try{
      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch notifications: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  Future<List<NotificationModel>> getUnreadNotifications(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/unread'),
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
        Uri.parse('$baseUrl/api/notifications/count'),
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