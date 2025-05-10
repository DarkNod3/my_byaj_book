import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/app_notification.dart';
import '../providers/loan_provider.dart';
import '../providers/card_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/bill_note_provider.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  static const String _notificationsKey = 'app_notifications';
  static const String _deletedNotificationsKey = 'deleted_notifications';
  static const String _completedTodayNotificationsKey = 'completed_today_notifications';
  
  List<AppNotification> _notifications = [];
  Set<String> _deletedNotificationIds = {};
  Set<String> _completedTodayNotificationIds = {}; // Track notifications completed today
  bool _isLoading = false;
  final int _maxFcmNotifications = 100;
  final NotificationService _notificationService = NotificationService.instance;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  NotificationService get notificationService => _notificationService;

  // Get unread notifications
  List<AppNotification> get unreadNotifications => 
    _notifications.where((notification) => !notification.isRead).toList();
  
  // Get due notifications (not paid and not FCM)
  List<AppNotification> get dueNotifications => 
    _notifications.where((notification) => 
      !notification.isPaid && notification.type != 'fcm').toList();
  
  // Get FCM notifications
  List<AppNotification> get fcmNotifications => 
    _notifications.where((notification) => notification.type == 'fcm').toList();
  
  // Get today's notifications
  List<AppNotification> get todayNotifications {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    return _notifications.where((notification) {
      // Filter only FCM messages, reminders, and due dates
      if (!_isAllowedNotificationType(notification)) {
        return false;
      }
      
      // Skip notifications that have been completed today
      if (_completedTodayNotificationIds.contains(notification.id)) {
        return false;
      }
      
      // Check if due date is in data
      if (notification.data != null && notification.data!.containsKey('dueDate')) {
        try {
          final dueDate = DateTime.parse(notification.data!['dueDate']);
          final dueDateDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
          // Check if due date is today
          return dueDateDay.isAtSameMomentAs(today);
        } catch (e) {
          // If date parsing fails, fall back to timestamp check
          return notification.timestamp.isAfter(today) && 
                 notification.timestamp.isBefore(tomorrow);
        }
      }
      
      // Use timestamp for notifications without due date
      return notification.timestamp.isAfter(today) && 
             notification.timestamp.isBefore(tomorrow);
    }).toList();
  }
  
  // Get upcoming notifications (future dates in current month)
  List<AppNotification> get upcomingNotifications {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    
    return _notifications.where((notification) {
      // Filter only FCM messages, reminders, and due dates
      if (!_isAllowedNotificationType(notification)) {
        return false;
      }
      
      // Check if due date is in data
      if (notification.data != null && notification.data!.containsKey('dueDate')) {
        try {
          final dueDate = DateTime.parse(notification.data!['dueDate']);
          final dueDateDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
          
          // Check if due date is after tomorrow but still in current month
          return dueDateDay.isAfter(tomorrow) && dueDateDay.isBefore(nextMonth);
        } catch (e) {
          // If date parsing fails, fall back to timestamp check
          return notification.timestamp.isAfter(tomorrow);
        }
      }
      
      // Use timestamp for notifications without due date
      return notification.timestamp.isAfter(tomorrow);
    }).toList();
  }
  
  // Count unread notifications
  int get unreadCount => unreadNotifications.length;

  // Constructor
  NotificationProvider() {
    _loadNotifications();
    _loadCompletedTodayNotifications();
    _cleanupExpiredCompletedNotifications(); // Cleanup completed notifications from previous days
  }

  // Load notifications from SharedPreferences
  Future<void> _loadNotifications() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList(_notificationsKey) ?? [];
      
      _notifications = notificationsJson
          .map((json) => AppNotification.fromJson(jsonDecode(json)))
          .toList();
      
      // Load deleted notification IDs
      final deletedNotificationsJson = prefs.getStringList(_deletedNotificationsKey) ?? [];
      _deletedNotificationIds = Set.from(deletedNotificationsJson);
      
      // Filter out any notifications that should be deleted
      _notifications.removeWhere((notification) => 
        _deletedNotificationIds.contains(notification.id) ||
        _shouldFilterNotification(notification)
      );
      
      // Sort by timestamp (newest first)
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      _notifications = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load completed today notifications from SharedPreferences
  Future<void> _loadCompletedTodayNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completedTodayJson = prefs.getStringList(_completedTodayNotificationsKey) ?? [];
      _completedTodayNotificationIds = Set.from(completedTodayJson);
    } catch (e) {
      debugPrint('Error loading completed today notifications: $e');
      _completedTodayNotificationIds = {};
    }
  }

  // Save completed today notifications to SharedPreferences
  Future<void> _saveCompletedTodayNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_completedTodayNotificationsKey, _completedTodayNotificationIds.toList());
    } catch (e) {
      debugPrint('Error saving completed today notifications: $e');
    }
  }

  // Clean up expired completed notifications (from previous days)
  Future<void> _cleanupExpiredCompletedNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCleanupTimeStr = prefs.getString('last_notification_cleanup_time');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    DateTime lastCleanupTime;
    if (lastCleanupTimeStr != null) {
      try {
        lastCleanupTime = DateTime.parse(lastCleanupTimeStr);
      } catch (e) {
        lastCleanupTime = DateTime(1970);
      }
    } else {
      lastCleanupTime = DateTime(1970);
    }
    
    // If the last cleanup was not today, reset completed today notifications
    if (lastCleanupTime.year != today.year || 
        lastCleanupTime.month != today.month || 
        lastCleanupTime.day != today.day) {
      _completedTodayNotificationIds.clear();
      await _saveCompletedTodayNotifications();
      await prefs.setString('last_notification_cleanup_time', today.toIso8601String());
    }
  }

  // Helper to determine if a notification should be filtered out
  bool _shouldFilterNotification(AppNotification notification) {
    // Filter out notifications for contacts, cards, loans or bills that were previously deleted
    if (notification.data != null) {
      if (notification.type == 'contact' && notification.data!.containsKey('contactId')) {
        final contactId = notification.data!['contactId'];
        return _deletedNotificationIds.contains('contact_$contactId');
      } else if (notification.type == 'card' && notification.data!.containsKey('cardId')) {
        final cardId = notification.data!['cardId'];
        return _deletedNotificationIds.contains('card_$cardId');
      } else if (notification.type == 'loan' && notification.data!.containsKey('loanId')) {
        final loanId = notification.data!['loanId'];
        return _deletedNotificationIds.contains('loan_$loanId');
      } else if (notification.type == 'bill' && notification.data!.containsKey('billId')) {
        final billId = notification.data!['billId'];
        return _deletedNotificationIds.contains('bill_$billId');
      }
    }
    return false;
  }

  // Save notifications to SharedPreferences
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = _notifications
          .map((notification) => jsonEncode(notification.toJson()))
          .toList();
      
      await prefs.setStringList(_notificationsKey, notificationsJson);
      
      // Save deleted notification IDs
      await prefs.setStringList(_deletedNotificationsKey, _deletedNotificationIds.toList());
    } catch (e) {
      debugPrint('Error saving notifications: $e');
    }
  }

  // Add a new notification
  Future<void> addNotification(AppNotification notification) async {
    // Skip if this notification ID or entity has been deleted
    if (_deletedNotificationIds.contains(notification.id) || 
        _shouldFilterNotification(notification)) {
      return;
    }
    
    // Check if notification with same ID already exists
    final existingIndex = _notifications.indexWhere((n) => n.id == notification.id);
    
    if (existingIndex >= 0) {
      // Update existing notification
      _notifications[existingIndex] = notification;
    } else {
      // Add new notification
      _notifications.add(notification);
    }
    
    // Limit FCM notifications if needed
    _limitFcmNotifications();
    
    // Sort by timestamp (newest first)
    _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    await _saveNotifications();
    notifyListeners();
  }

  // Add FCM notification
  Future<void> addFcmNotification({
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    final notification = AppNotification(
      id: const Uuid().v4(),
      type: 'fcm',
      title: title,
      message: message,
      timestamp: DateTime.now(),
      data: data,
    );
    
    await addNotification(notification);
  }

  // Mark notification as read
  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index >= 0) {
      _notifications[index].isRead = true;
      await _saveNotifications();
      notifyListeners();
    }
  }

  // Mark notification as paid
  Future<void> markAsPaid(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index >= 0) {
      _notifications[index].isPaid = true;
      
      // Add to completed today list to prevent reshowing today
      _completedTodayNotificationIds.add(id);
      await _saveCompletedTodayNotifications();
      
      await _saveNotifications();
      notifyListeners();
    }
  }
  
  // Mark notification as completed for today
  Future<void> markAsCompletedToday(String id) async {
    _completedTodayNotificationIds.add(id);
    await _saveCompletedTodayNotifications();
    notifyListeners();
  }
  
  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    for (final notification in _notifications) {
      notification.isRead = true;
    }
    await _saveNotifications();
    notifyListeners();
  }
  
  // Delete notification
  Future<void> deleteNotification(String id) async {
    try {
      // Get the notification before deleting
      final notificationIndex = _notifications.indexWhere((n) => n.id == id);
      if (notificationIndex < 0) return;
      
      final notification = _notifications[notificationIndex];
      
      // Add to deleted notifications list to prevent regeneration
      _deletedNotificationIds.add(notification.id);
      
      // Also add to completed today list to prevent reshowing today
      _completedTodayNotificationIds.add(notification.id);
      await _saveCompletedTodayNotifications();
      
      // Also track the entity ID to prevent similar notifications
      if (notification.data != null) {
        if (notification.type == 'contact' && notification.data!.containsKey('contactId')) {
          final contactId = notification.data!['contactId'];
          _deletedNotificationIds.add('contact_$contactId');
        } else if (notification.type == 'card' && notification.data!.containsKey('cardId')) {
          final cardId = notification.data!['cardId'];
          _deletedNotificationIds.add('card_$cardId');
        } else if (notification.type == 'loan' && notification.data!.containsKey('loanId')) {
          final loanId = notification.data!['loanId'];
          if (notification.data!.containsKey('installmentNumber')) {
            final installmentNumber = notification.data!['installmentNumber'];
            _deletedNotificationIds.add('loan_${loanId}_$installmentNumber');
          } else {
            _deletedNotificationIds.add('loan_$loanId');
          }
        } else if (notification.type == 'bill' && notification.data!.containsKey('billId')) {
          final billId = notification.data!['billId'];
          _deletedNotificationIds.add('bill_$billId');
        } else if (notification.type == 'reminder' && notification.data!.containsKey('reminderId')) {
          final reminderId = notification.data!['reminderId'];
          _deletedNotificationIds.add('reminder_$reminderId');
        }
      }
      
      // Remove from notifications list
      _notifications.removeAt(notificationIndex);
      
      // Cancel any scheduled notifications based on type
      if (notification.type == 'loan' && notification.data != null) {
        final loanId = notification.data!['loanId'];
        if (loanId != null) {
          await _notificationService.cancelNotificationForLoan(loanId);
        }
      } else if (notification.type == 'card' && notification.data != null) {
        final cardId = notification.data!['cardId'];
        if (cardId != null) {
          await _notificationService.cancelNotificationForCard(cardId);
        }
      } else if (notification.type == 'reminder' && notification.data != null) {
        final reminderId = notification.data!['reminderId'];
        if (reminderId != null) {
          await _notificationService.cancelNotificationForReminder(reminderId);
        }
      }
      
      await _saveNotifications();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    // Store all notification IDs before clearing to prevent regeneration
    for (final notification in _notifications) {
      _deletedNotificationIds.add(notification.id);
      
      if (notification.data != null) {
        if (notification.type == 'contact' && notification.data!.containsKey('contactId')) {
          final contactId = notification.data!['contactId'];
          _deletedNotificationIds.add('contact_$contactId');
        } else if (notification.type == 'card' && notification.data!.containsKey('cardId')) {
          final cardId = notification.data!['cardId'];
          _deletedNotificationIds.add('card_$cardId');
        } else if (notification.type == 'loan' && notification.data!.containsKey('loanId')) {
          final loanId = notification.data!['loanId'];
          _deletedNotificationIds.add('loan_$loanId');
        } else if (notification.type == 'bill' && notification.data!.containsKey('billId')) {
          final billId = notification.data!['billId'];
          _deletedNotificationIds.add('bill_$billId');
        } else if (notification.type == 'reminder' && notification.data!.containsKey('reminderId')) {
          final reminderId = notification.data!['reminderId'];
          _deletedNotificationIds.add('reminder_$reminderId');
        }
      }
    }
    
    _notifications.clear();
    await _saveNotifications();
    notifyListeners();
  }

  // Limit FCM notifications to prevent excessive storage usage
  void _limitFcmNotifications() {
    final fcmNotifications = _notifications.where((n) => n.type == 'fcm').toList();
    
    if (fcmNotifications.length > _maxFcmNotifications) {
      // Sort by timestamp (oldest first)
      fcmNotifications.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      // Get IDs of oldest notifications to remove
      final notificationsToRemove = fcmNotifications
          .sublist(0, fcmNotifications.length - _maxFcmNotifications)
          .map((n) => n.id)
          .toList();
      
      // Remove oldest notifications
      _notifications.removeWhere((n) => notificationsToRemove.contains(n.id));
    }
  }

  // Override the generateDueNotifications method to also create duplicates
  Future<void> generateDueNotifications({
    LoanProvider? loanProvider,
    CardProvider? cardProvider,
    TransactionProvider? transactionProvider,
    BillNoteProvider? billNoteProvider,
  }) async {
    // First generate standard notifications
    // Generate loan notifications
    if (loanProvider != null) {
      _generateLoanNotifications(loanProvider);
    }
    
    // Generate card notifications
    if (cardProvider != null) {
      _generateCardNotifications(cardProvider);
    }
    
    // Generate contact notifications
    if (transactionProvider != null) {
      _generateContactNotifications(transactionProvider);
    }
    
    // Generate bill notifications
    if (billNoteProvider != null) {
      _generateBillNotifications(billNoteProvider);
    }
    
    await _saveNotifications();
    
    // Then duplicate important ones for today
    await duplicateImportantNotifications();
    
    notifyListeners();
  }

  // Duplicate important notifications to show them multiple times
  Future<void> duplicateImportantNotifications() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<AppNotification> importantNotifications = [];
    
    // Find important notifications that should be duplicated
    for (final notification in _notifications) {
      // Only duplicate due date notifications due today
      if (notification.data != null && 
          notification.data!.containsKey('dueDate') &&
          !_completedTodayNotificationIds.contains(notification.id)) {
        try {
          final dueDate = DateTime.parse(notification.data!['dueDate']);
          final dueDateDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
          
          // If due today and it's a payment or reminder
          if (dueDateDay.isAtSameMomentAs(today) && 
              (notification.type == 'loan' || 
               notification.type == 'card' || 
               notification.type == 'bill' ||
               notification.type == 'reminder')) {
            
            // Create up to 3 duplicate notifications with slightly different messages
            for (int i = 1; i <= 3; i++) {
              // Create a new ID that's unique but deterministic
              final newId = "${notification.id}_duplicate_$i";
              
              // Skip if this duplicate already exists
              if (_notifications.any((n) => n.id == newId) ||
                  _completedTodayNotificationIds.contains(newId)) {
                continue;
              }
              
              // Create a duplicate with slightly different message
              String message = notification.message;
              if (i == 1) {
                message = "REMINDER: ${notification.message}";
              } else if (i == 2) {
                message = "IMPORTANT: ${notification.message}";
              } else {
                message = "FINAL REMINDER: ${notification.message}";
              }
              
              final duplicate = AppNotification(
                id: newId,
                type: notification.type,
                title: notification.title,
                message: message,
                timestamp: DateTime.now().add(Duration(hours: i)), // Space them out
                data: notification.data,
                isRead: false,
              );
              
              importantNotifications.add(duplicate);
            }
          }
        } catch (e) {
          // Skip if date can't be parsed
        }
      }
    }
    
    // Add the duplicates to the notifications list
    if (importantNotifications.isNotEmpty) {
      _notifications.addAll(importantNotifications);
      
      // Sort by timestamp (newest first)
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      await _saveNotifications();
      notifyListeners();
    }
  }

  // Handle FCM message notification
  Future<void> handleFcmMessage(String title, String body, Map<String, dynamic>? data) async {
    // Create a new notification ID
    final id = const Uuid().v4();
    
    // Determine notification type based on data
    String type = 'fcm';
    if (data != null) {
      if (data.containsKey('type')) {
        type = data['type'];
      } else if (data.containsKey('loanId')) {
        type = 'loan';
      } else if (data.containsKey('cardId')) {
        type = 'card';
      } else if (data.containsKey('contactId')) {
        type = 'contact';
      } else if (data.containsKey('billId')) {
        type = 'bill';
      }
    }
    
    // Create the notification
    final notification = AppNotification(
      id: id,
      type: type,
      title: title,
      message: body,
      timestamp: DateTime.now(),
      data: data,
    );
    
    // Add the notification
    await addNotification(notification);
  }
  
  // Add a contact reminder notification
  Future<void> addContactReminderNotification({
    required String contactId,
    required String contactName,
    required double amount,
    required DateTime dueDate,
    required String paymentType, // 'collect' or 'pay'
  }) async {
    // Skip if this contact notification was previously deleted
    if (_deletedNotificationIds.contains('contact_$contactId')) {
      return;
    }
    
    // Format the amount properly with commas
    final formattedAmount = NumberFormat.currency(
      symbol: '',
      locale: 'en_IN',
      decimalDigits: 1
    ).format(amount);
    
    // Create notification ID
    final id = 'contact_${contactId}_${dueDate.millisecondsSinceEpoch}';
    
    // Create title and message based on payment type
    final title = paymentType == 'collect' 
        ? 'Payment to Collect' 
        : 'Payment to Make';
        
    final message = paymentType == 'collect'
        ? 'You need to collect $formattedAmount from $contactName'
        : 'You need to pay $formattedAmount to $contactName';
    
    // Create notification
    final notification = AppNotification(
      id: id,
      type: 'contact',
      title: title,
      message: message,
      timestamp: DateTime.now(),
      data: {
        'contactId': contactId,
        'contactName': contactName,
        'amount': amount,
        'dueDate': dueDate.toIso8601String(),
        'paymentType': paymentType,
      },
    );
    
    // Add notification
    await addNotification(notification);
  }
  
  // Get notifications by type
  List<AppNotification> getNotificationsByType(String type) {
    return _notifications.where((notification) => 
      notification.type == type && 
      notification.data != null && 
      notification.data!.containsKey('dueDate') &&
      DateTime.parse(notification.data!['dueDate']).isAfter(DateTime.now())
    ).toList();
  }
  
  // Get due notifications by type
  List<AppNotification> getDueNotificationsByType(String type) {
    return _notifications.where((notification) => 
      notification.type == type && 
      !notification.isPaid &&
      notification.data != null && 
      notification.data!.containsKey('dueDate') &&
      DateTime.parse(notification.data!['dueDate']).isAfter(DateTime.now())
    ).toList();
  }

  // Sync all reminders and due dates from various sources
  Future<void> syncAllReminders() async {
    await syncBillReminders();
    await syncCardDueDates();
    await syncLoanPaymentDates();
    await syncUserReminders();
    
    // After syncing, ensure all deleted notifications stay deleted
    _notifications.removeWhere((notification) => 
      _deletedNotificationIds.contains(notification.id) ||
      _shouldFilterNotification(notification)
    );
    
    await _saveNotifications();
    notifyListeners();
  }
  
  // Sync bill reminders
  Future<void> syncBillReminders() async {
    try {
      final billProvider = BillNoteProvider();
      await billProvider.loadNotes();
      
      // Get upcoming bill reminders
      final upcomingReminders = billProvider.upcomingReminders;
      
      for (final bill in upcomingReminders) {
        if (bill.reminderDate != null) {
          final id = 'bill_${bill.id}';
          
          // Create notification from bill
          final notification = AppNotification(
            id: id,
            type: 'bill',
            title: 'Bill Reminder',
            message: 'Reminder for ${bill.title}' + (bill.amount != null ? ' (₹${bill.amount})' : ''),
            timestamp: DateTime.now(),
            data: {
              'billId': bill.id,
              'dueDate': bill.reminderDate!.toIso8601String(),
              'amount': bill.amount,
              'category': bill.category.index,
              'title': bill.title,
            },
          );
          
          // Add notification
          await addNotification(notification);
        }
      }
    } catch (e) {
      debugPrint('Error syncing bill reminders: $e');
    }
  }
  
  // Sync card due dates
  Future<void> syncCardDueDates() async {
    try {
      final cardProvider = CardProvider();
      await cardProvider.loadCards();
      
      for (int i = 0; i < cardProvider.cards.length; i++) {
        final card = cardProvider.cards[i];
        
        // Check if card has a due date entry
        if (card.containsKey('dueDate') && card['dueDate'] != null) {
          DateTime? dueDate;
          
          // Parse the due date
          if (card['dueDate'] is DateTime) {
            dueDate = card['dueDate'];
          } else if (card['dueDate'] is String) {
            try {
              dueDate = DateTime.parse(card['dueDate']);
            } catch (e) {
              // Try to parse formatted date strings
              try {
                final parts = card['dueDate'].split(' ');
                if (parts.length >= 3) {
                  // Format: "DD Month, YYYY"
                  final day = int.tryParse(parts[0]) ?? 1;
                  final month = _parseMonth(parts[1]);
                  final year = int.tryParse(parts[2].replaceAll(',', '')) ?? DateTime.now().year;
                  dueDate = DateTime(year, month, day);
                }
              } catch (e) {
                debugPrint('Error parsing card due date: $e');
              }
            }
          }
          
          if (dueDate != null) {
            final id = 'card_${card['id'] ?? i}';
            double amount = 0.0;
            
            // Try to parse amount
            if (card.containsKey('dueAmount') && card['dueAmount'] != null) {
              if (card['dueAmount'] is double) {
                amount = card['dueAmount'];
              } else if (card['dueAmount'] is int) {
                amount = card['dueAmount'].toDouble();
              } else if (card['dueAmount'] is String) {
                // Remove currency symbols and commas
                final amountStr = card['dueAmount'].toString()
                    .replaceAll('₹', '')
                    .replaceAll(',', '')
                    .trim();
                amount = double.tryParse(amountStr) ?? 0.0;
              }
            }
            
            // Create notification from card
            final notification = AppNotification(
              id: id,
              type: 'card',
              title: 'Card Payment Due',
              message: 'Payment due for ${card['cardName'] ?? card['bankName'] ?? 'your card'}: ₹${amount.toStringAsFixed(2)}',
              timestamp: DateTime.now(),
              data: {
                'cardId': card['id'] ?? i.toString(),
                'dueDate': dueDate.toIso8601String(),
                'amount': amount,
                'cardName': card['cardName'] ?? card['bankName'] ?? 'Credit Card',
              },
            );
            
            // Add notification
            await addNotification(notification);
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing card due dates: $e');
    }
  }
  
  // Sync loan payment dates
  Future<void> syncLoanPaymentDates() async {
    try {
      final loanProvider = LoanProvider();
      await loanProvider.loadLoans();
      
      // Iterate through active loans
      for (final loan in loanProvider.activeLoans) {
        // Check upcoming installments
        if (loan.containsKey('installments') && loan['installments'] is List) {
          final installments = loan['installments'] as List;
          
          for (final installment in installments) {
            if (installment.containsKey('dueDate') && 
                installment['dueDate'] != null && 
                !installment['isPaid']) {
              
              DateTime dueDate = installment['dueDate'];
              
              // Only consider current month installments
              final now = DateTime.now();
              final currentMonth = DateTime(now.year, now.month);
              final nextMonth = DateTime(now.year, now.month + 1);
              final dueDateMonth = DateTime(dueDate.year, dueDate.month);
              
              if (dueDateMonth.isAtSameMomentAs(currentMonth)) {
                final id = 'loan_${loan['id']}_${installment['number']}';
                
                // Get installment amount
                double amount = 0.0;
                if (installment.containsKey('amount')) {
                  amount = installment['amount'] is double 
                      ? installment['amount'] 
                      : double.tryParse(installment['amount'].toString()) ?? 0.0;
                } else if (loan.containsKey('emi')) {
                  amount = loan['emi'] is double
                      ? loan['emi']
                      : double.tryParse(loan['emi'].toString()) ?? 0.0;
                }
                
                // Format due date for message
                final formattedDueDate = DateFormat('dd MMM').format(dueDate);
                
                // Create notification from loan installment
                final notification = AppNotification(
                  id: id,
                  type: 'loan',
                  title: 'Loan Payment Due',
                  message: '${loan['name'] ?? 'Loan'} payment of ₹${amount.toStringAsFixed(0)} due on $formattedDueDate',
                  timestamp: DateTime.now(),
                  data: {
                    'loanId': loan['id'],
                    'installmentNumber': installment['number'],
                    'dueDate': dueDate.toIso8601String(),
                    'amount': amount,
                    'loanName': loan['name'] ?? loan['loanType'] ?? 'Loan',
                  },
                );
                
                // Add notification
                await addNotification(notification);
              }
            }
          }
        } else if (loan.containsKey('nextPaymentDate') && loan['nextPaymentDate'] != null) {
          // For loans without installments, check nextPaymentDate
          DateTime nextPaymentDate = loan['nextPaymentDate'];
          
          // Only consider current month payments
          final now = DateTime.now();
          final currentMonth = DateTime(now.year, now.month);
          final nextMonth = DateTime(now.year, now.month + 1);
          final paymentDateMonth = DateTime(nextPaymentDate.year, nextPaymentDate.month);
          
          if (paymentDateMonth.isAtSameMomentAs(currentMonth)) {
            final id = 'loan_${loan['id']}_next';
            
            // Get EMI amount
            double amount = 0.0;
            if (loan.containsKey('emi')) {
              amount = loan['emi'] is double
                  ? loan['emi']
                  : double.tryParse(loan['emi'].toString()) ?? 0.0;
            }
            
            // Format due date for message
            final formattedDueDate = DateFormat('dd MMM').format(nextPaymentDate);
            
            // Create notification from loan payment date
            final notification = AppNotification(
              id: id,
              type: 'loan',
              title: 'Loan Payment Due',
              message: '${loan['name'] ?? 'Loan'} payment of ₹${amount.toStringAsFixed(0)} due on $formattedDueDate',
              timestamp: DateTime.now(),
              data: {
                'loanId': loan['id'],
                'dueDate': nextPaymentDate.toIso8601String(),
                'amount': amount,
                'loanName': loan['name'] ?? loan['loanType'] ?? 'Loan',
              },
            );
            
            // Add notification
            await addNotification(notification);
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing loan payment dates: $e');
    }
  }
  
  // Sync user reminders
  Future<void> syncUserReminders() async {
    try {
      final transactionProvider = TransactionProvider();
      // Access manualReminders directly instead of calling loadReminders()
      // The initializer already calls _loadManualReminders() internally

      // Iterate through user reminders - use manualReminders instead of reminders
      for (final reminder in transactionProvider.manualReminders) {
        if (reminder.containsKey('dueDate') && reminder['dueDate'] != null) {
          DateTime dueDate;
          
          // Parse due date if needed
          if (reminder['dueDate'] is DateTime) {
            dueDate = reminder['dueDate'];
          } else if (reminder['dueDate'] is String) {
            try {
              dueDate = DateTime.parse(reminder['dueDate']);
            } catch (e) {
              // Skip reminders with invalid dates
              continue;
            }
          } else {
            // Skip reminders with invalid dates
            continue;
          }
          
          // Skip past reminders
          final now = DateTime.now();
          if (dueDate.isBefore(DateTime(now.year, now.month, now.day))) {
            continue;
          }
          
          // Only consider current month reminders
          final currentMonth = DateTime(now.year, now.month);
          final nextMonth = DateTime(now.year, now.month + 1);
          final dueDateMonth = DateTime(dueDate.year, dueDate.month);
          
          if (dueDateMonth.isAtSameMomentAs(currentMonth) || dueDateMonth.isAtSameMomentAs(nextMonth)) {
            final id = 'reminder_${reminder['id'] ?? DateTime.now().millisecondsSinceEpoch}';
            
            // Get reminder details
            String title = reminder['title'] ?? 'Reminder';
            String description = reminder['description'] ?? '';
            double amount = 0.0;
            
            if (reminder.containsKey('amount')) {
              amount = reminder['amount'] is double 
                  ? reminder['amount'] 
                  : double.tryParse(reminder['amount'].toString()) ?? 0.0;
            }
            
            // Format due date for message
            final formattedDueDate = DateFormat('dd MMM').format(dueDate);
            
            // Create message based on available data
            String message;
            if (description.isNotEmpty) {
              message = '$description - Due on $formattedDueDate';
            } else if (amount > 0) {
              message = 'Amount: ₹${amount.toStringAsFixed(0)} - Due on $formattedDueDate';
            } else {
              message = 'Due on $formattedDueDate';
            }
            
            // Create notification from reminder
            final notification = AppNotification(
              id: id,
              type: 'reminder',
              title: title,
              message: message,
              timestamp: DateTime.now(),
              data: {
                'reminderId': reminder['id'],
                'dueDate': dueDate.toIso8601String(),
                'amount': amount,
                'title': title,
                'description': description,
              },
            );
            
            // Add notification
            await addNotification(notification);
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing user reminders: $e');
    }
  }
  
  // Helper method to parse month name to month number
  int _parseMonth(String monthName) {
    final months = {
      'jan': 1, 'january': 1,
      'feb': 2, 'february': 2,
      'mar': 3, 'march': 3,
      'apr': 4, 'april': 4,
      'may': 5,
      'jun': 6, 'june': 6,
      'jul': 7, 'july': 7,
      'aug': 8, 'august': 8,
      'sep': 9, 'september': 9,
      'oct': 10, 'october': 10,
      'nov': 11, 'november': 11,
      'dec': 12, 'december': 12,
    };
    
    return months[monthName.toLowerCase()] ?? DateTime.now().month;
  }

  // Helper method to check if a notification is of allowed type (FCM, due date, or reminder)
  bool _isAllowedNotificationType(AppNotification notification) {
    // Always allow FCM notifications
    if (notification.type == 'fcm') {
      return true;
    }
    
    // Allow reminders
    if (notification.type == 'reminder') {
      return true;
    }
    
    // Allow due date notifications (loan, card, bill)
    if ((notification.type == 'loan' || 
         notification.type == 'card' || 
         notification.type == 'bill') && 
        notification.data != null && 
        notification.data!.containsKey('dueDate')) {
      return true;
    }
    
    // Allow contact notifications with due dates
    if (notification.type == 'contact' && 
        notification.data != null && 
        notification.data!.containsKey('dueDate')) {
      return true;
    }
    
    // Filter out other notification types
    return false;
  }

  // Generate loan notifications
  void _generateLoanNotifications(LoanProvider loanProvider) {
    for (final loan in loanProvider.activeLoans) {
      // Skip if this loan's notifications have been deleted
      final loanId = loan['id'] as String;
      if (_deletedNotificationIds.contains('loan_$loanId')) continue;
      
      // Check if loan has upcoming or overdue installments
      final installments = loan['installments'] as List<dynamic>?;
      if (installments == null || installments.isEmpty) continue;
      
      for (final installment in installments) {
        // Skip paid installments
        if (installment['isPaid'] == true) continue;
        
        // Check if installment has a due date
        final dueDate = installment['dueDate'] as DateTime?;
        if (dueDate == null) continue;
        
        // Skip if this specific installment notification was deleted
        final installmentNumber = installment['installmentNumber'] as int? ?? 0;
        if (_deletedNotificationIds.contains('loan_${loanId}_$installmentNumber')) continue;
        
        // Calculate days until due
        final daysUntilDue = dueDate.difference(DateTime.now()).inDays;
        
        // Create notification for installment due within 5 days or overdue
        if (daysUntilDue <= 5) {
          String title;
          String message;
          
          if (daysUntilDue < 0) {
            // Overdue
            title = 'Loan Payment Overdue';
            message = '${loan['loanName']} payment of ${installment['totalAmount']} is overdue by ${-daysUntilDue} days';
          } else if (daysUntilDue == 0) {
            // Due today
            title = 'Loan Payment Due Today';
            message = '${loan['loanName']} payment of ${installment['totalAmount']} is due today';
          } else {
            // Due soon
            title = 'Loan Payment Due Soon';
            message = '${loan['loanName']} payment of ${installment['totalAmount']} is due in $daysUntilDue days';
          }
          
          // Create notification
          final notification = AppNotification(
            id: 'loan_${loan['id']}_${installment['installmentNumber']}',
            type: 'loan',
            title: title,
            message: message,
            timestamp: DateTime.now(),
            data: {
              'loanId': loan['id'],
              'installmentNumber': installment['installmentNumber'],
              'dueDate': dueDate.toIso8601String(),
              'amount': installment['totalAmount'],
            },
          );
          
          // Add notification to list (automatically handles duplicates)
          _notifications.removeWhere((n) => n.id == notification.id);
          _notifications.add(notification);
        }
      }
    }
  }

  // Generate card notifications
  void _generateCardNotifications(CardProvider cardProvider) {
    for (final card in cardProvider.cards) {
      // Skip if this card's notifications have been deleted
      final cardId = card['id'] as String;
      if (_deletedNotificationIds.contains('card_$cardId')) continue;
      
      // Check if card has payment due date
      final dueDate = card['paymentDate'] as DateTime?;
      if (dueDate == null) continue;
      
      // Calculate days until due
      final daysUntilDue = dueDate.difference(DateTime.now()).inDays;
      
      // Create notification for card payment due within 5 days or overdue
      if (daysUntilDue <= 5) {
        String title;
        String message;
        
        if (daysUntilDue < 0) {
          // Overdue
          title = 'Card Payment Overdue';
          message = '${card['cardName']} payment is overdue by ${-daysUntilDue} days';
        } else if (daysUntilDue == 0) {
          // Due today
          title = 'Card Payment Due Today';
          message = '${card['cardName']} payment is due today';
        } else {
          // Due soon
          title = 'Card Payment Due Soon';
          message = '${card['cardName']} payment is due in $daysUntilDue days';
        }
        
        // Create notification
        final notification = AppNotification(
          id: 'card_${card['id']}_${dueDate.month}_${dueDate.year}',
          type: 'card',
          title: title,
          message: message,
          timestamp: DateTime.now(),
          data: {
            'cardId': card['id'],
            'dueDate': dueDate.toIso8601String(),
          },
        );
        
        // Add notification to list (automatically handles duplicates)
        _notifications.removeWhere((n) => n.id == notification.id);
        _notifications.add(notification);
      }
    }
  }

  // Generate contact notifications
  void _generateContactNotifications(TransactionProvider transactionProvider) {
    // Get contacts with balances
    for (final contact in transactionProvider.contacts) {
      final contactId = contact['phone'] as String;
      
      // Skip if this contact notification was previously deleted
      if (_deletedNotificationIds.contains('contact_$contactId')) {
        continue;
      }
      
      // Calculate balance
      final balance = transactionProvider.calculateBalance(contactId);
      
      // Skip contacts with zero balance
      if (balance == 0) continue;
      
      // Create notification
      final isPositive = balance > 0;
      
      // Create a unique ID that's consistent for this contact
      final notificationId = 'contact_$contactId';
      
      // Format the balance amount properly with commas
      final formattedAmount = NumberFormat.currency(
        symbol: '',
        locale: 'en_IN',
        decimalDigits: 1
      ).format(balance.abs());
      
      final notification = AppNotification(
        id: notificationId,
        type: 'contact',
        title: isPositive ? 'Payment to Collect' : 'Payment to Make',
        message: isPositive 
          ? 'You need to collect $formattedAmount from ${contact['name']}'
          : 'You need to pay $formattedAmount to ${contact['name']}',
        timestamp: DateTime.now(),
        data: {
          'contactId': contactId,
          'contactName': contact['name'],
          'amount': balance.abs(),
          // Add due date as today to ensure it appears in today's list
          'dueDate': DateTime.now().toIso8601String(),
        },
      );
      
      // Add notification to list (automatically handles duplicates)
      _notifications.removeWhere((n) => n.id == notification.id);
      _notifications.add(notification);
    }
  }

  // Generate bill notifications
  void _generateBillNotifications(BillNoteProvider billNoteProvider) {
    for (final bill in billNoteProvider.notes) {
      // Skip if this bill's notifications have been deleted
      if (_deletedNotificationIds.contains('bill_${bill.id}')) continue;
      
      // Check if bill has reminder date (equivalent to due date)
      final dueDate = bill.reminderDate;
      if (dueDate == null) continue;
      
      // Skip completed bills (equivalent to paid)
      if (bill.isCompleted) continue;
      
      // Calculate days until due
      final daysUntilDue = dueDate.difference(DateTime.now()).inDays;
      
      // Create notification for bill due within 5 days or overdue
      if (daysUntilDue <= 5) {
        String title;
        String message;
        
        // Format amount with proper formatting
        final formattedAmount = bill.amount != null 
            ? NumberFormat.currency(symbol: '₹', locale: 'en_IN', decimalDigits: 0).format(bill.amount)
            : '';
        
        if (daysUntilDue < 0) {
          // Overdue
          title = 'Bill Payment Overdue';
          message = '${bill.title} payment${formattedAmount.isNotEmpty ? ' of $formattedAmount' : ''} is overdue by ${-daysUntilDue} days';
        } else if (daysUntilDue == 0) {
          // Due today
          title = 'Bill Payment Due Today';
          message = '${bill.title} payment${formattedAmount.isNotEmpty ? ' of $formattedAmount' : ''} is due today';
        } else {
          // Due soon
          title = 'Bill Payment Due Soon';
          message = '${bill.title} payment${formattedAmount.isNotEmpty ? ' of $formattedAmount' : ''} is due in $daysUntilDue days';
        }
        
        // Create notification
        final notification = AppNotification(
          id: 'bill_${bill.id}',
          type: 'bill',
          title: title,
          message: message,
          timestamp: DateTime.now(),
          data: {
            'billId': bill.id,
            'dueDate': dueDate.toIso8601String(),
            'amount': bill.amount,
          },
        );
        
        // Add notification to list (automatically handles duplicates)
        _notifications.removeWhere((n) => n.id == notification.id);
        _notifications.add(notification);
      }
    }
  }
} 