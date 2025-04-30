import 'package:uuid/uuid.dart';

enum EntryShift { morning, evening }

class DailyEntry {
  final String id;
  final String sellerId;
  final DateTime date;
  final EntryShift shift;
  final double quantity;
  final double? fat;
  final double rate;
  final double amount;

  DailyEntry({
    String? id,
    required this.sellerId,
    required this.date,
    required this.shift,
    required this.quantity,
    this.fat,
    required this.rate,
    required this.amount,
  }) : id = id ?? const Uuid().v4();

  // Create a copy with modified fields
  DailyEntry copyWith({
    String? id,
    String? sellerId,
    DateTime? date,
    EntryShift? shift,
    double? quantity,
    double? fat,
    double? rate,
    double? amount,
  }) {
    return DailyEntry(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      date: date ?? this.date,
      shift: shift ?? this.shift,
      quantity: quantity ?? this.quantity,
      fat: fat ?? this.fat,
      rate: rate ?? this.rate,
      amount: amount ?? this.amount,
    );
  }

  // Convert DailyEntry to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sellerId': sellerId,
      'date': date.toIso8601String(),
      'shift': shift.toString().split('.').last,
      'quantity': quantity,
      'fat': fat,
      'rate': rate,
      'amount': amount,
    };
  }

  // Create a DailyEntry from Map
  factory DailyEntry.fromMap(Map<String, dynamic> map) {
    return DailyEntry(
      id: map['id'],
      sellerId: map['sellerId'],
      date: DateTime.parse(map['date']),
      shift: EntryShift.values.firstWhere(
        (e) => e.toString().split('.').last == map['shift'],
      ),
      quantity: map['quantity'].toDouble(),
      fat: map['fat'] != null ? map['fat'].toDouble() : null,
      rate: map['rate'].toDouble(),
      amount: map['amount'].toDouble(),
    );
  }

  @override
  String toString() {
    return 'DailyEntry(id: $id, sellerId: $sellerId, date: $date, shift: $shift, quantity: $quantity, fat: $fat, rate: $rate, amount: $amount)';
  }
} 