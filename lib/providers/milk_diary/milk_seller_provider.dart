import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/milk_diary/milk_seller.dart';

class MilkSellerProvider with ChangeNotifier {
  List<MilkSeller> _sellers = [];
  static const String _storageKey = 'milk_sellers';

  List<MilkSeller> get sellers => List.unmodifiable(_sellers);

  MilkSellerProvider() {
    _loadSellers();
  }

  Future<void> _loadSellers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sellerJson = prefs.getStringList(_storageKey) ?? [];
      
      _sellers = sellerJson
          .map((json) => MilkSeller.fromMap(jsonDecode(json)))
          .toList();
      
      // Sort by name
      _sellers.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading milk sellers: $e');
    }
  }

  Future<void> _saveSellers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sellerJson = _sellers
          .map((seller) => jsonEncode(seller.toMap()))
          .toList();
      
      await prefs.setStringList(_storageKey, sellerJson);
    } catch (e) {
      debugPrint('Error saving milk sellers: $e');
    }
  }

  Future<void> addSeller(MilkSeller seller) async {
    if (_sellers.any((s) => s.id == seller.id)) {
      throw Exception('Seller with ID ${seller.id} already exists');
    }
    
    _sellers.add(seller);
    _sellers.sort((a, b) => a.name.compareTo(b.name));
    
    notifyListeners();
    await _saveSellers();
  }

  Future<void> updateSeller(MilkSeller updatedSeller) async {
    final index = _sellers.indexWhere((s) => s.id == updatedSeller.id);
    
    if (index == -1) {
      throw Exception('No seller found with ID ${updatedSeller.id}');
    }
    
    _sellers[index] = updatedSeller;
    _sellers.sort((a, b) => a.name.compareTo(b.name));
    
    notifyListeners();
    await _saveSellers();
  }

  Future<void> deleteSeller(String sellerId) async {
    _sellers.removeWhere((s) => s.id == sellerId);
    
    notifyListeners();
    await _saveSellers();
  }

  MilkSeller? getSellerById(String id) {
    try {
      return _sellers.firstWhere((seller) => seller.id == id);
    } catch (e) {
      return null;
    }
  }

  List<MilkSeller> searchSellers(String query) {
    if (query.isEmpty) {
      return sellers;
    }
    
    final lowercaseQuery = query.toLowerCase();
    return _sellers.where((seller) {
      return seller.name.toLowerCase().contains(lowercaseQuery) ||
          (seller.phoneNumber?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          (seller.address?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }
} 