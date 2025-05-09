class AppNotification {
  final String id;           // Unique identifier for this notification
  final String type;         // Type of notification ("loan", "bill", "card", "contact", "fcm")
  final String title;        // Notification title
  final String message;      // Notification message
  final DateTime timestamp;  // Timestamp of the notification
  bool isRead;               // Whether the notification has been read
  bool isPaid;               // Whether the notification is paid (for due types only)
  final Map<String, dynamic>? data; // Additional data for specific notification types
  
  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.isPaid = false,
    this.data,
  });
  
  // Create from JSON (for storage and retrieval)
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      isPaid: json['isPaid'] ?? false,
      data: json['data'],
    );
  }
  
  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'isPaid': isPaid,
      'data': data,
    };
  }
  
  // Create a copy with updated fields
  AppNotification copyWith({
    String? id,
    String? type,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    bool? isPaid,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isPaid: isPaid ?? this.isPaid,
      data: data ?? this.data,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppNotification &&
        other.id == id &&
        other.type == type &&
        other.title == title &&
        other.message == message &&
        other.timestamp == timestamp &&
        other.isRead == isRead &&
        other.isPaid == isPaid;
  }
  
  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() {
    return 'AppNotification(id: $id, title: $title, timestamp: $timestamp, isRead: $isRead)';
  }
} 