import 'package:flutter/material.dart';

enum TransactionCategory {
  principal,
  interest
}

class InterestTransaction {
  final int? id;
  final int khataId;
  final TransactionCategory category;
  final double amount;
  final String? note;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  InterestTransaction({
    this.id,
    required this.khataId,
    required this.category,
    required this.amount,
    this.note,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    date = date ?? DateTime.now(),
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  InterestTransaction copyWith({
    int? id,
    int? khataId,
    TransactionCategory? category,
    double? amount,
    String? note,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InterestTransaction(
      id: id ?? this.id,
      khataId: khataId ?? this.khataId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  bool get isPrincipal => category == TransactionCategory.principal;
  bool get isInterest => category == TransactionCategory.interest;

  String get categoryText => isPrincipal ? 'Principal' : 'Interest';

  Color get categoryColor => isPrincipal ? Colors.blue : Colors.orange;

  IconData get categoryIcon => isPrincipal 
    ? Icons.account_balance_wallet 
    : Icons.trending_up;

  String get formattedAmount {
    return '₹${amount.toStringAsFixed(2)}';
  }

  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }
}
