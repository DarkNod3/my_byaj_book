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
                Tab(text: 'Today\'s'),
                Tab(text: 'Upcoming'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationList(filterType: 'today'),
                _buildNotificationList(filterType: 'upcoming'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList({required String filterType}) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        final List<AppNotification> notifications;
        
        if (filterType == 'today') {
          // Use the provider's todayNotifications getter
          notifications = provider.todayNotifications;
        } else {
          // Use the provider's upcomingNotifications getter
          notifications = provider.upcomingNotifications;
        }
        
        if (_isMarkingAllRead) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (notifications.isEmpty) {
          return _buildEmptyState(filterType);
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

  Widget _buildEmptyState(String filterType) {
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
            filterType == 'today'
                ? 'No notifications for today'
                : 'No upcoming notifications',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            filterType == 'today'
                ? 'You don\'t have any notifications scheduled for today'
                : 'You don\'t have any upcoming notifications scheduled',
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
    
    // Create the dismissible notification item with swipe to dismiss
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.blue,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: notification.isPaid 
            ? const Icon(Icons.check_circle, color: Colors.white)
            : const Icon(Icons.mark_email_read, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Left swipe - delete
          return await _confirmDeletion(notification);
        } else {
          // Right swipe - mark as read/paid
          if (!notification.isRead) {
            _markAsRead(notification.id);
            return false; // Don't dismiss, just mark as read
          } else if (!notification.isPaid && _canBePaid(notification)) {
            _markAsPaid(notification.id);
            return false; // Don't dismiss, just mark as paid
          }
          return false; // Don't dismiss for other cases
        }
      },
      child: Card(
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
                              decoration: const BoxDecoration(
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
                          if (_canBePaid(notification) && !notification.isPaid)
                            _buildMarkAsPaidButton(notification),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _canBePaid(AppNotification notification) {
    return notification.type == 'loan' || 
           notification.type == 'card' || 
           notification.type == 'bill' ||
           (notification.type == 'contact' && 
               notification.data != null && 
               notification.data!['paymentType'] != null);
  }

  Widget _buildMarkAsPaidButton(AppNotification notification) {
    return ElevatedButton.icon(
      onPressed: () => _markAsPaid(notification.id),
      icon: const Icon(Icons.check, size: 16),
      label: const Text('Mark as Paid'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 12),
        minimumSize: const Size(0, 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Future<bool> _confirmDeletion(AppNotification notification) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _markAsRead(String id) {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    provider.markAsRead(id);
  }

  void _markAsPaid(String id) {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    provider.markAsPaid(id);
    
    // Handle action based on notification type
    final notification = provider.notifications.firstWhere((n) => n.id == id);
    if (notification.type == 'loan' && notification.data != null) {
      _handleLoanPayment(notification);
    } else if (notification.type == 'card' && notification.data != null) {
      _handleCardPayment(notification);
    } else if (notification.type == 'contact' && notification.data != null) {
      _handleContactPayment(notification);
    }
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Marked as paid'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleLoanPayment(AppNotification notification) {
    // You would implement this based on your loan provider functionality
    // For example, update the loan installment status
    if (notification.data?['loanId'] != null && notification.data?['installmentNumber'] != null) {
      // Access your loan provider and mark installment as paid
    }
  }

  void _handleCardPayment(AppNotification notification) {
    // You would implement this based on your card provider functionality
    if (notification.data?['cardId'] != null) {
      // Access your card provider and mark payment as paid
    }
  }

  void _handleContactPayment(AppNotification notification) {
    // You would implement this based on your transaction provider functionality
    if (notification.data?['contactId'] != null) {
      // Access your transaction provider and record the payment
    }
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