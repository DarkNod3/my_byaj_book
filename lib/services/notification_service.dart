import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../providers/loan_provider.dart';
import '../models/loan_notification.dart';
import '../main.dart' show markLoanAsPaid;

// Import UILocalNotificationDateInterpretation
import 'package:flutter_local_notifications/src/flutter_local_notifications_plugin.dart'
    show UILocalNotificationDateInterpretation;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  // Map to track notification IDs by loan ID
  final Map<String, int> _loanNotificationIds = {};
  
  NotificationService._internal();
  
  Future<void> init() async {
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
    
    // Request notification permissions
    await _requestPermissions();
  }
  
  Future<void> _requestPermissions() async {
    // For iOS
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    
    // For Android 13+, don't call requestPermission as it depends on version
    // Permissions will be requested when notifications are displayed
  }
  
  void _onNotificationTapped(NotificationResponse response) {
    // Parse the payload which contains loan ID
    if (response.payload != null) {
      try {
        final notificationData = LoanNotification.fromJson(response.payload!);
        
        // If the action is "mark_as_paid", handle it
        if (notificationData.action == 'mark_as_paid') {
          _markLoanAsPaid(notificationData.loanId);
        }
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
      
      // Navigate to the loan details screen (this would be handled in the app)
      // This would be handled by the main app listening to notification opens
    }
  }
  
  Future<void> _markLoanAsPaid(String loanId) async {
    // Use the global function defined in main.dart
    // This will be implemented by main.dart to access LoanProvider
    markLoanAsPaid(loanId);
  }
  
  Future<void> scheduleLoanPaymentNotifications(LoanProvider loanProvider) async {
    // Cancel all existing notifications first
    await cancelAllNotifications();
    
    final activeLoans = loanProvider.activeLoans;
    
    for (final loan in activeLoans) {
      final loanId = loan['id'] as String;
      final loanName = loan['loanName'] as String;
      final paymentAmount = _calculateMonthlyEMI(loan);
      
      // Calculate the next payment date based on firstPaymentDate
      final firstPaymentDate = loan['firstPaymentDate'] as DateTime;
      final nextPaymentDate = _calculateNextPaymentDate(firstPaymentDate);
      
      // Only schedule notifications for future dates
      if (nextPaymentDate.isAfter(DateTime.now())) {
        // Generate a unique notification ID for this loan
        final notificationId = _generateNotificationId(loanId);
        _loanNotificationIds[loanId] = notificationId;
        
        // Show immediate notification for demonstration purposes
        await showLoanDueNotification(
          id: notificationId,
          loanId: loanId,
          loanName: loanName, 
          amount: paymentAmount,
          dueDate: nextPaymentDate,
        );
      }
    }
  }
  
  Future<void> showLoanDueNotification({
    required int id,
    required String loanId,
    required String loanName,
    required double amount,
    required DateTime dueDate,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'loan_payment_channel',
      'Loan Payment Notifications',
      channelDescription: 'Notifications for loan payment dues',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
    );
    
    final iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );
    
    final formattedDueDate = '${dueDate.day}/${dueDate.month}/${dueDate.year}';
    final payload = LoanNotification(
      loanId: loanId,
      action: 'view_details',
    ).toJson();
    
    await _flutterLocalNotificationsPlugin.show(
      id,
      'Payment Due: $loanName',
      '₹${amount.toStringAsFixed(2)} payment is due on $formattedDueDate.',
      notificationDetails,
      payload: payload,
    );
  }
  
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    _loanNotificationIds.clear();
  }
  
  Future<void> cancelNotificationForLoan(String loanId) async {
    final notificationId = _loanNotificationIds[loanId];
    if (notificationId != null) {
      await _flutterLocalNotificationsPlugin.cancel(notificationId);
      await _flutterLocalNotificationsPlugin.cancel(notificationId + 1000); // Cancel reminder too
      _loanNotificationIds.remove(loanId);
    }
  }
  
  int _generateNotificationId(String loanId) {
    // Use a simple hash of the loan ID to generate a notification ID
    return loanId.hashCode.abs() % 10000;
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
  
  DateTime _calculateNextPaymentDate(DateTime firstPaymentDate) {
    final now = DateTime.now();
    
    // If the first payment date is in the future, return it
    if (firstPaymentDate.isAfter(now)) {
      return firstPaymentDate;
    }
    
    // Calculate how many months have passed since the first payment
    int monthsPassed = (now.year - firstPaymentDate.year) * 12 + 
                       (now.month - firstPaymentDate.month);
    
    // Calculate the next payment date by adding months to the first payment date
    return DateTime(
      firstPaymentDate.year,
      firstPaymentDate.month + monthsPassed + 1,
      firstPaymentDate.day,
    );
  }
} 