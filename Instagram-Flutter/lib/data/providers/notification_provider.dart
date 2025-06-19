import 'package:flutter/foundation.dart';
import '../../models/notification.dart';
import '../../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  
  List<NotificationModel> _notifications = [];
  List<NotificationModel> _unreadNotifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<NotificationModel> get notifications => _notifications;
  List<NotificationModel> get unreadNotifications => _unreadNotifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch all notifications
  Future<void> fetchNotifications(String token) async {
    print('NotificationProvider: Starting to fetch notifications');
    print('NotificationProvider: Token preview: ${token.substring(0, 20)}...');
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('NotificationProvider: Calling notification service...');
      _notifications = await _notificationService.getNotifications(token);
      print('NotificationProvider: Successfully fetched ${_notifications.length} notifications');
      _error = null;
    } catch (e) {
      print('NotificationProvider: Error occurred: $e');
      _error = e.toString();
      print('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      print('NotificationProvider: Finished fetching notifications');
      notifyListeners();
    }
  }

  // Fetch unread notifications
  Future<void> fetchUnreadNotifications(String token) async {
    try {
      _unreadNotifications = await _notificationService.getUnreadNotifications(token);
      notifyListeners();
    } catch (e) {
      print('Error fetching unread notifications: $e');
    }
  }

  // Fetch unread count
  Future<void> fetchUnreadCount(String token) async {
    try {
      _unreadCount = await _notificationService.getUnreadNotificationCount(token);
      notifyListeners();
    } catch (e) {
      print('Error fetching unread count: $e');
    }
  }

  // Add new notification (from WebSocket)
  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    if (!notification.isRead) {
      _unreadNotifications.insert(0, notification);
      _unreadCount++;
    }
    notifyListeners();
  }

  // Mark notification as read
  void markAsRead(int notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
      
      // Remove from unread list
      _unreadNotifications.removeWhere((n) => n.id == notificationId);
      _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      
      notifyListeners();
    }
  }

  // Clear all notifications
  void clearNotifications() {
    _notifications.clear();
    _unreadNotifications.clear();
    _unreadCount = 0;
    notifyListeners();
  }

  // Refresh all notification data
  Future<void> refreshNotifications(String token) async {
    await Future.wait([
      fetchNotifications(token),
      fetchUnreadCount(token),
    ]);
  }
} 