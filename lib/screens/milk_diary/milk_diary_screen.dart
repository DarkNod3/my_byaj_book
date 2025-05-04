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
import 'add_entry_bottom_sheet.dart';
import 'milk_seller_screen.dart';
import 'milk_payments_screen.dart';
import 'package:uuid/uuid.dart';
import 'seller_profile_screen.dart';
import 'dart:io';
import '../../services/milk_diary_report_service.dart';
import 'milk_seller_bottom_sheet.dart';
import 'package:timeago/timeago.dart' as timeago;

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
          
            // Date selector row - replacing search bar with just the date selector
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Date display
                  Text(
                    DateFormat('dd MMM yyyy').format(_selectedDate),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
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
          
            // Smaller summary card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Consumer2<DailyEntryProvider, MilkSellerProvider>(
                builder: (context, entryProvider, sellerProvider, child) {
                  final entriesForDate = entryProvider.getEntriesForDate(_selectedDate);
                  final allEntries = entryProvider.entries;
                  
                  // Get all sellers
                  final allSellers = sellerProvider.sellers;
                  
                  // Count sellers with entries for the selected date
                  final sellerIdsWithEntriesToday = entriesForDate.map((e) => e.sellerId).toSet();
                  final activeSellersToday = sellerIdsWithEntriesToday.length;
                  
                  // Calculate statistics with proper rounding
                  final totalQuantity = entriesForDate.isEmpty ? 0.0 :
                    double.parse(entriesForDate.fold(0.0, (sum, entry) => sum + entry.quantity).toStringAsFixed(2));
                    
                  final totalAmount = entriesForDate.isEmpty ? 0.0 :
                    double.parse(entriesForDate.fold(0.0, (sum, entry) => sum + entry.amount).toStringAsFixed(2));
                  
                  // Get real seller counts
                  final totalSellers = allSellers.length;
                  
                  // Get payments data - replace with real implementation later
                  final totalPaid = 0.0; 
                  final dueAmount = totalAmount - totalPaid;
                  
                  return Column(
                    children: [
                      // Top row with 4 statistics
                      Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.teal[50],
                    child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                      child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                              // Total Sellers
                          Expanded(
                                child: _buildSummaryItem(
                                  '$activeSellersToday/$totalSellers',
                                  'Sellers',
                                  Icons.people,
                                  Colors.purple,
                                ),
                              ),
                              
                              // Total Milk Today
                              Expanded(
                                child: _buildSummaryItem(
                                  '${totalQuantity.toStringAsFixed(2)} L',
                                  'Milk Today',
                                  Icons.water_drop,
                                  Colors.blue,
                                ),
                              ),
                              
                              // Total Amount
                              Expanded(
                                child: _buildSummaryItem(
                                  '₹${totalAmount.toStringAsFixed(0)}',
                                  'Total Amount',
                                  Icons.currency_rupee,
                                  Colors.green,
                                ),
                              ),
                              
                              // Payments Received
                              Expanded(
                                child: _buildSummaryItem(
                                  '₹${totalPaid.toStringAsFixed(0)}',
                                  'Received',
                                  Icons.payments,
                                  Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Payment Due (full width below)
                      const SizedBox(height: 8),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: Colors.red[50],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                            child: Row(
                              children: [
                              Icon(Icons.account_balance_wallet, color: Colors.red[700]),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Payment Due',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '₹${dueAmount.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.red[700],
                                    ),
                            ),
                                ],
                              ),
                              const Spacer(),
                              OutlinedButton.icon(
                            onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const MilkPaymentsScreen()),
                                  );
                            },
                                icon: const Icon(Icons.visibility, size: 16),
                                label: const Text('View Details'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red[700],
                                  side: BorderSide(color: Colors.red[300]!),
                                ),
                          ),
                        ],
                      ),
                    ),
                      ),
                    ],
                  );
                },
              ),
            ),
          
            // Filter and Payment button row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Row(
                children: [
                  // Add Payment button (previously Filter button)
                  Expanded(
                    flex: 1,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showAddPaymentDialog();
                      },
                      icon: const Icon(Icons.add_card, size: 16),
                      label: const Text('Add Payment'),
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
                  
                  // View Payments button (unchanged)
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
                ],
              ),
            ),
          
            // Seller entries list - simplified to show less detail
            Expanded(
              child: Consumer2<DailyEntryProvider, MilkSellerProvider>(
                builder: (context, entryProvider, sellerProvider, child) {
                  final entriesForDate = entryProvider.getEntriesForDate(_selectedDate);
                  final allSellers = sellerProvider.sellers;
                  
                  if (entriesForDate.isEmpty) {
                    if (allSellers.isEmpty) {
                      // No sellers available
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                              'No sellers added yet',
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const MilkSellerScreen()),
                                );
                              },
                              icon: const Icon(Icons.person_add),
                              label: const Text('Add Seller'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                              ),
                          ),
                        ],
                      ),
                    );
                    } else {
                      // Sellers exist but no entries for this date
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: allSellers.length,
                        itemBuilder: (context, index) {
                          final seller = allSellers[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.purple.shade100,
                                child: Text(
                                  seller.name.isNotEmpty ? seller.name[0].toUpperCase() : '?',
                                  style: TextStyle(color: Colors.purple.shade800, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                seller.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Default Rate: ₹${seller.defaultRate.toStringAsFixed(2)}/L',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                  // Add last entry time in relative format
                                  Consumer<DailyEntryProvider>(
                                    builder: (context, entryProvider, child) {
                                      final sellerEntries = entryProvider.getEntriesForSeller(seller.id);
                                      if (sellerEntries.isNotEmpty) {
                                        // Find most recent entry
                                        final latestEntry = sellerEntries.reduce((a, b) => 
                                          a.date.isAfter(b.date) ? a : b
                                        );
                                        // Format as relative time (e.g., "5 minutes ago")
                                        final relativeTime = timeago.format(latestEntry.date);
                                        return Text(
                                          'Last entry: $relativeTime',
                                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                        );
                                      } else {
                                        return const Text(
                                          'No entries yet',
                                          style: TextStyle(fontSize: 11, color: Colors.grey),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                              // Add pending amount on the right
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Pending amount chip
                                  Consumer<DailyEntryProvider>(
                                    builder: (context, entryProvider, child) {
                                      final sellerEntries = entryProvider.getEntriesForSeller(seller.id);
                                      // Calculate total amount for this seller
                                      final totalAmount = sellerEntries.fold(0.0, (sum, entry) => sum + entry.amount);
                                      // This is a placeholder - in a real app, you would subtract payments from total
                                      final pendingAmount = totalAmount; // Implement your payment logic here
                                      
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: pendingAmount > 0 ? Colors.red.shade50 : Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '₹${pendingAmount.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            color: pendingAmount > 0 ? Colors.red.shade800 : Colors.green.shade800,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  
                                  const SizedBox(width: 4),
                                  
                                  // Add Entry icon
                                  IconButton(
                                    icon: const Icon(Icons.add_circle, color: Colors.green, size: 22),
                                    onPressed: () {
                                      AddEntryBottomSheet.show(
                                        context,
                                        sellerId: seller.id,
                                        initialDate: _selectedDate,
                                      );
                                    },
                                    tooltip: 'Add Entry',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  
                                  const SizedBox(width: 4),
                                  
                                  // Menu options (including PDF report)
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 22),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => SellerProfileScreen(seller: seller),
                                          ),
                                        );
                                      } else if (value == 'delete') {
                                        _confirmDeleteSeller(seller);
                                      } else if (value == 'report') {
                                        _generateSellerReportDirectly(seller);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 18),
                                            SizedBox(width: 8),
                                            Text('Edit Seller'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'report',
                                        child: Row(
                                          children: [
                                            Icon(Icons.picture_as_pdf, size: 18, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Generate Report'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, size: 18, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Delete Seller', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              onTap: () {
                                // Navigate to seller profile
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SellerProfileScreen(seller: seller),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    }
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
                      return _buildSimplifiedSellerCard(sellerId, entries, sellerProvider);
                    },
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: FloatingActionButton.extended(
          onPressed: () {
              // Show bottom sheet instead of navigating to a new screen
              showModalBottomSheet(
                context: context,
                isScrollControlled: true, // This allows the sheet to expand to its content
                backgroundColor: Colors.transparent,
                builder: (context) => const MilkSellerBottomSheet(),
              ).then((seller) {
                if (seller != null) {
                  // Handle the new seller
                  final sellerProvider = Provider.of<MilkSellerProvider>(context, listen: false);
                  try {
                    sellerProvider.addSeller(seller);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Seller added successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error adding seller: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              });
            },
            backgroundColor: Colors.deepPurple,
            icon: const Icon(Icons.person_add, color: Colors.white),
            label: const Text(
              'Add Seller',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 4,
          ),
        ),
    );
  }

  // More compact summary item for the smaller card
  Widget _buildCompactSummaryItem(String value, String title, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // Simplified seller card that hides detailed milk info
  Widget _buildSimplifiedSellerCard(String sellerId, List<DailyEntry> entries, MilkSellerProvider sellerProvider) {
    final seller = sellerProvider.getSellerById(sellerId);
    final sellerName = seller?.name ?? 'Unknown Seller';
    
    // Calculate seller totals
    final totalQuantity = entries.fold(0.0, (sum, entry) => sum + entry.quantity);
    final totalAmount = entries.fold(0.0, (sum, entry) => sum + entry.amount);
    
    // Get latest entry for last updated time
    final latestEntry = entries.reduce((a, b) => 
      a.date.isAfter(b.date) ? a : b
    );
    final lastUpdated = DateFormat('dd MMM, hh:mm a').format(latestEntry.date);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          // Navigate to seller profile when card is tapped
          if (seller != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SellerProfileScreen(seller: seller),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seller name and actions row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    sellerName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () {
                          // Navigate to edit
                          if (seller != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SellerProfileScreen(seller: seller),
                              ),
                            );
                          }
                        },
                        tooltip: 'Edit',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        onPressed: () => _confirmDeleteEntry(entries.first),
                        tooltip: 'Delete',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
              
              const Divider(),
              
              // Summary information only - no details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Quantity
                  Row(
                    children: [
                      const Icon(Icons.water_drop, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        '${totalQuantity.toStringAsFixed(2)} L',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  
                  // Amount
                  Row(
                    children: [
                      const Icon(Icons.currency_rupee, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        '${totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Last updated time and tap for details hint
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Last updated
                  Text(
                    'Updated: $lastUpdated',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  // Hint to tap for more
                  Text(
                    'Tap for details',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for summary card items - kept for reference
  Widget _buildSummaryItem(String value, String title, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
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

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showFilterDialog() {
    // Default filter values
    String? selectedSellerId;
    EntryShift? selectedShift;
    MilkType? selectedMilkType;
    DateTimeRange? dateRange;
    
    final startOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final endOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Filter Entries'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seller filter
                    const Text('Seller', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Consumer<MilkSellerProvider>(
                      builder: (context, sellerProvider, child) {
                        final sellers = sellerProvider.sellers;
                        
                        return DropdownButtonFormField<String?>(
                          value: selectedSellerId,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            isDense: true,
                          ),
                          hint: const Text('All Sellers'),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All Sellers'),
                            ),
                            ...sellers.map((seller) {
                              return DropdownMenuItem<String?>(
                                value: seller.id,
                                child: Text(seller.name),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedSellerId = value;
                            });
                          },
                        );
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Shift filter
                    const Text('Shift', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: selectedShift == null,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                selectedShift = null;
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Morning'),
                          selected: selectedShift == EntryShift.morning,
                          onSelected: (selected) {
                            setState(() {
                              selectedShift = selected ? EntryShift.morning : null;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Evening'),
                          selected: selectedShift == EntryShift.evening,
                          onSelected: (selected) {
                            setState(() {
                              selectedShift = selected ? EntryShift.evening : null;
                            });
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Milk type filter
                    const Text('Milk Type', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: selectedMilkType == null,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                selectedMilkType = null;
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Cow'),
                          selected: selectedMilkType == MilkType.cow,
                          onSelected: (selected) {
                            setState(() {
                              selectedMilkType = selected ? MilkType.cow : null;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Buffalo'),
                          selected: selectedMilkType == MilkType.buffalo,
                          onSelected: (selected) {
                            setState(() {
                              selectedMilkType = selected ? MilkType.buffalo : null;
                            });
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Date range filter
                    const Text('Date Range', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final result = await showDateRangePicker(
                                context: context,
                                initialDateRange: dateRange ?? DateTimeRange(
                                  start: startOfMonth,
                                  end: endOfMonth,
                                ),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              
                              if (result != null) {
                                setState(() {
                                  dateRange = result;
                                });
                              }
                            },
                            child: Text(
                              dateRange != null
                                ? '${DateFormat('dd/MM/yy').format(dateRange!.start)} - ${DateFormat('dd/MM/yy').format(dateRange!.end)}'
                                : 'Select Date Range',
                            ),
                          ),
                        ),
                        if (dateRange != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                dateRange = null;
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ),
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
                  // Apply the filter
                  final entryProvider = Provider.of<DailyEntryProvider>(context, listen: false);
                  
                  // Create a filter function to apply all selected filters
                  bool Function(DailyEntry) filterFunction = (entry) {
                    // Seller filter
                    if (selectedSellerId != null && entry.sellerId != selectedSellerId) {
                      return false;
                    }
                    
                    // Shift filter
                    if (selectedShift != null && entry.shift != selectedShift) {
                      return false;
                    }
                    
                    // Milk type filter
                    if (selectedMilkType != null && entry.milkType != selectedMilkType) {
                      return false;
                    }
                    
                    // Date range filter
                    if (dateRange != null) {
                      final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
                      final start = DateTime(dateRange!.start.year, dateRange!.start.month, dateRange!.start.day);
                      final end = DateTime(dateRange!.end.year, dateRange!.end.month, dateRange!.end.day);
                      
                      if (date.isBefore(start) || date.isAfter(end)) {
                        return false;
                      }
                    }
                    
                    return true;
                  };
                  
                  // Apply the filter
                  entryProvider.setFilter(filterFunction);
                  
                  // If a date range is selected, update the selected date to the start of the range
                  if (dateRange != null) {
                    this.setState(() {
                      _selectedDate = dateRange!.start;
                    });
                  }
                  
                  Navigator.of(context).pop();
                  
                  // Show filter indicator
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Filter applied${selectedSellerId != null ? " for seller" : ""}' +
                        '${selectedShift != null ? " with ${selectedShift == EntryShift.morning ? "morning" : "evening"} shift" : ""}' +
                        '${selectedMilkType != null ? " for ${selectedMilkType == MilkType.cow ? "cow" : "buffalo"} milk" : ""}' +
                        '${dateRange != null ? " in date range" : ""}'
                      ),
                      action: SnackBarAction(
                        label: 'CLEAR',
                        onPressed: () {
                          entryProvider.clearFilter();
                          this.setState(() {});
                        },
                      ),
                    ),
                  );
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showReportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            const Text(
              'Generate Report',
                  style: TextStyle(
                    fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              ),
            const SizedBox(height: 16),
            
            // Daily Report
              ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.calendar_today, color: Colors.blue.shade800),
              ),
                title: const Text('Daily Report'),
              subtitle: Text('For ${DateFormat('dd MMM yyyy').format(_selectedDate)}'),
                onTap: () {
                  Navigator.pop(context);
                _generateDailyReport();
                },
              ),
            
            // Monthly Report
              ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.date_range, color: Colors.green.shade800),
              ),
                title: const Text('Monthly Report'),
              subtitle: Text('For ${DateFormat('MMMM yyyy').format(_selectedDate)}'),
                onTap: () {
                  Navigator.pop(context);
                _generateMonthlyReport();
              },
            ),
            
            // Seller Report
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person, color: Colors.purple.shade800),
              ),
              title: const Text('Seller Report'),
              subtitle: const Text('Select a seller and date range'),
              onTap: () {
                Navigator.pop(context);
                _showSellerReportDialog();
                },
              ),
            ],
          ),
      ),
        );
  }

  void _generateDailyReport() async {
    try {
      final entryProvider = Provider.of<DailyEntryProvider>(context, listen: false);
      final sellerProvider = Provider.of<MilkSellerProvider>(context, listen: false);
      
      // Check if we need to first load a font
      final fontFile = File('assets/fonts/Roboto-Regular.ttf');
      if (!await fontFile.exists()) {
        // Create the fonts directory if it doesn't exist
        final fontDir = Directory('assets/fonts');
        if (!await fontDir.exists()) {
          await fontDir.create(recursive: true);
        }
        
        // Show a message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Font file is missing. Please add Roboto-Regular.ttf to assets/fonts/'),
          ),
        );
        return;
      }
      
      // Show loading indicator
      showDialog(
        context: context,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Generate the report
      final reportService = MilkDiaryReportService(
        entryProvider: entryProvider,
        sellerProvider: sellerProvider,
      );
      
      await reportService.generateDailyReport(_selectedDate);
      
      // Close loading indicator
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Close loading indicator
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Error generating report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _generateMonthlyReport() async {
    try {
      final entryProvider = Provider.of<DailyEntryProvider>(context, listen: false);
      final sellerProvider = Provider.of<MilkSellerProvider>(context, listen: false);
      
      // Show loading indicator
      showDialog(
      context: context,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Generate the report
      final reportService = MilkDiaryReportService(
        entryProvider: entryProvider,
        sellerProvider: sellerProvider,
      );
      
      await reportService.generateMonthlyReport(_selectedDate);
      
      // Close loading indicator
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Close loading indicator
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSellerReportDialog() {
    // Default values
    String? selectedSellerId;
    DateTime fromDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
    DateTime toDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Generate Seller Report'),
            content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // Seller selection
                const Text('Select Seller'),
                const SizedBox(height: 8),
                Consumer<MilkSellerProvider>(
                  builder: (context, sellerProvider, child) {
                    final sellers = sellerProvider.sellers;
                    
                    return DropdownButtonFormField<String>(
                      value: selectedSellerId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      hint: const Text('Select a seller'),
                      items: sellers.map((seller) {
                        return DropdownMenuItem<String>(
                          value: seller.id,
                          child: Text(seller.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedSellerId = value;
                        });
                      },
                    );
                  },
              ),
                
                const SizedBox(height: 16),
                
                // Date range selection
                const Text('Date Range'),
                const SizedBox(height: 8),
                Row(
                children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: fromDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          
                          if (picked != null && picked != fromDate) {
                            setState(() {
                              fromDate = picked;
                              
                              // Ensure toDate is after fromDate
                              if (toDate.isBefore(fromDate)) {
                                toDate = fromDate;
                              }
                            });
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: Text(DateFormat('dd/MM/yy').format(fromDate)),
                        ),
                      ),
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('to'),
                    ),
                    
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: toDate,
                            firstDate: fromDate,
                            lastDate: DateTime.now(),
                          );
                          
                          if (picked != null && picked != toDate) {
                            setState(() {
                              toDate = picked;
                            });
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: Text(DateFormat('dd/MM/yy').format(toDate)),
                        ),
                      ),
                  ),
                ],
              ),
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
                onPressed: selectedSellerId == null ? null : () {
                  Navigator.of(context).pop();
                  _generateSellerReport(selectedSellerId!, fromDate, toDate);
                },
                child: const Text('Generate'),
              ),
            ],
        );
      },
      ),
    );
  }

  void _generateSellerReport(String sellerId, DateTime fromDate, DateTime toDate) async {
    try {
      final entryProvider = Provider.of<DailyEntryProvider>(context, listen: false);
      final sellerProvider = Provider.of<MilkSellerProvider>(context, listen: false);
      
      final seller = sellerProvider.getSellerById(sellerId);
      if (seller == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seller not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Show loading indicator
      showDialog(
        context: context,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Generate the report
      final reportService = MilkDiaryReportService(
        entryProvider: entryProvider,
        sellerProvider: sellerProvider,
      );
      
      await reportService.generateSellerReport(seller, fromDate, toDate);
      
      // Close loading indicator
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Close loading indicator if open
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmDeleteEntry(DailyEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this entry? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteEntry(entry);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteEntry(DailyEntry entry) async {
    try {
    final entryProvider = Provider.of<DailyEntryProvider>(context, listen: false);
      await entryProvider.deleteEntry(entry.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entry deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting entry: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddPaymentDialog() {
    String? selectedSellerId;
    final paymentAmountController = TextEditingController();
    final remarksController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Payment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seller dropdown
              const Text('Select Seller', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Consumer<MilkSellerProvider>(
                builder: (context, sellerProvider, child) {
                  final sellers = sellerProvider.sellers;
                  return DropdownButtonFormField<String>(
                    value: selectedSellerId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    hint: const Text('Select a seller'),
                    items: sellers.map((seller) {
                      return DropdownMenuItem<String>(
                        value: seller.id,
                        child: Text(seller.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedSellerId = value;
                    },
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              // Payment amount
              const Text('Payment Amount', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: paymentAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.currency_rupee),
                  hintText: 'Enter amount',
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Remarks
              const Text('Remarks (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: remarksController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Add notes about this payment',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Dispose controllers before closing dialog
              paymentAmountController.dispose();
              remarksController.dispose();
              Navigator.pop(context);
            },
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              // Validate and save payment
              if (selectedSellerId != null && paymentAmountController.text.isNotEmpty) {
                try {
                  final amount = double.parse(paymentAmountController.text);
                  // Here you would save the payment to your payment provider
                  // This is a placeholder - implement actual payment saving
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment added successfully')),
                  );
                  // Dispose controllers before closing dialog
                  paymentAmountController.dispose();
                  remarksController.dispose();
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a seller and enter an amount')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('ADD PAYMENT'),
          ),
        ],
      ),
    ).then((_) {
      // Ensure controllers are disposed if dialog is dismissed in other ways
      if (paymentAmountController.hasListeners) {
        paymentAmountController.dispose();
      }
      if (remarksController.hasListeners) {
        remarksController.dispose();
      }
    });
  }

  void _confirmDeleteSeller(MilkSeller seller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Seller'),
        content: Text('Are you sure you want to delete ${seller.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final sellerProvider = Provider.of<MilkSellerProvider>(context, listen: false);
              final entryProvider = Provider.of<DailyEntryProvider>(context, listen: false);
              
              final sellerEntries = entryProvider.getEntriesForSeller(seller.id);
              if (sellerEntries.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cannot delete seller with existing entries (${sellerEntries.length} entries found)'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              sellerProvider.deleteSeller(seller.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${seller.name} has been deleted'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  void _generateSellerReportDirectly(MilkSeller seller) async {
    try {
      final entryProvider = Provider.of<DailyEntryProvider>(context, listen: false);
      final sellerProvider = Provider.of<MilkSellerProvider>(context, listen: false);
      
      // Default to current month for the report
      final now = DateTime.now();
      final fromDate = DateTime(now.year, now.month, 1);
      final toDate = DateTime(now.year, now.month + 1, 0);
      
      // Show loading indicator
      showDialog(
      context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Generate the report
      final reportService = MilkDiaryReportService(
        entryProvider: entryProvider,
        sellerProvider: sellerProvider,
      );
      
      await reportService.generateSellerReport(seller, fromDate, toDate);
      
      // Close loading indicator
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report generated for ${seller.name}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close loading indicator if open
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 