import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_byaj_book/constants/app_theme.dart';
import 'package:my_byaj_book/widgets/dialogs/confirm_dialog.dart';

class MilkDiaryScreen extends StatefulWidget {
  final bool showAppBar;
  
  const MilkDiaryScreen({
    Key? key,
    this.showAppBar = true
  }) : super(key: key);

  @override
  State<MilkDiaryScreen> createState() => _MilkDiaryScreenState();
}

class _MilkDiaryScreenState extends State<MilkDiaryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  String _selectedMonth = DateFormat('MMMM yyyy').format(DateTime.now());
  String _selectedFilter = 'All';
  
  // Sample data - will be replaced with actual data source later
  final List<Map<String, dynamic>> _milkSellers = [
    {
      'id': 1,
      'name': 'Jaggu',
      'phone': '9876543210',
      'totalQuantity': 4.0,
      'totalAmount': 240.0,
      'entries': [
        {
          'time': 'Morning',
          'quantity': 2.0,
          'rate': 60.0,
          'amount': 120.0,
          'fat': 6.5,
        },
        {
          'time': 'Evening',
          'quantity': 2.0,
          'rate': 60.0,
          'amount': 120.0,
          'fat': 6.5,
        },
      ],
      'outstanding': 1240.0,
      'thisMonthQuantity': 120.0,
      'thisMonthAmount': 7200.0,
      'thisMonthPaid': 5960.0,
    },
    {
      'id': 2,
      'name': 'Pappu',
      'phone': '8765432109',
      'totalQuantity': 5.0,
      'totalAmount': 300.0,
      'entries': [
        {
          'time': 'Morning',
          'quantity': 2.5,
          'rate': 60.0,
          'amount': 150.0,
          'fat': 6.5,
        },
        {
          'time': 'Evening',
          'quantity': 2.5,
          'rate': 60.0,
          'amount': 150.0,
          'fat': 6.5,
        },
      ],
      'outstanding': 2500.0,
      'thisMonthQuantity': 150.0,
      'thisMonthAmount': 9000.0,
      'thisMonthPaid': 6500.0,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar ? AppBar(
        title: const Text('Milk Diary'),
        backgroundColor: AppTheme.primaryColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Daily Entries'),
            Tab(text: 'Monthly Summary'),
          ],
        ),
      ) : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyEntriesTab(),
          _buildMonthlySummaryTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _tabController.index == 0 ? _showAddEntryDialog : _showAddSellerDialog,
        backgroundColor: AppTheme.primaryColor,
        child: Icon(_tabController.index == 0 ? Icons.add : Icons.person_add),
      ),
    );
  }

  Widget _buildDailyEntriesTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Date: ${DateFormat('MMMM d, yyyy').format(_selectedDate)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null && picked != _selectedDate) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: const Text('Change'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: _milkSellers.length,
            itemBuilder: (context, index) {
              final seller = _milkSellers[index];
              return _buildSellerCard(seller);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSellerCard(Map<String, dynamic> seller) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  seller['name'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      const TextSpan(
                        text: 'Total: ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: '${seller['totalQuantity']} L | ₹${seller['totalAmount']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: seller['entries'].length,
            itemBuilder: (context, entryIndex) {
              final entry = seller['entries'][entryIndex];
              return _buildEntryItem(entry, seller['id'], entryIndex);
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showAddEntryForSellerDialog(seller['id']),
                  icon: const Icon(Icons.add, color: AppTheme.primaryColor),
                  label: const Text(
                    'Add Entry',
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryItem(Map<String, dynamic> entry, int sellerId, int entryIndex) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: entryIndex < _milkSellers.firstWhere((s) => s['id'] == sellerId)['entries'].length - 1 ? 1 : 0,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  entry['time'] == 'Morning' ? Icons.wb_sunny : Icons.nights_stay,
                  color: entry['time'] == 'Morning' ? Colors.orange : Colors.indigo,
                ),
                const SizedBox(width: 8),
                Text(
                  entry['time'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry['quantity']} L × ₹${entry['rate']} = ₹${entry['amount']}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Fat: ${entry['fat']}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => _editEntry(sellerId, entryIndex),
            splashRadius: 24,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _deleteEntry(sellerId, entryIndex),
            splashRadius: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummaryTab() {
    // Calculate totals
    double totalQuantity = 0;
    double totalAmount = 0;
    double totalPaid = 0;
    
    for (var seller in _milkSellers) {
      totalQuantity += seller['thisMonthQuantity'];
      totalAmount += seller['thisMonthAmount'];
      totalPaid += seller['thisMonthPaid'];
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Month: $_selectedMonth',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _showMonthPicker(context);
                },
                icon: const Icon(Icons.calendar_today),
                label: const Text('Change'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  _buildFilterChip('All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('High Outstanding'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Low Outstanding'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Monthly Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryItem('Total Quantity', '$totalQuantity L'),
                    _buildSummaryItem('Total Amount', '₹$totalAmount'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryItem('Paid Amount', '₹$totalPaid'),
                    _buildSummaryItem('Outstanding', '₹${totalAmount - totalPaid}'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Seller Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _milkSellers.length,
            itemBuilder: (context, index) {
              final seller = _milkSellers[index];
              return _buildSellerSummaryCard(seller);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _selectedFilter == label ? AppTheme.primaryColor : Colors.transparent,
          border: Border.all(
            color: AppTheme.primaryColor,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: _selectedFilter == label ? Colors.white : AppTheme.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSellerSummaryCard(Map<String, dynamic> seller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  seller['name'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: seller['outstanding'] > 1000 ? Colors.red.shade100 : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '₹${seller['outstanding']} due',
                    style: TextStyle(
                      color: seller['outstanding'] > 1000 ? Colors.red.shade800 : Colors.green.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem('Quantity', '${seller['thisMonthQuantity']} L'),
                _buildSummaryItem('Amount', '₹${seller['thisMonthAmount']}'),
                _buildSummaryItem('Paid', '₹${seller['thisMonthPaid']}'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionButton(
                  'Remind',
                  Icons.notifications,
                  Colors.orange,
                  () => _remindSeller(seller['id']),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  'SMS',
                  Icons.message,
                  Colors.blue,
                  () => _sendSMS(seller['id']),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  'Details',
                  Icons.receipt_long,
                  AppTheme.primaryColor,
                  () => _viewSellerLedger(seller['id']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: color, size: 18),
      label: Text(
        label,
        style: TextStyle(color: color),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
      ),
    );
  }

  void _showMonthPicker(BuildContext context) {
    // In a real app, you would use a proper month picker
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Month'),
        content: const Text('Month picker would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // For demo, just set to next month
              setState(() {
                final current = DateFormat('MMMM yyyy').parse(_selectedMonth);
                final next = DateTime(current.year, current.month + 1);
                _selectedMonth = DateFormat('MMMM yyyy').format(next);
              });
            },
            child: const Text('Next Month'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // For demo, just set to previous month
              setState(() {
                final current = DateFormat('MMMM yyyy').parse(_selectedMonth);
                final prev = DateTime(current.year, current.month - 1);
                _selectedMonth = DateFormat('MMMM yyyy').format(prev);
              });
            },
            child: const Text('Previous Month'),
          ),
        ],
      ),
    );
  }

  void _showAddEntryDialog() {
    if (_milkSellers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a seller first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Implementation would go here
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Milk Entry'),
        content: const Text('Select a seller and add milk entry details.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Entry added successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddEntryForSellerDialog(int sellerId) {
    // Implementation would go here
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Entry for ${_milkSellers.firstWhere((s) => s['id'] == sellerId)['name']}'),
        content: const Text('Add milk entry details for morning or evening.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Entry added successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddSellerDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool fatBasedPricing = false;
          
          return AlertDialog(
            title: const Text('Add Milk Seller'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Price System:'),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Row(
                          children: [
                            Radio(
                              value: false,
                              groupValue: fatBasedPricing,
                              onChanged: (value) {
                                setState(() {
                                  fatBasedPricing = value as bool;
                                });
                              },
                              activeColor: AppTheme.primaryColor,
                            ),
                            const Text('Default Rate'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Radio(
                              value: true,
                              groupValue: fatBasedPricing,
                              onChanged: (value) {
                                setState(() {
                                  fatBasedPricing = value as bool;
                                });
                              },
                              activeColor: AppTheme.primaryColor,
                            ),
                            const Text('Fat Based'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(
                        flex: 3,
                        child: Text('Unit:'),
                      ),
                      Expanded(
                        flex: 7,
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          ),
                          value: 'Liter',
                          onChanged: (value) {},
                          items: const [
                            DropdownMenuItem(
                              value: 'Liter',
                              child: Text('Liter'),
                            ),
                            DropdownMenuItem(
                              value: 'Kg',
                              child: Text('Kg'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!fatBasedPricing)
                    Row(
                      children: [
                        const Expanded(
                          flex: 3,
                          child: Text('Rate:'),
                        ),
                        Expanded(
                          flex: 7,
                          child: TextField(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              prefixText: '₹',
                              contentPadding: EdgeInsets.symmetric(horizontal: 10),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              flex: 3,
                              child: Text('Base Fat:'),
                            ),
                            Expanded(
                              flex: 7,
                              child: TextField(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  suffixText: '%',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Expanded(
                              flex: 3,
                              child: Text('Rate:'),
                            ),
                            Expanded(
                              flex: 7,
                              child: TextField(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  prefixText: '₹',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Seller added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Add Seller'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _editEntry(int sellerId, int entryIndex) {
    // Implementation would go here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit entry feature coming soon'),
      ),
    );
  }

  void _deleteEntry(int sellerId, int entryIndex) {
    showDialog(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Delete Entry',
        content: 'Are you sure you want to delete this entry?',
        confirmText: 'Delete',
        confirmColor: Colors.red,
        onConfirm: () {
          // Implementation would go here
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Entry deleted'),
              backgroundColor: Colors.red,
            ),
          );
        },
      ),
    );
  }

  void _remindSeller(int sellerId) {
    // Implementation would go here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reminder feature coming soon'),
      ),
    );
  }

  void _sendSMS(int sellerId) {
    // Implementation would go here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('SMS feature coming soon'),
      ),
    );
  }

  void _viewSellerLedger(int sellerId) {
    // Implementation would go here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ledger view coming soon'),
      ),
    );
  }
} 