import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_byaj_book/widgets/header/app_header.dart';

class TeaDiaryScreen extends StatefulWidget {
  static const routeName = '/tea-diary';

  const TeaDiaryScreen({Key? key}) : super(key: key);

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
    
    _filterDataBySelectedDate();
    _updateTotals();
    _filteredCustomers = List.from(_customersForSelectedDate);
    _sortCustomers(); // Apply default sorting
    
    _searchController.addListener(_filterCustomers);
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
      _customersForSelectedDate = _allCustomers.where((customer) {
        // Compare year, month, and day only
        return customer.date.year == _selectedDate.year &&
               customer.date.month == _selectedDate.month &&
               customer.date.day == _selectedDate.day;
      }).toList();
      
      // Also update the filtered customers for search
      _filteredCustomers = List.from(_customersForSelectedDate);
      _searchController.text = ""; // Clear search when changing date
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
    
    for (var customer in _customersForSelectedDate) {
      cups += customer.cups;
      amount += customer.totalAmount;
      collected += customer.paymentsMade;
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
      setState(() {
        _selectedDate = picked;
        // Filter data for the selected date
        _filterDataBySelectedDate();
        // Update totals based on filtered data
        _updateTotals();
        _counterAnimationController.forward(from: 0);
      });
    }
  }
  
  // Modify total market pending calculation to ensure it captures all dates
  double get _totalMarketPending {
    double pending = 0;
    // Group all customers by name to avoid duplicates
    final Map<String, double> customerPendingMap = {};
    
    for (var customer in _allCustomers) {
      final pendingAmount = customer.totalAmount - customer.paymentsMade;
      if (pendingAmount > 0) {
        if (customerPendingMap.containsKey(customer.name)) {
          customerPendingMap[customer.name] = customerPendingMap[customer.name]! + pendingAmount;
        } else {
          customerPendingMap[customer.name] = pendingAmount;
        }
      }
    }
    
    // Sum up all pending amounts
    customerPendingMap.forEach((name, amount) {
      pending += amount;
    });
    
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
                          final phoneNumber = customerData['phoneNumber'] as String? ?? '';
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
                                if (phoneNumber.isNotEmpty)
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Track the original cups count and newly added cups
            int originalCups = customer.cups;
            int newlyAddedCups = 0;
            
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
                  Text(
                    customer.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
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
                                Text(
                                  newlyAddedCups > 0 
                                    ? '$originalCups + $newlyAddedCups = ${customer.cups}'
                                    : '${customer.cups}',
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
                                  '₹${(customer.totalAmount - customer.paymentsMade).toStringAsFixed(2)}',
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
                        child: ElevatedButton.icon(
                          onPressed: customer.coffeeRate > 0 ? () {
                            setState(() {
                              newlyAddedCups += 1;
                              customer.cups += 1;
                              customer.totalAmount += customer.coffeeRate;
                            });
                            
                            // Add to history
                            customer.history.add(
                              CustomerEntry(
                                type: EntryType.tea,
                                cups: 1,
                                amount: customer.coffeeRate,
                                timestamp: DateTime.now(),
                                beverageType: 'coffee',
                              ),
                            );
                            
                            // Update last updated timestamp
                            customer.lastUpdated = DateTime.now();
                            
                            this.setState(() {
                              _updateTotals();
                              _sortCustomers();
                              _counterAnimationController.forward(from: 0);
                            });
                          } : null,
                          icon: const Icon(Icons.coffee, size: 16),
                          label: Text(
                            customer.coffeeRate > 0 
                              ? '₹${customer.coffeeRate.toStringAsFixed(1)}'
                              : 'N/A',
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Milk button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: customer.milkRate > 0 ? () {
                            setState(() {
                              newlyAddedCups += 1;
                              customer.cups += 1;
                              customer.totalAmount += customer.milkRate;
                            });
                            
                            // Add to history
                            customer.history.add(
                              CustomerEntry(
                                type: EntryType.tea,
                                cups: 1,
                                amount: customer.milkRate,
                                timestamp: DateTime.now(),
                                beverageType: 'milk',
                              ),
                            );
                            
                            // Update last updated timestamp
                            customer.lastUpdated = DateTime.now();
                            
                            this.setState(() {
                              _updateTotals();
                              _sortCustomers();
                              _counterAnimationController.forward(from: 0);
                            });
                          } : null,
                          icon: const Icon(Icons.local_drink, size: 16),
                          label: Text(
                            customer.milkRate > 0 
                              ? '₹${customer.milkRate.toStringAsFixed(1)}'
                              : 'N/A',
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Tea cup button (renamed from Add Cup)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        int additionalCups = 1;
                        setState(() {
                          newlyAddedCups += additionalCups;
                          customer.cups += additionalCups;
                          customer.totalAmount += additionalCups * customer.teaRate;
                        });
                        
                        // Update customer history
                        customer.history.add(
                          CustomerEntry(
                            type: EntryType.tea,
                            cups: additionalCups,
                            amount: additionalCups * customer.teaRate,
                            timestamp: DateTime.now(),
                            beverageType: 'tea',
                          ),
                        );
                        
                        // Update last updated timestamp
                        customer.lastUpdated = DateTime.now();
                        
                        this.setState(() {
                          _updateTotals();
                          _sortCustomers(); // Re-sort to put most recent at top
                          _counterAnimationController.forward(from: 0);
                        });
                      },
                      icon: const Icon(Icons.local_cafe),
                      label: Text(
                        'Add Tea Cup (₹${customer.teaRate.toStringAsFixed(1)})',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Payment and Custom Entry buttons
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
                          onPressed: () {
                            _addTeaEntry(customer);
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Custom Entry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      setState(() {
        _updateTotals();
      });
    });
  }
  
  // Restore the add customer method that was accidentally removed
  void _addCustomer() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String name = '';
        String phoneNumber = '';
        double teaRate = 10.0;
        double coffeeRate = 15.0;
        double milkRate = 8.0;
        
        return AlertDialog(
          title: const Text('Add New Customer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Name'),
                  onChanged: (value) {
                    name = value;
                  },
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                  onChanged: (value) {
                    phoneNumber = value;
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Beverage Prices',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Tea Cup Price'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    teaRate = double.tryParse(value) ?? 10.0;
                  },
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Coffee Cup Price'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    coffeeRate = double.tryParse(value) ?? 15.0;
                  },
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Milk Cup Price'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    milkRate = double.tryParse(value) ?? 8.0;
                  },
                ),
              ],
            ),
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
                if (name.isNotEmpty) {
                  final newCustomer = Customer(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    phoneNumber: phoneNumber,
                    cups: 0,
                    teaRate: teaRate,
                    coffeeRate: coffeeRate,
                    milkRate: milkRate,
                    totalAmount: 0,
                    paymentsMade: 0,
                    date: _selectedDate,
                    lastUpdated: DateTime.now(),
                    history: [],
                  );
                  
                  setState(() {
                    // Add to both main list and filtered list
                    _allCustomers.add(newCustomer);
                    _customersForSelectedDate.add(newCustomer);
                    _filteredCustomers = List.from(_customersForSelectedDate);
                    _sortCustomers();
                    _updateTotals();
                  });
                  
                  Navigator.of(context).pop();
                  _counterAnimationController.forward(from: 0);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
  
  // Also update _addTeaEntry to update customer history and timestamps
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
                    ),
                  );
                  
                  // Update timestamp
                  customer.lastUpdated = DateTime.now();
                  
                  _updateTotals();
                  _sortCustomers(); // Re-sort to put most recent at top
                  _counterAnimationController.forward(from: 0);
                });
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
  
  // Also update _addPayment to update customer history and timestamps
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
                });
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Add Payment'),
            ),
          ],
        );
      },
    );
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
                            if (customer.phoneNumber.isNotEmpty)
                              Text(
                                customer.phoneNumber,
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
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
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
                                'Details',
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
                subtitle: Text('Report for ${DateFormat('dd MMM yyyy').format(DateTime.now())}'),
                onTap: () {
                  Navigator.pop(context);
                  _generateReport(isOneDay: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.date_range, color: Colors.deepPurple),
                title: const Text('7 Days Report'),
                subtitle: Text('Report from ${DateFormat('dd MMM').format(DateTime.now().subtract(const Duration(days: 6)))} to ${DateFormat('dd MMM yyyy').format(DateTime.now())}'),
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

  void _generateReport({required bool isOneDay}) {
    // Show a snackbar indicating report generation (placeholder for actual PDF generation)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isOneDay ? 'Generating one day report...' : 'Generating 7-day report...'),
        duration: const Duration(seconds: 2),
      ),
    );
    
    // Actual PDF generation would be implemented here
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('dd MMM yyyy').format(_selectedDate);
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      body: Column(
        children: [
          // Summary card with fixed width constraints
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.teal[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Improved layout for date and button row to prevent overflow
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Date picker - constrained width
                        GestureDetector(
                          onTap: () => _selectDate(context),
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
                        
                        // Action buttons with proper constraints
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Refresh button with minimal padding
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 18),
                              onPressed: () {
                                _updateTotals();
                                _counterAnimationController.forward(from: 0);
                              },
                              tooltip: 'Refresh totals',
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            const SizedBox(width: 4),
                            // More compact Add Customer button
                            SizedBox(
                              height: 32,
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
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Fix for pixel overflow - using a better constrained layout with properly sized metrics
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row of metric category labels with equal spacing
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Total Cups',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Total Sales',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Collected',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Remaining',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Row of metric values with equal spacing and animated values
                        Row(
                          children: [
                            Expanded(
                              child: AnimatedBuilder(
                                animation: _counterAnimationController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: 1.0 + _counterAnimationController.value * 0.1,
                                    child: Text(
                                      '$_totalCups',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                },
                              ),
                            ),
                            Expanded(
                              child: AnimatedBuilder(
                                animation: _counterAnimationController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: 1.0 + _counterAnimationController.value * 0.1,
                                    child: Text(
                                      '₹${_totalAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                },
                              ),
                            ),
                            Expanded(
                              child: AnimatedBuilder(
                                animation: _counterAnimationController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: 1.0 + _counterAnimationController.value * 0.1,
                                    child: Text(
                                      '₹${_collectedAmount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                },
                              ),
                            ),
                            Expanded(
                              child: AnimatedBuilder(
                                animation: _counterAnimationController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: 1.0 + _counterAnimationController.value * 0.1,
                                    child: Text(
                                      '₹${_remainingAmount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red[700],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: _showPendingBreakdown,
              icon: const Icon(Icons.account_balance_wallet),
              label: Row(
                children: [
                  const Text('Total Market Pending: '),
                  Text(
                    '₹${_totalMarketPending.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade100,
                foregroundColor: Colors.deepOrange.shade800,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  flex: 80,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search customers...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 20,
                  child: ElevatedButton(
                    onPressed: _showReportOptions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Icon(Icons.picture_as_pdf),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Updated Customer list heading with filter option
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Text(
                      'Customer List',
                      style: TextStyle(
                        fontSize: 16,
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getSortIcon(),
                          size: 16,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 4),
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
          
          // Updated Customer list
          Expanded(
            child: _filteredCustomers.isEmpty 
                ? Center(
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
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = _filteredCustomers[index];
                      return _buildDetailedCustomerItem(customer, index);
                    },
                  ),
          ),
        ],
      ),
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
                  CircleAvatar(
                    backgroundColor: Colors.primaries[customer.name.length % Colors.primaries.length],
                    child: Text(
                      customer.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              if (customer.phoneNumber.isNotEmpty)
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
  final String phoneNumber;
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
    this.phoneNumber = '',
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