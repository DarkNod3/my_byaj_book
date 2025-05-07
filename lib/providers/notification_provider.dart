import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import 'loan_provider.dart';
import 'card_provider.dart';
import 'transaction_provider.dart';
import 'package:uuid/uuid.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService;
  List<AppNotification> _notifications = [];
  final Uuid _uuid = const Uuid();
  bool _isNotificationsEnabled = true;
  bool _isSoundEnabled = true;
  String _defaultSound = 'alert_sound.mp3'; // Default sound file
  
  // Constructor
  NotificationProvider(this._notificationService);
  
  // Getters
  List<AppNotification> get notifications => _notifications;
  bool get isNotificationsEnabled => _isNotificationsEnabled;
  bool get isSoundEnabled => _isSoundEnabled;
  String get defaultSound => _defaultSound;
  
  // Getters for notification counts
  int get totalNotificationCount => _notifications.length;
  int get unreadNotificationCount => _notifications.where((n) => !n.isRead).length;
  int get upcomingDueDatesCount => _notifications.where((n) => 
      !n.isRead && n.daysLeft >= 0 && n.daysLeft <= 5).length;
      
  // Initialize notification provider
  Future<void> init() async {
    await _loadPreferences();
    await _loadNotifications();
    notifyListeners();
  }
  
  // Update notifications from all sources
  Future<void> refreshNotifications(
    LoanProvider loanProvider, 
    CardProvider cardProvider, 
    TransactionProvider transactionProvider
  ) async {
    await _collectAllDueDates(loanProvider, cardProvider, transactionProvider);
    notifyListeners();
    
    // Schedule push notifications if enabled
    if (_isNotificationsEnabled) {
      await _notificationService.scheduleNotifications(
        _notifications.where((n) => !n.isRead).toList(),
        isSoundEnabled: _isSoundEnabled,
        defaultSoundPath: _defaultSound,
      );
    }
  }
  
  // Collect all due dates from various sources
  Future<void> _collectAllDueDates(
    LoanProvider loanProvider, 
    CardProvider cardProvider, 
    TransactionProvider transactionProvider
  ) async {
    // Keep track of existing notification IDs to avoid duplicates
    final existingIds = _notifications.map((n) => n.sourceId).toSet();
    final newNotifications = <AppNotification>[];
    
    // 1. Collect loan payment due dates
    final activeLoans = loanProvider.activeLoans
        .where((loan) => loan['status'] != 'Inactive')
        .toList();
        
    for (final loan in activeLoans) {
      final loanId = loan['id'] as String;
      
      // Skip if we already have a notification for this loan
      if (existingIds.contains(loanId)) continue;
      
      final loanName = loan['loanName'] as String;
      final installments = loan['installments'] as List<dynamic>?;
      
      if (installments != null && installments.isNotEmpty) {
        // Find the next unpaid installment
        for (var installment in installments) {
          if (installment['isPaid'] != true) {
            final dueDate = installment['dueDate'] as DateTime;
            final installmentNumber = installment['installmentNumber'] as int;
            final amount = installment['amount'] as double? ?? 0.0;
            
            newNotifications.add(AppNotification(
              id: _uuid.v4(),
              title: 'Loan Payment Due',
              message: '$loanName - Installment #$installmentNumber is due on ${_formatDate(dueDate)}',
              source: 'loan',
              sourceId: loanId,
              dueDate: dueDate,
              amount: amount,
              hasSound: _isSoundEnabled,
              soundPath: _defaultSound,
            ));
            break; // Only add the next unpaid installment
          }
        }
      }
    }
    
    // 2. Collect credit card payment due dates
    final cards = cardProvider.cards;
    for (int i = 0; i < cards.length; i++) {
      final card = cards[i];
      final cardId = 'card_$i';
      
      // Skip if we already have a notification for this card
      if (existingIds.contains(cardId)) continue;
      
      // Check if the card has a due date
      if (card['dueDate'] != null && card['dueDate'] != 'N/A') {
        try {
          final String dueDateStr = card['dueDate'] as String;
          final parts = dueDateStr.split(' ');
          
          if (parts.length >= 3) {
            final int day = int.tryParse(parts[0]) ?? 1;
            final String monthName = parts[1].replaceAll(',', '');
            
            // Get month number
            final List<String> monthNames = [
              'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
            ];
            final int month = monthNames.indexOf(monthName) + 1;
            
            // Create date for current month's due date
            final now = DateTime.now();
            DateTime dueDate = DateTime(now.year, now.month, day);
            
            // If the day has already passed, use next month
            if (dueDate.isBefore(now)) {
              dueDate = DateTime(now.year, now.month + 1, day);
            }
            
            // Get balance amount
            final String balanceStr = card['balance'].toString().replaceAll('₹', '').replaceAll(',', '').trim();
            final double amount = double.tryParse(balanceStr) ?? 0.0;
            
            if (amount > 0) {
              newNotifications.add(AppNotification(
                id: _uuid.v4(),
                title: 'Card Payment Due',
                message: '${card['bank']} card payment of ₹${amount.toStringAsFixed(0)} is due on ${_formatDate(dueDate)}',
                source: 'card',
                sourceId: cardId,
                dueDate: dueDate,
                amount: amount,
                hasSound: _isSoundEnabled,
                soundPath: _defaultSound,
              ));
            }
          }
        } catch (e) {
          // Removed debug print
        }
      }
    }
    
    // 3. Collect contact payment reminders
    final upcomingPayments = transactionProvider.getUpcomingPayments();
    for (final payment in upcomingPayments) {
      final type = payment['type'] as String;
      final sourceId = type == 'contact_payment' 
          ? (payment['contactId'] as String)
          : payment['title'] as String;
          
      // Skip if we already have a notification for this payment
      if (existingIds.contains(sourceId)) continue;
      
      final dueDate = payment['dueDate'] as DateTime;
      final amount = payment['amount'] as double;
      
      newNotifications.add(AppNotification(
        id: _uuid.v4(),
        title: payment['title'] as String,
        message: 'Payment of ₹${amount.toStringAsFixed(0)} is due on ${_formatDate(dueDate)}',
        source: type,
        sourceId: sourceId,
        dueDate: dueDate,
        amount: amount,
        hasSound: _isSoundEnabled,
        soundPath: _defaultSound,
      ));
    }
    
    // 4. Add custom/manual reminders from transaction provider
    final manualReminders = transactionProvider.manualReminders;
    for (final reminder in manualReminders) {
      // Skip completed reminders
      if (reminder['isCompleted'] == true) continue;
      
      // Skip if we already have a notification for this reminder
      final reminderId = reminder['id'] as String? ?? 'reminder_${reminder.hashCode}';
      if (existingIds.contains(reminderId)) continue;
      
      final dueDate = reminder['dueDate'] as DateTime;
      final amount = reminder['amount'] as double? ?? 0.0;
      
      newNotifications.add(AppNotification(
        id: _uuid.v4(),
        title: reminder['title'] as String,
        message: 'Reminder for ${reminder['title']} on ${_formatDate(dueDate)}',
        source: 'manual',
        sourceId: reminderId,
        dueDate: dueDate,
        amount: amount,
        hasSound: reminder['hasSound'] as bool? ?? _isSoundEnabled,
        soundPath: reminder['soundPath'] as String? ?? _defaultSound,
      ));
    }
    
    // Combine existing notifications with new ones
    _notifications = [..._notifications, ...newNotifications]
      // Sort by due date (closest first)
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      
    // Save to shared preferences
    await _saveNotifications();
  }
  
  // Mark a notification as read
  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index >= 0) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
      await _saveNotifications();
    }
  }
  
  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
    await _saveNotifications();
  }
  
  // Clear a notification
  Future<void> removeNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
    await _saveNotifications();
  }
  
  // Set notification sound preference
  Future<void> setSoundEnabled(bool enabled) async {
    _isSoundEnabled = enabled;
    notifyListeners();
    await _savePreferences();
  }
  
  // Set notification enabled preference
  Future<void> setNotificationsEnabled(bool enabled) async {
    _isNotificationsEnabled = enabled;
    notifyListeners();
    await _savePreferences();
    
    // If disabled, cancel all notifications
    if (!enabled) {
      await _notificationService.cancelAllNotifications();
    } else {
      // If enabled, reschedule all notifications
      await _notificationService.scheduleNotifications(
        _notifications.where((n) => !n.isRead).toList(),
        isSoundEnabled: _isSoundEnabled,
        defaultSoundPath: _defaultSound,
      );
    }
  }
  
  // Set default notification sound
  Future<void> setDefaultSound(String soundPath) async {
    _defaultSound = soundPath;
    notifyListeners();
    await _savePreferences();
  }
  
  // Add a custom reminder with alarm
  Future<void> addCustomReminder({
    required String title,
    required String message,
    required DateTime dueDate,
    double amount = 0.0,
    bool hasSound = true,
    String? customSound,
  }) async {
    final notification = AppNotification(
      id: _uuid.v4(),
      title: title,
      message: message,
      source: 'custom',
      sourceId: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      dueDate: dueDate,
      amount: amount,
      hasSound: hasSound,
      soundPath: customSound ?? _defaultSound,
    );
    
    _notifications.add(notification);
    _notifications.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    
    notifyListeners();
    await _saveNotifications();
    
    // Schedule the notification if enabled
    if (_isNotificationsEnabled) {
      await _notificationService.scheduleNotification(
        notification,
        isSoundEnabled: hasSound,
        soundPath: customSound ?? _defaultSound,
      );
    }
  }
  
  // Helper method to format date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return 'Tomorrow';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }
  
  // Load notifications from SharedPreferences
  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList('notifications') ?? [];
      
      _notifications = notificationsJson
          .map((json) => AppNotification.fromJson(json))
          .toList();
      
      // Sort by due date
      _notifications.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    } catch (e) {
      // Removed debug print
    }
  }
  
  // Save notifications to SharedPreferences
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = _notifications.map((n) => n.toJson()).toList();
      await prefs.setStringList('notifications', notificationsJson);
    } catch (e) {
      // Removed debug print
    }
  }
  
  // Load preferences from SharedPreferences
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isNotificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _isSoundEnabled = prefs.getBool('notification_sound_enabled') ?? true;
      _defaultSound = prefs.getString('notification_default_sound') ?? 'alert_sound.mp3';
    } catch (e) {
      // Removed debug print
    }
  }
  
  // Save preferences to SharedPreferences
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', _isNotificationsEnabled);
      await prefs.setBool('notification_sound_enabled', _isSoundEnabled);
      await prefs.setString('notification_default_sound', _defaultSound);
    } catch (e) {
      // Removed debug print
    }
  }
} 