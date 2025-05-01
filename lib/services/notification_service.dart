import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../providers/loan_provider.dart';
import '../models/loan_notification.dart';
import '../main.dart' show markLoanAsPaid;

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
  }
  
  void _onNotificationTapped(NotificationResponse response) {
    // Parse the payload which contains loan ID
    if (response.payload != null) {
      try {
        final notificationData = LoanNotification.fromJson(response.payload!);
        
        // Handle the notification tap
        if (notificationData.action == 'mark_as_paid') {
          _markLoanAsPaid(notificationData.loanId);
        }
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
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
  
  Future<void> showLoanDueNotification({
    required int id,
    required String loanId,
    required String loanName,
    required double amount,
    required DateTime dueDate,
    required int installmentNumber,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'loan_payment_channel',
      'Loan Payment Notifications',
      channelDescription: 'Notifications for loan payment dues',
      importance: Importance.high,
      priority: Priority.high,
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
    
    // Store the notification ID for later cancellation
    _loanNotificationIds[loanId] = id;
    
    await _flutterLocalNotificationsPlugin.show(
      id,
      'Payment Due: $loanName',
      'Installment #$installmentNumber for ₹${amount.toStringAsFixed(2)} is due on $formattedDueDate. Tap to view details.',
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
} 