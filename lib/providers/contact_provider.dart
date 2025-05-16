import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContactProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = false;
  
  List<Map<String, dynamic>> get contacts => _contacts;
  bool get isLoading => _isLoading;
  
  // Constructor with initialization
  ContactProvider() {
    loadContacts();
  }
  
  // Public method to load contacts (to be called from outside)
  Future<void> loadContacts() async {
    if (_isLoading) return; // Prevent multiple simultaneous loads
    
    _isLoading = true;
    await _loadContacts();
    _isLoading = false;
  }
  
  // Load contacts from shared preferences
  Future<void> _loadContacts() async {
    try {
      print('ContactProvider._loadContacts: Starting to load contacts');
      final prefs = await SharedPreferences.getInstance();
      
      // First try loading as a string list (new format)
      final contactsStringList = prefs.getStringList('contacts');
      
      // Clear existing contacts before loading to prevent duplicates
      _contacts = [];
      
      if (contactsStringList != null && contactsStringList.isNotEmpty) {
        print('ContactProvider: Found ${contactsStringList.length} contacts in StringList format');
        // Process contacts from string list
        _contacts = contactsStringList.map((jsonStr) {
          try {
            final Map<String, dynamic> contact = Map<String, dynamic>.from(json.decode(jsonStr));
            return _convertDynamicContact(contact);
          } catch (e) {
            print('Error parsing contact JSON: $e');
            return <String, dynamic>{
              'name': 'Error',
              'phone': 'error_${DateTime.now().millisecondsSinceEpoch}',
              'lastEditedAt': DateTime.now(),
            };
          }
        }).toList();
      } else {
        // Try fallback to the old format (stored as a single JSON string)
        print('ContactProvider: No contacts in StringList format, checking old format');
        final contactsJson = prefs.getString('contacts');
        if (contactsJson != null && contactsJson.isNotEmpty && contactsJson != '[]') {
          try {
            final List<dynamic> contactsList = json.decode(contactsJson);
            print('ContactProvider: Found ${contactsList.length} contacts in old format');
            _contacts = contactsList.map((item) {
              return _convertDynamicContact(Map<String, dynamic>.from(item));
            }).toList();
          } catch (e) {
            print('Error parsing contacts from old format: $e');
          }
        } else {
          print('ContactProvider: No contacts found in either format');
        }
      }
      
      // Ensure we have a valid list, even if empty
      if (_contacts == null) {
        _contacts = [];
      }
      
      // If we still don't have contacts, check for transaction data
      if (_contacts.isEmpty) {
        print('ContactProvider: No contacts found, checking if we can recover from transaction data');
        await _recoverContactsFromTransactions();
      }
      
      print('ContactProvider: Successfully loaded ${_contacts.length} contacts');
      
      // Print contact details for debugging
      for (int i = 0; i < _contacts.length; i++) {
        final contact = _contacts[i];
        print('Contact ${i+1}: ${contact['name']} (${contact['phone']})');
      }
      
      // Notify listeners that contacts have been loaded
      notifyListeners();
    } catch (e) {
      print('Error loading contacts in ContactProvider: $e');
      print(e.toString());
      if (e is Error) {
        print(e.stackTrace);
      }
      // Always ensure we have a valid list
      _contacts = [];
      notifyListeners();
    }
  }
  
  // Recover contacts from transaction data
  Future<void> _recoverContactsFromTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactIds = prefs.getStringList('transaction_contacts') ?? [];
      
      print('ContactProvider: Found ${contactIds.length} contact IDs in transaction data');
      
      if (contactIds.isEmpty) return;
      
      // For each contact with transactions, try to recreate a contact entry
      for (final contactId in contactIds) {
        // Skip if contact already exists in our list
        final existingIndex = _contacts.indexWhere((c) => c['phone'] == contactId);
        if (existingIndex >= 0) continue;
        
        // Get transactions for this contact ID
        final transactionsList = prefs.getStringList('transactions_$contactId') ?? [];
        if (transactionsList.isEmpty) continue;
        
        print('ContactProvider: Found ${transactionsList.length} transactions for contact ID: $contactId');
        
        // Create a basic contact with this ID
        final newContact = {
          'name': 'Contact $contactId',
          'phone': contactId,
          'lastEditedAt': DateTime.now(),
        };
        
        // Add to contacts list
        _contacts.add(newContact);
      }
      
      // If we found contacts, save them
      if (_contacts.isNotEmpty) {
        await _saveContacts();
        print('ContactProvider: Recovered and saved ${_contacts.length} contacts from transaction data');
      }
    } catch (e) {
      print('Error recovering contacts from transactions: $e');
    }
  }
  
  // Helper to convert dynamic map to properly typed map
  Map<String, dynamic> _convertDynamicContact(dynamic item) {
    final Map<String, dynamic> contact = Map<String, dynamic>.from(item);
    
    // Convert ISO date strings back to DateTime objects
    if (contact.containsKey('lastEditedAt') && contact['lastEditedAt'] is String) {
      try {
        contact['lastEditedAt'] = DateTime.parse(contact['lastEditedAt']);
      } catch (e) {
        // Default to current time if parsing fails
        contact['lastEditedAt'] = DateTime.now();
      }
    } else if (!contact.containsKey('lastEditedAt')) {
      // Add timestamp if missing
      contact['lastEditedAt'] = DateTime.now();
    }
    
    return contact;
  }
  
  // Save contacts to shared preferences
  Future<void> _saveContacts() async {
    try {
      print('ContactProvider._saveContacts: Saving ${_contacts.length} contacts to SharedPreferences');
      final prefs = await SharedPreferences.getInstance();
      
      // Convert contacts to a list of JSON strings
      final List<String> serializedContacts = _contacts.map((contact) {
        // Create a clone of the contact
        final Map<String, dynamic> jsonContact = Map<String, dynamic>.from(contact);
        
        // Convert DateTime to ISO string
        if (jsonContact['lastEditedAt'] is DateTime) {
          jsonContact['lastEditedAt'] = (jsonContact['lastEditedAt'] as DateTime).toIso8601String();
        }
        
        return json.encode(jsonContact);
      }).toList();
      
      print('ContactProvider: Converted ${serializedContacts.length} contacts to JSON strings');
      
      // Save as a StringList (new format)
      await prefs.setStringList('contacts', serializedContacts);
      
      // Also save a backup in the old format for compatibility
      final String oldFormatJson = json.encode(_contacts.map((contact) {
        final Map<String, dynamic> jsonContact = Map<String, dynamic>.from(contact);
        
        // Convert DateTime to ISO string
        if (jsonContact['lastEditedAt'] is DateTime) {
          jsonContact['lastEditedAt'] = (jsonContact['lastEditedAt'] as DateTime).toIso8601String();
        }
        
        return jsonContact;
      }).toList());
      
      await prefs.setString('contacts_backup', oldFormatJson);
      
      print('ContactProvider: Successfully saved contacts to SharedPreferences');
    } catch (e) {
      print('Error saving contacts: $e');
      print(e.toString());
      if (e is Error) {
        print(e.stackTrace);
      }
    }
  }
  
  // Add a new contact
  Future<void> addContact(String name, String phone, bool isGet, double amount) async {
    // Check if contact with this phone already exists
    final existingIndex = _contacts.indexWhere((c) => c['phone'] == phone);
    if (existingIndex != -1) {
      // Update existing contact
      _contacts[existingIndex]['name'] = name;
      _contacts[existingIndex]['isGet'] = isGet;
      _contacts[existingIndex]['lastEditedAt'] = DateTime.now();
    } else {
      // Create new contact
      final newContact = {
        'name': name,
        'phone': phone,
        'isGet': isGet,
        'amount': amount,
        'lastEditedAt': DateTime.now(),
      };
      
      _contacts.add(newContact);
      
      // Sort contacts by last edited (recent first)
      _contacts.sort((a, b) {
        final dateA = a['lastEditedAt'] as DateTime;
        final dateB = b['lastEditedAt'] as DateTime;
        return dateB.compareTo(dateA);
      });
    }
    
    // Save changes
    await _saveContacts();
    
    // Notify listeners
    notifyListeners();
  }
  
  // Update an existing contact
  Future<void> updateContact(Map<String, dynamic> updatedContact) async {
    final phone = updatedContact['phone'] as String? ?? '';
    if (phone.isEmpty) return;
    
    final index = _contacts.indexWhere((c) => c['phone'] == phone);
    if (index != -1) {
      // Update the timestamp
      updatedContact['lastEditedAt'] = DateTime.now();
      
      // Update the contact
      _contacts[index] = updatedContact;
      
      // Save changes
      await _saveContacts();
      
      // Notify listeners
      notifyListeners();
    }
  }
  
  // Update contact phone (and associated data)
  Future<void> updateContactPhone(String oldPhone, String newPhone) async {
    final index = _contacts.indexWhere((c) => c['phone'] == oldPhone);
    if (index != -1) {
      // Update phone number
      _contacts[index]['phone'] = newPhone;
      _contacts[index]['lastEditedAt'] = DateTime.now();
      
      // Save changes
      await _saveContacts();
      
      // Notify listeners
      notifyListeners();
    }
  }
  
  // Delete a contact
  Future<void> deleteContact(String phone) async {
    print('ContactProvider.deleteContact: Starting deletion for phone: $phone');
    
    if (phone.isEmpty) {
      print('ContactProvider: Skipping deletion - empty phone number provided');
      return;
    }
    
    // Find the contact index
    final index = _contacts.indexWhere((c) => c['phone'] == phone);
    if (index < 0) {
      print('ContactProvider: Contact not found for deletion: $phone');
      return;
    }
    
    print('ContactProvider: Found contact at index $index: ${_contacts[index]['name']}');
    
    // Create a new list without the contact to be deleted
    final updatedContacts = List<Map<String, dynamic>>.from(_contacts);
    updatedContacts.removeAt(index);
    
    // Update the contacts list
    _contacts = updatedContacts;
    
    print('ContactProvider: Contact removed from memory, remaining contacts: ${_contacts.length}');
    
    // Save changes to SharedPreferences
    await _saveContacts();
    
    // If contacts list is now empty, ensure we save an empty array
    if (_contacts.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('contacts', []);
      print('ContactProvider: Saved empty contacts list to SharedPreferences');
    }
    
    print('ContactProvider: Contact deletion completed successfully');
    
    // Notify listeners
    notifyListeners();
  }
  
  // Get a contact by phone number
  Map<String, dynamic>? getContactByPhone(String phone) {
    final index = _contacts.indexWhere((c) => c['phone'] == phone);
    if (index != -1) {
      return _contacts[index];
    }
    return null;
  }
} 