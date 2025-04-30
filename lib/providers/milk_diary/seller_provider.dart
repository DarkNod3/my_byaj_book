import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../models/milk_diary/milk_seller.dart';

class SellerProvider with ChangeNotifier {
  static const String _sellersKey = 'milk_sellers';
  
  List<MilkSeller> _sellers = [];
  List<MilkSeller> get sellers => _sellers;
  
  List<MilkSeller> get activeSellers => 
    _sellers.where((seller) => seller.isActive).toList();

  Future<void> loadSellers() async {
    final prefs = await SharedPreferences.getInstance();
    final sellersJson = prefs.getStringList(_sellersKey) ?? [];
    
    _sellers = sellersJson
        .map((json) => MilkSeller.fromMap(jsonDecode(json)))
        .toList();
    
    notifyListeners();
  }

  Future<void> _saveSellers() async {
    final prefs = await SharedPreferences.getInstance();
    final sellersJson = _sellers
        .map((seller) => jsonEncode(seller.toMap()))
        .toList();
    
    await prefs.setStringList(_sellersKey, sellersJson);
  }

  Future<MilkSeller> addSeller({
    required String name,
    String? mobile,
    String? address,
    double? defaultRate,
  }) async {
    final newSeller = MilkSeller(
      id: const Uuid().v4(),
      name: name,
      mobile: mobile,
      address: address,
      defaultRate: defaultRate ?? 0.0,
    );
    
    _sellers.add(newSeller);
    await _saveSellers();
    notifyListeners();
    
    return newSeller;
  }

  Future<void> updateSeller(MilkSeller updatedSeller) async {
    final index = _sellers.indexWhere((seller) => seller.id == updatedSeller.id);
    
    if (index != -1) {
      _sellers[index] = updatedSeller;
      await _saveSellers();
      notifyListeners();
    }
  }
  
  Future<void> toggleSellerStatus(String sellerId) async {
    final index = _sellers.indexWhere((seller) => seller.id == sellerId);
    
    if (index != -1) {
      final seller = _sellers[index];
      _sellers[index] = seller.copyWith(isActive: !seller.isActive);
      await _saveSellers();
      notifyListeners();
    }
  }

  Future<void> deleteSeller(String sellerId) async {
    _sellers.removeWhere((seller) => seller.id == sellerId);
    await _saveSellers();
    notifyListeners();
  }
  
  MilkSeller? getSellerById(String sellerId) {
    try {
      return _sellers.firstWhere((seller) => seller.id == sellerId);
    } catch (_) {
      return null;
    }
  }
} 