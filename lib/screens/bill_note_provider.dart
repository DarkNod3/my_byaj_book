import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BillNoteProvider extends ChangeNotifier {
  List<BillNote> _notes = [];

  List<BillNote> get notes => _notes;

  Future<void> loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString('bill_notes');
      
      if (notesJson != null) {
        final List<dynamic> decodedNotes = jsonDecode(notesJson);
        _notes = decodedNotes.map((note) => BillNote.fromJson(note)).toList();
        
        // Sort notes by date (newest first)
        _notes.sort((a, b) => b.date.compareTo(a.date));
        
        notifyListeners();
      }
    } catch (e) {
      // Silent error handling in release mode
      // In debug mode, we could log this error
    }
  }
  
  Future<void> saveNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = jsonEncode(_notes.map((note) => note.toJson()).toList());
      await prefs.setString('bill_notes', notesJson);
    } catch (e) {
      // Silent error handling in release mode
      // In debug mode, we could log this error
    }
  }
} 