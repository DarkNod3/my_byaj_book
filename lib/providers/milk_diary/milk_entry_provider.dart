import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/milk_diary/milk_entry.dart';

class MilkEntryProvider with ChangeNotifier {
  List<MilkEntry> _entries = [];
  
  List<MilkEntry> get entries => [..._entries];
  
  MilkEntryProvider() {
    _loadEntries();
  }
  
  Future<void> _loadEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = prefs.getStringList('milk_entries') ?? [];
      
      _entries = entriesJson
          .map((json) => MilkEntry.fromMap(jsonDecode(json)))
          .toList();
      
      // Sort entries by date and shift (most recent first)
      _entries.sort((a, b) {
        final dateComparison = b.date.compareTo(a.date);
        if (dateComparison != 0) return dateComparison;
        // Use string comparison instead of index (fix for String type)
        return b.shift.compareTo(a.shift);
      });
      
      notifyListeners();
    } catch (e) {
      // Removed debug print
    }
  }
  
  Future<void> _saveEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = _entries
          .map((entry) => jsonEncode(entry.toMap()))
          .toList();
      
      await prefs.setStringList('milk_entries', entriesJson);
    } catch (e) {
      // Removed debug print
    }
  }
  
  Future<void> addEntry(MilkEntry entry) async {
    _entries.add(entry);
    
    // Sort entries by date and shift (most recent first)
    _entries.sort((a, b) {
      final dateComparison = b.date.compareTo(a.date);
      if (dateComparison != 0) return dateComparison;
      // Use string comparison instead of index (fix for String type)
      return b.shift.compareTo(a.shift);
    });
    
    notifyListeners();
    await _saveEntries();
  }
  
  Future<void> updateEntry(MilkEntry updatedEntry) async {
    final index = _entries.indexWhere((entry) => entry.id == updatedEntry.id);
    
    if (index >= 0) {
      _entries[index] = updatedEntry;
      
      // Sort entries by date and shift (most recent first)
      _entries.sort((a, b) {
        final dateComparison = b.date.compareTo(a.date);
        if (dateComparison != 0) return dateComparison;
        // Use string comparison instead of index (fix for String type)
        return b.shift.compareTo(a.shift);
      });
      
      notifyListeners();
      await _saveEntries();
    }
  }
  
  Future<void> deleteEntry(String entryId) async {
    _entries.removeWhere((entry) => entry.id == entryId);
    notifyListeners();
    await _saveEntries();
  }
  
  // Get entries for a specific seller
  List<MilkEntry> getEntriesBySeller(String sellerId) {
    return _entries.where((entry) => entry.sellerId == sellerId).toList();
  }
  
  // Get entries for a specific date range
  List<MilkEntry> getEntriesInDateRange(DateTime startDate, DateTime endDate) {
    return _entries.where((entry) {
      final date = entry.date;
      return date.isAtSameMomentAs(startDate) || 
             date.isAtSameMomentAs(endDate) || 
             (date.isAfter(startDate) && date.isBefore(endDate));
    }).toList();
  }
  
  // Get entries for a specific month
  List<MilkEntry> getEntriesForMonth(int year, int month) {
    return _entries.where((entry) {
      return entry.date.year == year && entry.date.month == month;
    }).toList();
  }
  
  // Calculate total amount for a seller in a date range
  double calculateTotalAmount(String sellerId, DateTime startDate, DateTime endDate) {
    final filtered = getEntriesInDateRange(startDate, endDate)
        .where((entry) => entry.sellerId == sellerId);
    
    return filtered.fold(0.0, (sum, entry) => sum + entry.amount);
  }
  
  // Calculate total amount for a seller in a month
  double calculateMonthlyAmount(String sellerId, int year, int month) {
    final filtered = getEntriesForMonth(year, month)
        .where((entry) => entry.sellerId == sellerId);
    
    return filtered.fold(0.0, (sum, entry) => sum + entry.amount);
  }
  
  // Calculate total quantity for a seller in a date range
  double calculateTotalQuantity(String sellerId, DateTime startDate, DateTime endDate) {
    final filtered = getEntriesInDateRange(startDate, endDate)
        .where((entry) => entry.sellerId == sellerId);
    
    return filtered.fold(0.0, (sum, entry) => sum + entry.quantity);
  }
  
  // Get average fat for a seller in a date range
  double calculateAverageFat(String sellerId, DateTime startDate, DateTime endDate) {
    final filtered = getEntriesInDateRange(startDate, endDate)
        .where((entry) => entry.sellerId == sellerId && entry.fat > 0);
    
    if (filtered.isEmpty) return 0.0;
    
    final totalFat = filtered.fold(0.0, (sum, entry) => sum + entry.fat);
    return totalFat / filtered.length;
  }
} 