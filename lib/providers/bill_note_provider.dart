import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/bill_note.dart';

class BillNoteProvider with ChangeNotifier {
  List<BillNote> _notes = [];
  final String _storageKey = 'bill_notes';
  bool _isLoading = false;
  
  BillNoteProvider() {
    loadNotes();
  }
  
  bool get isLoading => _isLoading;
  
  List<BillNote> get notes => [..._notes];
  
  List<BillNote> get completedNotes => 
      _notes.where((note) => note.isCompleted).toList();
  
  List<BillNote> get pendingNotes => 
      _notes.where((note) => !note.isCompleted).toList();
  
  List<BillNote> get upcomingReminders => 
      _notes.where((note) => 
        note.reminderDate != null && 
        !note.isCompleted && 
        note.reminderDate!.isAfter(DateTime.now())
      ).toList()
      ..sort((a, b) => a.reminderDate!.compareTo(b.reminderDate!));
  
  List<BillNote> getNotesByCategory(BillCategory category) {
    if (category == BillCategory.all) {
      return notes;
    }
    return _notes.where((note) => note.category == category).toList();
  }
  
  BillNote? getNoteById(String id) {
    try {
      return _notes.firstWhere((note) => note.id == id);
    } catch (e) {
      return null;
    }
  }
  
  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesData = prefs.getString(_storageKey);
      
      if (notesData != null) {
        final notesList = jsonDecode(notesData) as List<dynamic>;
        _notes = notesList
            .map((item) => BillNote.fromMap(item))
            .toList();
            
        // Sort notes by creation date, newest first
        _notes.sort((a, b) => b.createdDate.compareTo(a.createdDate));
      }
    } catch (e) {
      // Removed debug print
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> saveNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesData = jsonEncode(_notes.map((note) => note.toMap()).toList());
      await prefs.setString(_storageKey, notesData);
    } catch (e) {
      // Removed debug print
    }
  }
  
  Future<BillNote> addNote(String title, String content, BillCategory category, 
      {DateTime? reminderDate, double? amount}) async {
    final newNote = BillNote(
      title: title,
      content: content,
      category: category,
      reminderDate: reminderDate,
      amount: amount,
    );
    
    _notes.add(newNote);
    _notes.sort((a, b) => b.createdDate.compareTo(a.createdDate));
    await saveNotes();
    notifyListeners();
    return newNote;
  }
  
  Future<void> updateNote(BillNote updatedNote) async {
    final index = _notes.indexWhere((note) => note.id == updatedNote.id);
    if (index >= 0) {
      _notes[index] = updatedNote;
      await saveNotes();
      notifyListeners();
    }
  }
  
  Future<void> toggleNoteStatus(String id) async {
    final index = _notes.indexWhere((note) => note.id == id);
    if (index >= 0) {
      final note = _notes[index];
      _notes[index] = note.copyWith(isCompleted: !note.isCompleted);
      await saveNotes();
      notifyListeners();
    }
  }
  
  Future<void> deleteNote(String noteId) async {
    final index = _notes.indexWhere((note) => note.id == noteId);
    if (index >= 0) {
      // Remove from memory
      _notes.removeAt(index);
      
      // Immediately save to storage to ensure permanent deletion
      await saveNotes();
      
      // Notify listeners
      notifyListeners();
    }
  }
  
  // Statistics and summaries
  Map<BillCategory, int> getCategoryDistribution() {
    final Map<BillCategory, int> distribution = {};
    
    for (final category in BillCategory.values) {
      if (category != BillCategory.all) {
        distribution[category] = getNotesByCategory(category).length;
      }
    }
    
    return distribution;
  }
  
  double getTotalAmount({bool? completed}) {
    List<BillNote> filteredNotes = _notes;
    
    if (completed != null) {
      filteredNotes = _notes.where((note) => note.isCompleted == completed).toList();
    }
    
    return filteredNotes
        .where((note) => note.amount != null)
        .fold(0, (sum, note) => sum + (note.amount ?? 0));
  }
} 