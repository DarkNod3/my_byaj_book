import 'package:uuid/uuid.dart';

class MilkEntry {
  final String id;
  final String sellerId;
  final DateTime date;
  final String shift; // 'morning' or 'evening'
  final double quantity;
  final double fat;
  final double rate;
  final double amount;

  MilkEntry({
    String? id,
    required this.sellerId,
    required this.date,
    required this.shift,
    required this.quantity,
    this.fat = 0.0,
    required this.rate,
    required this.amount,
  }) : id = id ?? const Uuid().v4();

  // Create a copy of this MilkEntry with the given fields replaced with new values
  MilkEntry copyWith({
    String? id,
    String? sellerId,
    DateTime? date,
    String? shift,
    double? quantity,
    double? fat,
    double? rate,
    double? amount,
  }) {
    return MilkEntry(
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

  // Convert MilkEntry to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sellerId': sellerId,
      'date': date.toIso8601String(),
      'shift': shift,
      'quantity': quantity,
      'fat': fat,
      'rate': rate,
      'amount': amount,
    };
  }

  // Create a MilkEntry from a Map
  factory MilkEntry.fromMap(Map<String, dynamic> map) {
    return MilkEntry(
      id: map['id'],
      sellerId: map['sellerId'],
      date: DateTime.parse(map['date']),
      shift: map['shift'],
      quantity: map['quantity'].toDouble(),
      fat: map['fat']?.toDouble() ?? 0.0,
      rate: map['rate'].toDouble(),
      amount: map['amount'].toDouble(),
    );
  }

  // Add fromJson and toJson methods
  factory MilkEntry.fromJson(Map<String, dynamic> json) => MilkEntry.fromMap(json);
  
  Map<String, dynamic> toJson() => toMap();

  @override
  String toString() {
    return 'MilkEntry(id: $id, sellerId: $sellerId, date: $date, shift: $shift, '
        'quantity: $quantity, fat: $fat, rate: $rate, amount: $amount)';
  }
} 