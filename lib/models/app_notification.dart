import 'dart:convert';

class AppNotification {
  final String id;           // Unique identifier for this notification
  final String title;        // Notification title
  final String body;         // Notification body
  final String message;      // Notification message
  final String source;       // Source of notification (loan, card, contact, etc.)
  final String sourceId;     // ID of the source entity (loanId, cardId, etc.) 
  final DateTime dueDate;    // Due date for the notification
  final DateTime scheduledDate;
  final double amount;       // Amount associated with the notification
  final bool isRead;         // Whether the notification has been read
  final bool hasSound;       // Whether this notification should play sound
  final String soundPath;    // Custom sound path (if any)
  final int daysLeft;
  
  AppNotification({
    required this.id,
    required this.title,
    this.body = '',
    this.message = '',
    required this.source,
    required this.sourceId,
    required this.dueDate,
    DateTime? scheduledDate,
    this.amount = 0.0,
    this.isRead = false,
    this.hasSound = true,
    this.soundPath = '',
    int? daysLeft,
  }) : 
    scheduledDate = scheduledDate ?? dueDate,
    daysLeft = daysLeft ?? _calculateDaysLeft(dueDate);
  
  static int _calculateDaysLeft(DateTime dueDate) {
    final now = DateTime.now();
    return dueDate.difference(now).inDays;
  }
  
  // Create a copy of the notification with updated fields
  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? message,
    String? source,
    String? sourceId,
    DateTime? dueDate,
    DateTime? scheduledDate,
    double? amount,
    bool? isRead,
    bool? hasSound,
    String? soundPath,
    int? daysLeft,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      message: message ?? this.message,
      source: source ?? this.source,
      sourceId: sourceId ?? this.sourceId,
      dueDate: dueDate ?? this.dueDate,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      amount: amount ?? this.amount,
      isRead: isRead ?? this.isRead,
      hasSound: hasSound ?? this.hasSound,
      soundPath: soundPath ?? this.soundPath,
      daysLeft: daysLeft ?? this.daysLeft,
    );
  }
  
  // Check if the due date is today
  bool get isDueToday => daysLeft == 0;
  
  // Check if the due date is tomorrow
  bool get isDueTomorrow => daysLeft == 1;
  
  // Check if the due date is overdue
  bool get isOverdue => daysLeft < 0;
  
  // Convert notification to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'message': message,
      'source': source,
      'sourceId': sourceId,
      'dueDate': dueDate.toIso8601String(),
      'scheduledDate': scheduledDate.toIso8601String(),
      'amount': amount,
      'isRead': isRead,
      'hasSound': hasSound,
      'soundPath': soundPath,
      'daysLeft': daysLeft,
    };
  }
  
  // Convert to JSON string
  String toJson() {
    return jsonEncode(toMap());
  }
  
  // Create from JSON string
  factory AppNotification.fromJson(String jsonString) {
    final Map<String, dynamic> data = jsonDecode(jsonString);
    return AppNotification(
      id: data['id'],
      title: data['title'],
      body: data['body'] ?? '',
      message: data['message'] ?? '',
      source: data['source'],
      sourceId: data['sourceId'],
      dueDate: DateTime.parse(data['dueDate']),
      scheduledDate: data['scheduledDate'] != null 
          ? DateTime.parse(data['scheduledDate']) 
          : null,
      amount: data['amount'] ?? 0.0,
      isRead: data['isRead'] ?? false,
      hasSound: data['hasSound'] ?? true,
      soundPath: data['soundPath'] ?? '',
      daysLeft: data['daysLeft'],
    );
  }
  
  @override
  String toString() {
    return 'AppNotification(id: $id, title: $title, dueDate: $dueDate, isRead: $isRead)';
  }
} 