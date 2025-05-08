enum PriceSystem {
  defaultRate,
  fatBased,
}

class MilkSeller {
  final String id;
  final String name;
  final String? mobile;
  final String? phone;
  final String? address;
  final double defaultRate;
  final bool isActive;
  final PriceSystem priceSystem;
  final Map<double, double>? fatRates;
  final int unit;
  final int baseFat;
  final bool fatBasedPricing;
  double _dueAmount = 0.0;

  MilkSeller({
    required this.id,
    required this.name,
    this.mobile,
    this.phone,
    this.address,
    this.defaultRate = 0.0,
    this.isActive = true,
    this.priceSystem = PriceSystem.defaultRate,
    this.fatRates,
    double dueAmount = 0.0,
    this.unit = 1,
    this.baseFat = 3,
    this.fatBasedPricing = false,
  }) : _dueAmount = dueAmount;

  double get dueAmount => _dueAmount;
  double get outstanding => _dueAmount;
  
  // Method to update the due amount
  void updateDueAmount(double amount) {
    _dueAmount = amount;
  }

  MilkSeller copyWith({
    String? id,
    String? name,
    String? mobile,
    String? phone,
    String? address,
    double? defaultRate,
    bool? isActive,
    PriceSystem? priceSystem,
    Map<double, double>? fatRates,
    double? dueAmount,
    int? unit,
    int? baseFat,
    bool? fatBasedPricing,
  }) {
    return MilkSeller(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      defaultRate: defaultRate ?? this.defaultRate,
      isActive: isActive ?? this.isActive,
      priceSystem: priceSystem ?? this.priceSystem,
      fatRates: fatRates ?? this.fatRates,
      dueAmount: dueAmount ?? _dueAmount,
      unit: unit ?? this.unit,
      baseFat: baseFat ?? this.baseFat,
      fatBasedPricing: fatBasedPricing ?? this.fatBasedPricing,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'phone': phone ?? mobile,
      'address': address,
      'defaultRate': defaultRate,
      'isActive': isActive,
      'priceSystem': priceSystem.toString().split('.').last,
      'fatRates': fatRates != null ? Map<String, dynamic>.fromEntries(
        fatRates!.entries.map((e) => MapEntry(e.key.toString(), e.value))
      ) : null,
      'dueAmount': _dueAmount,
      'outstanding': _dueAmount,
      'unit': unit,
      'baseFat': baseFat,
      'fatBasedPricing': fatBasedPricing,
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
      phone: map['phone'] ?? map['mobile'],
      address: map['address'],
      defaultRate: map['defaultRate']?.toDouble() ?? 0.0,
      isActive: map['isActive'] ?? true,
      priceSystem: map['priceSystem'] != null 
        ? PriceSystem.values.firstWhere(
            (e) => e.toString().split('.').last == map['priceSystem'],
            orElse: () => PriceSystem.defaultRate)
        : PriceSystem.defaultRate,
      fatRates: fatRatesMap,
      dueAmount: map['dueAmount']?.toDouble() ?? map['outstanding']?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 1,
      baseFat: map['baseFat'] ?? 3,
      fatBasedPricing: map['fatBasedPricing'] ?? false,
    );
  }

  factory MilkSeller.fromJson(Map<String, dynamic> json) => MilkSeller.fromMap(json);
  
  Map<String, dynamic> toJson() => toMap();

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