import 'package:flutter/material.dart';
import 'transaction.dart';

enum KhataType {
  withoutInterest,
  withInterest
}

enum InterestCalculationType {
  simple,
  compound,
}

class Khata {
  final int? id;
  final int contactId;
  final KhataType type;
  final double interestRate;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double currentBalance;
  final String contactName;
  final bool isLender;
  final InterestCalculationType interestCalculationType;
  final List<Transaction> transactions;

  Khata({
    this.id,
    required this.contactId,
    required this.contactName,
    required this.type,
    this.interestRate = 0.0,
    this.note,
    required this.currentBalance,
    this.isLender = true,
    this.interestCalculationType = InterestCalculationType.simple,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.transactions = const [],
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Khata copyWith({
    int? id,
    int? contactId,
    KhataType? type,
    double? interestRate,
    String? note,
    double? currentBalance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Khata(
      id: id ?? this.id,
      contactId: contactId ?? this.contactId,
      contactName: contactName,
      type: type ?? this.type,
      interestRate: interestRate ?? this.interestRate,
      note: note ?? this.note,
      currentBalance: currentBalance ?? this.currentBalance,
      isLender: isLender,
      interestCalculationType: interestCalculationType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      transactions: transactions,
    );
  }

  bool get hasInterest => type == KhataType.withInterest;
  
  Color get typeColor => hasInterest ? Colors.orange : Colors.blue;
      
  IconData get typeIcon => hasInterest 
    ? Icons.account_balance 
    : Icons.account_balance_wallet;
      
  String get typeText => hasInterest ? 'With Interest' : 'Without Interest';
      
  String get balanceText => currentBalance >= 0
      ? "You'll get ₹${currentBalance.abs().toStringAsFixed(2)}"
      : "You'll give ₹${currentBalance.abs().toStringAsFixed(2)}";
      
  Color get balanceColor => currentBalance >= 0
      ? Colors.green.shade700
      : Colors.red.shade700;

  double get balanceAmount {
    if (transactions.isEmpty) return 0.0;
    
    double balance = 0.0;
    for (var transaction in transactions) {
      if (transaction.type == TransactionType.youGot) {
        balance += transaction.amount;
      } else {
        balance -= transaction.amount;
      }
    }
    return balance;
  }

  double calculateInterest() {
    if (!hasInterest || balanceAmount == 0) return 0.0;
    
    final principal = balanceAmount.abs();
    
    if (interestCalculationType == InterestCalculationType.simple) {
      // Simple interest calculation: P * R * T / 100
      // Here R is annual rate, and T is in months, so we divide by 12
      return principal * interestRate * 12 / 100;
    } else {
      // Compound interest calculation: P * (1 + R/100)^(T/12) - P
      // For monthly compounding over period in months
      final monthlyRate = interestRate / 100 / 12;
      return principal * (Math.pow(1 + monthlyRate, 12) - 1);
    }
  }

  double calculateTotalInterest() {
    // For simple calculations - if more complex logic is needed,
    // this would need to be enhanced
    return transactions
        .where((t) => t.isInterestTransaction)
        .fold<double>(0, (sum, t) => sum + t.amount);
  }

  DateTime getNextInterestDueDate() {
    // This is a simplified implementation
    // In a real app, would need to look at the last interest payment
    // and calculate the next due date based on rotation period
    
    // For now, just return a date that's rotationPeriodMonths from now
    return DateTime.now().add(const Duration(days: 30 * 12));
  }

  int getDaysUntilNextInterestDue() {
    final nextDueDate = getNextInterestDueDate();
    return nextDueDate.difference(DateTime.now()).inDays;
  }
}

// For importing Math in the real implementation
class Math {
  static double pow(double x, int y) {
    double result = 1.0;
    for (int i = 0; i < y; i++) {
      result *= x;
    }
    return result;
  }
} 