import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/milk_diary/daily_entry.dart';
import '../../providers/milk_diary/daily_entry_provider.dart';
import '../../providers/milk_diary/milk_seller_provider.dart';
import '../../constants/app_theme.dart';
import 'add_entry_screen.dart';
import 'milk_seller_screen.dart';
import 'milk_payments_screen.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MilkSellerScreen()),
              );
            },
            tooltip: 'Manage Sellers',
          ),
          IconButton(
            icon: const Icon(Icons.payment),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MilkPaymentsScreen()),
              );
            },
            tooltip: 'Payments',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Daily Entries'),
            Tab(text: 'Summary'),
            Tab(text: 'Reports'),
          ],
        ),
      ) : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyEntriesTab(),
          _buildSummaryTab(),
          _buildReportsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEntryScreen()),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Add New Entry',
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
              
              // Group entries by shift
              final morningEntries = entriesForDate
                  .where((entry) => entry.shift == EntryShift.morning)
                  .toList();
              final eveningEntries = entriesForDate
                  .where((entry) => entry.shift == EntryShift.evening)
                  .toList();
              
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShiftSection('Morning', morningEntries, sellerProvider),
                      const SizedBox(height: 24),
                      _buildShiftSection('Evening', eveningEntries, sellerProvider),
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
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.grey.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
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
            child: Text(
              DateFormat('dd MMMM yyyy').format(_selectedDate),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: _selectedDate.isBefore(DateTime.now()) ? () {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 1));
              });
            } : null,
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

  Widget _buildSummaryTab() {
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
            };
          }
          
          sellerSummaries[entry.sellerId]!['quantity'] += entry.quantity;
          sellerSummaries[entry.sellerId]!['amount'] += entry.amount;
          sellerSummaries[entry.sellerId]!['entries'] += 1;
        }
        
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMonthlySummaryCard(totalQuantity, totalAmount, avgRate, entriesThisMonth.length),
                const SizedBox(height: 24),
                const Text(
                  'Seller-wise Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...sellerSummaries.entries.map((entry) {
                  final seller = sellerProvider.getSellerById(entry.key);
                  final summary = entry.value;
                  
                  return _buildSellerSummaryCard(
                    seller?.name ?? 'Unknown Seller',
                    summary['quantity'] as double,
                    summary['amount'] as double,
                    summary['entries'] as int,
                    sellerId: entry.key,
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildMonthlySummaryCard(double quantity, double amount, double avgRate, int entries) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary for ${DateFormat('MMMM yyyy').format(DateTime.now())}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryColumn('Total Quantity', '${quantity.toStringAsFixed(2)} L'),
                _buildSummaryColumn('Total Amount', '₹${amount.toStringAsFixed(2)}', isHighlighted: true),
                _buildSummaryColumn('Avg. Rate', '₹${avgRate.toStringAsFixed(2)}/L'),
                _buildSummaryColumn('Entries', entries.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryColumn(String label, String value, {bool isHighlighted = false}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isHighlighted ? AppTheme.primaryColor : null,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSellerSummaryCard(String name, double quantity, double amount, int entries, {required String sellerId}) {
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bar_chart, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Reports Coming Soon',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Detailed reports and analytics will be available in a future update',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MilkPaymentsScreen()),
              );
            },
            icon: const Icon(Icons.payment),
            label: const Text('Go to Payments'),
          ),
        ],
      ),
    );
  }
} 