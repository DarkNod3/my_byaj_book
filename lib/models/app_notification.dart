import 'dart:convert';

class AppNotification {
  final String id;           // Unique identifier for this notification
  final String title;        // Notification title
  final String message;      // Notification message
  final String source;       // Source of notification (loan, card, contact, etc.)
  final String sourceId;     // ID of the source entity (loanId, cardId, etc.) 
  final DateTime dueDate;    // Due date for the notification
  final double amount;       // Amount associated with the notification
  final String action;       // Action to take when notification is tapped
  final bool isRead;         // Whether the notification has been read
  final bool hasSound;       // Whether this notification should play sound
  final String soundPath;    // Custom sound path (if any)
  
  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.source,
    required this.sourceId,
    required this.dueDate,
    required this.amount,
    this.action = 'view_details',
    this.isRead = false,
    this.hasSound = false,
    this.soundPath = '',
  });
  
  // Create a copy of the notification with updated fields
  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    String? source,
    String? sourceId,
    DateTime? dueDate,
    double? amount,
    String? action,
    bool? isRead,
    bool? hasSound,
    String? soundPath,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      source: source ?? this.source,
      sourceId: sourceId ?? this.sourceId,
      dueDate: dueDate ?? this.dueDate,
      amount: amount ?? this.amount,
      action: action ?? this.action,
      isRead: isRead ?? this.isRead,
      hasSound: hasSound ?? this.hasSound,
      soundPath: soundPath ?? this.soundPath,
    );
  }
  
  // Get days left until the due date
  int get daysLeft => dueDate.difference(DateTime.now()).inDays;
  
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
      'message': message,
      'source': source,
      'sourceId': sourceId,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'amount': amount,
      'action': action,
      'isRead': isRead,
      'hasSound': hasSound,
      'soundPath': soundPath,
    };
  }
  
  // Create a notification from Map
  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      source: map['source'] as String,
      sourceId: map['sourceId'] as String,
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate'] as int),
      amount: map['amount'] as double,
      action: map['action'] as String? ?? 'view_details',
      isRead: map['isRead'] as bool? ?? false,
      hasSound: map['hasSound'] as bool? ?? false,
      soundPath: map['soundPath'] as String? ?? '',
    );
  }
  
  // Convert to JSON string
  String toJson() => json.encode(toMap());
  
  // Create from JSON string
  factory AppNotification.fromJson(String source) => 
      AppNotification.fromMap(json.decode(source) as Map<String, dynamic>);
      
  @override
  String toString() {
    return 'AppNotification(id: $id, title: $title, dueDate: $dueDate, isRead: $isRead)';
  }
} 