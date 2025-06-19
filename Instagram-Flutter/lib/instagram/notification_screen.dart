import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/providers/auth_provider.dart';
import '../data/providers/user_provider.dart';
import '../data/providers/notification_provider.dart';
import '../services/websocket_service.dart';
import '../models/notification.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with WidgetsBindingObserver {
  final WebSocketService _webSocketService = WebSocketService();
  StreamSubscription<NotificationModel>? _notificationSubscription;
  bool _isInitialized = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeNotifications();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('App lifecycle state changed to: $state');
    if (state == AppLifecycleState.resumed) {
      print('App resumed - reinitializing notifications');
      _initializeNotifications();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      print('Dependencies changed - initializing notifications');
      _initializeNotifications();
      _isInitialized = true;
    }
  }

  Future<void> _initializeNotifications() async {
    print('Starting notification initialization...');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

    print('Initializing notifications...');
    print('Token available: ${authProvider.token != null}');
    print('User available: ${userProvider.user != null}');
    
    // Debug token information
    if (authProvider.token != null) {
      print('Token preview: ${authProvider.token!.substring(0, 20)}...');
      print('Token valid: ${authProvider.isTokenValid}');
    }

    if (authProvider.token != null) {
      try {
        // Load user data if not already available
        if (userProvider.user == null) {
          print('User data not available, fetching current user...');
          await userProvider.fetchCurrentUser(authProvider.token!);
          print('User data loaded: ${userProvider.user?.username} (ID: ${userProvider.user?.userId})');
        }

        if (userProvider.user != null) {
          print('Fetching notifications from API...');
          
          // Fetch initial notifications from API
          await notificationProvider.fetchNotifications(authProvider.token!);
          
          print('Connecting to WebSocket for user: ${userProvider.user!.userId}');

          // Connect to WebSocket for real-time notifications
          await _webSocketService.connect(authProvider.token!, userProvider.user!.userId!);
          _isConnected = true;

          // Listen for new notifications via WebSocket
          _notificationSubscription?.cancel(); // Cancel existing subscription if any
          _notificationSubscription = _webSocketService.notificationStream.listen(
            (notification) {
              print('Received notification in screen: ${notification.message}');
              if (mounted) {
                // Add to provider
                notificationProvider.addNotification(notification);
                
                // Show a snack bar for new notifications
                _showNotificationSnackBar(notification);
              }
            },
            onError: (error) {
              print('Error in notification stream: $error');
              _isConnected = false;
              // Attempt to reconnect after a delay
              Future.delayed(Duration(seconds: 5), () {
                if (mounted) {
                  _initializeNotifications();
                }
              });
            },
            onDone: () {
              print('Notification stream closed');
              _isConnected = false;
              // Attempt to reconnect after a delay
              Future.delayed(Duration(seconds: 5), () {
                if (mounted) {
                  _initializeNotifications();
                }
              });
            },
          );

          print('Notification listener set up successfully');
        } else {
          print('Cannot initialize notifications: user data could not be loaded');
        }
      } catch (e) {
        print('Error initializing notifications: $e');
        _isConnected = false;
      }
    } else {
      print('Cannot initialize notifications: missing token');
    }
  }

  void _showNotificationSnackBar(NotificationModel notification) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getNotificationIcon(notification.type),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                notification.message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: _getNotificationColor(notification.type),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'LIKE':
        return Icons.favorite;
      case 'COMMENT':
        return Icons.chat_bubble;
      case 'FOLLOW':
        return Icons.person_add;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'LIKE':
        return Colors.red;
      case 'COMMENT':
        return Colors.blue;
      case 'FOLLOW':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              print('Refresh button pressed - reinitializing notifications');
              _initializeNotifications();
            },
          ),
          IconButton(
            icon: Icon(
              _isConnected ? Icons.wifi : Icons.wifi_off,
              color: _isConnected ? Colors.green : Colors.red,
            ),
            onPressed: () {
              if (kDebugMode) {
                print('WebSocket status: ${_isConnected ? "Connected" : "Disconnected"}');
              }
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          if (notificationProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          
          if (notificationProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading notifications',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    notificationProvider.error!,
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _initializeNotifications,
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (notificationProvider.notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'When someone likes or comments on your posts,\nyou\'ll see it here',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: _initializeNotifications,
            child: ListView.builder(
              itemCount: notificationProvider.notifications.length,
              itemBuilder: (context, index) {
                final notification = notificationProvider.notifications[index];
                return _buildNotificationItem(notification);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey[800],
          backgroundImage: notification.fromUserProfilePicture != null
              ? NetworkImage(_getProfileImageUrl(notification.fromUserProfilePicture))
              : null,
          child: notification.fromUserProfilePicture == null
              ? Icon(
                  _getNotificationIcon(notification.type),
                  color: Colors.white,
                  size: 20,
                )
              : null,
        ),
        title: Text(
          notification.message,
          style: TextStyle(
            color: Colors.white,
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          _formatTime(notification.createdAt),
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        trailing: notification.postImageUrl != null
            ? Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  image: DecorationImage(
                    image: NetworkImage(_getProfileImageUrl(notification.postImageUrl)),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            : (!notification.isRead
                ? Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  )
                : null),
        onTap: () {
          // Mark as read when tapped
          if (!notification.isRead) {
            final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
            notificationProvider.markAsRead(notification.id);
          }
          
          // Navigate to post or user profile based on notification type
          if (notification.postId != null) {
            // Navigate to post (you can implement this)
            print('Navigate to post: ${notification.postId}');
          }
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
  
  String _getProfileImageUrl(String? profilePicture) {
    if (profilePicture == null) return '';
    if (profilePicture.startsWith('http')) {
      return profilePicture;
    } else {
      final baseUrl = 'http://192.168.100.23:8080';
      return '$baseUrl/uploads/$profilePicture';
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationSubscription?.cancel();
    _webSocketService.dispose();
    super.dispose();
  }
}
