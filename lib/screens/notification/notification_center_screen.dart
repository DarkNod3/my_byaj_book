import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../models/app_notification.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/header/app_header.dart';

class NotificationCenterScreen extends StatefulWidget {
  static const routeName = '/notification-center';

  const NotificationCenterScreen({Key? key}) : super(key: key);

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isMarkingAllRead = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          AppHeader(
            title: 'Notifications',
            showBackButton: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.done_all, color: Colors.white),
                onPressed: _markAllAsRead,
              ),
            ],
          ),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.primaryColor,
              tabs: const [
                Tab(text: 'Unread'),
                Tab(text: 'All'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationList(unreadOnly: true),
                _buildNotificationList(unreadOnly: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList({required bool unreadOnly}) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        final notifications = unreadOnly 
            ? provider.unreadNotifications 
            : provider.notifications;
        
        if (_isMarkingAllRead) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (notifications.isEmpty) {
          return _buildEmptyState(unreadOnly);
        }
        
        return ListView.builder(
          itemCount: notifications.length,
          padding: const EdgeInsets.only(bottom: 16),
          itemBuilder: (context, index) {
            return _buildNotificationItem(notifications[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(bool unreadOnly) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            unreadOnly 
                ? 'No unread notifications'
                : 'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            unreadOnly
                ? 'You\'re all caught up!'
                : 'Notifications about payments and reminders will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(AppNotification notification) {
    final formattedDate = DateFormat('dd MMM yy, hh:mm a').format(notification.timestamp);
    
    // Define colors and icons based on notification type
    IconData icon;
    Color iconColor;
    
    switch (notification.type) {
      case 'loan':
        icon = Icons.account_balance;
        iconColor = Colors.blue;
        break;
      case 'bill':
        icon = Icons.receipt_long;
        iconColor = Colors.orange;
        break;
      case 'card':
        icon = Icons.credit_card;
        iconColor = Colors.green;
        break;
      case 'contact':
        icon = Icons.person;
        iconColor = Colors.purple;
        break;
      case 'fcm':
        icon = Icons.notifications;
        iconColor = Colors.red;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
    }
    
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      elevation: notification.isRead ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: notification.isRead ? Colors.transparent : AppTheme.primaryColor.withAlpha(100),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _handleNotificationTap(notification),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        if (_shouldShowActionButton(notification))
                          _buildActionButton(notification),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _shouldShowActionButton(AppNotification notification) {
    // Show 'Mark as Paid' button for due notifications
    return !notification.isPaid && 
           (notification.type == 'loan' || 
            notification.type == 'bill' || 
            notification.type == 'card' ||
            notification.type == 'contact');
  }

  Widget _buildActionButton(AppNotification notification) {
    return ElevatedButton.icon(
      onPressed: () => _markAsPaid(notification),
      icon: const Icon(Icons.check, size: 16),
      label: const Text('Mark as Paid'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        minimumSize: const Size(10, 30),
        textStyle: const TextStyle(fontSize: 12),
      ),
    );
  }

  Future<void> _handleNotificationTap(AppNotification notification) async {
    // Mark notification as read
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    await provider.markAsRead(notification.id);
    
    // Handle navigation based on notification type and data
    if (notification.data != null) {
      switch (notification.type) {
        case 'loan':
          if (notification.data!.containsKey('loanId')) {
            // Navigate to loan details screen
            if (mounted) {
              // Navigator.of(context).pushNamed('/loan-details', arguments: notification.data!['loanId']);
            }
          }
          break;
        case 'bill':
          if (notification.data!.containsKey('billId')) {
            // Navigate to bill details screen
            if (mounted) {
              // Navigator.of(context).pushNamed('/bill-details', arguments: notification.data!['billId']);
            }
          }
          break;
        case 'card':
          if (notification.data!.containsKey('cardId')) {
            // Navigate to card details screen
            if (mounted) {
              // Navigator.of(context).pushNamed('/card-details', arguments: notification.data!['cardId']);
            }
          }
          break;
        case 'contact':
          if (notification.data!.containsKey('contactId')) {
            // Navigate to contact details screen
            if (mounted) {
              // Navigator.of(context).pushNamed('/contact-details', arguments: notification.data!['contactId']);
            }
          }
          break;
      }
    }
  }

  Future<void> _markAsPaid(AppNotification notification) async {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    await provider.markAsPaid(notification.id);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${notification.title} marked as paid'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    
    if (provider.unreadCount > 0) {
      setState(() {
        _isMarkingAllRead = true;
      });
      
      await provider.markAllAsRead();
      
      setState(() {
        _isMarkingAllRead = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
} 