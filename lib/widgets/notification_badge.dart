import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/notification_provider.dart';
import '../screens/notification/notification_center_screen.dart';

class NotificationBadge extends StatelessWidget {
  final Color? iconColor;
  final double iconSize;
  
  const NotificationBadge({
    super.key,
    this.iconColor,
    this.iconSize = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        final unreadCount = provider.unreadCount;
        
        return InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.of(context).pushNamed(NotificationCenterScreen.routeName);
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: iconColor ?? Colors.white,
                  size: iconSize,
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: unreadCount > 9
                        ? const Text(
                            '9+',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          )
                        : Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
} 