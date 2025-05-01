import 'package:uuid/uuid.dart';

class ContactProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _withoutInterestContacts = [];
  final List<Map<String, dynamic>> _withInterestContacts = [];

  Future<void> addContact(Map<String, dynamic> contact, String tabType) async {
    // Add tab type to the contact
    contact['tabType'] = tabType;
    
    // Ensure the contact has a unique ID
    if (!contact.containsKey('id')) {
      contact['id'] = const Uuid().v4();
    }
    
    if (tabType == 'withoutInterest') {
      _withoutInterestContacts.add(contact);
      notifyListeners();
      await _saveWithoutInterestContacts();
    } else {
      _withInterestContacts.add(contact);
      notifyListeners();
      await _saveWithInterestContacts();
    }
  }

  Future<void> _saveWithoutInterestContacts() async {
    // Implementation of saving without interest contacts
  }

  Future<void> _saveWithInterestContacts() async {
    // Implementation of saving with interest contacts
  }
} 