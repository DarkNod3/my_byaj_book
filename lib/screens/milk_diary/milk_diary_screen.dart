import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../models/milk_diary/daily_entry.dart';
import '../../models/milk_diary/milk_seller.dart';
import '../../providers/milk_diary/daily_entry_provider.dart';
import '../../providers/milk_diary/milk_seller_provider.dart';
import '../../constants/app_theme.dart';
import 'add_entry_screen.dart';
import 'milk_seller_screen.dart';
import 'milk_payments_screen.dart';
import 'package:uuid/uuid.dart';

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
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Configure system UI
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get status bar height
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        // Remove default body padding/safe area
        body: Column(
          children: [
            // Custom app bar that includes status bar area
            Container(
              color: AppTheme.primaryColor,
              child: Column(
                children: [
                  // Status bar space (sized exactly to match system status bar)
                  SizedBox(height: statusBarHeight),
                  
                  // App bar content
                  if (widget.showAppBar) 
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          const Text(
                            'Milk Diary',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
          IconButton(
                            icon: const Icon(Icons.people, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MilkSellerScreen()),
              );
            },
            tooltip: 'Manage Sellers',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
          ),
                          const SizedBox(width: 8),
          IconButton(
                            icon: const Icon(Icons.payment, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MilkPaymentsScreen()),
              );
            },
            tooltip: 'Payments',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
          ),
        ],
                      ),
                    ),
                  
                  // Tab bar (no matter which mode)
                  TabBar(
          controller: _tabController,
          tabs: const [
                      Tab(
                        text: 'Daily Entry',
                        icon: Icon(Icons.calendar_today, size: 18),
                        height: 42,
                      ),
                      Tab(
                        text: 'Monthly Summary',
                        icon: Icon(Icons.analytics, size: 18),
                        height: 42,
                      ),
                    ],
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    labelPadding: EdgeInsets.zero,
                  ),
          ],
        ),
      ),
            
            // Tab content
            Expanded(
              child: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyEntriesTab(),
                  _buildMonthlySummaryTab(),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              enableDrag: true,
              isDismissible: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const Padding(
                padding: EdgeInsets.only(top: 30),
                child: AddEntryScreen(),
              ),
          );
        },
          backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
        tooltip: 'Add New Entry',
        ),
      ),
    );
  }

  Widget _buildDailyEntriesTab() {
    return Column(
      children: [
        _buildDateSelector(),
        Expanded(
          child: Consumer2<DailyEntryProvider, MilkSellerProvider>(
            builder: (context, entryProvider, sellerProvider, child) {
              final entriesForDate = entryProvider.getEntriesForDate(_selectedDate);
              
              if (entriesForDate.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No entries for ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddEntryScreen()),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Entry'),
                      ),
                    ],
                  ),
                );
              }
              
              // Group entries by seller ID
              Map<String, List<DailyEntry>> entriesBySeller = {};
              
              for (var entry in entriesForDate) {
                if (!entriesBySeller.containsKey(entry.sellerId)) {
                  entriesBySeller[entry.sellerId] = [];
                }
                entriesBySeller[entry.sellerId]!.add(entry);
              }
              
              // Calculate total for all entries
              final totalQuantity = entriesForDate.fold(0.0, (sum, entry) => sum + entry.quantity);
              final totalAmount = entriesForDate.fold(0.0, (sum, entry) => sum + entry.amount);
              
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...entriesBySeller.entries.map((entry) => 
                        _buildSellerEntryCard(entry.key, entry.value, sellerProvider)
                      ).toList(),
                      const SizedBox(height: 16),
                      // Total summary card
                      Card(
                        color: Colors.grey.shade100,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Quantity: ${totalQuantity.toStringAsFixed(2)} L',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Total: ₹${totalAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: Colors.grey.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
            },
          ),
          TextButton(
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (picked != null && picked != _selectedDate) {
                setState(() {
                  _selectedDate = picked;
                });
              }
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
            ),
            child: Text(
              DateFormat('dd MMMM yyyy').format(_selectedDate),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  _showAddSellerDialog();
                },
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text('Add Seller', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                ),
              ),
              const SizedBox(width: 4),
          IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
            onPressed: _selectedDate.isBefore(DateTime.now()) ? () {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 1));
              });
            } : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShiftSection(String title, List<DailyEntry> entries, MilkSellerProvider sellerProvider) {
    if (entries.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'No entries for this shift',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Calculate totals
    final totalQuantity = entries.fold(0.0, (sum, entry) => sum + entry.quantity);
    final totalAmount = entries.fold(0.0, (sum, entry) => sum + entry.amount);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Total: ₹${totalAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Column(
          children: entries.map((entry) {
            final seller = sellerProvider.getSellerById(entry.sellerId);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          seller?.name ?? 'Unknown Seller',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () {
                                // Navigate to edit entry screen
                              },
                              tooltip: 'Edit Entry',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () => _confirmDeleteEntry(entry),
                              tooltip: 'Delete Entry',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildEntryDetail('Quantity', '${entry.quantity} L'),
                            _buildEntryDetail('Fat', '${entry.fat}%'),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildEntryDetail('Rate', '₹${entry.rate}/L'),
                            _buildEntryDetail('Amount', '₹${entry.amount.toStringAsFixed(2)}'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Card(
          color: Colors.grey.shade100,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Quantity: ${totalQuantity.toStringAsFixed(2)} L',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Total: ₹${totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEntryDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteEntry(DailyEntry entry) async {
    final entryProvider = Provider.of<DailyEntryProvider>(context, listen: false);
    final sellerProvider = Provider.of<MilkSellerProvider>(context, listen: false);
    final seller = sellerProvider.getSellerById(entry.sellerId);
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: Text(
          'Are you sure you want to delete this entry for ${seller?.name ?? 'Unknown Seller'}?\n\n'
          'Quantity: ${entry.quantity} L\n'
          'Amount: ₹${entry.amount.toStringAsFixed(2)}'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              entryProvider.deleteEntry(entry.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Entry deleted successfully')),
              );
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummaryTab() {
    return Consumer2<DailyEntryProvider, MilkSellerProvider>(
      builder: (context, entryProvider, sellerProvider, child) {
        // Get current month entries
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        
        final entriesThisMonth = entryProvider.entries.where((entry) {
          return entry.date.isAfter(startOfMonth.subtract(const Duration(days: 1))) && 
                 entry.date.isBefore(endOfMonth.add(const Duration(days: 1)));
        }).toList();
        
        if (entriesThisMonth.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No entries for ${DateFormat('MMMM yyyy').format(now)}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => const Padding(
                        padding: EdgeInsets.only(top: 30),
                        child: AddEntryScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add First Entry'),
                ),
              ],
            ),
          );
        }
        
        // Calculate monthly totals
        final totalQuantity = entriesThisMonth.fold(0.0, (sum, entry) => sum + entry.quantity);
        final totalAmount = entriesThisMonth.fold(0.0, (sum, entry) => sum + entry.amount);
        final avgRate = totalQuantity > 0 ? totalAmount / totalQuantity : 0.0;
        
        // Group by seller
        final sellerSummaries = <String, Map<String, dynamic>>{};
        for (var entry in entriesThisMonth) {
          if (!sellerSummaries.containsKey(entry.sellerId)) {
            sellerSummaries[entry.sellerId] = {
              'quantity': 0.0,
              'amount': 0.0,
              'entries': 0,
              'payments': 0.0,
              'balance': 0.0,
            };
          }
          
          sellerSummaries[entry.sellerId]!['quantity'] += entry.quantity;
          sellerSummaries[entry.sellerId]!['amount'] += entry.amount;
          sellerSummaries[entry.sellerId]!['entries'] += 1;
          sellerSummaries[entry.sellerId]!['balance'] = 
              sellerSummaries[entry.sellerId]!['amount'] - sellerSummaries[entry.sellerId]!['payments'];
        }
        
        return DefaultTabController(
          length: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Container(
                color: Colors.grey.shade100,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMMM yyyy').format(now),
                          style: const TextStyle(
                            fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                        ),
                        _buildMonthSelector(),
                      ],
                ),
                const SizedBox(height: 16),
                    _buildMonthlySummaryCard(totalQuantity, totalAmount, avgRate, entriesThisMonth.length),
                  ],
                ),
              ),
              Material(
                color: AppTheme.primaryColor.withOpacity(0.1),
                child: TabBar(
                  tabs: const [
                    Tab(text: 'Seller-wise', icon: Icon(Icons.people)),
                    Tab(text: 'Payments', icon: Icon(Icons.payment)),
                    Tab(text: 'Reports', icon: Icon(Icons.summarize)),
                  ],
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppTheme.primaryColor,
                  indicatorWeight: 3,
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // SELLER-WISE TAB
                    ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                ...sellerSummaries.entries.map((entry) {
                  final seller = sellerProvider.getSellerById(entry.key);
                  final summary = entry.value;
                  
                  return _buildSellerSummaryCard(
                    seller?.name ?? 'Unknown Seller',
                    summary['quantity'] as double,
                    summary['amount'] as double,
                    summary['entries'] as int,
                            summary['payments'] as double,
                            summary['balance'] as double,
                    sellerId: entry.key,
                  );
                }).toList(),
              ],
            ),
                    
                    // PAYMENTS TAB
                    _buildPaymentsTab(sellerSummaries, sellerProvider),
                    
                    // REPORTS TAB
                    _buildReportsTab(totalQuantity, totalAmount, entriesThisMonth),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildMonthSelector() {
    return TextButton.icon(
      onPressed: () async {
        // TODO: Implement month picker dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Month selection coming soon')),
        );
      },
      icon: const Icon(Icons.calendar_month),
      label: const Text('Change'),
    );
  }
  
  Widget _buildPaymentsTab(Map<String, Map<String, dynamic>> sellerSummaries, MilkSellerProvider sellerProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Management',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: sellerSummaries.length,
              itemBuilder: (context, index) {
                final entry = sellerSummaries.entries.elementAt(index);
                final sellerId = entry.key;
                final summary = entry.value;
                final seller = sellerProvider.getSellerById(sellerId);
                final double balance = summary['balance'] as double;
                
    return Card(
                  margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
                              seller?.name ?? 'Unknown Seller',
              style: const TextStyle(
                                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: balance > 0 ? Colors.green.shade50 : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: balance > 0 ? Colors.green.shade300 : Colors.grey.shade400,
                                ),
                              ),
                              child: Text(
                                'Balance: ₹${balance.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: balance > 0 ? Colors.green.shade700 : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Milk Value:'),
                                  Text(
                                    '₹${(summary['amount'] as double).toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Payments Made:'),
                                  Text(
                                    '₹${(summary['payments'] as double).toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showAddPaymentDialog(sellerId, seller?.name ?? 'Unknown', balance),
                          icon: const Icon(Icons.payment),
                          label: const Text('Add Payment'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
            ),
          ],
        ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  void _showAddPaymentDialog(String sellerId, String sellerName, double balance) {
    final amountController = TextEditingController();
    final dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(DateTime.now()),
    );
    final remarksController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payment for $sellerName'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Balance: ₹${balance.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Payment Amount (₹)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dateController,
                decoration: InputDecoration(
                  labelText: 'Payment Date',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        dateController.text = DateFormat('dd/MM/yyyy').format(picked);
                      }
                    },
                  ),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: remarksController,
                decoration: const InputDecoration(
                  labelText: 'Remarks (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
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
              // TODO: Implement payment processing
              if (amountController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter payment amount')),
                );
                return;
              }
              
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter valid amount')),
                );
                return;
              }
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Payment of ₹${amount.toStringAsFixed(2)} recorded')),
              );
            },
            child: const Text('Save Payment'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReportsTab(double totalQuantity, double totalAmount, List<DailyEntry> entries) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reports & Analytics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                _buildReportCard(
                  title: 'Monthly Summary Report',
                  description: 'Complete breakdown of milk collection and payments',
                  icon: Icons.summarize,
                  onTap: () => _generateReport('summary'),
                ),
                const SizedBox(height: 16),
                _buildReportCard(
                  title: 'Seller-wise Report',
                  description: 'Detailed report for each seller with daily entries',
                  icon: Icons.people,
                  onTap: () => _generateReport('seller'),
                ),
                const SizedBox(height: 16),
                _buildReportCard(
                  title: 'Payment Report',
                  description: 'All payment transactions and outstanding balances',
                  icon: Icons.payment,
                  onTap: () => _generateReport('payment'),
                ),
                const SizedBox(height: 16),
                _buildReportCard(
                  title: 'Daily Collection Report',
                  description: 'Day-wise milk collection quantities and amounts',
                  icon: Icons.calendar_today,
                  onTap: () => _generateReport('daily'),
                ),
                const SizedBox(height: 16),
                _buildReportCard(
                  title: 'Export Data',
                  description: 'Export all data to Excel/CSV format',
                  icon: Icons.file_download,
                  onTap: () => _generateReport('export'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReportCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      description,
          style: TextStyle(
                        fontSize: 14,
            color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  void _generateReport(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating $type report...'),
        duration: const Duration(seconds: 2),
      ),
    );
    
    // TODO: Implement actual report generation
  }
  
  Widget _buildMonthlySummaryCard(double totalQuantity, double totalAmount, double avgRate, int entriesCount) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  'Total Quantity',
                  '${totalQuantity.toStringAsFixed(2)} L',
                  Icons.water_drop,
                  Colors.blue,
                ),
                _buildSummaryItem(
                  'Total Amount',
                  '₹${totalAmount.toStringAsFixed(2)}',
                  Icons.currency_rupee,
                  Colors.green,
                ),
                _buildSummaryItem(
                  'Avg. Rate',
                  '₹${avgRate.toStringAsFixed(2)}/L',
                  Icons.trending_up,
                  Colors.orange,
                ),
                _buildSummaryItem(
                  'Entries',
                  '$entriesCount',
                  Icons.list_alt,
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSellerSummaryCard(
    String name, 
    double quantity, 
    double amount, 
    int entries, 
    double payments,
    double balance,
    {required String sellerId}
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MilkPaymentsScreen(sellerId: sellerId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$entries entries',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantity:',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      Text(
                        '${quantity.toStringAsFixed(2)} L',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount:',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      Text(
                        '₹${amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Balance:',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        Text(
                          '₹${balance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: balance > 0 ? Colors.green : Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _showAddPaymentDialog(sellerId, name, balance),
                icon: const Icon(Icons.payment, size: 16),
                label: const Text('Add Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(120, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSellerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final rateController = TextEditingController();
    final fatRateController = TextEditingController(text: '85.0');
    final baseFatController = TextEditingController(text: '100.0');
    bool isFatBased = false;
    String unit = 'Liter (L)';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
      child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                    const Center(
                      child: Text(
                        'Add Milk Seller',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address (Optional)',
                        prefixIcon: Icon(Icons.home),
                        border: OutlineInputBorder(),
                      ),
                    ),
          const SizedBox(height: 16),
          const Text(
                      'Price System',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Radio<bool>(
                          value: false,
                          groupValue: isFatBased,
                          activeColor: AppTheme.primaryColor,
                          onChanged: (value) {
                            setState(() {
                              isFatBased = false;
                            });
                          },
                        ),
                        const Text('Default Rate'),
                        const SizedBox(width: 20),
                        Radio<bool>(
                          value: true,
                          groupValue: isFatBased,
                          activeColor: AppTheme.primaryColor,
                          onChanged: (value) {
                            setState(() {
                              isFatBased = true;
                            });
                          },
                        ),
                        const Text('Fat Based'),
                      ],
          ),
          const SizedBox(height: 8),
          const Text(
                      'Default Unit',
                      style: TextStyle(fontSize: 14),
                    ),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      value: unit,
                      items: const [
                        DropdownMenuItem(
                          value: 'Liter (L)',
                          child: Text('Liter (L)'),
                        ),
                        DropdownMenuItem(
                          value: 'Kilogram (Kg)',
                          child: Text('Kilogram (Kg)'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            unit = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    if (!isFatBased) ...[
                      TextField(
                        controller: rateController,
                        decoration: const InputDecoration(
                          labelText: 'Default Rate',
                          prefixIcon: Icon(Icons.currency_rupee),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ] else ...[
                      TextField(
                        controller: fatRateController,
                        decoration: const InputDecoration(
                          labelText: 'Rate per 100 Fat',
                          prefixIcon: Icon(Icons.currency_rupee),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ex: ₹${fatRateController.text} for 100 fat',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: baseFatController,
                        decoration: const InputDecoration(
                          labelText: 'Base Fat Value',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Usually 100',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
            onPressed: () {
                          if (nameController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter seller name')),
                            );
                            return;
                          }
                          
                          final sellerProvider = Provider.of<MilkSellerProvider>(context, listen: false);
                          
                          // Get the appropriate rate depending on the selected option
                          double defaultRate = 0.0;
                          if (!isFatBased) {
                            defaultRate = double.tryParse(rateController.text) ?? 0.0;
                          } else {
                            // For fat-based pricing, we store the rate per fat point
                            defaultRate = double.tryParse(fatRateController.text) ?? 0.0;
                          }
                          
                          final seller = MilkSeller(
                            id: const Uuid().v4(),
                            name: nameController.text.trim(),
                            mobile: phoneController.text.trim(),
                            address: addressController.text.trim(),
                            defaultRate: defaultRate,
                            isActive: true,
                          );
                          
                          sellerProvider.addSeller(seller).then((_) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Seller ${seller.name} added successfully'),
                                backgroundColor: Colors.green,
                              ),
              );
                          }).catchError((error) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error adding seller: $error'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Add Seller'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
          ),
        ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSellerEntryCard(String sellerId, List<DailyEntry> entries, MilkSellerProvider sellerProvider) {
    final seller = sellerProvider.getSellerById(sellerId);
    final sellerName = seller?.name ?? 'Unknown Seller';
    
    // Sort entries by shift
    entries.sort((a, b) => a.shift.index.compareTo(b.shift.index));
    
    // Calculate seller totals
    final totalQuantity = entries.fold(0.0, (sum, entry) => sum + entry.quantity);
    final totalAmount = entries.fold(0.0, (sum, entry) => sum + entry.amount);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  sellerName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {
                        // Navigate to edit entry screen
                      },
                      tooltip: 'Edit Entry',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () => _confirmDeleteEntry(entries.first),
                      tooltip: 'Delete Entry',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            
            // List individual entries with shift times
            ...entries.map((entry) {
              final isFirstEntry = entries.indexOf(entry) == 0;
              
              return Column(
                children: [
                  if (!isFirstEntry) const Divider(height: 16, indent: 8, endIndent: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            entry.shift == EntryShift.morning 
                                ? Icons.wb_sunny_outlined 
                                : Icons.nightlight_outlined,
                            size: 16,
                            color: entry.shift == EntryShift.morning 
                                ? Colors.orange 
                                : Colors.indigo,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entry.shift == EntryShift.morning ? 'Morning' : 'Evening',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: entry.shift == EntryShift.morning 
                                  ? Colors.orange.shade700 
                                  : Colors.indigo,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '₹${entry.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildEntryDetail('Quantity', '${entry.quantity} L'),
                          _buildEntryDetail('Fat', '${entry.fat}%'),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildEntryDetail('Rate', '₹${entry.rate}/L'),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            }).toList(),
            
            // Show total for this seller
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ${totalQuantity.toStringAsFixed(2)} L',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Total: ₹${totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 