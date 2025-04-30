import 'package:intl/intl.dart';

class WorkEntry {
  final String id;
  final DateTime date;
  final String durationType;
  final double? hours;
  final double amount;
  final String description;

  WorkEntry({
    required this.id,
    required this.date,
    required this.durationType,
    this.hours,
    required this.amount,
    this.description = '',
  });

  String get formattedDate {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String get typeDisplay {
    if (durationType == 'Hourly' && hours != null) {
      return '${hours!.toStringAsFixed(1)} hour${hours == 1.0 ? '' : 's'}';
    }
    return durationType;
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'durationType': durationType,
      'hours': hours,
      'amount': amount,
      'description': description,
    };
  }

  // Create from JSON
  factory WorkEntry.fromJson(Map<String, dynamic> json) {
    return WorkEntry(
      id: json['id'],
      date: DateTime.fromMillisecondsSinceEpoch(json['date']),
      durationType: json['durationType'],
      hours: json['hours']?.toDouble(),
      amount: json['amount'].toDouble(),
      description: json['description'] ?? '',
    );
  }
} 