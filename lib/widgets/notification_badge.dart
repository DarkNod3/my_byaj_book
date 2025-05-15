import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../screens/notification/notification_center_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationBadge extends StatefulWidget {
  const NotificationBadge({Key? key}) : super(key: key);

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  static const String _lastSyncKey = 'last_notification_sync';
  
  @override
  void initState() {
    super.initState();
    
    // Set up animation controller for the badge pulse effect
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Make the animation repeat
    _animationController.repeat(reverse: true);
    
    // Check if we need to load notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNotifications();
    });
  }
  
  Future<void> _checkNotifications() async {
    try {
      // Check if we've synced recently to avoid excessive updates
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getString(_lastSyncKey);
      final now = DateTime.now();
      
      if (lastSync == null) {
        // No sync has happened yet, do it immediately
        _syncNotifications(now, prefs);
        return;
      }
      
      // Parse last sync time
      final lastSyncTime = DateTime.parse(lastSync);
      final difference = now.difference(lastSyncTime);
      
      // Only sync if it's been at least 30 minutes since last sync
      if (difference.inMinutes >= 30) {
        _syncNotifications(now, prefs);
      }
    } catch (e) {
      // Ignore any errors during sync check
    }
  }
  
  void _syncNotifications(DateTime now, SharedPreferences prefs) {
    if (!mounted) return;
    
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    
    // Force sync of all notifications without UI refresh indicator
    provider.syncAllReminders();
    
    // Save the timestamp
    prefs.setString(_lastSyncKey, now.toIso8601String());
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        final unreadCount = provider.unreadCount;
        
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationCenterScreen()),
                );
              },
            ),
            if (unreadCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _animation.value,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: unreadCount > 9 ? BoxShape.rectangle : BoxShape.circle,
                          borderRadius: unreadCount > 9 ? BorderRadius.circular(8) : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
} 