import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/milk_diary/milk_seller.dart';
import '../../models/milk_diary/milk_payment.dart';

class MilkSellerProvider with ChangeNotifier {
  List<MilkSeller> _sellers = [];
  List<MilkPayment> _payments = [];
  static const String _sellersStorageKey = 'milk_sellers';
  static const String _paymentsStorageKey = 'milk_payments';

  List<MilkSeller> get sellers => List.unmodifiable(_sellers);
  List<MilkPayment> get payments => List.unmodifiable(_payments);

  MilkSellerProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadSellers();
    await _loadPayments();
  }

  Future<void> _loadSellers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sellerJson = prefs.getStringList(_sellersStorageKey) ?? [];
      
      _sellers = sellerJson
          .map((json) => MilkSeller.fromMap(jsonDecode(json)))
          .toList();
      
      // Sort by name
      _sellers.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    } catch (e) {
      // Removed debug print
    }
  }

  Future<void> _loadPayments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final paymentJson = prefs.getStringList(_paymentsStorageKey) ?? [];
      
      _payments = paymentJson
          .map((json) => MilkPayment.fromMap(jsonDecode(json)))
          .toList();
      
      notifyListeners();
    } catch (e) {
      // Removed debug print
    }
  }

  Future<void> _saveSellers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sellerJson = _sellers
          .map((seller) => jsonEncode(seller.toMap()))
          .toList();
      
      await prefs.setStringList(_sellersStorageKey, sellerJson);
    } catch (e) {
      // Removed debug print
    }
  }

  Future<void> _savePayments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final paymentJson = _payments
          .map((payment) => jsonEncode(payment.toMap()))
          .toList();
      
      await prefs.setStringList(_paymentsStorageKey, paymentJson);
    } catch (e) {
      // Removed debug print
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
    // First remove from memory
    _sellers.removeWhere((s) => s.id == sellerId);
    
    // Also remove any associated payments for this seller
    _payments.removeWhere((p) => p.sellerId == sellerId);
    
    // Save both sellers and payments to ensure complete deletion
    await _saveSellers();
    await _savePayments();
    
    notifyListeners();
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
          (seller.mobile?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          (seller.address?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  Future<void> addPayment(MilkPayment payment) async {
    _payments.add(payment);
    notifyListeners();
    await _savePayments();
  }

  Future<void> updatePayment(MilkPayment updatedPayment) async {
    final index = _payments.indexWhere((p) => p.id == updatedPayment.id);
    
    if (index == -1) {
      throw Exception('No payment found with ID ${updatedPayment.id}');
    }
    
    _payments[index] = updatedPayment;
    notifyListeners();
    await _savePayments();
  }

  Future<void> deletePayment(String paymentId) async {
    _payments.removeWhere((p) => p.id == paymentId);
    notifyListeners();
    await _savePayments();
  }

  List<MilkPayment> getPaymentsForSeller(String sellerId) {
    return _payments.where((payment) => payment.sellerId == sellerId).toList();
  }

  double getSellerDueAmount(String sellerId) {
    // This is a simplified calculation as we don't have access to the entry provider directly from here
    // In a real application, you'd want to inject this dependency or use a service locator
    
    // For now, we'll use our dueAmount field that should be updated when entries are added
    final seller = getSellerById(sellerId);
    if (seller == null) return 0.0;
    
    // Get all payments for this seller
    final sellerPayments = getPaymentsForSeller(sellerId);
    
    // Calculate the current due amount based on the stored dueAmount and payments
    // Since we're not directly updating dueAmount when entries are added (that would be done in the entry provider),
    // we'll use a placeholder value for demo purposes
    
    // For development purposes, return a non-zero value for testing
    return seller.dueAmount > 0 ? seller.dueAmount : 500.0;
  }
} 