import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:firebase_messaging/firebase_messaging.dart';
import '../providers/loan_provider.dart';
import '../providers/card_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/loan_notification.dart';
import '../models/card_notification.dart';
import '../models/app_notification.dart';
import '../screens/reminder/reminder_screen.dart';
import '../main.dart' show markLoanAsPaid, navigatorKey;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  // Map to track notification IDs by loan ID
  final Map<String, int> _loanNotificationIds = {};
  // Map to track notification IDs by card ID
  final Map<String, int> _cardNotificationIds = {};
  // Map to track notification IDs by reminder ID
  final Map<String, int> _reminderNotificationIds = {};
  
  NotificationService._internal();
  
  Future<void> init() async {
    // Initialize timezone
    tz_data.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Setup FCM message handlers
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  // Handle FCM messages that arrive when the app is in the foreground
  void _handleForegroundMessage(RemoteMessage message) {
    // Show local notification
    _showLocalNotificationFromFCM(message);
  }

  // Handle messages received in the background
  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    // You could store the message data for later use when app is opened
    // Or immediately show a notification using the local notifications plugin
    
    if (message.notification != null) {
      await _showLocalNotificationFromFCM(message);
    }
  }
  
  Future<void> _showLocalNotificationFromFCM(RemoteMessage message) async {
    // Extract message data
    final notification = message.notification;
    final data = message.data;
    final notificationId = (message.messageId?.hashCode ?? Random().nextInt(1000)) & 0x3FFFFFFF;
    
    if (notification != null) {
      // Create android notification details
      const androidNotificationDetails = AndroidNotificationDetails(
        'push_notification_channel',
        'Push Notifications',
        channelDescription: 'Channel for push notifications',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        visibility: NotificationVisibility.public,
      );
      
      // Create iOS notification details
      const iosNotificationDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      // Create platform-specific notification details
      const platformChannelSpecifics = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );
      
      // Prepare payload based on notification type
      String? payload;
      if (data.containsKey('type')) {
        final type = data['type'];
        
        if (type == 'loan') {
          // Create loan notification payload
          final loanNotification = {
            'loanId': data['loanId'] ?? '',
            'action': data['action'] ?? 'view_details',
          };
          payload = jsonEncode(loanNotification);
        } else if (type == 'card') {
          // Create card notification payload
          final cardNotification = {
            'cardId': data['cardId'] ?? '',
            'action': data['action'] ?? 'view_details',
          };
          payload = jsonEncode(cardNotification);
        } else if (type == 'reminder') {
          // Create reminder notification payload
          final reminderNotification = {
            'reminderId': data['reminderId'] ?? '',
            'action': data['action'] ?? 'view_details',
          };
          payload = jsonEncode(reminderNotification);
        }
      } else {
        // Default payload with the raw data
        payload = jsonEncode(data);
      }
      
      // Show the notification
      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        notification.title,
        notification.body,
        platformChannelSpecifics,
        payload: payload,
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Parse the payload to determine if it's a loan, card, or reminder notification
    if (response.payload != null) {
      try {
        final Map<String, dynamic> payloadData = jsonDecode(response.payload!);
        
        // Check if it's a card notification
        if (payloadData.containsKey('cardId')) {
          final notificationData = CardNotification.fromJson(response.payload!);
          
          // Handle the card notification tap
          if (notificationData.action == 'view_details') {
            // Navigate to card details
            // This would be implemented in main.dart similar to the loan handling
          }
        } 
        // Check if it's a reminder notification
        else if (payloadData.containsKey('reminderId')) {
          // Navigate to reminder screen
          final context = navigatorKey.currentContext;
          if (context != null) {
            Navigator.of(context).pushNamed(ReminderScreen.routeName);
          }
        }
        // Otherwise assume it's a loan notification
        else if (payloadData.containsKey('loanId')) {
          final notificationData = LoanNotification.fromJson(response.payload!);
          
          // Handle the notification tap
          if (notificationData.action == 'mark_as_paid') {
            _markLoanAsPaid(notificationData.loanId);
          }
        }
      } catch (e) {
        // Error parsing notification payload - silent in release
      }
    }
  }
  
  Future<void> _markLoanAsPaid(String loanId) async {
    markLoanAsPaid(loanId);
  }
  
  Future<void> scheduleLoanPaymentNotifications(LoanProvider loanProvider) async {
    // Cancel all existing notifications first
    await cancelAllNotifications();
    
    final activeLoans = loanProvider.activeLoans.where((loan) => loan['status'] != 'Inactive').toList();
    
    for (final loan in activeLoans) {
      final loanId = loan['id'] as String;
      final loanName = loan['loanName'] as String;
      final paymentAmount = _calculateMonthlyEMI(loan);
      
      // Get installments if available
      final installments = loan['installments'] as List<dynamic>?;
      
      if (installments != null && installments.isNotEmpty) {
        // Find the next unpaid installment
        for (var installment in installments) {
          if (installment['isPaid'] != true) {
            final dueDate = installment['dueDate'] as DateTime;
            final installmentNumber = installment['installmentNumber'] as int;
            
            if (dueDate.isAfter(DateTime.now())) {
              // Show notification for upcoming payment
              await showLoanDueNotification(
                id: _generateNotificationId(loanId),
                loanId: loanId,
                loanName: loanName,
                amount: paymentAmount,
                dueDate: dueDate,
                installmentNumber: installmentNumber,
              );
              break; // Only show for the next unpaid installment
            }
          }
        }
      } else {
        // If no installments, use the first payment date
        final firstPaymentDate = loan['firstPaymentDate'] as DateTime;
        if (firstPaymentDate.isAfter(DateTime.now())) {
          await showLoanDueNotification(
            id: _generateNotificationId(loanId),
            loanId: loanId,
            loanName: loanName,
            amount: paymentAmount,
            dueDate: firstPaymentDate,
            installmentNumber: 1,
          );
        }
      }
    }
  }
  
  // Schedule notifications for card due dates
  Future<void> scheduleCardDueNotifications(CardProvider cardProvider) async {
    // Cancel all existing card notifications first
    await cancelCardNotifications();
    
    final cards = cardProvider.cards;
    
    for (int i = 0; i < cards.length; i++) {
      final card = cards[i];
      final cardId = 'card_$i'; // Create a unique ID based on index
      final bankName = card['bank'] as String;
      
      // Check if the card has a due date
      if (card['dueDate'] != null && card['dueDate'] != 'N/A') {
        // Parse the due date
        try {
          final String dueDateStr = card['dueDate'] as String;
          final parts = dueDateStr.split(' ');
          
          if (parts.length >= 3) {
            final int day = int.tryParse(parts[0]) ?? 1;
            final String monthName = parts[1];
            final int month = _getMonthNumber(monthName);
            final int year = int.tryParse(parts[2].replaceAll(',', '')) ?? DateTime.now().year;
            
            // Create date for this month's due date
            final now = DateTime.now();
            DateTime dueDate = DateTime(now.year, now.month, day);
            
            // If the day has already passed this month, use next month
            if (dueDate.isBefore(now)) {
              dueDate = DateTime(now.year, now.month + 1, day);
            }
            
            // Extract balance as amount due
            final String balanceStr = card['balance'].toString().replaceAll('₹', '').replaceAll(',', '').trim();
            final double amountDue = double.tryParse(balanceStr) ?? 0.0;
            
            // Show notification for upcoming due date
            if (amountDue > 0) {
              await showCardDueNotification(
                id: _generateCardNotificationId(cardId),
                cardId: cardId,
                cardIndex: i,
                bankName: bankName,
                amount: amountDue,
                dueDate: dueDate,
              );
            }
          }
        } catch (e) {
          // Error scheduling card notification - silent in release
        }
      }
    }
  }
  
  // Schedule notifications for manual reminders
  Future<void> scheduleManualReminders(TransactionProvider transactionProvider) async {
    // Cancel existing manual reminder notifications
    await cancelManualReminderNotifications();
    
    final manualReminders = transactionProvider.manualReminders;
    
    for (final reminder in manualReminders) {
      // Skip completed reminders
      if (reminder['isCompleted'] == true) continue;
      
      final dueDate = reminder['dueDate'] as DateTime;
      // Skip past reminders
      if (dueDate.isBefore(DateTime.now())) continue;
      
      final reminderId = reminder['id'] as String? ?? 'reminder_${reminder.hashCode}';
      final title = reminder['title'] as String;
      final amount = reminder['amount'] as double? ?? 0.0;
      
      await scheduleTimeBasedReminder(
        id: _generateReminderNotificationId(reminderId),
        reminderId: reminderId,
        title: title,
        amount: amount,
        scheduledDate: dueDate,
      );
    }
  }
  
  int _getMonthNumber(String monthName) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    int index = monthNames.indexOf(monthName.replaceAll(',', ''));
    return index >= 0 ? index + 1 : 1;
  }
  
  Future<void> showLoanDueNotification({
    required int id,
    required String loanId,
    required String loanName,
    required double amount,
    required DateTime dueDate,
    required int installmentNumber,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'loan_payment_channel',
      'Loan Payment Notifications',
      channelDescription: 'Notifications for loan payment dues',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );
    
    final formattedDueDate = '${dueDate.day}/${dueDate.month}/${dueDate.year}';
    final payload = LoanNotification(
      loanId: loanId,
      action: 'view_details',
    ).toJson();
    
    // Store the notification ID for later cancellation
    _loanNotificationIds[loanId] = id;
    
    await _flutterLocalNotificationsPlugin.show(
      id,
      'Payment Due: $loanName',
      'Installment #$installmentNumber for ₹${amount.toStringAsFixed(2)} is due on $formattedDueDate. Tap to view details.',
      notificationDetails,
      payload: payload,
    );
    
    // Also schedule a time-based notification for the actual due date
    await _scheduleTimedNotification(
      id: id + 1000, // Use a different ID for the scheduled notification
      title: 'Payment Due: $loanName',
      body: 'Installment #$installmentNumber for ₹${amount.toStringAsFixed(2)} is due today. Tap to view details.',
      scheduledDate: dueDate,
      payload: payload,
    );
  }
  
  // Show notification for card due date
  Future<void> showCardDueNotification({
    required int id,
    required String cardId,
    required int cardIndex,
    required String bankName,
    required double amount,
    required DateTime dueDate,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'card_payment_channel',
      'Card Payment Notifications',
      channelDescription: 'Notifications for credit card payment dues',
      importance: Importance.high,
      priority: Priority.high,
      color: Colors.orange,
    );
    
    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );
    
    final formattedDueDate = '${dueDate.day}/${dueDate.month}/${dueDate.year}';
    
    // Create payload with card info
    final payload = CardNotification(
      cardId: cardId,
      action: 'view_details',
    ).toJson();
    
    // Store the notification ID for later cancellation
    _cardNotificationIds[cardId] = id;
    
    // Calculate days remaining
    final int daysRemaining = dueDate.difference(DateTime.now()).inDays;
    String daysText = daysRemaining == 0 
        ? 'TODAY!' 
        : daysRemaining == 1 
            ? 'TOMORROW!' 
            : 'in $daysRemaining days';
    
    await _flutterLocalNotificationsPlugin.show(
      id,
      'Credit Card Payment Due: $bankName',
      'Payment of ₹${amount.toStringAsFixed(0)} is due $daysText (${dueDate.day} ${_getMonthName(dueDate.month)}). Tap to view details.',
      notificationDetails,
      payload: payload,
    );
    
    // Also schedule a time-based notification for the actual due date
    await _scheduleTimedNotification(
      id: id + 2000, // Use a different ID for the scheduled notification
      title: 'Credit Card Payment Due: $bankName',
      body: 'Payment of ₹${amount.toStringAsFixed(0)} is due TODAY. Tap to view details.',
      scheduledDate: dueDate,
      payload: payload,
    );
  }
  
  // Schedule a time-based manual reminder
  Future<void> scheduleTimeBasedReminder({
    required int id,
    required String reminderId,
    required String title,
    required double amount,
    required DateTime scheduledDate,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'manual_reminder_channel',
      'Manual Reminder Notifications',
      channelDescription: 'Notifications for manually set reminders',
      importance: Importance.high,
      priority: Priority.high,
      color: Colors.purple,
    );
    
    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );
    
    final payload = jsonEncode({
      'reminderId': reminderId,
      'action': 'view_details',
    });
    
    // Store the notification ID for later cancellation
    _reminderNotificationIds[reminderId] = id;
    
    // Calculate days remaining
    final int daysRemaining = scheduledDate.difference(DateTime.now()).inDays;
    
    // Show immediate notification if due date is within 7 days
    if (daysRemaining <= 7) {
      String daysText = daysRemaining == 0 
          ? 'TODAY!' 
          : daysRemaining == 1 
              ? 'TOMORROW!' 
              : 'in $daysRemaining days';
      
      await _flutterLocalNotificationsPlugin.show(
        id,
        'Reminder: $title',
        'Your reminder for ₹${amount.toStringAsFixed(0)} is due $daysText (${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year})',
        notificationDetails,
        payload: payload,
      );
    }
    
    // Schedule a time-based notification for the actual due date at 9 AM
    await _scheduleTimedNotification(
      id: id + 3000, // Use a different ID for the scheduled notification
      title: 'Reminder: $title',
      body: 'Your reminder for ₹${amount.toStringAsFixed(0)} is due TODAY',
      scheduledDate: DateTime(
        scheduledDate.year, 
        scheduledDate.month, 
        scheduledDate.day, 
        9, 0, 0 // 9:00 AM
      ),
      payload: payload,
    );
  }
  
  // Schedule a notification at a specific date and time
  Future<void> _scheduleTimedNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String payload,
  }) async {
    // Skip if the scheduled date is in the past
    if (scheduledDate.isBefore(DateTime.now())) {
      return;
    }
    
    const androidDetails = AndroidNotificationDetails(
      'scheduled_notification_channel',
      'Scheduled Notifications',
      channelDescription: 'Notifications scheduled for a specific time',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );
    
    // Convert to TZ format
    final scheduledDateTZ = tz.TZDateTime.from(scheduledDate, tz.local);
    
    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDateTZ,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } catch (e) {
      // Error scheduling notification - silent in release
    }
  }
  
  String _getMonthName(int month) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    if (month >= 1 && month <= 12) {
      return monthNames[month - 1];
    }
    return '';
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    _loanNotificationIds.clear();
    _cardNotificationIds.clear();
    _reminderNotificationIds.clear();
  }
  
  Future<void> cancelCardNotifications() async {
    // Cancel all card notifications
    for (final id in _cardNotificationIds.values) {
      await _flutterLocalNotificationsPlugin.cancel(id);
      await _flutterLocalNotificationsPlugin.cancel(id + 2000); // Cancel scheduled notification too
    }
    _cardNotificationIds.clear();
  }
  
  Future<void> cancelManualReminderNotifications() async {
    // Cancel all manual reminder notifications
    for (final id in _reminderNotificationIds.values) {
      await _flutterLocalNotificationsPlugin.cancel(id);
      await _flutterLocalNotificationsPlugin.cancel(id + 3000); // Cancel scheduled notification too
    }
    _reminderNotificationIds.clear();
  }
  
  Future<void> cancelNotificationForLoan(String loanId) async {
    final notificationId = _loanNotificationIds[loanId];
    if (notificationId != null) {
      await _flutterLocalNotificationsPlugin.cancel(notificationId);
      await _flutterLocalNotificationsPlugin.cancel(notificationId + 1000); // Cancel scheduled notification too
      _loanNotificationIds.remove(loanId);
    }
  }
  
  Future<void> cancelNotificationForCard(String cardId) async {
    final notificationId = _cardNotificationIds[cardId];
    if (notificationId != null) {
      await _flutterLocalNotificationsPlugin.cancel(notificationId);
      await _flutterLocalNotificationsPlugin.cancel(notificationId + 2000); // Cancel scheduled notification too
      _cardNotificationIds.remove(cardId);
    }
  }
  
  Future<void> cancelNotificationForReminder(String reminderId) async {
    final notificationId = _reminderNotificationIds[reminderId];
    if (notificationId != null) {
      await _flutterLocalNotificationsPlugin.cancel(notificationId);
      await _flutterLocalNotificationsPlugin.cancel(notificationId + 3000); // Cancel scheduled notification too
      _reminderNotificationIds.remove(reminderId);
    }
  }
  
  int _generateNotificationId(String loanId) {
    // Use a simple hash of the loan ID to generate a notification ID
    return loanId.hashCode.abs() % 10000;
  }
  
  int _generateCardNotificationId(String cardId) {
    // Use a simple hash of the card ID to generate a notification ID
    // Add 20000 to avoid conflicts with loan notification IDs
    return cardId.hashCode.abs() % 10000 + 20000;
  }
  
  int _generateReminderNotificationId(String reminderId) {
    // Use a simple hash of the reminder ID to generate a notification ID
    // Add 40000 to avoid conflicts with other notification IDs
    return reminderId.hashCode.abs() % 10000 + 40000;
  }
  
  double _calculateMonthlyEMI(Map<String, dynamic> loan) {
    final loanAmount = double.parse(loan['loanAmount'] ?? '0');
    final interestRate = double.parse(loan['interestRate'] ?? '0') / 100 / 12; // Monthly rate
    final loanTerm = int.parse(loan['loanTerm'] ?? '0');
    
    if (interestRate == 0 || loanTerm == 0) {
      return loanAmount / loanTerm; // Simple division for zero interest
    }
    
    // EMI = P * r * (1+r)^n / ((1+r)^n - 1)
    return loanAmount * interestRate * pow(1 + interestRate, loanTerm) / 
        (pow(1 + interestRate, loanTerm) - 1);
  }

  // Schedule notification
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    TimeOfDay? time,
    String? payload,
    bool isSoundEnabled = true,
    String? soundPath,
  }) async {
    // If time is provided, use it to set hours and minutes
    final DateTime notificationDateTime = time != null
        ? DateTime(
            scheduledDate.year,
            scheduledDate.month,
            scheduledDate.day,
            time.hour,
            time.minute,
          )
        : scheduledDate;
        
    // Configure notification details
    AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'loan_due_channel',
      'Loan Due Notifications',
      channelDescription: 'Notifications for loan payment due dates',
      importance: Importance.high,
      priority: Priority.high,
      sound: isSoundEnabled
          ? soundPath != null
              ? RawResourceAndroidNotificationSound(soundPath.split('.').first)
              : const RawResourceAndroidNotificationSound('notification_sound')
          : null,
      playSound: isSoundEnabled,
    );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    // Schedule notification
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(notificationDateTime, tz.local),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  // Alias for cancelAllNotifications for compatibility with NotificationProvider
  Future<void> cancelAll() async {
    await cancelAllNotifications();
  }
  
  // Schedule notifications from the notification provider
  Future<void> schedule(
    List<dynamic> notifications, {
    bool isSoundEnabled = true,
    String? defaultSoundPath,
  }) async {
    // Cancel all existing notifications first
    await cancelAllNotifications();
    
    // Schedule each notification
    for (final notification in notifications) {
      // Skip notifications that are due in the past
      if (notification.dueDate.isBefore(DateTime.now())) {
        continue;
      }
      
      // Generate a random ID for the notification
      final id = notification.hashCode & 0x3FFFFFFF;
      
      // Create payload with notification data
      final payload = notification.toJson();
      
      // Determine if sound should be played
      final useSound = isSoundEnabled && notification.hasSound;
      
      // Use notification's custom sound or default
      final soundPath = notification.soundPath.isNotEmpty 
          ? notification.soundPath 
          : defaultSoundPath;
      
      // Schedule the notification
      await _scheduleNotification(
        id: id,
        title: notification.title,
        body: notification.message,
        scheduledDate: notification.dueDate,
        payload: payload,
        isSoundEnabled: useSound,
        soundPath: soundPath,
      );
    }
  }
  
  // Schedule a single notification
  Future<void> scheduleOne(
    AppNotification notification, {
    bool isSoundEnabled = true,
    String? soundPath,
  }) async {
    await _scheduleTimedNotification(
      id: notification.id.hashCode,
      title: notification.title,
      body: notification.body,
      scheduledDate: notification.scheduledDate,
      payload: jsonEncode(notification.toJson()),
    );
  }
}