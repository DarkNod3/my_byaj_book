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
    
    return Scaffold(
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
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                        // Menu icon
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 16),
                        
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
                          icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
                            // Show transaction history
            },
                          tooltip: 'History',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
          ),
                        const SizedBox(width: 16),
          IconButton(
                          icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
                            // Show notifications
            },
                          tooltip: 'Notifications',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
          ),
        ],
                      ),
                  ),
              ],
            ),
          ),
          
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
        children: [
        Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search sellers...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    onChanged: (value) {
                      // Search functionality
            },
          ),
        ),
                const SizedBox(width: 8),
                // Date selector button
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.calendar_today, size: 20),
                    onPressed: () => _selectDate(context),
                    color: AppTheme.primaryColor,
                    tooltip: 'Select Date',
                  ),
              ),
            ],
          ),
          ),
          
          // Overall summary card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Consumer2<DailyEntryProvider, MilkSellerProvider>(
              builder: (context, entryProvider, sellerProvider, child) {
                final entriesForDate = entryProvider.getEntriesForDate(_selectedDate);
                
                // Calculate total for all entries
                final totalQuantity = entriesForDate.fold(0.0, (sum, entry) => sum + entry.quantity);
                final totalAmount = entriesForDate.fold(0.0, (sum, entry) => sum + entry.amount);
                final totalSellers = sellerProvider.sellers.length;
                final activeSellers = sellerProvider.sellers.where((seller) => seller.isActive).length;
                
            return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.teal[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                              DateFormat('dd MMM yyyy').format(_selectedDate),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                                fontSize: 16,
                          ),
                        ),
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 18),
                              onPressed: () {
                                setState(() {});
                              },
                              tooltip: 'Refresh data',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                    Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                            _buildSummaryItem('Total Quantity', '${totalQuantity.toStringAsFixed(2)} L', Icons.water_drop, Colors.blue),
                            _buildSummaryItem('Total Amount', '₹${totalAmount.toStringAsFixed(2)}', Icons.currency_rupee, Colors.green),
                            _buildSummaryItem('Active Sellers', '$activeSellers/$totalSellers', Icons.people, Colors.orange),
                          ],
                        ),
                  ],
                ),
              ),
            );
              },
            ),
          ),
          
          // Filter and Payment button row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                // Filter button
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showFilterDialog();
                    },
                    icon: const Icon(Icons.filter_list, size: 16),
                    label: const Text('Filter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade100,
                      foregroundColor: Colors.blue.shade800,
                      minimumSize: const Size(0, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                
                // Add spacing between buttons
                const SizedBox(width: 8),
                
                // Add Payment button
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MilkPaymentsScreen()),
                      );
                    },
                    icon: const Icon(Icons.payments, size: 16),
                    label: const Text('Payments'),
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
          
          // Sellers list title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
                const Icon(Icons.people, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  'Seller List',
                  style: TextStyle(
              fontSize: 14,
                    fontWeight: FontWeight.w500,
            ),
          ),
                const Spacer(),
          Text(
                  DateFormat('dd MMM yyyy').format(_selectedDate),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
            ),
          ),
        ],
      ),
          ),
          
          // Seller entries list
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
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: entriesBySeller.length,
                  itemBuilder: (context, index) {
                    final sellerId = entriesBySeller.keys.elementAt(index);
                    final entries = entriesBySeller[sellerId]!;
                    return _buildSellerEntryCard(sellerId, entries, sellerProvider);
                  },
                );
              },
                ),
              ),
            ],
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to seller screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MilkSellerScreen()),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.person_add),
        tooltip: 'Add Seller',
      ),
    );
  }

  // Helper for summary card items
  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Column(
        children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
            Text(
          title,
                                style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
                              ),
                            ),
                          ],
    );
  }

  // Filter dialog method
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
                'Filter Entries',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
              const SizedBox(height: 20),
              const Text('Time of Day'),
              Wrap(
                spacing: 8,
              children: [
                  FilterChip(
                    label: const Text('Morning'),
                    selected: true,
                    onSelected: (selected) {},
                  ),
                  FilterChip(
                    label: const Text('Evening'),
                    selected: true,
                    onSelected: (selected) {},
                  ),
                ],
                ),
                const SizedBox(height: 16),
              const Text('Sort By'),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Name'),
                    selected: true,
                    onSelected: (selected) {},
                  ),
                  ChoiceChip(
                    label: const Text('Quantity'),
                    selected: false,
                    onSelected: (selected) {},
                  ),
                  ChoiceChip(
                    label: const Text('Amount'),
                    selected: false,
                    onSelected: (selected) {},
          ),
        ],
      ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Apply Filters'),
                      ),
                    ),
                  ],
          ),
        );
      },
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

  // Helper method to build entry detail items with consistent formatting
  Widget _buildEntryDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
                        style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
                      Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
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

  void _selectDate(BuildContext context) {
    showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    ).then((picked) {
      if (picked != null && picked != _selectedDate) {
        setState(() {
          _selectedDate = picked;
        });
      }
    });
  }
} 