import 'package:uuid/uuid.dart';

class Payment {
  final String id;
  final String sellerId;
  final DateTime date;
  final double amount;
  final String? description;

  Payment({
    String? id,
    required this.sellerId,
    required this.date,
    required this.amount,
    this.description,
  }) : id = id ?? const Uuid().v4();

  // Create a copy with modified fields
  Payment copyWith({
    String? id,
    String? sellerId,
    DateTime? date,
    double? amount,
    String? description,
  }) {
    return Payment(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      description: description ?? this.description,
    );
  }

  // Convert Payment to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sellerId': sellerId,
      'date': date.toIso8601String(),
      'amount': amount,
      'description': description,
    };
  }

  // Create a Payment from Map
  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      sellerId: map['sellerId'],
      date: DateTime.parse(map['date']),
      amount: map['amount'].toDouble(),
      description: map['description'],
    );
  }

  @override
  String toString() {
    return 'Payment(id: $id, sellerId: $sellerId, date: $date, amount: $amount, description: $description)';
  }
} 