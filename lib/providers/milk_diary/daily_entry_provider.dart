import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/milk_diary/daily_entry.dart';

class DailyEntryProvider with ChangeNotifier {
  List<DailyEntry> _entries = [];
  List<DailyEntry> _filteredEntries = [];
  bool Function(DailyEntry)? _filterFunction;
  bool _isFiltered = false;
  static const String _storageKey = 'daily_entries';

  List<DailyEntry> get entries => 
    _isFiltered ? List.unmodifiable(_filteredEntries) : List.unmodifiable(_entries);

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
        return a.shift.toString().compareTo(b.shift.toString());
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
      
      await prefs.setStringList(_storageKey, entriesJson);
    } catch (e) {
      // Removed debug print
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
      // Instead of throwing an exception, try to update the existing entry
      // Create updated entry with new values but keep the existing ID
      final updatedEntry = DailyEntry(
        id: _entries[existingEntryIndex].id,
        sellerId: entry.sellerId,
        date: entry.date,
        shift: entry.shift,
        quantity: entry.quantity,
        fat: entry.fat,
        snf: entry.snf,
        rate: entry.rate,
        amount: entry.amount,
        remarks: entry.remarks,
        status: entry.status,
        milkType: entry.milkType,
      );
      
      // Replace the existing entry
      _entries[existingEntryIndex] = updatedEntry;
      _sortEntries();
      
      notifyListeners();
      await _saveEntries();
      return;
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
      // Get the existing duplicate entry
      final existingEntry = _entries[duplicateIndex];
      
      // Throw a more user-friendly exception
      throw Exception('An entry for this seller, date, and shift already exists');
    }
    
    _entries[index] = updatedEntry;
    _sortEntries();
    
    notifyListeners();
    await _saveEntries();
  }

  Future<void> deleteEntry(String entryId) async {
    // Remove entry from memory
    final entryIndex = _entries.indexWhere((entry) => entry.id == entryId);
    if (entryIndex != -1) {
      _entries.removeAt(entryIndex);
      
      // Save changes to storage immediately
      await _saveEntries();
      
      // Update any filtered entries if necessary
      if (_isFiltered) {
        _filteredEntries.removeWhere((entry) => entry.id == entryId);
      }
      
      notifyListeners();
    }
  }

  void _sortEntries() {
    _entries.sort((a, b) {
      final dateComparison = b.date.compareTo(a.date);
      if (dateComparison != 0) return dateComparison;
      return a.shift.toString().compareTo(b.shift.toString());
    });
  }

  void setFilter(bool Function(DailyEntry) filterFunction) {
    _filterFunction = filterFunction;
    _applyFilter();
    _isFiltered = true;
    notifyListeners();
  }

  void clearFilter() {
    _filterFunction = null;
    _filteredEntries = [];
    _isFiltered = false;
    notifyListeners();
  }

  void _applyFilter() {
    if (_filterFunction != null) {
      _filteredEntries = _entries.where(_filterFunction!).toList();
      _sortFilteredEntries();
    } else {
      _filteredEntries = [];
    }
  }

  void _sortFilteredEntries() {
    _filteredEntries.sort((a, b) {
      final dateComparison = b.date.compareTo(a.date);
      if (dateComparison != 0) return dateComparison;
      return a.shift.toString().compareTo(b.shift.toString());
    });
  }

  List<DailyEntry> getEntriesForDate(DateTime date) {
    final entriesList = _isFiltered ? _filteredEntries : _entries;
    return entriesList.where((entry) => 
      entry.date.year == date.year && 
      entry.date.month == date.month && 
      entry.date.day == date.day
    ).toList();
  }

  List<DailyEntry> getEntriesForSeller(String sellerId) {
    final entriesList = _isFiltered ? _filteredEntries : _entries;
    return entriesList.where((entry) => entry.sellerId == sellerId).toList();
  }
  
  List<DailyEntry> getEntriesForSellerInRange(String sellerId, DateTime startDate, DateTime endDate) {
    // Normalize dates to start of day
    final normalizedStartDate = DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEndDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    
    final entriesList = _isFiltered ? _filteredEntries : _entries;
    return entriesList.where((entry) => 
      entry.sellerId == sellerId &&
      ((entry.date.isAtSameMomentAs(normalizedStartDate) || 
      entry.date.isAfter(normalizedStartDate)) &&
      (entry.date.isAtSameMomentAs(normalizedEndDate) || 
      entry.date.isBefore(normalizedEndDate)))
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
  
  // Get all entries in a specific date range
  List<DailyEntry> getEntriesInDateRange(DateTime startDate, DateTime endDate) {
    // Normalize dates to start of day
    final normalizedStartDate = DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEndDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    
    final entriesList = _isFiltered ? _filteredEntries : _entries;
    return entriesList.where((entry) => 
      (entry.date.isAtSameMomentAs(normalizedStartDate) || 
       entry.date.isAfter(normalizedStartDate)) &&
      (entry.date.isAtSameMomentAs(normalizedEndDate) || 
       entry.date.isBefore(normalizedEndDate))
    ).toList();
  }
} 