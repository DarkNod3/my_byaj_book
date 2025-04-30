import 'package:flutter/material.dart';

enum TransactionType {
  received,
  given
}

class Transaction {
  final int? id;
  final int khataId;
  final TransactionType type;
  final double amount;
  final String? note;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    this.id,
    required this.khataId,
    required this.type,
    required this.amount,
    this.note,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    this.date = date ?? DateTime.now(),
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();

  Transaction copyWith({
    int? id,
    int? khataId,
    TransactionType? type,
    double? amount,
    String? note,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      khataId: khataId ?? this.khataId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  bool get isReceived => type == TransactionType.received;
  bool get isGiven => type == TransactionType.given;

  String get typeText => isReceived ? 'Received' : 'Given';

  Color get typeColor => isReceived ? Colors.green : Colors.red;

  IconData get typeIcon => isReceived 
    ? Icons.arrow_downward 
    : Icons.arrow_upward;

  double get signedAmount => isReceived ? amount : -amount;

  String get formattedAmount {
    return '₹${amount.toStringAsFixed(2)}';
  }

  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }
} 