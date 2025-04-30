import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../models/milk_diary/daily_entry.dart';

class EntryProvider with ChangeNotifier {
  static const String _entriesKey = 'milk_entries';
  
  List<DailyEntry> _entries = [];
  List<DailyEntry> get entries => _entries;
  
  Future<void> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = prefs.getStringList(_entriesKey) ?? [];
    
    _entries = entriesJson
        .map((json) => DailyEntry.fromMap(jsonDecode(json)))
        .toList();
    
    notifyListeners();
  }

  Future<void> _saveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = _entries
        .map((entry) => jsonEncode(entry.toMap()))
        .toList();
    
    await prefs.setStringList(_entriesKey, entriesJson);
  }

  Future<DailyEntry> addEntry({
    required String sellerId,
    required DateTime date,
    required EntryShift shift,
    required double quantity,
    required double fat,
    required double rate,
  }) async {
    final amount = quantity * rate;
    
    final newEntry = DailyEntry(
      id: const Uuid().v4(),
      sellerId: sellerId,
      date: date,
      shift: shift,
      quantity: quantity,
      fat: fat,
      rate: rate,
      amount: amount,
    );
    
    _entries.add(newEntry);
    await _saveEntries();
    notifyListeners();
    
    return newEntry;
  }

  Future<void> updateEntry(DailyEntry updatedEntry) async {
    final index = _entries.indexWhere((entry) => entry.id == updatedEntry.id);
    
    if (index != -1) {
      _entries[index] = updatedEntry;
      await _saveEntries();
      notifyListeners();
    }
  }

  Future<void> deleteEntry(String entryId) async {
    _entries.removeWhere((entry) => entry.id == entryId);
    await _saveEntries();
    notifyListeners();
  }
  
  List<DailyEntry> getEntriesBySeller(String sellerId) {
    return _entries.where((entry) => entry.sellerId == sellerId).toList();
  }
  
  List<DailyEntry> getEntriesByDate(DateTime date) {
    return _entries.where((entry) {
      final entryDate = entry.date;
      return entryDate.year == date.year && 
             entryDate.month == date.month && 
             entryDate.day == date.day;
    }).toList();
  }
  
  List<DailyEntry> getEntriesByDateRange(DateTime start, DateTime end) {
    return _entries.where((entry) {
      final entryDate = entry.date;
      return entryDate.isAfter(start.subtract(const Duration(days: 1))) && 
             entryDate.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }
  
  double getTotalQuantityForSeller(String sellerId) {
    return getEntriesBySeller(sellerId)
        .fold(0.0, (sum, entry) => sum + entry.quantity);
  }
  
  double getTotalAmountForSeller(String sellerId) {
    return getEntriesBySeller(sellerId)
        .fold(0.0, (sum, entry) => sum + entry.amount);
  }
  
  Map<String, double> getSellerTotals() {
    final Map<String, double> totals = {};
    
    for (final entry in _entries) {
      totals[entry.sellerId] = (totals[entry.sellerId] ?? 0) + entry.amount;
    }
    
    return totals;
  }
} 