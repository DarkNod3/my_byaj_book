import 'package:flutter/foundation.dart';
import 'milk_entry.dart';
import 'milk_payment.dart';
import 'package:uuid/uuid.dart';

enum PriceSystem {
  defaultRate,
  fatBased,
}

class MilkSeller {
  final String id;
  final String name;
  final String? mobile;
  final String? address;
  final double defaultRate;
  final bool isActive;

  MilkSeller({
    required this.id,
    required this.name,
    this.mobile,
    this.address,
    this.defaultRate = 0.0,
    this.isActive = true,
  });

  MilkSeller copyWith({
    String? id,
    String? name,
    String? mobile,
    String? address,
    double? defaultRate,
    bool? isActive,
  }) {
    return MilkSeller(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      address: address ?? this.address,
      defaultRate: defaultRate ?? this.defaultRate,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'address': address,
      'defaultRate': defaultRate,
      'isActive': isActive,
    };
  }

  factory MilkSeller.fromMap(Map<String, dynamic> map) {
    return MilkSeller(
      id: map['id'],
      name: map['name'],
      mobile: map['mobile'],
      address: map['address'],
      defaultRate: map['defaultRate'] ?? 0.0,
      isActive: map['isActive'] ?? true,
    );
  }

  @override
  String toString() {
    return 'MilkSeller(id: $id, name: $name, mobile: $mobile, defaultRate: $defaultRate, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is MilkSeller &&
      other.id == id &&
      other.name == name &&
      other.mobile == mobile &&
      other.address == address &&
      other.defaultRate == defaultRate &&
      other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      name.hashCode ^
      mobile.hashCode ^
      address.hashCode ^
      defaultRate.hashCode ^
      isActive.hashCode;
  }
}

class MilkEntry {
  final int id;
  final int sellerId;
  final DateTime date;
  final String time; // Morning or Evening
  final double quantity;
  final double rate;
  final double? fat;
  final double amount;
  
  MilkEntry({
    required this.id,
    required this.sellerId,
    required this.date,
    required this.time,
    required this.quantity,
    required this.rate,
    this.fat,
    required this.amount,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sellerId': sellerId,
      'date': date.toIso8601String(),
      'time': time,
      'quantity': quantity,
      'rate': rate,
      'fat': fat,
      'amount': amount,
    };
  }
  
  factory MilkEntry.fromJson(Map<String, dynamic> json) {
    return MilkEntry(
      id: json['id'],
      sellerId: json['sellerId'],
      date: DateTime.parse(json['date']),
      time: json['time'],
      quantity: json['quantity'] ?? 0.0,
      rate: json['rate'] ?? 0.0,
      fat: json['fat'],
      amount: json['amount'] ?? 0.0,
    );
  }
} 