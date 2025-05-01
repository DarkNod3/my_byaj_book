import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionProvider extends ChangeNotifier {
  // Map of contactId -> list of transactions
  Map<String, List<Map<String, dynamic>>> _contactTransactions = {};
  
  // Constructor
  TransactionProvider() {
    _loadTransactions();
    _loadContacts();
  }
  
  // Get transactions for a specific contact
  List<Map<String, dynamic>> getTransactionsForContact(String contactId) {
    return _contactTransactions[contactId] ?? [];
  }
  
  // Add a transaction
  Future<void> addTransaction(String contactId, Map<String, dynamic> transaction) async {
    if (!_contactTransactions.containsKey(contactId)) {
      _contactTransactions[contactId] = [];
    }
    
    // Add to start of the list (newest first)
    _contactTransactions[contactId]!.insert(0, transaction);
    
    // Save to preferences
    await _saveTransactions();
    
    // Notify listeners
    notifyListeners();
  }
  
  // Add a transaction with individual fields
  Future<void> addTransactionDetails(
    String contactId, 
    double amount, 
    String type, 
    DateTime date, 
    String note, 
    String? imagePath,
    {Map<String, dynamic>? extraData}
  ) async {
    // Ensure amount is always positive (absolute value)
    final double positiveAmount = amount.abs();
    
    Map<String, dynamic> transaction = {
      'date': date,
      'amount': positiveAmount, // Always store as positive
      'type': type,             // 'gave' or 'got' determines the sign
      'note': note,
    };
    
    if (imagePath != null) {
      transaction['imagePath'] = imagePath;
    }
    
    // Add any extra data
    if (extraData != null) {
      transaction.addAll(extraData);
    }
    
    await addTransaction(contactId, transaction);
    
    // Debug print after adding
    print('DEBUG - Added transaction to $contactId: $transaction');
    debugPrintAllTransactions();
  }
  
  // Update a transaction
  Future<void> updateTransaction(String contactId, int index, Map<String, dynamic> updatedTransaction) async {
    if (_contactTransactions.containsKey(contactId) && 
        index >= 0 && 
        index < _contactTransactions[contactId]!.length) {
      _contactTransactions[contactId]![index] = updatedTransaction;
      
      // Save to preferences
      await _saveTransactions();
      
      // Notify listeners
      notifyListeners();
    }
  }
  
  // Delete a transaction
  Future<void> deleteTransaction(String contactId, int index) async {
    if (_contactTransactions.containsKey(contactId) && 
        index >= 0 && 
        index < _contactTransactions[contactId]!.length) {
      _contactTransactions[contactId]!.removeAt(index);
      
      // Save to preferences
      await _saveTransactions();
      
      // Notify listeners
      notifyListeners();
    }
  }
  
  // Delete all transactions for a contact
  Future<void> deleteContactTransactions(String contactId) async {
    if (_contactTransactions.containsKey(contactId)) {
      _contactTransactions.remove(contactId);
      
      // Save to preferences
      await _saveTransactions();
      
      // Notify listeners
      notifyListeners();
    }
  }
  
  // Save transactions to SharedPreferences
  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Convert complex objects to strings
    final Map<String, List<String>> serializedData = {};
    
    _contactTransactions.forEach((contactId, transactions) {
      serializedData[contactId] = transactions.map((tx) {
        // Convert DateTime to ISO string for easier serialization
        final txCopy = Map<String, dynamic>.from(tx);
        if (txCopy['date'] is DateTime) {
          txCopy['date'] = txCopy['date'].toIso8601String();
        }
        return jsonEncode(txCopy);
      }).toList();
    });
    
    // Save each contact's transactions as a separate preference entry
    for (final contactId in serializedData.keys) {
      await prefs.setStringList('transactions_$contactId', serializedData[contactId]!);
    }
    
    // Save list of all contactIds that have transactions
    await prefs.setStringList('transaction_contacts', serializedData.keys.toList());
  }
  
  // Load transactions from SharedPreferences
  Future<void> _loadTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get list of contactIds that have transactions
      final contactIds = prefs.getStringList('transaction_contacts') ?? [];
      
      for (final contactId in contactIds) {
        final serializedTransactions = prefs.getStringList('transactions_$contactId') ?? [];
        
        _contactTransactions[contactId] = serializedTransactions.map((txString) {
          final txMap = jsonDecode(txString) as Map<String, dynamic>;
          
          // Convert ISO string back to DateTime
          if (txMap['date'] is String) {
            txMap['date'] = DateTime.parse(txMap['date']);
          }
          
          return txMap;
        }).toList();
      }
      
      // Notify listeners
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    }
  }
  
  // Calculate total balance for a contact
  double calculateBalance(String contactId) {
    double balance = 0;
    final transactions = getTransactionsForContact(contactId);
    
    for (var tx in transactions) {
      final amount = (tx['amount'] as double).abs(); // Always get positive amount
      
      if (tx['type'] == 'gave') {
        // If you GAVE money, it's a positive balance (you'll get it back)
        balance += amount;
      } else {
        // If you GOT money, it's a negative balance (you'll give it back)
        balance -= amount;
      }
    }
    
    return balance;
  }

  // Add debug method 
  void debugPrintAllTransactions() {
    _contactTransactions.forEach((contactId, transactions) {
      print('DEBUG - Transactions for contactId: $contactId');
      for (int i = 0; i < transactions.length; i++) {
        final tx = transactions[i];
        print('  Transaction $i: type=${tx['type']}, amount=${tx['amount']}, date=${tx['date']}');
      }
    });
  }

  // Add methods for contact management
  
  // List of contacts (stored separately from transactions)
  List<Map<String, dynamic>> _contacts = [];
  
  // Get all contacts
  List<Map<String, dynamic>> get contacts => _contacts;
  
  // Load contacts from SharedPreferences
  Future<void> _loadContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson = prefs.getStringList('contacts') ?? [];
      
      _contacts = contactsJson.map((jsonStr) => 
        Map<String, dynamic>.from(jsonDecode(jsonStr))
      ).toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading contacts: $e');
    }
  }
  
  // Save contacts to SharedPreferences
  Future<void> _saveContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson = _contacts.map((contact) => jsonEncode(contact)).toList();
      
      await prefs.setStringList('contacts', contactsJson);
    } catch (e) {
      debugPrint('Error saving contacts: $e');
    }
  }
  
  // Add a new contact
  Future<bool> addContact(Map<String, dynamic> contact) async {
    try {
      // Make sure phone number is used as contactId and is unique
      final contactId = contact['phone'] as String?;
      
      if (contactId == null || contactId.isEmpty) {
        return false;
      }
      
      // Check if contact with this phone already exists
      final existingIndex = _contacts.indexWhere((c) => c['phone'] == contactId);
      if (existingIndex >= 0) {
        return false; // Contact already exists
      }
      
      // Sanitize the contact data to prevent null values
      final sanitizedContact = Map<String, dynamic>.from(contact);
      
      // Handle common string fields
      ['name', 'phone', 'category', 'type', 'interestPeriod'].forEach((key) {
        if (sanitizedContact.containsKey(key) && sanitizedContact[key] == null) {
          sanitizedContact[key] = '';
        }
      });
      
      // Handle numeric fields
      if (sanitizedContact.containsKey('interestRate') && sanitizedContact['interestRate'] == null) {
        sanitizedContact['interestRate'] = 0.0;
      }
      
      // Add the sanitized contact
      _contacts.add(sanitizedContact);
      
      // Save to SharedPreferences
      await _saveContacts();
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding contact: $e');
      return false;
    }
  }
  
  // Add a contact if it doesn't already exist
  Future<bool> addContactIfNotExists(Map<String, dynamic> contact) async {
    try {
      final contactId = contact['phone'] as String?;
      
      if (contactId == null || contactId.isEmpty) {
        return false;
      }
      
      // Check if contact with this phone already exists
      final existingIndex = _contacts.indexWhere((c) => c['phone'] == contactId);
      if (existingIndex >= 0) {
        // Contact already exists, no need to add
        return true;
      }
      
      // Sanitize the contact data to prevent null values
      final sanitizedContact = Map<String, dynamic>.from(contact);
      
      // Handle common string fields
      ['name', 'phone', 'category', 'type', 'interestPeriod'].forEach((key) {
        if (sanitizedContact.containsKey(key) && sanitizedContact[key] == null) {
          sanitizedContact[key] = '';
        }
      });
      
      // Handle numeric fields
      if (sanitizedContact.containsKey('interestRate') && sanitizedContact['interestRate'] == null) {
        sanitizedContact['interestRate'] = 0.0;
      }
      
      // Add the sanitized contact since it doesn't exist
      _contacts.add(sanitizedContact);
      
      // Save to SharedPreferences
      await _saveContacts();
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error in addContactIfNotExists: $e');
      return false;
    }
  }
  
  // Update an existing contact
  Future<bool> updateContact(Map<String, dynamic> updatedContact) async {
    try {
      // Ensure we have a valid phone number (contact ID)
      final contactId = updatedContact['phone'] as String?;
      
      if (contactId == null || contactId.isEmpty) {
        return false;
      }
      
      // Find the contact index
      final index = _contacts.indexWhere((c) => c['phone'] == contactId);
      if (index < 0) {
        return false; // Contact not found
      }
      
      // Check if phone number is being changed
      final oldContactId = _contacts[index]['phone'];
      final newContactId = updatedContact['phone'];
      
      if (oldContactId != newContactId) {
        // Phone number changed, need to update transaction mapping
        final transactions = _contactTransactions[oldContactId] ?? [];
        if (transactions.isNotEmpty) {
          _contactTransactions[newContactId] = transactions;
          _contactTransactions.remove(oldContactId);
          await _saveTransactions();
        }
      }
      
      // Ensure all string values are non-null before updating
      final sanitizedContact = Map<String, dynamic>.from(updatedContact);
      
      // Handle common string fields
      ['name', 'phone', 'category', 'type', 'interestPeriod'].forEach((key) {
        if (sanitizedContact.containsKey(key) && sanitizedContact[key] == null) {
          sanitizedContact[key] = '';
        }
      });
      
      // Handle numeric fields
      if (sanitizedContact.containsKey('interestRate') && sanitizedContact['interestRate'] == null) {
        sanitizedContact['interestRate'] = 0.0;
      }
      
      // Update the contact with sanitized data
      _contacts[index] = sanitizedContact;
      
      // Save to SharedPreferences
      await _saveContacts();
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating contact: $e');
      return false;
    }
  }
  
  // Delete a contact and optionally its transactions
  Future<bool> deleteContact(String contactId) async {
    try {
      // Find the contact index
      final index = _contacts.indexWhere((c) => c['phone'] == contactId);
      if (index < 0) {
        return false; // Contact not found
      }
      
      // Remove the contact
      _contacts.removeAt(index);
      
      // Delete associated transactions
      await deleteContactTransactions(contactId);
      
      // Save to SharedPreferences
      await _saveContacts();
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting contact: $e');
      return false;
    }
  }
  
  // Get a contact by ID
  Map<String, dynamic>? getContactById(String contactId) {
    final index = _contacts.indexWhere((c) => c['phone'] == contactId);
    if (index < 0) {
      return null;
    }
    return _contacts[index];
  }
  
  // Export all data as JSON for backup
  Future<Map<String, dynamic>> exportAllData() async {
    try {
      // Create a data structure that includes all app data
      final exportData = {
        'contacts': _contacts,
        'transactions': _contactTransactions,
        'exportDate': DateTime.now().toIso8601String(),
        'appVersion': '1.0.0', // Update with your app version
      };
      
      // Convert any DateTime objects in transactions to ISO strings
      final Map<String, List<Map<String, dynamic>>> serializedTransactions = {};
      
      _contactTransactions.forEach((contactId, transactions) {
        serializedTransactions[contactId] = transactions.map((tx) {
          final txCopy = Map<String, dynamic>.from(tx);
          if (txCopy['date'] is DateTime) {
            txCopy['date'] = txCopy['date'].toIso8601String();
          }
          return txCopy;
        }).toList();
      });
      
      exportData['transactions'] = serializedTransactions;
      
      return exportData;
    } catch (e) {
      debugPrint('Error exporting data: $e');
      return {'error': e.toString()};
    }
  }
  
  // Import data from backup JSON
  Future<bool> importAllData(Map<String, dynamic> importData) async {
    try {
      // Validate the import data
      if (!importData.containsKey('contacts') || !importData.containsKey('transactions')) {
        debugPrint('Import data is missing required fields');
        return false;
      }
      
      // Import contacts
      final contactsList = List<Map<String, dynamic>>.from(
        (importData['contacts'] as List).map((c) => Map<String, dynamic>.from(c))
      );
      
      // Import transactions
      final transactionsMap = importData['transactions'] as Map<String, dynamic>;
      final Map<String, List<Map<String, dynamic>>> parsedTransactions = {};
      
      transactionsMap.forEach((contactId, transactions) {
        parsedTransactions[contactId] = List<Map<String, dynamic>>.from(
          (transactions as List).map((tx) {
            final txMap = Map<String, dynamic>.from(tx);
            // Convert ISO date strings back to DateTime
            if (txMap['date'] is String) {
              txMap['date'] = DateTime.parse(txMap['date']);
            }
            return txMap;
          })
        );
      });
      
      // Replace the current data with imported data
      _contacts = contactsList;
      _contactTransactions = parsedTransactions;
      
      // Save the imported data to SharedPreferences
      await _saveContacts();
      await _saveTransactions();
      
      // Notify listeners of the data change
      notifyListeners();
      
      return true;
    } catch (e) {
      debugPrint('Error importing data: $e');
      return false;
    }
  }
  
  // Check if backup data exists
  Future<bool> hasBackupData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('contacts') && prefs.containsKey('transaction_contacts');
  }
  
  // Create automatic backup of data
  Future<bool> createAutomaticBackup() async {
    try {
      final backupData = await exportAllData();
      final prefs = await SharedPreferences.getInstance();
      
      // Store backup as a JSON string
      final backupString = jsonEncode(backupData);
      await prefs.setString('data_backup', backupString);
      await prefs.setString('last_backup_date', DateTime.now().toIso8601String());
      
      return true;
    } catch (e) {
      debugPrint('Error creating automatic backup: $e');
      return false;
    }
  }
  
  // Restore from automatic backup
  Future<bool> restoreFromAutomaticBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupString = prefs.getString('data_backup');
      
      if (backupString == null || backupString.isEmpty) {
        return false;
      }
      
      final backupData = jsonDecode(backupString) as Map<String, dynamic>;
      return await importAllData(backupData);
    } catch (e) {
      debugPrint('Error restoring from automatic backup: $e');
      return false;
    }
  }
} 