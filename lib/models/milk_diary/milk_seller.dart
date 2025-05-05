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
  final PriceSystem priceSystem;
  final Map<double, double>? fatRates;
  double _dueAmount = 0.0;

  MilkSeller({
    required this.id,
    required this.name,
    this.mobile,
    this.address,
    this.defaultRate = 0.0,
    this.isActive = true,
    this.priceSystem = PriceSystem.defaultRate,
    this.fatRates,
    double dueAmount = 0.0,
  }) : _dueAmount = dueAmount;

  double get dueAmount => _dueAmount;
  
  // Method to update the due amount
  void updateDueAmount(double amount) {
    _dueAmount = amount;
  }

  MilkSeller copyWith({
    String? id,
    String? name,
    String? mobile,
    String? address,
    double? defaultRate,
    bool? isActive,
    PriceSystem? priceSystem,
    Map<double, double>? fatRates,
    double? dueAmount,
  }) {
    return MilkSeller(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      address: address ?? this.address,
      defaultRate: defaultRate ?? this.defaultRate,
      isActive: isActive ?? this.isActive,
      priceSystem: priceSystem ?? this.priceSystem,
      fatRates: fatRates ?? this.fatRates,
      dueAmount: dueAmount ?? this._dueAmount,
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
      'priceSystem': priceSystem.toString().split('.').last,
      'fatRates': fatRates != null ? Map<String, dynamic>.fromEntries(
        fatRates!.entries.map((e) => MapEntry(e.key.toString(), e.value))
      ) : null,
      'dueAmount': _dueAmount,
    };
  }

  factory MilkSeller.fromMap(Map<String, dynamic> map) {
    Map<double, double>? fatRatesMap;
    if (map['fatRates'] != null) {
      fatRatesMap = Map<double, double>.fromEntries(
        (map['fatRates'] as Map<String, dynamic>).entries.map(
          (e) => MapEntry(double.parse(e.key), e.value.toDouble())
        )
      );
    }
    
    return MilkSeller(
      id: map['id'],
      name: map['name'],
      mobile: map['mobile'],
      address: map['address'],
      defaultRate: map['defaultRate'] ?? 0.0,
      isActive: map['isActive'] ?? true,
      priceSystem: map['priceSystem'] != null 
        ? PriceSystem.values.firstWhere(
            (e) => e.toString().split('.').last == map['priceSystem'],
            orElse: () => PriceSystem.defaultRate)
        : PriceSystem.defaultRate,
      fatRates: fatRatesMap,
      dueAmount: map['dueAmount']?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() {
    return 'MilkSeller(id: $id, name: $name, mobile: $mobile, defaultRate: $defaultRate, isActive: $isActive, priceSystem: $priceSystem)';
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
      other.isActive == isActive &&
      other.priceSystem == priceSystem;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      name.hashCode ^
      mobile.hashCode ^
      address.hashCode ^
      defaultRate.hashCode ^
      isActive.hashCode ^
      priceSystem.hashCode;
  }
} 