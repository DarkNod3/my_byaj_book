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
    _loadManualReminders();
  }
  
  // Get transactions for a specific contact
  List<Map<String, dynamic>> getTransactionsForContact(String contactId) {
    return _contactTransactions[contactId] ?? [];
  }
  
  // Get all transactions across all tools
  List<Map<String, dynamic>> getAllTransactions() {
    List<Map<String, dynamic>> allTransactions = [];
    
    // 1. Add contact transactions
    _contactTransactions.forEach((contactId, transactions) {
      final contact = getContactById(contactId);
      if (contact != null) {
        for (var tx in transactions) {
          final enrichedTx = Map<String, dynamic>.from(tx);
          enrichedTx['contactName'] = contact['name'] ?? 'Unknown';
          enrichedTx['source'] = 'contact';
          enrichedTx['contactId'] = contactId;
          enrichedTx['contactType'] = contact['type'] ?? '';
          allTransactions.add(enrichedTx);
        }
      }
    });
    
    // 2. Add loan transactions
    // Get from loan provider or stored loan transactions
    final loanTransactions = _getLoanTransactions();
    allTransactions.addAll(loanTransactions);
    
    // 3. Add card transactions
    // Get from card provider or stored card transactions
    final cardTransactions = _getCardTransactions();
    allTransactions.addAll(cardTransactions);
    
    // 4. Add bill diary transactions
    final billTransactions = _getBillTransactions();
    allTransactions.addAll(billTransactions);
    
    // 5. Add calculator transactions (EMI, Land, SIP, Tax)
    final calculatorTransactions = _getCalculatorTransactions();
    allTransactions.addAll(calculatorTransactions);
    
    // 6. Add diary transactions (Milk, Work, Tea)
    final diaryTransactions = _getDiaryTransactions();
    allTransactions.addAll(diaryTransactions);
    
    // Sort by date (newest first)
    allTransactions.sort((a, b) {
      final dateA = a['date'] as DateTime;
      final dateB = b['date'] as DateTime;
      return dateB.compareTo(dateA);
    });
    
    return allTransactions;
  }
  
  // Helper methods to get transactions from different sources
  // These would be implemented to fetch from respective providers
  // or local storage in a real app
  
  List<Map<String, dynamic>> _getLoanTransactions() {
    // This would fetch from a loan provider in a real app
    // For now, return an empty list as placeholder
    return [];
  }
  
  List<Map<String, dynamic>> _getCardTransactions() {
    // This would fetch from a card provider in a real app
    return [];
  }
  
  List<Map<String, dynamic>> _getBillTransactions() {
    // This would fetch from a bill diary provider in a real app
    return [];
  }
  
  List<Map<String, dynamic>> _getCalculatorTransactions() {
    // This would fetch calculator-related transactions
    return [];
  }
  
  List<Map<String, dynamic>> _getDiaryTransactions() {
    // This would fetch diary-related transactions
    return [];
  }
  
  // Get upcoming/due payments for notifications
  List<Map<String, dynamic>> getUpcomingPayments() {
    List<Map<String, dynamic>> upcomingPayments = [];
    final now = DateTime.now();
    
    // Add manually created reminders
    final manualReminders = _getManualReminders();
    upcomingPayments.addAll(manualReminders);
    
    // Check contact transactions for due dates
    _contacts.forEach((contact) {
      final contactId = contact['phone'] as String?;
      if (contactId == null || contactId.isEmpty) return;
      
      // Get total amount for this contact
      final balance = calculateBalance(contactId);
      
      // Skip if nothing is owed
      if (balance == 0) return;
      
      // Determine if it's a payment (you'll give) or receipt (you'll get)
      final isPayment = balance < 0;
      
      // Include only payments (amounts you owe others)
      if (isPayment) {
        // Get the most recent transaction
        final transactions = getTransactionsForContact(contactId);
        if (transactions.isEmpty) return;
        
        // Use the most recent transaction date as reference
        final lastTxDate = transactions.first['date'] as DateTime;
        
        // Calculate due date (for example, 30 days after last transaction)
        final dueDate = lastTxDate.add(const Duration(days: 30));
        
        // If due within next 7 days, add to upcoming payments
        if (dueDate.isAfter(now) && dueDate.isBefore(now.add(const Duration(days: 7)))) {
          upcomingPayments.add({
            'title': 'Payment to ${contact['name']}',
            'amount': balance.abs(),
            'dueDate': dueDate,
            'daysLeft': dueDate.difference(now).inDays,
            'contactId': contactId,
            'type': 'contact_payment',
            'isCompleted': false,
          });
        }
      }
    });
    
    // Add credit card payment reminders
    try {
      // Get all cards from SharedPreferences
      final prefs = SharedPreferences.getInstance();
      String? cardsJson;
      prefs.then((sharedPrefs) {
        cardsJson = sharedPrefs.getString('cards');
        if (cardsJson != null) {
          final List<dynamic> cards = jsonDecode(cardsJson!);
          
          // Process each card
          for (int i = 0; i < cards.length; i++) {
            final card = cards[i];
            
            // Skip cards without due date
            if (card['dueDate'] == null || card['dueDate'] == 'N/A') continue;
            
            // Parse the balance amount
            final String balanceStr = card['balance'].toString().replaceAll('₹', '').replaceAll(',', '').trim();
            final double balance = double.tryParse(balanceStr) ?? 0.0;
            if (balance <= 0) continue;
            
            try {
              // Parse the due date
              final String dueDateStr = card['dueDate'];
              final parts = dueDateStr.split(' ');
              
              if (parts.length >= 3) {
                final int day = int.tryParse(parts[0]) ?? 1;
                final String monthName = parts[1].replaceAll(',', '');
                
                // Get month number
                final List<String> monthNames = [
                  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                ];
                final int month = monthNames.indexOf(monthName) + 1;
                
                // Create date for current month's due date
                DateTime dueDate = DateTime(now.year, now.month, day);
                
                // If the day has already passed, use next month
                if (dueDate.isBefore(now)) {
                  dueDate = DateTime(now.year, now.month + 1, day);
                }
                
                // Calculate days left
                final int daysLeft = dueDate.difference(now).inDays;
                
                // Only add cards that are due within the next 30 days
                if (daysLeft <= 30) {
                  upcomingPayments.add({
                    'title': '${card['bank']} Card Payment',
                    'amount': balance,
                    'dueDate': dueDate,
                    'daysLeft': daysLeft,
                    'cardIndex': i,
                    'type': 'card_payment',
                    'isCompleted': false,
                  });
                }
              }
            } catch (e) {
              print('Error creating card reminder: $e');
            }
          }
        }
      });
    } catch (e) {
      print('Error fetching cards for reminders: $e');
    }
    
    // Sort by due date (closest first)
    upcomingPayments.sort((a, b) => 
      (a['daysLeft'] as int).compareTo(b['daysLeft'] as int));
    
    return upcomingPayments;
  }
  
  // Get manually created reminders
  List<Map<String, dynamic>> _getManualReminders() {
    final prefs = SharedPreferences.getInstance();
    
    try {
      final manualReminders = _manualReminders.map((reminder) {
        // Update days left calculation each time
        final dueDate = reminder['dueDate'] as DateTime;
        final daysLeft = dueDate.difference(DateTime.now()).inDays;
        
        // Create a copy with updated days left
        final updatedReminder = Map<String, dynamic>.from(reminder);
        updatedReminder['daysLeft'] = daysLeft;
        
        return updatedReminder;
      }).toList();
      
      return manualReminders;
    } catch (e) {
      return [];
    }
  }
  
  // Store for manual reminders
  List<Map<String, dynamic>> _manualReminders = [];
  
  // Public getter for manual reminders
  List<Map<String, dynamic>> get manualReminders => _manualReminders;
  
  // Add a manual reminder
  Future<bool> addManualReminder(Map<String, dynamic> reminder) async {
    try {
      // Add to list
      _manualReminders.add(reminder);
      
      // Save to storage
      await _saveManualReminders();
      
      // Notify listeners
      notifyListeners();
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Mark manual reminder as completed
  Future<bool> updateManualReminderStatus(int index, bool isCompleted) async {
    try {
      if (index >= 0 && index < _manualReminders.length) {
        _manualReminders[index]['isCompleted'] = isCompleted;
        
        // Save to storage
        await _saveManualReminders();
        
        // Notify listeners
        notifyListeners();
        
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // Delete a manual reminder
  Future<bool> deleteManualReminder(int index) async {
    try {
      if (index >= 0 && index < _manualReminders.length) {
        _manualReminders.removeAt(index);
        
        // Save to storage
        await _saveManualReminders();
        
        // Notify listeners
        notifyListeners();
        
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // Save manual reminders to SharedPreferences
  Future<void> _saveManualReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert DateTime objects to strings for serialization
      final serializedReminders = _manualReminders.map((reminder) {
        final reminderCopy = Map<String, dynamic>.from(reminder);
        if (reminderCopy['dueDate'] is DateTime) {
          reminderCopy['dueDate'] = reminderCopy['dueDate'].toIso8601String();
        }
        return jsonEncode(reminderCopy);
      }).toList();
      
      await prefs.setStringList('manual_reminders', serializedReminders);
    } catch (e) {
      // Handle error silently
    }
  }
  
  // Load manual reminders from SharedPreferences
  Future<void> _loadManualReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serializedReminders = prefs.getStringList('manual_reminders') ?? [];
      
      _manualReminders = serializedReminders.map((jsonStr) {
        final Map<String, dynamic> reminder = Map<String, dynamic>.from(jsonDecode(jsonStr));
        
        // Convert date string back to DateTime
        if (reminder['dueDate'] is String) {
          reminder['dueDate'] = DateTime.parse(reminder['dueDate']);
        }
        
        // Update days left calculation
        final dueDate = reminder['dueDate'] as DateTime;
        reminder['daysLeft'] = dueDate.difference(DateTime.now()).inDays;
        
        return reminder;
      }).toList();
      
    } catch (e) {
      // Handle error silently
    }
  }
  
  // Add a transaction
  Future<void> addTransaction(String contactId, Map<String, dynamic> transaction) async {
    if (!_contactTransactions.containsKey(contactId)) {
      _contactTransactions[contactId] = [];
    }
    
    // Add to start of the list (newest first)
    _contactTransactions[contactId]!.insert(0, transaction);
    
    // Update lastEditedAt timestamp in the associated contact
    final contactIndex = _contacts.indexWhere((contact) => contact['phone'] == contactId);
    if (contactIndex != -1) {
      final contact = _contacts[contactIndex];
      
      // Get the transaction date or use current time
      final DateTime txDate = transaction['date'] is DateTime ? 
                             transaction['date'] as DateTime : 
                             DateTime.now();
      
      // Update lastEditedAt timestamp
      contact['lastEditedAt'] = txDate;
      
      // Save the updated contact
      _contacts[contactIndex] = contact;
      await _saveContacts();
    }
    
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
    // print('DEBUG - Added transaction to $contactId: $transaction');
    // debugPrintAllTransactions();
  }
  
  // Update a transaction
  Future<void> updateTransaction(String contactId, int index, Map<String, dynamic> updatedTransaction) async {
    if (_contactTransactions.containsKey(contactId) && 
        index >= 0 && 
        index < _contactTransactions[contactId]!.length) {
      _contactTransactions[contactId]![index] = updatedTransaction;
      
      // Update lastEditedAt timestamp in the associated contact
      final contactIndex = _contacts.indexWhere((contact) => contact['phone'] == contactId);
      if (contactIndex != -1) {
        final contact = _contacts[contactIndex];
        
        // Update lastEditedAt to current time (edited just now)
        contact['lastEditedAt'] = DateTime.now();
        
        // Save the updated contact
        _contacts[contactIndex] = contact;
        await _saveContacts();
      }
      
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
    
    // Create a backup immediately after saving transactions
    await createAutomaticBackup();
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
        
        // Sort transactions by date (newest first)
        _contactTransactions[contactId]!.sort((a, b) {
          final dateA = a['date'] as DateTime;
          final dateB = b['date'] as DateTime;
          return dateB.compareTo(dateA); // Descending order (newest first)
        });
      }
      
      // Notify listeners
      notifyListeners();
    } catch (e) {
      // Log the error without using debug print
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
      
      _contacts = contactsJson.map((jsonStr) {
        final Map<String, dynamic> contact = Map<String, dynamic>.from(jsonDecode(jsonStr));
        
        // Convert color value back to Color object
        if (contact['color'] != null && contact['color'] is int) {
          contact['color'] = Color(contact['color'] as int);
        }
        
        // Make sure tabType field exists for each contact
        if (!contact.containsKey('tabType')) {
          // Determine tabType based on interest rate or type
          if (contact.containsKey('interestRate') || contact.containsKey('type')) {
            contact['tabType'] = 'withInterest';
          } else {
            contact['tabType'] = 'withoutInterest';
          }
        }
        
        return contact;
      }).toList();
      
      // Notify listeners
      notifyListeners();
    } catch (e) {
      // Log the error without using debug print
    }
  }
  
  // Save contacts to SharedPreferences
  Future<void> _saveContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert contacts to JSON-friendly format
      final List<String> contactsJson = _contacts.map((contact) {
        // Make a copy of the contact to avoid modifying the original
        final Map<String, dynamic> contactCopy = Map<String, dynamic>.from(contact);
        
        // Convert Colors to hex strings if present
        if (contactCopy['color'] != null && contactCopy['color'] is Color) {
          final Color color = contactCopy['color'] as Color;
          contactCopy['color'] = color.value; // Store color as int value
        }
        
        // Ensure tabType is set
        if (!contactCopy.containsKey('tabType')) {
          if (contactCopy.containsKey('interestRate') || contactCopy.containsKey('type')) {
            contactCopy['tabType'] = 'withInterest';
          } else {
            contactCopy['tabType'] = 'withoutInterest';
          }
        }
        
        return jsonEncode(contactCopy);
      }).toList();
      
      await prefs.setStringList('contacts', contactsJson);
      // Notify listeners
      notifyListeners();
      
      // Create a backup immediately after saving contacts
      await createAutomaticBackup();
    } catch (e) {
      // Log the error without using debug print
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
      // Log the error without using debug print
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
      // Log the error without using debug print
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
      // Log the error without using debug print
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
      // Log the error without using debug print
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
      // Log the error without using debug print
      return {'error': e.toString()};
    }
  }
  
  // Import data from backup JSON
  Future<bool> importAllData(Map<String, dynamic> importData) async {
    try {
      // Validate the import data
      if (!importData.containsKey('contacts') || !importData.containsKey('transactions')) {
        // Log the error without using debug print
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
      // Log the error without using debug print
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
      // Log the error without using debug print
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
      // Log the error without using debug print
      return false;
    }
  }
} 