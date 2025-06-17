import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/providers/auth_provider.dart';
import '../services/notification_service.dart';
class NotificationBadge extends StatefulWidget{
  final Widget child;
  final Color? badgeColor;
  final Color? textColor;
  final double? badgeSize;
  final bool showZero;

  const NotificationBadge({
    Key? key,
    required this.child,
    this.badgeColor = Colors.red,
    this.textColor = Colors.white,
    this.badgeSize = 16,
    this.showZero = false,
  }) : super(key: key);

  @override
  _NotificationBadgeState createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  final NotificationService _notificationService = NotificationService();
  int _unreadCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    // Refresh count every 30 seconds
    _startPeriodicRefresh();
  }

  void _startPeriodicRefresh() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _loadUnreadCount();
        _startPeriodicRefresh();
      }
    });
  }

  Future<void> _loadUnreadCount() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null) {
      try {
        final count = await _notificationService.getUnreadNotificationCount(authProvider.token!);
        if (mounted) {
          setState(() {
            _unreadCount = count;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error loading unread count: $e');
        }
        // Try to get cached count
        final cachedCount = await _notificationService.getCachedUnreadCount();
        if (mounted) {
          setState(() {
            _unreadCount = cachedCount;
            _isLoading = false;
          });
        }
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if ((_unreadCount > 0 || widget.showZero) && !_isLoading)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: widget.badgeColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
              constraints: BoxConstraints(
                minWidth: widget.badgeSize!,
                minHeight: widget.badgeSize!,
              ),
              child: Text(
                _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: widget.badgeSize! * 0.6,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        if (_isLoading)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              width: widget.badgeSize!,
              height: widget.badgeSize!,
              decoration: const BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: widget.badgeSize! * 0.6,
                height: widget.badgeSize! * 0.6,
                child: const CircularProgressIndicator(
                  strokeWidth: 1,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Method to manually refresh the badge count
  void refresh() {
    _loadUnreadCount();
  }
}

class NotificationBadgeProvider extends StatefulWidget {
  final Widget child;
  final Color? badgeColor;
  final Color? textColor;
  final double? badgeSize;
  final bool showZero;

  const NotificationBadgeProvider({
    Key? key,
    required this.child,
    this.badgeColor = Colors.red,
    this.textColor = Colors.white,
    this.badgeSize = 16,
    this.showZero = false,
  }) : super(key: key);

  @override
  _NotificationBadgeProviderState createState() => _NotificationBadgeProviderState();
}

class _NotificationBadgeProviderState extends State<NotificationBadgeProvider> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.token == null) {
          return widget.child;
        }

        return NotificationBadge(
          badgeColor: widget.badgeColor,
          textColor: widget.textColor,
          badgeSize: widget.badgeSize,
          showZero: widget.showZero,
          child: widget.child,
        );
      },
    );
  }
}