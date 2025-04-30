import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/milk_diary/daily_entry.dart';

class DailyEntryProvider with ChangeNotifier {
  List<DailyEntry> _entries = [];
  static const String _storageKey = 'daily_entries';

  List<DailyEntry> get entries => List.unmodifiable(_entries);

  DailyEntryProvider() {
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = prefs.getStringList(_storageKey) ?? [];
      
      _entries = entriesJson
          .map((json) => DailyEntry.fromMap(jsonDecode(json)))
          .toList();
      
      // Sort by date and shift
      _entries.sort((a, b) {
        final dateComparison = b.date.compareTo(a.date);
        if (dateComparison != 0) return dateComparison;
        return a.shift.index.compareTo(b.shift.index);
      });
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading daily entries: $e');
    }
  }

  Future<void> _saveEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = _entries
          .map((entry) => jsonEncode(entry.toMap()))
          .toList();
      
      await prefs.setStringList(_storageKey, entriesJson);
    } catch (e) {
      debugPrint('Error saving daily entries: $e');
    }
  }

  Future<void> addEntry(DailyEntry entry) async {
    // Check if an entry with the same date, shift, and seller already exists
    final existingEntryIndex = _entries.indexWhere((e) => 
        e.date.year == entry.date.year && 
        e.date.month == entry.date.month && 
        e.date.day == entry.date.day &&
        e.shift == entry.shift &&
        e.sellerId == entry.sellerId);
    
    if (existingEntryIndex != -1) {
      throw Exception('An entry for this seller, date, and shift already exists');
    }
    
    _entries.add(entry);
    _sortEntries();
    
    notifyListeners();
    await _saveEntries();
  }

  Future<void> updateEntry(DailyEntry updatedEntry) async {
    final index = _entries.indexWhere((e) => e.id == updatedEntry.id);
    
    if (index == -1) {
      throw Exception('No entry found with ID ${updatedEntry.id}');
    }
    
    // Check if updating would create a duplicate
    final duplicateIndex = _entries.indexWhere((e) => 
        e.id != updatedEntry.id &&
        e.date.year == updatedEntry.date.year && 
        e.date.month == updatedEntry.date.month && 
        e.date.day == updatedEntry.date.day &&
        e.shift == updatedEntry.shift &&
        e.sellerId == updatedEntry.sellerId);
    
    if (duplicateIndex != -1) {
      throw Exception('An entry for this seller, date, and shift already exists');
    }
    
    _entries[index] = updatedEntry;
    _sortEntries();
    
    notifyListeners();
    await _saveEntries();
  }

  Future<void> deleteEntry(String entryId) async {
    _entries.removeWhere((e) => e.id == entryId);
    
    notifyListeners();
    await _saveEntries();
  }

  void _sortEntries() {
    _entries.sort((a, b) {
      final dateComparison = b.date.compareTo(a.date);
      if (dateComparison != 0) return dateComparison;
      return a.shift.index.compareTo(b.shift.index);
    });
  }

  List<DailyEntry> getEntriesForDate(DateTime date) {
    return _entries.where((entry) => 
      entry.date.year == date.year && 
      entry.date.month == date.month && 
      entry.date.day == date.day
    ).toList();
  }

  List<DailyEntry> getEntriesForSeller(String sellerId) {
    return _entries.where((entry) => entry.sellerId == sellerId).toList();
  }
  
  List<DailyEntry> getEntriesForSellerInRange(String sellerId, DateTime startDate, DateTime endDate) {
    // Normalize dates to start of day
    final normalizedStartDate = DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEndDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    
    return _entries.where((entry) => 
      entry.sellerId == sellerId &&
      entry.date.isAtSameMomentAs(normalizedStartDate) || 
      entry.date.isAfter(normalizedStartDate) &&
      entry.date.isAtSameMomentAs(normalizedEndDate) || 
      entry.date.isBefore(normalizedEndDate)
    ).toList();
  }

  // Calculate total quantity for a seller in a date range
  double getTotalQuantityForSeller(String sellerId, DateTime startDate, DateTime endDate) {
    final entriesInRange = getEntriesForSellerInRange(sellerId, startDate, endDate);
    return entriesInRange.fold(0.0, (sum, entry) => sum + entry.quantity);
  }
  
  // Calculate total amount for a seller in a date range
  double getTotalAmountForSeller(String sellerId, DateTime startDate, DateTime endDate) {
    final entriesInRange = getEntriesForSellerInRange(sellerId, startDate, endDate);
    return entriesInRange.fold(0.0, (sum, entry) => sum + entry.amount);
  }
} 