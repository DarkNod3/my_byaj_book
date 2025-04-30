import 'package:uuid/uuid.dart';

class MilkPayment {
  final String id;
  final String sellerId;
  final DateTime date;
  final double amount;
  final String? description;

  MilkPayment({
    String? id,
    required this.sellerId,
    required this.date,
    required this.amount,
    this.description,
  }) : this.id = id ?? const Uuid().v4();

  // Create a copy of this payment with the given fields replaced
  MilkPayment copyWith({
    String? sellerId,
    DateTime? date,
    double? amount,
    String? description,
  }) {
    return MilkPayment(
      id: this.id,
      sellerId: sellerId ?? this.sellerId,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      description: description ?? this.description,
    );
  }

  // Convert payment to a map (for storage)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sellerId': sellerId,
      'date': date.millisecondsSinceEpoch,
      'amount': amount,
      'description': description,
    };
  }

  // Create a payment from a map
  factory MilkPayment.fromMap(Map<String, dynamic> map) {
    return MilkPayment(
      id: map['id'],
      sellerId: map['sellerId'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      amount: map['amount'],
      description: map['description'],
    );
  }
} 