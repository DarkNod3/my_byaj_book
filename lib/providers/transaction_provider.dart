import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class TransactionProvider extends ChangeNotifier {
  // Map of contactId -> list of transactions
  Map<String, List<Map<String, dynamic>>> _contactTransactions = {};
  
  // UUID generator
  final _uuid = const Uuid();
  
  // Constructor
  TransactionProvider() {
    // Changed to sequentially await each operation with single notification at the end
    _initializeProvider();
  }
  
  // New method for sequential initialization
  Future<void> _initializeProvider() async {
    try {
      // First attempt to load data
      await _loadData();
      
      // Set up a delayed reload to ensure data is fully loaded
      // This helps when the app is first launched and SharedPreferences might be slow
      Future.delayed(const Duration(milliseconds: 300), () {
        // Check if data loaded properly
        if (_contacts.isEmpty) {
          _loadData(notifyChanges: true);
        }
        
        // Always recalculate interest values to ensure they're up to date
        _recalculateInterestValues();
        
        // Notify listeners again after everything is loaded
        notifyListeners();
      });
    } catch (e) {
      print('Error initializing TransactionProvider: $e');
      
      // Attempt to reload data after a short delay
      Future.delayed(const Duration(seconds: 1), () {
        _loadData(notifyChanges: true);
      });
    }
  }
  
  // Helper method to load all data
  Future<void> _loadData({bool notifyChanges = false}) async {
    try {
      // Load data in sequence
      await _loadContacts();
      await _loadTransactions();
      await _loadManualReminders();
      await _ensureContactTransactionSynchronization(notifyChanges: false);
      await _recalculateInterestValues();
      
      // Notify listeners only once if requested
      if (notifyChanges) {
        notifyListeners();
      } else {
        // Always notify at least once during initial load
        notifyListeners();
      }
    } catch (e) {
      print('Error loading data: $e');
      // Still notify listeners even if there was an error
      // This ensures the UI gets updated with whatever data was loaded
      notifyListeners();
    }
  }
  
  // Ensure contact transactions are synchronized
  Future<void> _ensureContactTransactionSynchronization({bool notifyChanges = true}) async {
    try {
      // Get list of contacts and check if their transactions are loaded
      final prefs = await SharedPreferences.getInstance();
      final contactIds = prefs.getStringList('transaction_contacts') ?? [];
      
      bool dataChanged = false;
      
      // For each contact ID that has transactions, make sure it's in our contacts list
      for (final contactId in contactIds) {
        // Check if we have this contact in our contacts list
        final contactIndex = _contacts.indexWhere((c) => c['phone'] == contactId);
        
        // If contact is not found but has transactions, try to reload transactions
        if (contactIndex < 0) {
          // Contact might be missing but transactions exist, load them anyway
          final serializedTransactions = prefs.getStringList('transactions_$contactId') ?? [];
          
          if (serializedTransactions.isNotEmpty) {
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
            
            dataChanged = true;
          }
        } else {
          // Contact exists but check if transactions are loaded properly
          if (!_contactTransactions.containsKey(contactId)) {
            // Transactions not loaded, load them now
            final serializedTransactions = prefs.getStringList('transactions_$contactId') ?? [];
            
            if (serializedTransactions.isNotEmpty) {
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
              
              dataChanged = true;
            }
          }
        }
      }
      
      // Also check for contacts that have empty transaction lists and create them
      for (final contact in _contacts) {
        final contactId = contact['phone'] as String?;
        if (contactId != null && contactId.isNotEmpty && !_contactTransactions.containsKey(contactId)) {
          _contactTransactions[contactId] = [];
          dataChanged = true;
        }
      }
      
      // Notify listeners if data changed and notifyChanges is true
      if (dataChanged && notifyChanges) {
        notifyListeners();
      }
    } catch (e) {
      // Handle error silently
    }
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
    for (var contact in _contacts) {
      final contactId = contact['phone'] as String?;
      if (contactId == null || contactId.isEmpty) continue;
      
      // Get total amount for this contact
      final balance = calculateBalance(contactId);
      
      // Skip if nothing is owed
      if (balance == 0) continue;
      
      // Determine if it's a payment (you'll give) or receipt (you'll get)
      final isPayment = balance < 0;
      
      // Include only payments (amounts you owe others)
      if (isPayment) {
        // Get the most recent transaction
        final transactions = getTransactionsForContact(contactId);
        if (transactions.isEmpty) continue;
        
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
    }
    
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
              // Removed debug print
            }
          }
        }
      });
    } catch (e) {
      // Removed debug print
    }
    
    // Sort by due date (closest first)
    upcomingPayments.sort((a, b) => 
      (a['daysLeft'] as int).compareTo(b['daysLeft'] as int));
    
    return upcomingPayments;
  }
  
  // Get manually created reminders
  List<Map<String, dynamic>> _getManualReminders() {
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
      // Generate a unique ID for this reminder
      reminder['id'] = _uuid.v4();
      
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
    // Ensure transaction has createdAt timestamp
    if (!transaction.containsKey('createdAt')) {
      transaction['createdAt'] = DateTime.now().millisecondsSinceEpoch;
    }
    
    // Initialize transaction list for this contact if needed
    if (!_contactTransactions.containsKey(contactId)) {
      _contactTransactions[contactId] = [];
    }
    
    // Ensure note is never null
    if (transaction['note'] == null) {
      transaction['note'] = transaction['type'] == 'gave' ? 'Payment sent' : 'Payment received';
    }
    
    // Add to memory
    _contactTransactions[contactId]!.add(transaction);
    
    // Save to preferences immediately to ensure persistence
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
    
    // Removed debug print comments
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
      // Remove from memory immediately
      _contactTransactions[contactId]!.removeAt(index);
      
      // Update lastEditedAt timestamp in the associated contact to keep it active
      final contactIndex = _contacts.indexWhere((contact) => contact['phone'] == contactId);
      if (contactIndex != -1) {
        final contact = _contacts[contactIndex];
        
        // Update lastEditedAt to current time
        contact['lastEditedAt'] = DateTime.now();
        
        // Save the updated contact
        _contacts[contactIndex] = contact;
        await _saveContacts();
      }
      
      // Save to preferences to ensure permanent deletion
      await _saveTransactions();
      
      // Create automatic backup to ensure consistency
      await createAutomaticBackup();
      
      // Notify listeners
      notifyListeners();
    }
  }
  
  // Delete all transactions for a contact
  Future<void> deleteContactTransactions(String contactId) async {
    if (_contactTransactions.containsKey(contactId)) {
      // Clear the transactions but keep an empty list to maintain the contact
      _contactTransactions[contactId] = [];
      
      // Update lastEditedAt timestamp in the associated contact to keep it active
      final contactIndex = _contacts.indexWhere((contact) => contact['phone'] == contactId);
      if (contactIndex != -1) {
        final contact = _contacts[contactIndex];
        
        // Update lastEditedAt to current time
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
        
        // Ensure note is never null
        if (txCopy['note'] == null) {
          txCopy['note'] = '';
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
          
          // Ensure note is never null
          if (txMap['note'] == null) {
            txMap['note'] = '';
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
      
      // Removed notifyListeners() call from here to prevent multiple notifications
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
        
        // Convert lastEditedAt DateTime if it exists
        if (contact.containsKey('lastEditedAt') && contact['lastEditedAt'] is String) {
          try {
            contact['lastEditedAt'] = DateTime.parse(contact['lastEditedAt']);
          } catch (e) {
            // If parsing fails, set to current time
            contact['lastEditedAt'] = DateTime.now();
          }
        } else if (!contact.containsKey('lastEditedAt') || contact['lastEditedAt'] == null) {
          // Ensure lastEditedAt exists
          contact['lastEditedAt'] = DateTime.now();
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
        
        // Ensure interest fields are properly initialized
        if (contact['tabType'] == 'withInterest') {
          // Make sure interestRate exists and is a double
          if (!contact.containsKey('interestRate') || contact['interestRate'] == null) {
            contact['interestRate'] = 0.0;
          } else if (contact['interestRate'] is int) {
            contact['interestRate'] = (contact['interestRate'] as int).toDouble();
          }
          
          // Make sure interestPeriod exists
          if (!contact.containsKey('interestPeriod') || contact['interestPeriod'] == null) {
            contact['interestPeriod'] = 'monthly';
          }
          
          // Make sure relationship type exists
          if (!contact.containsKey('type') || contact['type'] == null) {
            contact['type'] = 'borrower';
          }
          
          // Initialize interest due for display
          if (!contact.containsKey('interestDue') || contact['interestDue'] == null) {
            contact['interestDue'] = 0.0;
          }
        }
        
        return contact;
      }).toList();
    } catch (e) {
      // Log the error without using debug print
      print('Error loading contacts: $e');
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

        // Ensure lastEditedAt is converted to ISO string
        if (contactCopy['lastEditedAt'] != null && contactCopy['lastEditedAt'] is DateTime) {
          contactCopy['lastEditedAt'] = contactCopy['lastEditedAt'].toIso8601String();
        }
        
        // Ensure tabType is set
        if (!contactCopy.containsKey('tabType')) {
          if (contactCopy.containsKey('interestRate') || contactCopy.containsKey('type')) {
            contactCopy['tabType'] = 'withInterest';
          } else {
            contactCopy['tabType'] = 'withoutInterest';
          }
        }
        
        // Ensure interest fields are properly serialized
        if (contactCopy['tabType'] == 'withInterest') {
          // Make sure interestRate exists and is a number
          if (!contactCopy.containsKey('interestRate') || contactCopy['interestRate'] == null) {
            contactCopy['interestRate'] = 0.0;
          }
          
          // Make sure interestPeriod exists
          if (!contactCopy.containsKey('interestPeriod') || contactCopy['interestPeriod'] == null) {
            contactCopy['interestPeriod'] = 'monthly';
          }
          
          // Make sure relationship type exists
          if (!contactCopy.containsKey('type') || contactCopy['type'] == null) {
            contactCopy['type'] = 'borrower';
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
      print('Error saving contacts: $e');
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
      for (var key in ['name', 'phone', 'category', 'type', 'interestPeriod']) {
        if (sanitizedContact.containsKey(key) && sanitizedContact[key] == null) {
          sanitizedContact[key] = '';
        }
      }
      
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
        // Contact already exists, ensure contact data is up to date
        final existingContact = _contacts[existingIndex];
        
        // Update fields if needed (e.g., name might have changed)
        bool hasChanges = false;
        final updateContact = Map<String, dynamic>.from(existingContact);
        
        // Check basic fields to update
        for (var key in ['name', 'category', 'type', 'interestPeriod', 'interestRate', 'tabType']) {
          if (contact.containsKey(key) && contact[key] != existingContact[key]) {
            updateContact[key] = contact[key];
            hasChanges = true;
          }
        }
        
        // If changes detected, update the contact
        if (hasChanges) {
          _contacts[existingIndex] = updateContact;
          await _saveContacts();
        }
        
        // Make sure transactions are loaded for this contact
        await _ensureTransactionsLoaded(contactId);
        
        return true;
      }
      
      // Sanitize the contact data to prevent null values
      final sanitizedContact = Map<String, dynamic>.from(contact);
      
      // Handle common string fields
      for (var key in ['name', 'phone', 'category', 'type', 'interestPeriod']) {
        if (sanitizedContact.containsKey(key) && sanitizedContact[key] == null) {
          sanitizedContact[key] = '';
        }
      }
      
      // Handle numeric fields
      if (sanitizedContact.containsKey('interestRate') && sanitizedContact['interestRate'] == null) {
        sanitizedContact['interestRate'] = 0.0;
      }
      
      // Ensure the contact has a tabType
      if (!sanitizedContact.containsKey('tabType')) {
        if (sanitizedContact.containsKey('interestRate') || 
            (sanitizedContact.containsKey('type') && sanitizedContact['type'] != null && 
             sanitizedContact['type'].toString().isNotEmpty)) {
          sanitizedContact['tabType'] = 'withInterest';
        } else {
          sanitizedContact['tabType'] = 'withoutInterest';
        }
      }
      
      // Add the sanitized contact since it doesn't exist
      _contacts.add(sanitizedContact);
      
      // Check if there are existing transactions for this contact ID
      await _ensureTransactionsLoaded(contactId);
      
      // Save to SharedPreferences
      await _saveContacts();
      
      notifyListeners();
      return true;
    } catch (e) {
      // Log the error without using debug print
      return false;
    }
  }
  
  // Helper method to ensure transactions are loaded for a contact
  Future<void> _ensureTransactionsLoaded(String contactId) async {
    // Check if transactions are already loaded
    if (_contactTransactions.containsKey(contactId)) {
      return;
    }
    
    try {
      // Try to load transactions for this contact
      final prefs = await SharedPreferences.getInstance();
      final serializedTransactions = prefs.getStringList('transactions_$contactId') ?? [];
      
      if (serializedTransactions.isNotEmpty) {
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
      } else {
        // Initialize with empty list if no transactions found
        _contactTransactions[contactId] = [];
      }
    } catch (e) {
      // If error loading, initialize with empty list
      _contactTransactions[contactId] = [];
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
      for (var key in ['name', 'phone', 'category', 'type', 'interestPeriod']) {
        if (sanitizedContact.containsKey(key) && sanitizedContact[key] == null) {
          sanitizedContact[key] = '';
        }
      }
      
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
      
      // Delete entries from milk diary
      await _cleanupMilkDiaryEntries(contactId);
      
      // Save to SharedPreferences
      await _saveContacts();
      
      notifyListeners();
      return true;
    } catch (e) {
      // Log the error without using debug print
      return false;
    }
  }
  
  // Clean up milk diary entries for a deleted contact
  Future<void> _cleanupMilkDiaryEntries(String contactId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clean up milk sellers
      final sellersJson = prefs.getString('milk_sellers');
      if (sellersJson != null) {
        final sellers = jsonDecode(sellersJson) as List;
        final updatedSellers = sellers.where((seller) => 
          seller['id'] != contactId && seller['mobile'] != contactId).toList();
        
        // Save updated sellers list
        await prefs.setString('milk_sellers', jsonEncode(updatedSellers));
      }
      
      // Clean up milk entries
      final entriesJson = prefs.getString('milk_entries');
      if (entriesJson != null) {
        final entries = jsonDecode(entriesJson) as List;
        final updatedEntries = entries.where((entry) => 
          entry['sellerId'] != contactId).toList();
        
        // Save updated entries list
        await prefs.setString('milk_entries', jsonEncode(updatedEntries));
      }
      
      // Clean up milk payments
      final paymentsJson = prefs.getString('milk_payments');
      if (paymentsJson != null) {
        final payments = jsonDecode(paymentsJson) as List;
        final updatedPayments = payments.where((payment) => 
          payment['sellerId'] != contactId).toList();
        
        // Save updated payments list
        await prefs.setString('milk_payments', jsonEncode(updatedPayments));
      }
    } catch (e) {
      // Silently handle errors
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
  
  // Add a method to recalculate interest values
  Future<void> _recalculateInterestValues() async {
    try {
      // Loop through all contacts with interest
      for (var contact in _contacts) {
        // Skip non-interest contacts
        if (contact['tabType'] != 'withInterest') continue;
        
        final String contactId = contact['phone'] ?? '';
        if (contactId.isEmpty) continue;
        
        // Get transactions for this contact
        final transactions = getTransactionsForContact(contactId);
        if (transactions.isEmpty) continue;
        
        // Get contact type and initial values
        final String contactType = contact['type'] as String? ?? 'borrower';
        final double interestRate = contact['interestRate'] as double? ?? 12.0;
        final bool isMonthly = contact['interestPeriod'] == 'monthly';
        
        // Sort transactions chronologically for accurate interest calculation
        transactions.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
        
        // Calculate interest using the transaction history
        DateTime? lastInterestDate = transactions.first['date'] as DateTime;
        double runningPrincipal = 0.0;
        double accumulatedInterest = 0.0;
        double interestPaid = 0.0;
        
        // Process all transactions
        for (var tx in transactions) {
          final txDate = tx['date'] as DateTime;
          final amount = tx['amount'] as double;
          final isGave = tx['type'] == 'gave';
          final isInterestPayment = tx['isInterestPayment'] == true;
          
          if (isInterestPayment) {
            // Handle interest payment
            if (contactType == 'borrower' && !isGave) {
              // Borrower paid interest
              interestPaid += amount;
            } else if (contactType == 'lender' && isGave) {
              // User paid interest to lender
              interestPaid += amount;
            }
          } else {
            // Calculate interest for the period
            if (lastInterestDate != null && runningPrincipal > 0) {
              // Calculate interest based on principal and days
              double interestForPeriod = 0.0;

              if (isMonthly) {
                // Monthly rate calculation
                int completeMonths = 0;
                DateTime tempDate = DateTime(lastInterestDate.year, lastInterestDate.month, lastInterestDate.day);
                
                while (true) {
                  DateTime nextMonth = DateTime(tempDate.year, tempDate.month + 1, tempDate.day);
                  if (nextMonth.isAfter(txDate)) break;
                  
                  completeMonths++;
                  tempDate = nextMonth;
                }
                
                if (completeMonths > 0) {
                  interestForPeriod += runningPrincipal * (interestRate / 100) * completeMonths;
                }
                
                final remainingDays = txDate.difference(tempDate).inDays;
                if (remainingDays > 0) {
                  final daysInMonth = DateTime(tempDate.year, tempDate.month + 1, 0).day;
                  double monthProportion = remainingDays / daysInMonth;
                  interestForPeriod += runningPrincipal * (interestRate / 100) * monthProportion;
                }
              } else {
                // Yearly rate converted to monthly
                double monthlyRate = interestRate / 12;
                
                int completeMonths = 0;
                DateTime tempDate = DateTime(lastInterestDate.year, lastInterestDate.month, lastInterestDate.day);
                
                while (true) {
                  DateTime nextMonth = DateTime(tempDate.year, tempDate.month + 1, tempDate.day);
                  if (nextMonth.isAfter(txDate)) break;
                  
                  completeMonths++;
                  tempDate = nextMonth;
                }
                
                if (completeMonths > 0) {
                  interestForPeriod += runningPrincipal * (monthlyRate / 100) * completeMonths;
                }
                
                final remainingDays = txDate.difference(tempDate).inDays;
                if (remainingDays > 0) {
                  final daysInMonth = DateTime(tempDate.year, tempDate.month + 1, 0).day;
                  double monthProportion = remainingDays / daysInMonth;
                  interestForPeriod += runningPrincipal * (monthlyRate / 100) * monthProportion;
                }
              }
              
              accumulatedInterest += interestForPeriod;
            }
            
            // Adjust principal based on transaction type
            if (isGave) {
              if (contactType == 'borrower') {
                runningPrincipal += amount;
              } else {
                runningPrincipal = (runningPrincipal - amount > 0) ? runningPrincipal - amount : 0;
              }
            } else {
              if (contactType == 'borrower') {
                runningPrincipal = (runningPrincipal - amount > 0) ? runningPrincipal - amount : 0;
              } else {
                runningPrincipal += amount;
              }
            }
            
            lastInterestDate = txDate;
          }
        }
        
        // Calculate interest from last transaction to now
        if (lastInterestDate != null && runningPrincipal > 0) {
          double interestFromLastTx = 0.0;
          final now = DateTime.now();
          
          if (isMonthly) {
            int completeMonths = 0;
            DateTime tempDate = DateTime(lastInterestDate.year, lastInterestDate.month, lastInterestDate.day);
            
            while (true) {
              DateTime nextMonth = DateTime(tempDate.year, tempDate.month + 1, tempDate.day);
              if (nextMonth.isAfter(now)) break;
              
              completeMonths++;
              tempDate = nextMonth;
            }
            
            if (completeMonths > 0) {
              interestFromLastTx += runningPrincipal * (interestRate / 100) * completeMonths;
            }
            
            final remainingDays = now.difference(tempDate).inDays;
            if (remainingDays > 0) {
              final daysInMonth = DateTime(tempDate.year, tempDate.month + 1, 0).day;
              double monthProportion = remainingDays / daysInMonth;
              interestFromLastTx += runningPrincipal * (interestRate / 100) * monthProportion;
            }
          } else {
            double monthlyRate = interestRate / 12;
            
            int completeMonths = 0;
            DateTime tempDate = DateTime(lastInterestDate.year, lastInterestDate.month, lastInterestDate.day);
            
            while (true) {
              DateTime nextMonth = DateTime(tempDate.year, tempDate.month + 1, tempDate.day);
              if (nextMonth.isAfter(now)) break;
              
              completeMonths++;
              tempDate = nextMonth;
            }
            
            if (completeMonths > 0) {
              interestFromLastTx += runningPrincipal * (monthlyRate / 100) * completeMonths;
            }
            
            final remainingDays = now.difference(tempDate).inDays;
            if (remainingDays > 0) {
              final daysInMonth = DateTime(tempDate.year, tempDate.month + 1, 0).day;
              double monthProportion = remainingDays / daysInMonth;
              interestFromLastTx += runningPrincipal * (monthlyRate / 100) * monthProportion;
            }
          }
          
          accumulatedInterest += interestFromLastTx;
        }
        
        // Adjust for interest already paid
        double totalInterestDue = (accumulatedInterest - interestPaid > 0) ? accumulatedInterest - interestPaid : 0;
        
        // Update contact with calculated values
        contact['interestDue'] = totalInterestDue;
        contact['principal'] = runningPrincipal;
        contact['displayAmount'] = runningPrincipal + totalInterestDue;
        
        // Ensure we save these values
        _saveContacts();
      }
    } catch (e) {
      print('Error recalculating interest: $e');
    }
  }
} 