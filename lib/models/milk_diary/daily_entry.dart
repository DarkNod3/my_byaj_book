import 'package:uuid/uuid.dart';

enum EntryShift { morning, evening }
enum EntryStatus { pending, paid }
enum MilkType { cow, buffalo }

class DailyEntry {
  final String id;
  final String sellerId;
  final DateTime date;
  final EntryShift shift;
  final double quantity;
  final double? fat;
  final double? snf;  // Solids-Not-Fat percentage
  final double rate;
  final double amount;
  final String? remarks;
  final EntryStatus status;
  final MilkType milkType;
  final String unit; // 'L' for liter or 'kg' for kilogram

  DailyEntry({
    String? id,
    required this.sellerId,
    required this.date,
    required this.shift,
    required this.quantity,
    this.fat,
    this.snf,
    required this.rate,
    required this.amount,
    this.remarks,
    this.status = EntryStatus.pending,
    this.milkType = MilkType.cow,
    this.unit = 'L', // Default to Liter
  }) : id = id ?? const Uuid().v4();

  // Create a copy with modified fields
  DailyEntry copyWith({
    String? id,
    String? sellerId,
    DateTime? date,
    EntryShift? shift,
    double? quantity,
    double? fat,
    double? snf,
    double? rate,
    double? amount,
    String? remarks,
    EntryStatus? status,
    MilkType? milkType,
    String? unit,
  }) {
    return DailyEntry(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      date: date ?? this.date,
      shift: shift ?? this.shift,
      quantity: quantity ?? this.quantity,
      fat: fat ?? this.fat,
      snf: snf ?? this.snf,
      rate: rate ?? this.rate,
      amount: amount ?? this.amount,
      remarks: remarks ?? this.remarks,
      status: status ?? this.status,
      milkType: milkType ?? this.milkType,
      unit: unit ?? this.unit,
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
      'snf': snf,
      'rate': rate,
      'amount': amount,
      'remarks': remarks,
      'status': status.toString().split('.').last,
      'milkType': milkType.toString().split('.').last,
      'unit': unit,
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
        orElse: () => EntryShift.morning,
      ),
      quantity: map['quantity'].toDouble(),
      fat: map['fat'] != null ? map['fat'].toDouble() : null,
      snf: map['snf'] != null ? map['snf'].toDouble() : null,
      rate: map['rate'].toDouble(),
      amount: map['amount'].toDouble(),
      remarks: map['remarks'],
      status: map['status'] != null
          ? EntryStatus.values.firstWhere(
              (e) => e.toString().split('.').last == map['status'],
              orElse: () => EntryStatus.pending)
          : EntryStatus.pending,
      milkType: map['milkType'] != null
          ? MilkType.values.firstWhere(
              (e) => e.toString().split('.').last == map['milkType'],
              orElse: () => MilkType.cow)
          : MilkType.cow,
      unit: map['unit'] ?? 'L', // Default to L if not specified
    );
  }

  @override
  String toString() {
    return 'DailyEntry(id: $id, sellerId: $sellerId, date: $date, shift: $shift, quantity: $quantity, fat: $fat, snf: $snf, rate: $rate, amount: $amount, status: $status, milkType: $milkType, unit: $unit)';
  }
} 