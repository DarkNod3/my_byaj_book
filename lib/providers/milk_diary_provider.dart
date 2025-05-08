import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/milk_diary/milk_seller.dart';
import '../models/milk_diary/milk_entry.dart';

class MilkDiaryProvider with ChangeNotifier {
  List<MilkSeller> _sellers = [];
  DateTime _selectedDate = DateTime.now();
  DateTime _selectedMonth = DateTime.now();
  String _filter = 'All'; // All, High Outstanding, Low Outstanding
  
  List<MilkSeller> get sellers => _sellers;
  DateTime get selectedDate => _selectedDate;
  DateTime get selectedMonth => _selectedMonth;
  String get filter => _filter;
  
  MilkDiaryProvider() {
    _loadData();
  }
  
  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? sellersJson = prefs.getString('milk_sellers');
      
      if (sellersJson != null) {
        final List<dynamic> decoded = jsonDecode(sellersJson);
        _sellers = decoded.map((item) => MilkSeller.fromJson(item)).toList();
      } else {
        // No sample data
        _sellers = [];
      }
      notifyListeners();
    } catch (e) {
      // Error loading milk diary data - silent in release
    }
  }
  
  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String sellersJson = jsonEncode(_sellers.map((s) => s.toJson()).toList());
      await prefs.setString('milk_sellers', sellersJson);
    } catch (e) {
      // Error saving milk diary data - silent in release
    }
  }
  
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }
  
  void setSelectedMonth(DateTime month) {
    _selectedMonth = month;
    notifyListeners();
  }
  
  void setFilter(String filter) {
    _filter = filter;
    notifyListeners();
  }
  
  List<MilkSeller> getFilteredSellers() {
    if (_filter == 'All') {
      return _sellers;
    } else if (_filter == 'High Outstanding') {
      return _sellers.where((seller) => seller.outstanding > 1000).toList();
    } else if (_filter == 'Low Outstanding') {
      return _sellers.where((seller) => seller.outstanding <= 1000).toList();
    }
    return _sellers;
  }
  
  List<MilkEntry> getEntriesForDay(String sellerId, DateTime day) {
    // Using daily_entry model instead of entries in MilkSeller - this function needs to be updated
    // in a real implementation to use a DailyEntryProvider
    // This is a placeholder implementation
    return [];
  }
  
  List<MilkEntry> getEntriesForMonth(String sellerId, DateTime month) {
    // Using daily_entry model instead of entries in MilkSeller - this function needs to be updated
    // in a real implementation to use a DailyEntryProvider
    // This is a placeholder implementation
    return [];
  }
  
  Future<void> addMilkSeller(MilkSeller seller) async {
    _sellers.add(seller);
    await _saveData();
    notifyListeners();
  }
  
  Future<void> updateMilkSeller(MilkSeller updatedSeller) async {
    final index = _sellers.indexWhere((s) => s.id == updatedSeller.id);
    if (index >= 0) {
      _sellers[index] = updatedSeller;
      await _saveData();
      notifyListeners();
    }
  }
  
  Future<void> deleteMilkSeller(String id) async {
    _sellers.removeWhere((s) => s.id == id);
    await _saveData();
    notifyListeners();
  }
  
  Future<void> recordPayment(String sellerId, double amount, String description) async {
    final sellerIndex = _sellers.indexWhere((s) => s.id == sellerId);
    if (sellerIndex >= 0) {
      final seller = _sellers[sellerIndex];
      
      // Create a new seller with updated due amount
      final updatedSeller = seller.copyWith(
        dueAmount: seller.dueAmount - amount,
      );
      
      _sellers[sellerIndex] = updatedSeller;
      
      await _saveData();
      notifyListeners();
    }
  }
  
  Map<String, dynamic> getMonthlySummary(DateTime month) {
    // These values are not being calculated properly
    // and are just placeholders returning 0
    double totalQuantity = 0;
    double totalAmount = 0;
    double totalOutstanding = 0;
    
    for (var seller in _sellers) {
      // Get entries for this month - in a real implementation, this would
      // use the DailyEntryProvider
      // This is a placeholder calculation
      
      totalOutstanding += seller.outstanding;
    }
    
    return {
      'totalQuantity': totalQuantity,
      'totalAmount': totalAmount,
      'totalOutstanding': totalOutstanding,
    };
  }
} 