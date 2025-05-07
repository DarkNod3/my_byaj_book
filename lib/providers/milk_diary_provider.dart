import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/milk_diary/milk_seller.dart';

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
  
  List<MilkEntry> getEntriesForDay(int sellerId, DateTime day) {
    final seller = _sellers.firstWhere((s) => s.id == sellerId);
    return seller.entries.where((entry) => 
      entry.date.year == day.year && 
      entry.date.month == day.month && 
      entry.date.day == day.day
    ).toList();
  }
  
  List<MilkEntry> getEntriesForMonth(int sellerId, DateTime month) {
    final seller = _sellers.firstWhere((s) => s.id == sellerId);
    return seller.entries.where((entry) => 
      entry.date.year == month.year && 
      entry.date.month == month.month
    ).toList();
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
  
  Future<void> deleteMilkSeller(int id) async {
    _sellers.removeWhere((s) => s.id == id);
    await _saveData();
    notifyListeners();
  }
  
  Future<void> addMilkEntry(MilkEntry entry) async {
    final index = _sellers.indexWhere((s) => s.id == entry.sellerId);
    if (index >= 0) {
      final seller = _sellers[index];
      final updatedEntries = List<MilkEntry>.from(seller.entries)..add(entry);
      
      _sellers[index] = MilkSeller(
        id: seller.id,
        name: seller.name,
        phone: seller.phone,
        address: seller.address,
        fatBasedPricing: seller.fatBasedPricing,
        unit: seller.unit,
        rate: seller.rate,
        baseFat: seller.baseFat,
        entries: updatedEntries,
        outstanding: seller.outstanding + entry.amount,
      );
      
      await _saveData();
      notifyListeners();
    }
  }
  
  Future<void> updateMilkEntry(MilkEntry updatedEntry) async {
    final sellerIndex = _sellers.indexWhere((s) => s.id == updatedEntry.sellerId);
    if (sellerIndex >= 0) {
      final seller = _sellers[sellerIndex];
      final entryIndex = seller.entries.indexWhere((e) => e.id == updatedEntry.id);
      
      if (entryIndex >= 0) {
        final oldEntry = seller.entries[entryIndex];
        final updatedEntries = List<MilkEntry>.from(seller.entries);
        updatedEntries[entryIndex] = updatedEntry;
        
        _sellers[sellerIndex] = MilkSeller(
          id: seller.id,
          name: seller.name,
          phone: seller.phone,
          address: seller.address,
          fatBasedPricing: seller.fatBasedPricing,
          unit: seller.unit,
          rate: seller.rate,
          baseFat: seller.baseFat,
          entries: updatedEntries,
          outstanding: seller.outstanding - oldEntry.amount + updatedEntry.amount,
        );
        
        await _saveData();
        notifyListeners();
      }
    }
  }
  
  Future<void> deleteMilkEntry(int sellerId, int entryId) async {
    final sellerIndex = _sellers.indexWhere((s) => s.id == sellerId);
    if (sellerIndex >= 0) {
      final seller = _sellers[sellerIndex];
      final entryIndex = seller.entries.indexWhere((e) => e.id == entryId);
      
      if (entryIndex >= 0) {
        final oldEntry = seller.entries[entryIndex];
        final updatedEntries = List<MilkEntry>.from(seller.entries);
        updatedEntries.removeAt(entryIndex);
        
        _sellers[sellerIndex] = MilkSeller(
          id: seller.id,
          name: seller.name,
          phone: seller.phone,
          address: seller.address,
          fatBasedPricing: seller.fatBasedPricing,
          unit: seller.unit,
          rate: seller.rate,
          baseFat: seller.baseFat,
          entries: updatedEntries,
          outstanding: seller.outstanding - oldEntry.amount,
        );
        
        await _saveData();
        notifyListeners();
      }
    }
  }
  
  Future<void> recordPayment(int sellerId, double amount, String description) async {
    final sellerIndex = _sellers.indexWhere((s) => s.id == sellerId);
    if (sellerIndex >= 0) {
      final seller = _sellers[sellerIndex];
      
      _sellers[sellerIndex] = MilkSeller(
        id: seller.id,
        name: seller.name,
        phone: seller.phone,
        address: seller.address,
        fatBasedPricing: seller.fatBasedPricing,
        unit: seller.unit,
        rate: seller.rate,
        baseFat: seller.baseFat,
        entries: seller.entries,
        outstanding: seller.outstanding - amount,
      );
      
      await _saveData();
      notifyListeners();
    }
  }
  
  Map<String, dynamic> getMonthlySummary(DateTime month) {
    double totalQuantity = 0;
    double totalAmount = 0;
    double totalOutstanding = 0;
    
    for (var seller in _sellers) {
      final monthEntries = getEntriesForMonth(seller.id, month);
      
      for (var entry in monthEntries) {
        totalQuantity += entry.quantity;
        totalAmount += entry.amount;
      }
      
      totalOutstanding += seller.outstanding;
    }
    
    return {
      'totalQuantity': totalQuantity,
      'totalAmount': totalAmount,
      'totalOutstanding': totalOutstanding,
    };
  }
} 