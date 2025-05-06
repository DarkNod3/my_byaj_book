import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_byaj_book/widgets/header/app_header.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io'; // Use dart:io instead of file package

class TeaDiaryScreen extends StatefulWidget {
  static const routeName = '/tea-diary';
  final bool showAppBar;

  const TeaDiaryScreen({Key? key, this.showAppBar = true}) : super(key: key);

  @override
  State<TeaDiaryScreen> createState() => _TeaDiaryScreenState();
}

class _TeaDiaryScreenState extends State<TeaDiaryScreen> with SingleTickerProviderStateMixin {
  // Store all customers across all dates
  final List<Customer> _allCustomers = [];
  
  // Filtered customers for the selected date
  List<Customer> _customersForSelectedDate = [];
  
  // Filtered customers for search
  List<Customer> _filteredCustomers = [];
  
  int _totalCups = 0;
  double _totalAmount = 0;
  double _collectedAmount = 0;
  double _remainingAmount = 0;
  DateTime _selectedDate = DateTime.now();
  late AnimationController _counterAnimationController;
  final TextEditingController _searchController = TextEditingController();
  
  // Sorting options
  String _sortBy = 'recent'; // 'recent', 'name', 'amount', 'cups'
  
  @override
  void initState() {
    super.initState();
    _counterAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Load saved data
    _loadCustomers();
    
    // Check if it's a new day compared to the last time the app was used
    _checkForDayChange();
    
    // Add search listener
    _searchController.addListener(_filterCustomers);
  }

  // New method to check if the day has changed since last app use
  Future<void> _checkForDayChange() async {
    final prefs = await SharedPreferences.getInstance();
    final String? lastUsedDateStr = prefs.getString('lastUsedDate');
    
    if (lastUsedDateStr != null) {
      final DateTime lastUsedDate = DateTime.parse(lastUsedDateStr);
      final DateTime now = DateTime.now();
      
      // Check if it's a different day
      if (lastUsedDate.day != now.day || 
          lastUsedDate.month != now.month ||
          lastUsedDate.year != now.year) {
        // Reset cups if it's a new day
        _resetDailyCups();
      }
    }
    
    // Update last used date to today
    prefs.setString('lastUsedDate', DateTime.now().toIso8601String());
  }

  // Save customers to shared preferences
  Future<void> _saveCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> customersJson = _allCustomers.map((customer) => jsonEncode({
      'id': customer.id,
      'name': customer.name,
      'phoneNumber': customer.phoneNumber,
      'cups': customer.cups,
      'teaRate': customer.teaRate,
      'coffeeRate': customer.coffeeRate,
      'milkRate': customer.milkRate,
      'totalAmount': customer.totalAmount,
      'paymentsMade': customer.paymentsMade,
      'date': customer.date.toIso8601String(),
      'lastUpdated': customer.lastUpdated.toIso8601String(),
      'history': customer.history.map((entry) => {
        'type': entry.type.index,
        'cups': entry.cups,
        'amount': entry.amount,
        'timestamp': entry.timestamp.toIso8601String(),
        'beverageType': entry.beverageType,
      }).toList(),
    })).toList();
    
    await prefs.setStringList('customers', customersJson);
  }

  // Load customers from shared preferences
  Future<void> _loadCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? customersJson = prefs.getStringList('customers');
    
    if (customersJson != null) {
      setState(() {
        _allCustomers.clear();
        for (final json in customersJson) {
          final Map<String, dynamic> data = jsonDecode(json);
          
          final List<CustomerEntry> history = [];
          if (data['history'] != null) {
            for (final Map<String, dynamic> entryData in data['history']) {
              history.add(CustomerEntry(
                type: EntryType.values[entryData['type']],
                cups: entryData['cups'],
                amount: entryData['amount'],
                timestamp: DateTime.parse(entryData['timestamp']),
                beverageType: entryData['beverageType'],
              ));
            }
          }
          
          _allCustomers.add(Customer(
            id: data['id'],
            name: data['name'],
            phoneNumber: data['phoneNumber'], // No need for default value, it's now optional
            cups: data['cups'],
            teaRate: data['teaRate'],
            coffeeRate: data['coffeeRate'] ?? 0.0,
            milkRate: data['milkRate'] ?? 0.0,
            totalAmount: data['totalAmount'],
            paymentsMade: data['paymentsMade'],
            date: DateTime.parse(data['date']),
            lastUpdated: DateTime.parse(data['lastUpdated']),
            history: history,
          ));
        }
    
    _filterDataBySelectedDate();
    _updateTotals();
    _filteredCustomers = List.from(_customersForSelectedDate);
        _sortCustomers();
      });
    }
  }
  
  @override
  void dispose() {
    _counterAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  // Sort customers based on selected option
  void _sortCustomers() {
    setState(() {
      switch (_sortBy) {
        case 'recent':
          _filteredCustomers.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
          break;
        case 'name':
          _filteredCustomers.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'amount':
          _filteredCustomers.sort((a, b) => (b.totalAmount - b.paymentsMade)
              .compareTo(a.totalAmount - a.paymentsMade));
          break;
        case 'cups':
          _filteredCustomers.sort((a, b) => b.cups.compareTo(a.cups));
          break;
      }
    });
  }
  
  // Show sort options menu
  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Sort Customers By',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.access_time, 
                  color: _sortBy == 'recent' ? Colors.teal : Colors.grey,
                ),
                title: const Text('Most Recent'),
                selected: _sortBy == 'recent',
                selectedColor: Colors.teal,
                onTap: () {
                  setState(() {
                    _sortBy = 'recent';
                    _sortCustomers();
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.sort_by_alpha, 
                  color: _sortBy == 'name' ? Colors.teal : Colors.grey,
                ),
                title: const Text('Name (A-Z)'),
                selected: _sortBy == 'name',
                selectedColor: Colors.teal,
                onTap: () {
                  setState(() {
                    _sortBy = 'name';
                    _sortCustomers();
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.money, 
                  color: _sortBy == 'amount' ? Colors.teal : Colors.grey,
                ),
                title: const Text('Amount (High to Low)'),
                selected: _sortBy == 'amount',
                selectedColor: Colors.teal,
                onTap: () {
                  setState(() {
                    _sortBy = 'amount';
                    _sortCustomers();
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.local_cafe, 
                  color: _sortBy == 'cups' ? Colors.teal : Colors.grey,
                ),
                title: const Text('Cups (High to Low)'),
                selected: _sortBy == 'cups',
                selectedColor: Colors.teal,
                onTap: () {
                  setState(() {
                    _sortBy = 'cups';
                    _sortCustomers();
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Filter customers by the selected date
  void _filterDataBySelectedDate() {
    setState(() {
      // Show all customers for all dates - don't filter by date anymore
      _customersForSelectedDate = _allCustomers.toList();
      
      // Also update the filtered customers for search
      _filteredCustomers = List.from(_customersForSelectedDate);
      
      _sortCustomers(); // Apply sorting
    });
  }
  
  void _filterCustomers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = List.from(_customersForSelectedDate);
      } else {
        _filteredCustomers = _customersForSelectedDate
            .where((customer) => customer.name.toLowerCase().contains(query))
            .toList();
      }
      _sortCustomers(); // Apply sorting
    });
  }
  
  // Update this method to calculate totals based on selected date
  void _updateTotals() {
    int cups = 0;
    double amount = 0;
    double collected = 0;
    double remaining = 0;
    
    // Calculate daily totals for all customers, not filtered by date
    // This ensures the summary matches what the user sees in the list
    for (var customer in _allCustomers) {
      cups += customer.cups;
      amount += customer.totalAmount;
      collected += customer.paymentsMade;
    }
    
    // Calculate overall remaining/pending amount across all dates
    for (var customer in _allCustomers) {
      remaining += (customer.totalAmount - customer.paymentsMade);
    }
    
    setState(() {
      _totalCups = cups;
      _totalAmount = amount;
      _collectedAmount = collected;
      _remainingAmount = remaining;
    });
  }
  
  // Change sample data method to not add any data by default, but keep the method for possible future use
  void _addSampleData() {
    // Method kept for potential future sample data addition
    // Currently no sample data is added by default
  }
  
  // Add method to handle date selection
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    
    if (picked != null && picked != _selectedDate) {
      // Check if the new date is a different day
      bool isDifferentDay = picked.day != _selectedDate.day || 
                           picked.month != _selectedDate.month ||
                           picked.year != _selectedDate.year;
                           
      setState(() {
        _selectedDate = picked;
        
        // Reset cups for customers if it's a different day
        if (isDifferentDay) {
          _resetDailyCups();
        }
        
        // Filter data for the selected date
        _filterDataBySelectedDate();
        // Update totals based on filtered data
        _updateTotals();
        _counterAnimationController.forward(from: 0);
      });
    }
  }
  
  // New method to reset customer cups while preserving history and pending amounts
  void _resetDailyCups() {
    // This method resets cups to 0 for all customers
    // while preserving their history and pending amounts
    for (var customer in _allCustomers) {
      // Reset cups to 0
      customer.cups = 0;
      
      // Make sure we save this change
      customer.lastUpdated = DateTime.now();
    }
    
    // Save the changes to shared preferences
    _saveCustomers();
  }
  
  // Modify total market pending calculation to ensure it captures all dates
  double get _totalMarketPending {
    double pending = 0;
    // Sum up all pending amounts across all customers and all dates
    for (var customer in _allCustomers) {
      final pendingAmount = customer.totalAmount - customer.paymentsMade;
      if (pendingAmount > 0) {
        pending += pendingAmount;
      }
    }
    
    return pending;
  }
  
  // Calculate today's pending amount only
  double get _todayPending {
    double pending = 0;
    // Sum up pending amounts for today's customers only (matching selected date)
    for (var customer in _allCustomers) {
      if (customer.date.year == _selectedDate.year &&
          customer.date.month == _selectedDate.month &&
          customer.date.day == _selectedDate.day) {
        final pendingAmount = customer.totalAmount - customer.paymentsMade;
        if (pendingAmount > 0) {
          pending += pendingAmount;
        }
      }
    }
    
    return pending;
  }
  
  // Update the _showPendingBreakdown method to fix the customer creation with new parameters
  void _showPendingBreakdown() {
    // Group customers by name and sum their pending amounts
    final Map<String, Map<String, dynamic>> customerPendingMap = {};
    
    for (var customer in _allCustomers) {
      final pendingAmount = customer.totalAmount - customer.paymentsMade;
      
      if (pendingAmount <= 0) continue;
      
      if (!customerPendingMap.containsKey(customer.name)) {
        customerPendingMap[customer.name] = {
          'name': customer.name,
          'phoneNumber': customer.phoneNumber,
          'pendingAmount': pendingAmount,
          'cups': customer.cups,
          'teaRate': customer.teaRate,
          'coffeeRate': customer.coffeeRate,
          'milkRate': customer.milkRate,
          'dates': [customer.date],
          'pendingCups': pendingAmount / customer.teaRate,
        };
      } else {
        customerPendingMap[customer.name]!['pendingAmount'] += pendingAmount;
        customerPendingMap[customer.name]!['cups'] += customer.cups;
        customerPendingMap[customer.name]!['pendingCups'] += pendingAmount / customer.teaRate;
        customerPendingMap[customer.name]!['dates'].add(customer.date);
      }
    }
    
    // Convert map to list and sort by pending amount
    final customersWithPending = customerPendingMap.values.toList()
      ..sort((a, b) => (b['pendingAmount'] as double).compareTo(a['pendingAmount'] as double));
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Pending Amount',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '₹${_totalMarketPending.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Today\'s Pending:',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '₹${_todayPending.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.red[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Showing ${customersWithPending.length} customers with pending amounts',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const Divider(height: 24),
              Expanded(
                child: customersWithPending.isEmpty
                    ? const Center(
                        child: Text(
                          'No pending amounts!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: customersWithPending.length,
                        itemBuilder: (context, index) {
                          final customerData = customersWithPending[index];
                          final name = customerData['name'] as String;
                          final phoneNumber = customerData['phoneNumber'] as String?;
                          final pendingAmount = customerData['pendingAmount'] as double;
                          final teaRate = customerData['teaRate'] as double;
                          final coffeeRate = customerData['coffeeRate'] as double? ?? 0.0;
                          final milkRate = customerData['milkRate'] as double? ?? 0.0;
                          final pendingCups = customerData['pendingCups'] as double;
                          final dates = customerData['dates'] as List<DateTime>;
                          final String dateRangeText = dates.length > 1 
                              ? '${dates.length} days (${DateFormat('dd MMM').format(dates.reduce((a, b) => a.isBefore(b) ? a : b))} - ${DateFormat('dd MMM').format(dates.reduce((a, b) => a.isAfter(b) ? a : b))})'
                              : DateFormat('dd MMM yyyy').format(dates.first);
                          
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.primaries[index % Colors.primaries.length],
                              child: Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (phoneNumber != null && phoneNumber.isNotEmpty)
                                  Text(
                                    phoneNumber,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                Text('Tea: ₹${teaRate.toStringAsFixed(2)}/cup'),
                                Text(
                                  'Period: $dateRangeText',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${pendingAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[700],
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${pendingCups.toStringAsFixed(0)} cups pending',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              // Find customers with this name from today
                              final todayCustomers = _customersForSelectedDate
                                  .where((c) => c.name == name)
                                  .toList();
                              
                              if (todayCustomers.isNotEmpty) {
                                _showCustomerActions(todayCustomers.first);
                              } else {
                                // If no customer for today, create a new entry for today with the same name and rates
                                final latestCustomer = _allCustomers
                                    .where((c) => c.name == name)
                                    .reduce((a, b) => a.lastUpdated.isAfter(b.lastUpdated) ? a : b);
                                
                                // Create a new customer for today using the updated parameter names
                                final newCustomer = Customer(
                                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                                  name: name,
                                  phoneNumber: latestCustomer.phoneNumber,
                                  cups: 0, // Start with 0 cups
                                  teaRate: latestCustomer.teaRate,
                                  coffeeRate: latestCustomer.coffeeRate,
                                  milkRate: latestCustomer.milkRate,
                                  totalAmount: 0,
                                  paymentsMade: 0,
                                  date: _selectedDate,
                                  lastUpdated: DateTime.now(),
                                  history: [],
                                );
                                
                                setState(() {
                                  _allCustomers.add(newCustomer);
                                  _customersForSelectedDate.add(newCustomer);
                                  _filteredCustomers = List.from(_customersForSelectedDate);
                                  _sortCustomers();
                                  _updateTotals();
                                });
                                
                                // Show the customer actions for the new entry
                                _showCustomerActions(newCustomer);
                              }
                            },
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Modified to show running total of cups and add coffee and milk buttons
  void _showCustomerActions(Customer customer) {
    // Initialize counters outside the builder
    int newTeaCups = 0;
    int newCoffeeCups = 0;
    int newMilkCups = 0;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // Track the original cups count and newly added cups
            final int originalCups = customer.cups;
            
            int getTotalNewCups() => newTeaCups + newCoffeeCups + newMilkCups;
            
            // Add cup functions
            void addTeaCup() {
              setModalState(() {
                newTeaCups++;
              });
            }
            
            void removeTeaCup() {
              setModalState(() {
                if (newTeaCups > 0) newTeaCups--;
              });
            }
            
            void addCoffeeCup() {
              setModalState(() {
                newCoffeeCups++;
              });
            }
            
            void removeCoffeeCup() {
              setModalState(() {
                if (newCoffeeCups > 0) newCoffeeCups--;
              });
            }
            
            void addMilkCup() {
              setModalState(() {
                newMilkCups++;
              });
            }
            
            void removeMilkCup() {
              setModalState(() {
                if (newMilkCups > 0) newMilkCups--;
              });
            }
            
            void saveChanges() {
              // Update customer with the new cups
              int totalNewCups = getTotalNewCups();
              
              // Only add tea cup entries if there are any
              if (newTeaCups > 0) {
                customer.cups += newTeaCups;
                customer.totalAmount += newTeaCups * customer.teaRate;
                
                // Add to history
                customer.history.add(
                  CustomerEntry(
                    type: EntryType.tea,
                    cups: newTeaCups,
                    amount: newTeaCups * customer.teaRate,
                    timestamp: DateTime.now(),
                    beverageType: 'tea',
                  ),
                );
              }
              
              // Only add coffee cup entries if there are any
              if (newCoffeeCups > 0) {
                customer.cups += newCoffeeCups;
                customer.totalAmount += newCoffeeCups * customer.coffeeRate;
                
                // Add to history
                customer.history.add(
                  CustomerEntry(
                    type: EntryType.tea,
                    cups: newCoffeeCups,
                    amount: newCoffeeCups * customer.coffeeRate,
                    timestamp: DateTime.now(),
                    beverageType: 'coffee',
                  ),
                );
              }
              
              // Only add milk cup entries if there are any
              if (newMilkCups > 0) {
                customer.cups += newMilkCups;
                customer.totalAmount += newMilkCups * customer.milkRate;
                
                // Add to history
                customer.history.add(
                  CustomerEntry(
                    type: EntryType.tea,
                    cups: newMilkCups,
                    amount: newMilkCups * customer.milkRate,
                    timestamp: DateTime.now(),
                    beverageType: 'milk',
                  ),
                );
              }
              
              // Update last updated timestamp if any cups were added
              if (totalNewCups > 0) {
                customer.lastUpdated = DateTime.now();
              }
              
              // Update main screen state
              setState(() {
                _updateTotals();
                _sortCustomers();
                _counterAnimationController.forward(from: 0);
                // Save the data
                _saveCustomers();
              });
              
              // Close the bottom sheet
              Navigator.of(context).pop();
            }
            
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    customer.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Cancel',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          elevation: 2,
                          color: Colors.green[50],
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                const Text('Cups'),
                                const SizedBox(height: 4),
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(fontSize: 24),
                                    children: [
                                      TextSpan(
                                        text: '$originalCups',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      if (getTotalNewCups() > 0) ...[
                                        TextSpan(
                                          text: ' + ${getTotalNewCups()} = ${originalCups + getTotalNewCups()}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.normal,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Card(
                          elevation: 2,
                          color: Colors.amber[50],
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                const Text('Balance'),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${((customer.totalAmount - customer.paymentsMade) + 
                                    (newTeaCups * customer.teaRate) + 
                                    (newCoffeeCups * customer.coffeeRate) + 
                                    (newMilkCups * customer.milkRate)).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Add coffee and milk buttons in a row
                  Row(
                    children: [
                      // Coffee button
                      Expanded(
                        child: Card(
                          color: Colors.brown,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                            child: Column(
                              children: [
                                // Label
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.coffee, color: Colors.white, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '₹${customer.coffeeRate.toStringAsFixed(1)}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                  
                                if (newCoffeeCups > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      '+$newCoffeeCups',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                      ),
                    ),
                  ),
                  
                                const SizedBox(height: 4),
                  
                                // Controls
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                                    IconButton(
                                      onPressed: newCoffeeCups > 0 ? () => removeCoffeeCup() : null,
                                      icon: const Icon(Icons.remove_circle),
                                      color: newCoffeeCups > 0 ? Colors.white : Colors.white30,
                                      iconSize: 24,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    
                                    IconButton(
                                      onPressed: customer.coffeeRate > 0 ? () => addCoffeeCup() : null,
                                      icon: const Icon(Icons.add_circle),
                                      color: Colors.white,
                                      iconSize: 24,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ],
                          ),
                        ),
                      ),
                  ),
                  
                      const SizedBox(width: 8),
                      
                      // Milk button
                      Expanded(
                        child: Card(
                          color: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Column(
              children: [
                                // Label
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                                    const Icon(Icons.water_drop, color: Colors.white, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '₹${customer.milkRate.toStringAsFixed(1)}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                                  ],
                                ),
                                
                                if (newMilkCups > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      '+$newMilkCups',
                                      style: const TextStyle(
                                        color: Colors.white,
                          fontWeight: FontWeight.bold,
                                        fontSize: 11,
                      ),
                  ),
                ),
                
                                const SizedBox(height: 4),
                                
                                // Controls
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                                    IconButton(
                                      onPressed: newMilkCups > 0 ? () => removeMilkCup() : null,
                                      icon: const Icon(Icons.remove_circle),
                                      color: newMilkCups > 0 ? Colors.white : Colors.white30,
                                      iconSize: 24,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                            ),
                                    
                                    IconButton(
                                      onPressed: customer.milkRate > 0 ? () => addMilkCup() : null,
                                      icon: const Icon(Icons.add_circle),
                                      color: Colors.white,
                                      iconSize: 24,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                            ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Tea cup button
                  Card(
                    color: Colors.teal,
                    shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                            children: [
                          // Label
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.local_cafe, color: Colors.white, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                'Tea Cup (₹${customer.teaRate.toStringAsFixed(1)})',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          
                          if (newTeaCups > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '+$newTeaCups cups',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                            ),
                          ),
                            
                          const SizedBox(height: 8),
                          
                          // Controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              SizedBox(
                                height: 32,
                                width: 100,
                                child: ElevatedButton.icon(
                                  onPressed: newTeaCups > 0 ? () => removeTeaCup() : null,
                                  icon: const Icon(Icons.remove, size: 16),
                                  label: const Text('Remove', style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                  ),
                                ),
                        ),
                              
                              SizedBox(
                                height: 32,
                                width: 100,
                                child: ElevatedButton.icon(
                                  onPressed: () => addTeaCup(),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Add', style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.teal,
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                  ),
                                ),
                        ),
                      ],
                    ),
                        ],
                      ),
                  ),
                ),
                
                  const SizedBox(height: 16),
                  
                  // Payment and Save buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _addPayment(customer);
                          },
                          icon: const Icon(Icons.payments),
                          label: const Text('Add Payment'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: saveChanges,
                          icon: const Icon(Icons.save),
                          label: const Text('Save'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
            ],
          ),
            );
          }
        );
              },
    ).then((_) {
                setState(() {
                  _updateTotals();
      });
                });
  }

  Widget _buildCustomerCard(Customer customer) {
    return GestureDetector(
      onTap: () => _showCustomerActions(customer),
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (customer.paymentsMade > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.check, color: Colors.green[800], size: 12),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.local_cafe, size: 14, color: Colors.brown),
                      const SizedBox(width: 4),
                      Text('${customer.cups} cups'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.currency_rupee, size: 14, color: Colors.teal),
                      const SizedBox(width: 4),
                      Text('₹${(customer.totalAmount - customer.paymentsMade).toStringAsFixed(2)}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Updated customer item with last update time and view details button
  Widget _buildDetailedCustomerItem(Customer customer, int index) {
    final pendingAmount = customer.totalAmount - customer.paymentsMade;
    
    return Card(
      key: ValueKey(customer.id),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showCustomerActions(customer),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                backgroundColor: Colors.primaries[index % Colors.primaries.length],
                child: Text(
                  customer.name[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              
              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and cups/amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Name and rate
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            // Only show phone if available
                            if (customer.phoneNumber != null && customer.phoneNumber!.isNotEmpty)
                              Text(
                                customer.phoneNumber!,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                            Text(
                              'Tea: ₹${customer.teaRate.toStringAsFixed(1)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        
                        // Cups and amount
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${customer.cups} cups',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${pendingAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: pendingAmount > 0 
                                    ? Colors.red[700] 
                                    : Colors.green[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    // Last update time and view details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Last updated time
                        Text(
                          'Updated: ${_getFormattedTime(customer.lastUpdated)}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10,
                          ),
                        ),
                        
                        // View details button
                        InkWell(
                          onTap: () => _showCustomerHistory(customer),
                          child: Row(
                            children: [
                              Icon(
                                Icons.history,
                                size: 14,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'View History',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Tea Diary Reports',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                subtitle: Text('Generate PDF reports of tea transactions'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.teal),
                title: const Text('One Day Report'),
                subtitle: Text('Report for ${DateFormat('dd MMM yyyy').format(_selectedDate)}'),
                onTap: () {
                  Navigator.pop(context);
                  _generateReport(isOneDay: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.date_range, color: Colors.deepPurple),
                title: const Text('7 Days Report'),
                subtitle: Text('Report from ${DateFormat('dd MMM').format(_selectedDate.subtract(const Duration(days: 6)))} to ${DateFormat('dd MMM yyyy').format(_selectedDate)}'),
                onTap: () {
                  Navigator.pop(context);
                  _generateReport(isOneDay: false);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _generateReport({required bool isOneDay}) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Get data for report
      final List<Customer> reportCustomers = isOneDay 
          ? _customersForSelectedDate 
          : _getCustomersForLastSevenDays();
      
      // Create PDF document
      final pdf = await _createPdf(
        title: isOneDay 
            ? 'Tea Diary Report - ${DateFormat('dd MMM yyyy').format(_selectedDate)}'
            : 'Tea Diary Report - ${DateFormat('dd MMM').format(_selectedDate.subtract(const Duration(days: 6)))} to ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
        customers: reportCustomers,
        isOneDay: isOneDay,
      );
      
      // Get the app's documents directory
      final directory = await getApplicationDocumentsDirectory();
      final reportName = isOneDay 
          ? 'tea_report_${DateFormat('dd_MM_yyyy').format(_selectedDate)}.pdf'
          : 'tea_report_7days_${DateFormat('dd_MM_yyyy').format(_selectedDate)}.pdf';
      final filePath = '${directory.path}/$reportName';
      
      // Save the PDF
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Show success and open file
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Report saved: $reportName'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () => OpenFile.open(filePath),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      // Close loading dialog and show error
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating report: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  List<Customer> _getCustomersForLastSevenDays() {
    // Get the date range (last 7 days including today)
    final DateTime startDate = _selectedDate.subtract(const Duration(days: 6));
    
    // Filter customers within the date range
    return _allCustomers.where((customer) {
      return !customer.date.isBefore(DateTime(startDate.year, startDate.month, startDate.day)) &&
              !customer.date.isAfter(DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59));
    }).toList();
  }
  
  Future<pw.Document> _createPdf({required String title, required List<Customer> customers, required bool isOneDay}) async {
    final pdf = pw.Document();
    
    double totalCups = 0;
    double totalAmount = 0;
    double collectedAmount = 0;
    double remainingAmount = 0;
    
    // Calculate totals
    for (var customer in customers) {
      totalCups += customer.cups;
      totalAmount += customer.totalAmount;
      collectedAmount += customer.paymentsMade;
    }
    remainingAmount = totalAmount - collectedAmount;
    
    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                color: PdfColors.teal50,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'My Byaj Book - Tea Diary',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      title,
                      style: const pw.TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Summary section
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _pdfSummaryItem('Total Cups', totalCups.toInt().toString()),
                    _pdfSummaryItem('Total Sales', '${totalAmount.toStringAsFixed(2)}'),
                    _pdfSummaryItem('Collected', '${collectedAmount.toStringAsFixed(2)}'),
                    _pdfSummaryItem('Remaining', '${remainingAmount.toStringAsFixed(2)}'),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Table header
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.teal100),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Customer Name',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Cups',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Rate',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
      ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Total',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Balance',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  
                  // Table data - all customers
                  ...customers.asMap().entries.map((entry) {
                    int index = entry.key;
                    Customer customer = entry.value;
                    final pendingAmount = customer.totalAmount - customer.paymentsMade;
                    
                    return pw.TableRow(
                      decoration: index % 2 == 0 
                          ? const pw.BoxDecoration(color: PdfColors.grey100)
                          : const pw.BoxDecoration(color: PdfColors.white),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(customer.name),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            '${customer.cups}',
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            '${customer.teaRate.toStringAsFixed(1)}',
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            '${customer.totalAmount.toStringAsFixed(2)}',
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            '${pendingAmount.toStringAsFixed(2)}',
                            style: pendingAmount > 0
                                ? const pw.TextStyle(color: PdfColors.red)
                                : const pw.TextStyle(color: PdfColors.green),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              
              pw.SizedBox(height: 20),
              
              // Footer
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Generated on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
    
    return pdf;
  }
  
  pw.Widget _pdfSummaryItem(String title, String value) {
    return pw.Column(
      children: [
        pw.Text(
          title,
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Replace the improperly placed method with a proper class method at the class level
  // Add this method properly outside the build method
  void _showSelectCustomerForPaymentDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Customer for Payment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search customers...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (value) {
                        setState(() {
                          // Filter customers based on search query
                          // This is just a placeholder, actual implementation can be added
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _customersForSelectedDate.isEmpty
                        ? const Center(
                            child: Text('No customers for this date'),
                          )
                        : ListView.builder(
                            itemCount: _customersForSelectedDate.length,
                            itemBuilder: (context, index) {
                              final customer = _customersForSelectedDate[index];
                              final pendingAmount = customer.totalAmount - customer.paymentsMade;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.primaries[index % Colors.primaries.length],
                                  child: Text(
                                    customer.name[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(customer.name),
                                subtitle: Text('Pending: ₹${pendingAmount.toStringAsFixed(2)}'),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  _addPayment(customer);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Now fix the build method to remove the improperly placed method
  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('dd MMM yyyy').format(_selectedDate);
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      appBar: widget.showAppBar ? AppBar(
        backgroundColor: Colors.teal,
        title: const Text('Tea Diary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 2,
      ) : null,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar at the top (fixed position)
            // Remove the search bar
            
            // Make everything else scrollable
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _updateTotals();
                    _sortCustomers();
                    _counterAnimationController.forward(from: 0);
                  });
                },
                child: ListView(
                  padding: EdgeInsets.zero,
        children: [
          // Summary card with fixed width constraints
          Padding(
                      padding: const EdgeInsets.all(12.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.teal[50],
              child: Padding(
                          padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Improved layout for date and button row to prevent overflow
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                                  // Date picker with better constraints
                        GestureDetector(
                          onTap: () => _selectDate(context),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.teal.withOpacity(0.3)),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.calendar_today, size: 15),
                            ],
                                      ),
                          ),
                        ),
                        
                        // Action buttons with proper constraints
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                                      // Remove the PDF icon button
                            // More compact Add Customer button
                            SizedBox(
                                        height: 36,
                              child: ElevatedButton.icon(
                                onPressed: _addCustomer,
                                icon: const Icon(Icons.person_add, size: 14),
                                label: const Text(
                                  'Add Customer',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                                      ),
                                    ],
                            ),
                          ],
                        ),
                              const SizedBox(height: 16),
                        
                              // Statistics with 1x4 grid layout
                        Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                                  _buildStatCard('Total Cups', '$_totalCups', Icons.local_cafe, Colors.teal),
                                  _buildStatCard('Total Sales', '₹${_totalAmount.toStringAsFixed(2)}', Icons.monetization_on, Colors.blue),
                                  _buildStatCard('Collected', '₹${_collectedAmount.toStringAsFixed(2)}', Icons.payments, Colors.green),
                                  _buildStatCard('Remaining', '₹${_remainingAmount.toStringAsFixed(2)}', Icons.account_balance_wallet, Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

                    // Row with Pending and Payment buttons
          Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Row(
                        children: [
                          // Total Market Pending button
                          Expanded(
                            flex: 3, // Changed from 1 to 3 for a 60% width
                            child: ElevatedButton.icon(
                              onPressed: _showPendingBreakdown,
                              icon: const Icon(Icons.account_balance_wallet, size: 16),
                              label: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Pending: '),
                                  Row(
                                    children: [
                                  Text(
                                        'Today: ₹${_todayPending.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                          fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        'Total: ₹${_totalMarketPending.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade100,
                                foregroundColor: Colors.deepOrange.shade800,
                                minimumSize: const Size(0, 40),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          
                          // Add spacing between buttons
                          const SizedBox(width: 8),
                          
                          // Add Payment button - fix alignment by making flex equal to the Pending button
                          Expanded(
                            flex: 2, // Changed from 1 to 2 for a 40% width
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Show dialog to select a customer first
                                _showSelectCustomerForPaymentDialog();
                              },
                              icon: const Icon(Icons.payments, size: 16),
                              label: const Text('Add Payment'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade100,
                                foregroundColor: Colors.green.shade800,
                                minimumSize: const Size(0, 40),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
          ),
          
          // Updated Customer list heading with filter option
          Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                              const Icon(Icons.people, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                    const Text(
                      'Customer List',
                      style: TextStyle(
                                  fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                // Filter/Sort button
                InkWell(
                  onTap: () => _showSortOptions(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getSortIcon(),
                                    size: 14,
                          color: Colors.grey.shade700,
                        ),
                                  const SizedBox(width: 2),
                        Text(
                          _getSortLabel(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
                    // Customer list
                    _filteredCustomers.isEmpty 
                ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(30.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 56,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _customersForSelectedDate.isEmpty 
                              ? 'No customers for ${DateFormat('dd MMM yyyy').format(_selectedDate)}'
                              : 'No customers match your search',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        if (_customersForSelectedDate.isEmpty)
                          ElevatedButton(
                            onPressed: _addCustomer,
                            child: const Text('Add Customer for This Date'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                            ),
                          ),
                      ],
                            ),
                    ),
                  )
                : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = _filteredCustomers[index];
                            return _buildDismissibleCustomerItem(customer, index);
                          },
                        ),
                    
                    // Add some bottom padding for better UX
                    const SizedBox(height: 80),
                  ],
                ),
                  ),
          ),
        ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCustomer,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.person_add, color: Colors.white),
        tooltip: 'Add Customer',
      ),
    );
  }
  
  // Dismissible customer item with swipe and long press deletion
  Widget _buildDismissibleCustomerItem(Customer customer, int index) {
    return Dismissible(
      key: Key(customer.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.horizontal, // Allow both left and right swipe
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Customer'),
              content: Text('Are you sure you want to delete ${customer.name}?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    // Delete customer logic
                    setState(() {
                      _allCustomers.remove(customer);
                      _customersForSelectedDate.remove(customer);
                      _filteredCustomers.remove(customer);
                      _updateTotals();
                      _saveCustomers(); // Save changes
                    });
                  },
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          }
        );
      },
      child: GestureDetector(
        onLongPress: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Delete Customer'),
                content: Text('Do you want to delete ${customer.name}?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Delete customer logic
                      setState(() {
                        _allCustomers.remove(customer);
                        _customersForSelectedDate.remove(customer);
                        _filteredCustomers.remove(customer);
                        _updateTotals();
                        _saveCustomers(); // Save changes
                      });
                    },
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              );
            }
          );
        },
        child: _buildCustomerItem(customer, index),
      ),
    );
  }

  // Helper method to build stat cards
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Icon(icon, size: 14, color: color),
            const SizedBox(height: 2),
            AnimatedBuilder(
              animation: _counterAnimationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + _counterAnimationController.value * 0.05,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // More compact customer item
  Widget _buildCustomerItem(Customer customer, int index) {
    final pendingAmount = customer.totalAmount - customer.paymentsMade;
    final String lastUpdatedTime = _getFormattedTime(customer.lastUpdated);
    
    return Card(
      key: ValueKey(customer.id),
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showCustomerActions(customer),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.primaries[index % Colors.primaries.length],
                child: Text(
                  customer.name[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              
              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Name
                        Text(
                          customer.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        
                        // Cup count
                        Text(
                          '${customer.cups} cups',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Tea rate
                        Text(
                          'Tea: ₹${customer.teaRate.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                        
                        // Pending amount
                        Text(
                          '₹${pendingAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: pendingAmount > 0 ? Colors.red[700] : Colors.green[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Last updated time
                        Text(
                          'Updated: $lastUpdatedTime',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10,
                          ),
                        ),
                        
                        // Details button
                        TextButton.icon(
                          onPressed: () => _showCustomerHistory(customer),
                          icon: Icon(
                            Icons.visibility,
                            size: 14,
                            color: Colors.blue.shade700,
                          ),
                          label: Text(
                            'View History',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            minimumSize: const Size(0, 0),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Show customer history dialog
  void _showCustomerHistory(Customer customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    customer.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Add PDF export button
                  ElevatedButton.icon(
                    onPressed: () => _generateCustomerPdf(customer),
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text('Export PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              
              if (customer.phoneNumber != null && customer.phoneNumber!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Phone: ${customer.phoneNumber}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              // Display all rates in a row
              Row(
                children: [
                  _buildRateChip('Tea', customer.teaRate, Colors.green[100]!, Colors.green[700]!),
                  const SizedBox(width: 8),
                  if (customer.coffeeRate > 0)
                    _buildRateChip('Coffee', customer.coffeeRate, Colors.brown[100]!, Colors.brown[700]!),
                  if (customer.coffeeRate > 0 && customer.milkRate > 0)
                    const SizedBox(width: 8),
                  if (customer.milkRate > 0)
                    _buildRateChip('Milk', customer.milkRate, Colors.blue[100]!, Colors.blue[700]!),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Total Cups: ${customer.cups}',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Balance: ₹${(customer.totalAmount - customer.paymentsMade).toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              
              const Divider(height: 24),
              
              const Text(
                'Transaction History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              Expanded(
                child: customer.history.isEmpty
                    ? const Center(
                        child: Text(
                          'No transaction history available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: customer.history.length,
                        itemBuilder: (context, index) {
                          final entry = customer.history[index];
                          final bool isPayment = entry.type == EntryType.payment;
                          
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isPayment 
                                  ? Colors.green[100]
                                  : Colors.orange[100],
                              child: Icon(
                                isPayment 
                                    ? Icons.payment
                                    : Icons.local_cafe,
                                color: isPayment 
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                                size: 20,
                              ),
                            ),
                            title: Text(
                              isPayment 
                                  ? 'Payment Received'
                                  : '${entry.cups} cups of ${entry.beverageType ?? 'tea'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              DateFormat('dd MMM yyyy, hh:mm a').format(entry.timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            trailing: Text(
                              isPayment 
                                  ? '+₹${entry.amount.toStringAsFixed(2)}'
                                  : '-₹${entry.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: isPayment ? Colors.green[700] : Colors.red[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
              ),
              
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Helper method to format time
  String _getFormattedTime(DateTime time) {
    final now = DateTime.now();
    if (time.year == now.year && time.month == now.month && time.day == now.day) {
      return 'Today, ${DateFormat('hh:mm a').format(time)}';
    } else if (time.year == now.year && time.month == now.month && time.day == now.day - 1) {
      return 'Yesterday, ${DateFormat('hh:mm a').format(time)}';
    } else {
      return DateFormat('dd MMM, hh:mm a').format(time);
    }
  }

  // Helper widget to display rate chips
  Widget _buildRateChip(String type, double rate, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$type: ₹${rate.toStringAsFixed(1)}',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  void _showAddSellerDialog() {
    // Implementation...
  }
  
  // Add missing methods
  void _addPayment(Customer customer) {
    showDialog(
      context: context,
      builder: (context) {
        double amount = 0;
        
        return AlertDialog(
          title: const Text('Add Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  amount = double.tryParse(value) ?? 0;
                },
              ),
              const SizedBox(height: 8),
              Text('Current Balance: ₹${(customer.totalAmount - customer.paymentsMade).toStringAsFixed(2)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  customer.paymentsMade += amount;
                  
                  // Add to history
                  customer.history.add(
                    CustomerEntry(
                      type: EntryType.payment,
                      amount: amount,
                      timestamp: DateTime.now(),
                    ),
                  );
                  
                  // Update timestamp
                  customer.lastUpdated = DateTime.now();
                  
                  _updateTotals();
                  _sortCustomers(); // Re-sort to put most recent at top
                  _saveCustomers(); // Save changes
                });
                Navigator.of(context).pop();
              },
              child: const Text('Add Payment'),
            ),
          ],
        );
      },
    );
  }
  
  void _addTeaEntry(Customer customer) {
    showDialog(
      context: context,
      builder: (context) {
        int cups = 1;
        
        return AlertDialog(
          title: const Text('Add Custom Tea Entry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Number of Cups'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  cups = int.tryParse(value) ?? 1;
                },
              ),
              const SizedBox(height: 8),
              Text('Rate: ₹${customer.teaRate}/cup'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  customer.cups += cups;
                  customer.totalAmount += cups * customer.teaRate;
                  
                  // Add to history
                  customer.history.add(
                    CustomerEntry(
                      type: EntryType.tea,
                      cups: cups,
                      amount: cups * customer.teaRate,
                      timestamp: DateTime.now(),
                      beverageType: 'tea',
                    ),
                  );
                  
                  // Update timestamp
                  customer.lastUpdated = DateTime.now();
                  
                  _updateTotals();
                  _sortCustomers(); // Re-sort to put most recent at top
                  _counterAnimationController.forward(from: 0);
                });
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
  
  void _addCustomer() {
    // Initial values
    String name = '';
    String phoneNumber = '';
    double teaRate = 10.0;
    double coffeeRate = 15.0;
    double milkRate = 20.0;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle indicator
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                        margin: const EdgeInsets.only(bottom: 20),
                      ),
                    ),
                    
                    // Title
                    const Center(
                      child: Text(
                        'Add New Customer',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Name field
                    Row(
                      children: [
                        const Icon(Icons.person, color: Colors.teal),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            autofocus: true,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              name = value;
                              // Show warning if customer already exists
                              if (_customerExists(value)) {
                                setModalState(() {});
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    // Warning message if customer exists
                    if (name.isNotEmpty && _customerExists(name))
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'This customer already exists!',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 16),
                    
                    // Phone field
                    Row(
                      children: [
                        const Icon(Icons.phone, color: Colors.teal),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Phone Number (Optional)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                            onChanged: (value) {
                              phoneNumber = value;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Beverage section
                    Row(
                      children: [
                        const Icon(Icons.local_cafe, color: Colors.teal),
                        const SizedBox(width: 10),
                        const Text(
                          'Beverage Prices',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Tea price
                    Row(
                      children: [
                        const Icon(Icons.emoji_food_beverage, color: Colors.brown),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Tea Cup Price',
                              border: OutlineInputBorder(),
                              prefixText: '₹ ',
                            ),
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(text: '10'),
                            onChanged: (value) {
                              teaRate = double.tryParse(value) ?? 10.0;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Coffee price
                    Row(
                      children: [
                        const Icon(Icons.coffee, color: Colors.brown),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Coffee Cup Price',
                              border: OutlineInputBorder(),
                              prefixText: '₹ ',
                            ),
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(text: '15'),
                            onChanged: (value) {
                              coffeeRate = double.tryParse(value) ?? 15.0;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Milk price
                    Row(
                      children: [
                        const Icon(Icons.water_drop, color: Colors.blue),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Milk Cup Price',
                              border: OutlineInputBorder(),
                              prefixText: '₹ ',
                            ),
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(text: '20'),
                            onChanged: (value) {
                              milkRate = double.tryParse(value) ?? 20.0;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: name.isEmpty || _customerExists(name) 
                              ? null 
                              : () {
                                // Create a unique customer ID
                                final customerId = DateTime.now().millisecondsSinceEpoch.toString();
                                
                                // Create a new customer
                                final newCustomer = Customer(
                                  id: customerId,
                                  name: name,
                                  phoneNumber: phoneNumber,
                                  cups: 0,
                                  teaRate: teaRate,
                                  coffeeRate: coffeeRate,
                                  milkRate: milkRate,
                                  totalAmount: 0,
                                  paymentsMade: 0,
                                  date: _selectedDate, // Use the selected date
                                  lastUpdated: DateTime.now(),
                                  history: [],
                                );
                                
                                // Add customer to the list
                                setState(() {
                                  _allCustomers.add(newCustomer);
                                  _customersForSelectedDate = List.from(_allCustomers);
                                  _filteredCustomers = List.from(_customersForSelectedDate);
                                  _sortCustomers();
                                  _updateTotals();
                                  
                                  // Save to shared preferences
                                  _saveCustomers();
                                });
                                
                                // Close the modal
                                Navigator.of(context).pop();
                              },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Add Customer',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  // Helper method to get sort icon
  IconData _getSortIcon() {
    switch (_sortBy) {
      case 'recent':
        return Icons.access_time;
      case 'name':
        return Icons.sort_by_alpha;
      case 'amount':
        return Icons.money;
      case 'cups':
        return Icons.local_cafe;
      default:
        return Icons.sort;
    }
  }
  
  // Helper method to get sort label
  String _getSortLabel() {
    switch (_sortBy) {
      case 'recent':
        return 'Recent';
      case 'name':
        return 'Name';
      case 'amount':
        return 'Amount';
      case 'cups':
        return 'Cups';
      default:
        return 'Sort';
    }
  }

  // Add this new method to check if a customer already exists by name
  bool _customerExists(String name) {
    return _allCustomers.any((customer) => customer.name.toLowerCase() == name.toLowerCase());
  }

  // Add the new method to generate PDF for a single customer
  Future<void> _generateCustomerPdf(Customer customer) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Create PDF document
      final pdf = await _createCustomerPdf(customer);
      
      // Get the app's documents directory
      final directory = await getApplicationDocumentsDirectory();
      final reportName = 'customer_${customer.name.replaceAll(' ', '_')}_${DateFormat('dd_MM_yyyy').format(DateTime.now())}.pdf';
      final filePath = '${directory.path}/$reportName';
      
      // Save the PDF
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Automatically open the PDF file
      await OpenFile.open(filePath);
      
      // Show a simple snackbar notification that PDF was saved
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF report saved and opened: $reportName'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Close loading dialog and show error
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating report: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Create PDF for a single customer with detailed transaction history
  Future<pw.Document> _createCustomerPdf(Customer customer) async {
    final pdf = pw.Document();
    final pendingAmount = customer.totalAmount - customer.paymentsMade;
    
    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with app name
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                color: PdfColors.teal50,
                width: double.infinity,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'My Byaj Book - Tea Diary',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal800,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Customer Report',
                      style: const pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.teal700,
                      ),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Customer Details
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.teal200),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Customer: ${customer.name}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    
                    if (customer.phoneNumber != null && customer.phoneNumber!.isNotEmpty)
                      pw.Text('Phone: ${customer.phoneNumber}'),
                    
                    pw.SizedBox(height: 10),
                    
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Tea Rate: Rs. ${customer.teaRate.toStringAsFixed(2)}/cup'),
                            if (customer.coffeeRate > 0)
                              pw.Text('Coffee Rate: Rs. ${customer.coffeeRate.toStringAsFixed(2)}/cup'),
                            if (customer.milkRate > 0)
                              pw.Text('Milk Rate: Rs. ${customer.milkRate.toStringAsFixed(2)}/cup'),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text('Total Cups: ${customer.cups}'),
                            pw.Text('Total Amount: Rs. ${customer.totalAmount.toStringAsFixed(2)}'),
                            pw.Text('Amount Paid: Rs. ${customer.paymentsMade.toStringAsFixed(2)}'),
                            pw.Text(
                              'Balance Due: Rs. ${pendingAmount.toStringAsFixed(2)}',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: pendingAmount > 0 ? PdfColors.red : PdfColors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Transaction History
              pw.Text(
                'Transaction History',
                style: pw.TextStyle(
                  fontSize: 16, 
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal800,
                ),
              ),
              
              pw.SizedBox(height: 10),
              
              // Transaction table
              customer.history.isEmpty
                ? pw.Center(
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 30),
                      child: pw.Text(
                        'No transaction history available',
                        style: const pw.TextStyle(
                          color: PdfColors.grey600, 
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ),
                  )
                : pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    children: [
                      // Table header
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.teal100),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              'Date & Time',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              'Type',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              'Details',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              'Amount',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      
                      // Table data
                      ...customer.history.asMap().entries.map((entry) {
                        int index = entry.key;
                        CustomerEntry historyItem = entry.value;
                        bool isPayment = historyItem.type == EntryType.payment;
                        
                        return pw.TableRow(
                          decoration: index % 2 == 0 
                              ? const pw.BoxDecoration(color: PdfColors.grey100)
                              : const pw.BoxDecoration(color: PdfColors.white),
                          children: [
                            // Date column
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                DateFormat('dd MMM yyyy, hh:mm a').format(historyItem.timestamp),
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                            ),
                            
                            // Type column
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                isPayment ? 'Payment' : 'Purchase',
                                style: pw.TextStyle(
                                  color: isPayment ? PdfColors.green700 : PdfColors.red700,
                                ),
                              ),
                            ),
                            
                            // Details column
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                isPayment 
                                  ? 'Payment received'
                                  : '${historyItem.cups} cups of ${historyItem.beverageType ?? 'tea'}',
                              ),
                            ),
                            
                            // Amount column
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                isPayment 
                                  ? '+ Rs. ${historyItem.amount.toStringAsFixed(2)}'
                                  : '- Rs. ${historyItem.amount.toStringAsFixed(2)}',
                                style: pw.TextStyle(
                                  color: isPayment ? PdfColors.green700 : PdfColors.red700,
                                ),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
              
              pw.Spacer(),
              
              // Footer
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Generated on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'My Byaj Book App',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    
    return pdf;
  }
}

// Add entry type enum
enum EntryType {
  tea,
  payment
}

// Customer history entry class
class CustomerEntry {
  final EntryType type;
  final int cups;
  final double amount;
  final DateTime timestamp;
  final String? beverageType; // 'tea', 'coffee', or 'milk'
  
  CustomerEntry({
    required this.type,
    this.cups = 0,
    required this.amount,
    required this.timestamp,
    this.beverageType,
  });
}

// Update the Customer class to include phone number and multiple beverage prices
class Customer {
  final String id;
  final String name;
  final String? phoneNumber; // Make optional
  int cups;
  final double teaRate;
  final double coffeeRate;
  final double milkRate;
  double totalAmount;
  double paymentsMade;
  final DateTime date;
  DateTime lastUpdated;
  List<CustomerEntry> history;
  
  Customer({
    required this.id,
    required this.name,
    this.phoneNumber, // Remove default value to make fully optional
    required this.cups,
    required this.teaRate,
    this.coffeeRate = 0.0,
    this.milkRate = 0.0,
    required this.totalAmount,
    required this.paymentsMade,
    required this.date,
    required this.lastUpdated,
    this.history = const [],
  });
  
  // Helper getter to get the primary rate (for backward compatibility)
  double get rate => teaRate;
} 