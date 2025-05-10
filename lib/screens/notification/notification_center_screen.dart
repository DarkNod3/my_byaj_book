import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../constants/app_theme.dart';
import '../../models/app_notification.dart';
import '../../providers/notification_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/card_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/header/app_header.dart';
import '../../screens/loan/loan_details_screen.dart';
import '../../screens/card/card_screen.dart';
import '../../screens/contact/contact_detail_screen.dart';
import '../../screens/reminder/reminder_screen.dart';
import '../../utils/permission_handler.dart';
import '../settings/notification_settings_screen.dart';

class NotificationCenterScreen extends StatefulWidget {
  static const routeName = '/notification-center';

  const NotificationCenterScreen({Key? key}) : super(key: key);

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isMarkingAllRead = false;
  late List<AppNotification> _notifications;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load notifications
    _loadNotifications();
    
    // Check notification permission
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNotificationPermission();
    });
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
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pushNamed(NotificationSettingsScreen.routeName);
                },
                tooltip: 'Notification Settings',
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _refreshNotifications,
                tooltip: 'Refresh notifications',
              ),
              IconButton(
                icon: const Icon(Icons.done_all, color: Colors.white),
                onPressed: _markAllAsRead,
                tooltip: 'Mark all as read',
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep, color: Colors.white),
                onPressed: _showClearAllConfirmation,
                tooltip: 'Clear notifications',
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
    
    // Format due date if available
    String? formattedDueDate;
    DateTime? dueDate;
    if (notification.data != null && notification.data!.containsKey('dueDate')) {
      try {
        dueDate = DateTime.parse(notification.data!['dueDate']);
        formattedDueDate = DateFormat('dd MMM yyyy').format(dueDate);
      } catch (e) {
        // Ignore parsing errors
      }
    }
    
    // Check if due today
    bool isDueToday = false;
    if (dueDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
      isDueToday = dueDay.isAtSameMomentAs(today);
    }
    
    // Define colors and icons based on notification type
    IconData icon;
    Color iconColor;
    
    // Extract amount and name information for different notification types
    String displayTitle = notification.title;
    String displayAmount = "";
    
    if (notification.data != null) {
      // Extract amount if available
      if (notification.data!.containsKey('amount')) {
        try {
          final amount = notification.data!['amount'];
          if (amount != null) {
            if (amount is double || amount is int) {
              displayAmount = "₹${NumberFormat('#,##,##0.00').format(amount)}";
            } else {
              // Try to parse string to double
              final parsedAmount = double.tryParse(amount.toString());
              if (parsedAmount != null) {
                displayAmount = "₹${NumberFormat('#,##,##0.00').format(parsedAmount)}";
              }
            }
          }
        } catch (e) {
          // Ignore errors in amount formatting
        }
      }
      
      // Set specific title and icons based on notification type
      switch (notification.type) {
        case 'loan':
          if (notification.data!.containsKey('loanName')) {
            displayTitle = notification.data!['loanName'] ?? 'Loan Payment';
          }
          break;
        case 'card':
          if (notification.data!.containsKey('cardName')) {
            displayTitle = notification.data!['cardName'] ?? 'Card Payment';
          }
          break;
        case 'bill':
          if (notification.data!.containsKey('title')) {
            displayTitle = notification.data!['title'] ?? 'Bill Payment';
          }
          break;
      }
    }
    
    switch (notification.type) {
      case 'reminder':
        icon = Icons.notifications_active;
        iconColor = Colors.red;
        break;
      case 'fcm':
        icon = Icons.notifications;
        iconColor = Colors.purple;
        break;
      case 'loan':
        icon = Icons.account_balance;
        iconColor = Colors.blue;
        break;
      case 'card':
        icon = Icons.credit_card;
        iconColor = Colors.orange;
        break;
      case 'bill':
        icon = Icons.receipt;
        iconColor = Colors.green;
        break;
      case 'contact':
        // For contact with due date (Payment to Collect/Make)
        if (notification.data != null && notification.data!.containsKey('paymentType')) {
          final paymentType = notification.data!['paymentType'];
          if (paymentType == 'collect') {
            icon = Icons.arrow_downward;
            iconColor = Colors.green;
          } else {
            icon = Icons.arrow_upward;
            iconColor = Colors.orange;
          }
        } else {
          icon = Icons.person;
          iconColor = Colors.purple;
        }
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 24),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        color: notification.isPaid ? Colors.orange : Colors.blue,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              notification.isPaid 
                ? Icons.visibility_off
                : notification.isRead ? Icons.done_all : Icons.visibility,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              notification.isPaid 
                ? 'Hide Today' 
                : notification.isRead ? 'Read' : 'Mark Read',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          // Left swipe - delete
          final provider = Provider.of<NotificationProvider>(context, listen: false);
          provider.deleteNotification(notification.id);
          
          // Show confirmation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification deleted'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Left swipe - delete
          final shouldDelete = await _confirmDeletion(notification);
          if (shouldDelete) {
            // Also mark as completed for today to ensure it doesn't reappear
            final provider = Provider.of<NotificationProvider>(context, listen: false);
            provider.markAsCompletedToday(notification.id);
          }
          return shouldDelete;
        } else {
          // Right swipe - mark as read or hide today
          if (notification.isPaid) {
            // If already paid, just hide for today
            _markAsCompletedToday(notification.id);
            return false; // Don't dismiss
          } else if (!notification.isRead) {
            _markAsRead(notification.id);
            return false; // Don't dismiss, just mark as read
          }
          return false; // Don't dismiss
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
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: iconColor.withAlpha(40),
                        shape: BoxShape.circle,
                        border: !notification.isRead 
                            ? Border.all(color: iconColor, width: 2)
                            : null,
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  displayTitle,
                                  style: TextStyle(
                                    fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                                    fontSize: 15,
                                    color: notification.isRead ? Colors.black87 : AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              if (displayAmount.isNotEmpty)
                                Text(
                                  displayAmount,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: iconColor,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification.message,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (formattedDueDate != null) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.event,
                                  size: 12,
                                  color: isDueToday ? Colors.red : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Due: $formattedDueDate',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isDueToday ? FontWeight.bold : FontWeight.normal,
                                    color: isDueToday ? Colors.red : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
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
            // Get the loan data from provider
            final loanId = notification.data!['loanId'];
            final loanProvider = Provider.of<LoanProvider>(context, listen: false);
            final loan = loanProvider.activeLoans.firstWhere(
              (loan) => loan['id'] == loanId,
              orElse: () => <String, dynamic>{},
            );
            
            if (mounted && loan.isNotEmpty) {
              // Navigate to loan details screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LoanDetailsScreen(loanData: loan),
                ),
              );
            }
          }
          break;
        case 'bill':
          if (notification.data!.containsKey('billId')) {
            // Navigate to bill details screen
            if (mounted) {
              // Use the standard method defined in your app for bill navigation
              Navigator.pushNamed(context, '/bill-details', arguments: notification.data!['billId']);
            }
          }
          break;
        case 'card':
          if (notification.data!.containsKey('cardId') || notification.data!.containsKey('cardIndex')) {
            // For card, we need to set the selected card index
            final cardProvider = Provider.of<CardProvider>(context, listen: false);
            
            // Try to get cardIndex or find it by cardId
            int? cardIndex;
            if (notification.data!.containsKey('cardIndex')) {
              cardIndex = notification.data!['cardIndex'] as int?;
            } else if (notification.data!.containsKey('cardId')) {
              final cardId = notification.data!['cardId'];
              // Find the index of the card with this ID
              for (int i = 0; i < cardProvider.cards.length; i++) {
                if (cardProvider.cards[i]['id'] == cardId) {
                  cardIndex = i;
                  break;
                }
              }
            }
            
            // Set the selected card index if found
            if (cardIndex != null) {
              cardProvider.setSelectedCardIndex(cardIndex);
            }
            
            // Navigate to the card screen
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CardScreen(showAppBar: true),
                ),
              );
            }
          }
          break;
        case 'contact':
          if (notification.data!.containsKey('contactId')) {
            // Get contact data from transaction provider
            final contactId = notification.data!['contactId'];
            final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
            final contact = transactionProvider.contacts.firstWhere(
              (contact) => contact['phone'] == contactId,
              orElse: () => <String, dynamic>{},
            );
            
            if (mounted && contact.isNotEmpty) {
              // Navigate to contact details screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContactDetailScreen(contact: contact),
                ),
              );
            }
          }
          break;
        case 'reminder':
          // Navigate to reminders screen
          if (mounted) {
            Navigator.pushNamed(context, ReminderScreen.routeName);
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

  Future<void> _refreshNotifications() async {
    setState(() {
      _isMarkingAllRead = true;
    });
    
    try {
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      await notificationProvider.syncAllReminders();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifications refreshed'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      // If there was an error, show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to refresh notifications'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isMarkingAllRead = false;
        });
      }
    }
  }

  // Show confirmation dialog for clearing all notifications
  Future<void> _showClearAllConfirmation() async {
    final bool confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: Text(
          'Are you sure you want to clear all ${_tabController.index == 0 ? 'today\'s' : 'upcoming'} notifications?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirm) {
      setState(() {
        _isMarkingAllRead = true; // Use the same loading indicator
      });
      
      final provider = Provider.of<NotificationProvider>(context, listen: false);
      
      if (_tabController.index == 0) {
        // Clear today's notifications
        for (final notification in provider.todayNotifications) {
          await provider.deleteNotification(notification.id);
        }
      } else {
        // Clear upcoming notifications
        for (final notification in provider.upcomingNotifications) {
          await provider.deleteNotification(notification.id);
        }
      }
      
      setState(() {
        _isMarkingAllRead = false;
      });
      
      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifications cleared'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Mark as completed for today (hide from today's list)
  void _markAsCompletedToday(String id) {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    provider.markAsCompletedToday(id);
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Marked as completed for today'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  // Add method to check notification permission
  Future<void> _checkNotificationPermission() async {
    final permissionUtils = PermissionUtils();
    final hasPermission = await permissionUtils.requestNotificationPermission(context);
    
    if (!hasPermission && mounted) {
      // Show a persistent banner at the top
      ScaffoldMessenger.of(context).showMaterialBanner(
        MaterialBanner(
          content: const Text(
            'Notification permission is needed for payment reminders and alerts',
          ),
          actions: [
            TextButton(
              onPressed: () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
              child: const Text('DISMISS'),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                openAppSettings();
              },
              child: const Text('SETTINGS'),
            ),
          ],
        ),
      );
    }
  }

  void _loadNotifications() {
    // ... existing code ...
  }
} 