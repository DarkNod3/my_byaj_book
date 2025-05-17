import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class ContactProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = false;
  
  List<Map<String, dynamic>> get contacts => _contacts;
  bool get isLoading => _isLoading;
  
  // Constructor with initialization
  ContactProvider() {
    loadContacts();
    
    // Set up auto-save timer to ensure contacts are persisted regularly
    Timer.periodic(const Duration(minutes: 2), (_) {
      if (_contacts.isNotEmpty) {
        print('ContactProvider: Auto-saving ${_contacts.length} contacts');
        _saveContacts();
      }
    });
  }
  
  // Public method to load contacts (to be called from outside)
  Future<void> loadContacts() async {
    if (_isLoading) {
      print('ContactProvider: Already loading contacts, waiting...');
      // Wait a short time and then check if contacts are loaded
      await Future.delayed(const Duration(milliseconds: 300));
      if (_contacts.isEmpty) {
        // If still empty, force a reload anyway
        _isLoading = false;
      } else {
        // Contacts loaded while waiting, just return
        return;
      }
    }
    
    _isLoading = true;
    print('ContactProvider: Starting to load contacts');
    
    try {
      await _loadContacts();
      
      // Verify we actually loaded something
      if (_contacts.isEmpty) {
        print('ContactProvider: Warning - No contacts loaded, trying recovery methods');
        // Try recovery method - check for transaction data
        await _recoverContactsFromTransactions();
        
        // If still no contacts, check for backup format
        if (_contacts.isEmpty) {
          print('ContactProvider: No contacts found after recovery attempt, checking backup format');
          await _loadFromBackupFormat();
        }
      }
    } catch (e) {
      print('ContactProvider: Error in loadContacts: $e');
    } finally {
      _isLoading = false;
    }
    
    // Log the final state
    print('ContactProvider: Completed loading contacts, found ${_contacts.length} contacts');
    notifyListeners();
  }
  
  // Load contacts from shared preferences
  Future<void> _loadContacts() async {
    try {
      print('ContactProvider._loadContacts: Starting to load contacts');
      final prefs = await SharedPreferences.getInstance();
      
      // Always reload from disk to ensure we have the most recent data
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
        
        // Print contact details for debugging
        for (int i = 0; i < _contacts.length; i++) {
          final contact = _contacts[i];
          print('Contact ${i+1}: ${contact['name']} (${contact['phone']})');
        }
        
        // Immediately save back to ensure we're using the most current format
        if (_contacts.isNotEmpty) {
          // Schedule a save to make sure data is in the correct format
          Future.delayed(Duration.zero, () {
            _saveContacts();
          });
        }
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
            
            // Immediately save back in new format
            _saveContacts();
          } catch (e) {
            print('Error parsing contacts from old format: $e');
          }
        } else {
          // Try to load from the backup with timestamp
          print('ContactProvider: No contacts found in standard formats, checking backups');
          await _loadMostRecentBackup(prefs);
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
  
  // Load contacts from the most recent backup
  Future<void> _loadMostRecentBackup(SharedPreferences prefs) async {
    try {
      // Get all keys that match the backup pattern
      final allKeys = prefs.getKeys();
      final backupKeys = allKeys.where((key) => key.startsWith('contacts_backup_')).toList();
      
      if (backupKeys.isEmpty) {
        print('ContactProvider: No backup keys found');
        return;
      }
      
      // Sort keys by timestamp (newest first)
      backupKeys.sort((a, b) {
        final timestampA = int.tryParse(a.split('_').last) ?? 0;
        final timestampB = int.tryParse(b.split('_').last) ?? 0;
        return timestampB.compareTo(timestampA);
      });
      
      // Try to load from each backup until we find one that works
      for (final key in backupKeys) {
        final backupJson = prefs.getString(key);
        if (backupJson != null && backupJson.isNotEmpty && backupJson != '[]') {
          try {
            final List<dynamic> contactsList = json.decode(backupJson);
            print('ContactProvider: Found ${contactsList.length} contacts in backup $key');
            
            _contacts = contactsList.map((item) {
              return _convertDynamicContact(Map<String, dynamic>.from(item));
            }).toList();
            
            if (_contacts.isNotEmpty) {
              print('ContactProvider: Successfully loaded ${_contacts.length} contacts from backup');
              
              // Save back in the standard format
              await _saveContacts();
              return;
            }
          } catch (e) {
            print('Error parsing contacts from backup $key: $e');
          }
        }
      }
      
      print('ContactProvider: No valid backups found');
    } catch (e) {
      print('Error loading from backup: $e');
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
      final result = await prefs.setStringList('contacts', serializedContacts);
      
      // Add additional error checking
      if (!result) {
        print('ContactProvider: WARNING - Failed to save contacts to SharedPreferences');
        // Try again with a delay
        await Future.delayed(const Duration(milliseconds: 200));
        await prefs.setStringList('contacts', serializedContacts);
      }
      
      // Save redundant contacts in multiple formats for recovery
      // Keep a backup in the old format for compatibility
      final String oldFormatJson = json.encode(_contacts.map((contact) {
        final Map<String, dynamic> jsonContact = Map<String, dynamic>.from(contact);
        
        // Convert DateTime to ISO string
        if (jsonContact['lastEditedAt'] is DateTime) {
          jsonContact['lastEditedAt'] = (jsonContact['lastEditedAt'] as DateTime).toIso8601String();
        }
        
        return jsonContact;
      }).toList());
      
      await prefs.setString('contacts_backup', oldFormatJson);
      
      // Save an additional backup with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await prefs.setString('contacts_backup_$timestamp', oldFormatJson);
      
      // Force an immediate commit to ensure data is written to disk
      await prefs.commit();
      
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
    
    try {
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
      
      // Get shared preferences instance only once
      final prefs = await SharedPreferences.getInstance();
      
      // Save changes to SharedPreferences
      await _saveContacts();
      
      // Ensure the deletion is immediately persistent by using explicit key saving
      final contactsStringList = _contacts.map((contact) {
        final Map<String, dynamic> jsonContact = Map<String, dynamic>.from(contact);
        if (jsonContact['lastEditedAt'] is DateTime) {
          jsonContact['lastEditedAt'] = (jsonContact['lastEditedAt'] as DateTime).toIso8601String();
        }
        return json.encode(jsonContact);
      }).toList();
      
      // Save directly and force commit
      await prefs.setStringList('contacts', contactsStringList);
      await prefs.commit();
      
      // If contacts list is now empty, ensure we save an empty array
      if (_contacts.isEmpty) {
        await prefs.setStringList('contacts', []);
        print('ContactProvider: Saved empty contacts list to SharedPreferences');
      }
      
      // Save backup with timestamp to ensure we have a recovery point
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupJson = json.encode(_contacts.map((contact) {
        final Map<String, dynamic> jsonContact = Map<String, dynamic>.from(contact);
        if (jsonContact['lastEditedAt'] is DateTime) {
          jsonContact['lastEditedAt'] = (jsonContact['lastEditedAt'] as DateTime).toIso8601String();
        }
        return jsonContact;
      }).toList());
      await prefs.setString('contacts_backup_$timestamp', backupJson);
      
      print('ContactProvider: Contact deletion completed successfully');
      
      // Notify listeners
      notifyListeners();
    } catch (e) {
      print('Error in ContactProvider.deleteContact: $e');
      if (e is Error) {
        print(e.stackTrace);
      }
      
      // Attempt to reload contacts in case of error to ensure consistency
      await loadContacts();
    }
  }
  
  // Get a contact by phone number
  Map<String, dynamic>? getContactByPhone(String phone) {
    final index = _contacts.indexWhere((c) => c['phone'] == phone);
    if (index != -1) {
      return _contacts[index];
    }
    return null;
  }
  
  // Try to load contacts from backup format
  Future<void> _loadFromBackupFormat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupJson = prefs.getString('contacts_backup');
      
      if (backupJson != null && backupJson.isNotEmpty && backupJson != '[]') {
        print('ContactProvider: Found backup contacts json');
        try {
          final List<dynamic> contactsList = json.decode(backupJson);
          print('ContactProvider: Parsed ${contactsList.length} contacts from backup');
          
          _contacts = contactsList.map((item) {
            return _convertDynamicContact(Map<String, dynamic>.from(item));
          }).toList();
          
          // If we successfully loaded from backup, save in current format
          await _saveContacts();
        } catch (e) {
          print('ContactProvider: Error parsing backup contacts: $e');
        }
      }
    } catch (e) {
      print('ContactProvider: Error in _loadFromBackupFormat: $e');
    }
  }
  
  // Public method to force contact saving now
  Future<void> saveContactsNow() async {
    print('ContactProvider.saveContactsNow: Forcing immediate save of ${_contacts.length} contacts');
    return _saveContacts();
  }
  
  // Method to clear loading flag to force a reload
  void clearLoadingFlag() {
    _isLoading = false;
  }
} 