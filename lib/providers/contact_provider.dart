import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContactProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _contacts = [];
  
  List<Map<String, dynamic>> get contacts => _contacts;
  
  // Constructor with initialization
  ContactProvider() {
    loadContacts();
  }
  
  // Public method to load contacts (to be called from outside)
  Future<void> loadContacts() async {
    await _loadContacts();
  }
  
  // Load contacts from shared preferences
  Future<void> _loadContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson = prefs.getString('contacts') ?? '[]';
      
      // Parse contacts
      final List<dynamic> decoded = json.decode(contactsJson);
      _contacts = decoded.map((item) => _convertDynamicContact(item)).toList();
      
      notifyListeners();
    } catch (e) {
      print('Error loading contacts: $e');
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
      final prefs = await SharedPreferences.getInstance();
      
      // Convert contacts to JSON-compatible format
      final List<Map<String, dynamic>> serializedContacts = _contacts.map((contact) {
        // Create a clone of the contact
        final Map<String, dynamic> jsonContact = Map<String, dynamic>.from(contact);
        
        // Convert DateTime to ISO string
        if (jsonContact['lastEditedAt'] is DateTime) {
          jsonContact['lastEditedAt'] = (jsonContact['lastEditedAt'] as DateTime).toIso8601String();
        }
        
        return jsonContact;
      }).toList();
      
      await prefs.setString('contacts', json.encode(serializedContacts));
    } catch (e) {
      print('Error saving contacts: $e');
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
    if (phone.isEmpty) return;
    
    _contacts.removeWhere((c) => c['phone'] == phone);
    
    // Save changes
    await _saveContacts();
    
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