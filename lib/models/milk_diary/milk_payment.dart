import 'package:uuid/uuid.dart';

class MilkPayment {
  final String id;
  final String sellerId;
  final DateTime date;
  final double amount;
  final String? note;

  MilkPayment({
    String? id,
    required this.sellerId,
    required this.date,
    required this.amount,
    this.note,
  }) : id = id ?? const Uuid().v4();

  // Create a copy of this payment with the given fields replaced
  MilkPayment copyWith({
    String? sellerId,
    DateTime? date,
    double? amount,
    String? note,
  }) {
    return MilkPayment(
      id: id,
      sellerId: sellerId ?? this.sellerId,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      note: note ?? this.note,
    );
  }

  // Convert payment to a map (for storage)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sellerId': sellerId,
      'date': date.millisecondsSinceEpoch,
      'amount': amount,
      'note': note,
    };
  }

  // Create a payment from a map
  factory MilkPayment.fromMap(Map<String, dynamic> map) {
    return MilkPayment(
      id: map['id'],
      sellerId: map['sellerId'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      amount: map['amount'],
      note: map['note'],
    );
  }
} 