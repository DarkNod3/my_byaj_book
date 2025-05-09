import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/app_notification.dart';
import '../providers/loan_provider.dart';
import '../providers/card_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/bill_note_provider.dart';

class NotificationProvider with ChangeNotifier {
  static const String _notificationsKey = 'app_notifications';
  
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  final int _maxFcmNotifications = 100;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;

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
  
  // Count unread notifications
  int get unreadCount => unreadNotifications.length;

  // Constructor
  NotificationProvider() {
    _loadNotifications();
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
      
      // Sort by timestamp (newest first)
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      _notifications = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Save notifications to SharedPreferences
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = _notifications
          .map((notification) => jsonEncode(notification.toJson()))
          .toList();
      
      await prefs.setStringList(_notificationsKey, notificationsJson);
        } catch (e) {
      debugPrint('Error saving notifications: $e');
    }
  }

  // Add a new notification
  Future<void> addNotification(AppNotification notification) async {
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
      await _saveNotifications();
      notifyListeners();
    }
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
    _notifications.removeWhere((n) => n.id == id);
    await _saveNotifications();
    notifyListeners();
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
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

  // Generate notifications from loans, bills, cards, and contacts
  Future<void> generateDueNotifications({
    LoanProvider? loanProvider,
    CardProvider? cardProvider,
    TransactionProvider? transactionProvider,
    BillNoteProvider? billNoteProvider,
  }) async {
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
    notifyListeners();
  }

  // Generate loan notifications
  void _generateLoanNotifications(LoanProvider loanProvider) {
    for (final loan in loanProvider.activeLoans) {
      // Check if loan has upcoming or overdue installments
      final installments = loan['installments'] as List<dynamic>?;
      if (installments == null || installments.isEmpty) continue;
      
      for (final installment in installments) {
        // Skip paid installments
        if (installment['isPaid'] == true) continue;
        
        // Check if installment has a due date
        final dueDate = installment['dueDate'] as DateTime?;
        if (dueDate == null) continue;
        
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
      // Calculate balance
      final balance = transactionProvider.calculateBalance(contact['phone']);
      
      // Skip contacts with zero balance
      if (balance == 0) continue;
      
      // Create notification
      final isPositive = balance > 0;
      
      final notification = AppNotification(
        id: 'contact_${contact['phone']}',
        type: 'contact',
        title: isPositive ? 'Payment to Collect' : 'Payment to Make',
        message: isPositive 
          ? 'You need to collect ${balance.abs()} from ${contact['name']}'
          : 'You need to pay ${balance.abs()} to ${contact['name']}',
        timestamp: DateTime.now(),
        data: {
          'contactId': contact['phone'],
          'contactName': contact['name'],
          'amount': balance.abs(),
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
        
        if (daysUntilDue < 0) {
          // Overdue
          title = 'Bill Payment Overdue';
          message = '${bill.title} payment of ${bill.amount} is overdue by ${-daysUntilDue} days';
        } else if (daysUntilDue == 0) {
          // Due today
          title = 'Bill Payment Due Today';
          message = '${bill.title} payment of ${bill.amount} is due today';
        } else {
          // Due soon
          title = 'Bill Payment Due Soon';
          message = '${bill.title} payment of ${bill.amount} is due in $daysUntilDue days';
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