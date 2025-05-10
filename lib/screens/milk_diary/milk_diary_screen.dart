import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter/services.dart';
import '../../constants/app_theme.dart';
import '../../models/milk_diary/daily_entry.dart';
import '../../models/milk_diary/milk_seller.dart';
import '../../models/milk_diary/milk_payment.dart';
import '../../providers/milk_diary/daily_entry_provider.dart';
import '../../providers/milk_diary/milk_seller_provider.dart';
import '../../services/milk_diary_report_service.dart';
import 'milk_diary_add_entry.dart';
import 'milk_diary_add_seller.dart';

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
  final DateTime _selectedDate = DateTime.now();
  
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

  // Create a summary item widget
  Widget _buildSummaryItem(String value, String title, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
          children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
                            style: TextStyle(
            fontSize: 16,
                              fontWeight: FontWeight.bold,
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
  
  // Navigate to add entry screen
  void _navigateToAddEntry({String? sellerId}) {
    if (sellerId != null) {
      // Show the add entry bottom sheet
      MilkDiaryAddEntry.showAddEntryBottomSheet(
        context,
        sellerId: sellerId,
        initialDate: _selectedDate,
      );
    } else {
      // Show snackbar that seller must be selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a seller first'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  // Show seller details
  void _showSellerDetails(BuildContext context, String sellerId) {
    final sellerProvider = Provider.of<MilkSellerProvider>(context, listen: false);
    final seller = sellerProvider.getSellerById(sellerId);
    
    if (seller != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SellerProfileScreen(seller: seller),
        ),
      );
    }
  }
  
  // Show add seller dialog
  void _showAddSellerBottomSheet() {
    MilkDiaryAddSeller.showAddSellerBottomSheet(context).then((seller) {
      if (seller != null && mounted) {
        // Add seller to provider
        final sellerProvider = Provider.of<MilkSellerProvider>(context, listen: false);
        sellerProvider.addSeller(seller);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seller added successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }
  
  // Time ago format for last entry
  String _timeAgo(DateTime date) {
    return timeago.format(date, locale: 'en_short');
  }
  
  // Updated _buildSummaryCard method to show complete history and current month dues
  Widget _buildSummaryCard(BuildContext context) {
    return Consumer2<DailyEntryProvider, MilkSellerProvider>(
                builder: (context, entryProvider, sellerProvider, child) {
        // Current month calculations for the 4th button
        final now = DateTime.now();
        final DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
        final DateTime lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
        
        // Format for date range display
        final String dateRangeText = "1-${now.day} ${DateFormat('MMM yyyy').format(now)}";
        
        // Get entries for current month (for 4th button only)
        final entriesForMonth = entryProvider.getEntriesInDateRange(firstDayOfMonth, lastDayOfMonth);
        final monthlyAmount = entriesForMonth.isEmpty ? 0.0 :
          double.parse(entriesForMonth.fold(0.0, (sum, entry) => sum + entry.amount).toStringAsFixed(2));
        
        // Get payments for current month (for 4th button only)
        final allPayments = sellerProvider.payments;
        final validPayments = allPayments.where((payment) => 
          sellerProvider.getSellerById(payment.sellerId) != null
        ).toList();
        
        final paymentsForMonth = validPayments.where((payment) => 
          payment.date.isAfter(firstDayOfMonth.subtract(const Duration(days: 1))) &&
          payment.date.isBefore(lastDayOfMonth.add(const Duration(days: 1)))
        ).toList();
        
        final monthlyPaid = paymentsForMonth.isEmpty ? 0.0 :
          double.parse(paymentsForMonth.fold(0.0, (sum, payment) => sum + payment.amount).toStringAsFixed(2));
        
        // Calculate monthly dues by seller (only consider positive dues)
        final Map<String, double> sellerMonthlyDues = {};
        final sellers = sellerProvider.sellers;
        
        // Calculate each seller's monthly due amount
        for (var seller in sellers) {
          // Get seller's entries for this month
          final sellerEntries = entriesForMonth.where((entry) => entry.sellerId == seller.id).toList();
          final sellerAmount = sellerEntries.isEmpty ? 0.0 :
            sellerEntries.fold(0.0, (sum, entry) => sum + entry.amount);
            
          // Get seller's payments for this month
          final sellerPayments = paymentsForMonth.where((payment) => payment.sellerId == seller.id).toList();
          final sellerPaid = sellerPayments.isEmpty ? 0.0 :
            sellerPayments.fold(0.0, (sum, payment) => sum + payment.amount);
            
          // Calculate due amount (can be negative if paid in advance)
          sellerMonthlyDues[seller.id] = sellerAmount - sellerPaid;
        }
        
        // Sum only positive dues for the monthly due total (ignore negative dues)
        final monthlyDue = sellerMonthlyDues.values
          .where((due) => due > 0) // Only consider positive dues
          .fold(0.0, (sum, due) => sum + due);
        
        // Get all-time entries and payments (for first 3 buttons)
        final allEntries = entryProvider.entries;
        final allTimeAmount = allEntries.isEmpty ? 0.0 :
          double.parse(allEntries.fold(0.0, (sum, entry) => sum + entry.amount).toStringAsFixed(2));
        
        final allTimePaid = validPayments.isEmpty ? 0.0 :
          double.parse(validPayments.fold(0.0, (sum, payment) => sum + payment.amount).toStringAsFixed(2));
        
        // Calculate all-time dues by seller (only consider positive dues)
        final Map<String, double> sellerAllTimeDues = {};
        
        // Calculate each seller's all-time due amount
        for (var seller in sellers) {
          // Get all of seller's entries
          final sellerAllEntries = allEntries.where((entry) => entry.sellerId == seller.id).toList();
          final sellerAllAmount = sellerAllEntries.isEmpty ? 0.0 :
            sellerAllEntries.fold(0.0, (sum, entry) => sum + entry.amount);
            
          // Get all of seller's payments
          final sellerAllPayments = validPayments.where((payment) => payment.sellerId == seller.id).toList();
          final sellerAllPaid = sellerAllPayments.isEmpty ? 0.0 :
            sellerAllPayments.fold(0.0, (sum, payment) => sum + payment.amount);
            
          // Calculate due amount (can be negative if paid in advance)
          sellerAllTimeDues[seller.id] = sellerAllAmount - sellerAllPaid;
        }
        
        // Sum only positive dues for the all-time due total (ignore negative dues/advance payments)
        final allTimeDue = sellerAllTimeDues.values
          .where((due) => due > 0) // Only consider positive dues
          .fold(0.0, (sum, due) => sum + due);
        
        return Column(
          children: [
            // Date range display
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.date_range, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    "All-Time + ${DateFormat('MMM yyyy').format(now)}",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            
            // Top row with statistics
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
                          // Total All-Time Amount
                          Expanded(
                            child: _buildSummaryItem(
                              '₹${allTimeAmount.toStringAsFixed(0)}',
                              'Total Amount',
                              Icons.currency_rupee,
                              Colors.green,
                            ),
                          ),
                          
                          // All-Time Received Amount
                          Expanded(
                            child: _buildSummaryItem(
                              '₹${allTimePaid.toStringAsFixed(0)}',
                              'All Received',
                              Icons.payments,
                              Colors.purple,
                            ),
                          ),
                          
                          // All-Time Due Amount
                          Expanded(
                            child: _buildSummaryItem(
                              '₹${allTimeDue.toStringAsFixed(0)}',
                              'Total Due',
                              Icons.account_balance_wallet,
                              Colors.red,
                            ),
                          ),
                          
                          // This Month Dues Only
                          Expanded(
                            child: _buildSummaryItem(
                              '₹${monthlyDue.toStringAsFixed(0)}',
                              '${DateFormat('MMM').format(now)} Dues',
                              Icons.calendar_month,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
  
  // Fix for the pending dues section to prevent overflow
  Widget _buildPendingDuesSection(BuildContext context) {
    return Consumer2<DailyEntryProvider, MilkSellerProvider>(
      builder: (context, entryProvider, sellerProvider, child) {
        final sellers = sellerProvider.sellers;
        
        // Calculate pending dues for each seller
        Map<String, double> pendingDues = {};
        
        // Only process if there are sellers
        if (sellers.isNotEmpty) {
          for (var seller in sellers) {
            final entries = entryProvider.getEntriesForSeller(seller.id);
            final totalAmount = entries.isEmpty ? 0.0 :
              entries.fold(0.0, (sum, entry) => sum + entry.amount);
            
            // Get payments for this seller and calculate actual due amount
            final sellerPayments = sellerProvider.getPaymentsForSeller(seller.id);
            final totalPaid = sellerPayments.isEmpty ? 0.0 :
              sellerPayments.fold(0.0, (sum, payment) => sum + payment.amount);
            
            pendingDues[seller.id] = totalAmount - totalPaid;
            
            // Update the seller's due amount for consistency
            seller.updateDueAmount(pendingDues[seller.id] ?? 0.0);
            sellerProvider.updateSeller(seller);
          }
        }
        
        return Row(
          children: [
            // Pending Dues Section
                  Expanded(
              flex: 3,
              child: Card(
                color: Colors.pink[50],
                elevation: 2,
                        shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: Colors.deepOrange,
                            size: 20,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Pending Dues',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                          Spacer(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      if (sellers.isEmpty || pendingDues.values.every((due) => due <= 0))
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'No pending dues',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        )
                      else
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 100),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: sellers
                                .where((seller) => pendingDues[seller.id]! > 0)
                                .take(2) // Show only top 2 sellers with pending dues
                                .map((seller) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              seller.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w400,
                                                fontSize: 13,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            '₹${pendingDues[seller.id]!.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      
                      // Add View More button below the entries
                      if (sellers.where((seller) => pendingDues[seller.id]! > 0).length > 2)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: GestureDetector(
                            onTap: () => _showAllPendingDues(context, sellers, pendingDues),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'View More',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward,
                                  size: 12,
                                  color: Colors.blue[700],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            
                  const SizedBox(width: 8),
                  
            // Payment Actions Card
                  Expanded(
              flex: 2,
              child: SizedBox(
                height: 100,
                child: Card(
                  color: Colors.green[50],
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Add Payment Button
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            // Show add payment dialog for any seller
                            _showAddPaymentDialog(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.payments,
                                  color: Colors.green[800],
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Add Payment',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const Divider(height: 1, thickness: 1, indent: 8, endIndent: 8),
                      
                      // Payment History Button
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            // Navigate to payment history screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MilkPaymentsScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history,
                                  color: Colors.blue[800],
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Payment History',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  // Seller list title row
  Widget _buildSellerListTitle() {
    return const Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey),
            SizedBox(width: 4),
                  Text(
                    'Seller List',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
    );
  }

  // Build seller card with entry history
  Widget _buildSellerCard(String sellerId, List<DailyEntry> entries, MilkSellerProvider sellerProvider) {
    final seller = sellerProvider.getSellerById(sellerId);
    if (seller == null) return const SizedBox();
    
    // Get most recent entry
    final mostRecentEntry = entries.isNotEmpty 
      ? entries.reduce((a, b) => a.date.isAfter(b.date) ? a : b) 
      : null;
    
    // Calculate totals for all entries (not just today)
    final totalAmount = entries.isEmpty ? 0.0 :
      entries.fold(0.0, (sum, entry) => sum + entry.amount);
    
    // Get payments data - calculate actual payments
    final payments = sellerProvider.getPaymentsForSeller(sellerId);
    final totalPaid = payments.isEmpty ? 0.0 :
      payments.fold(0.0, (sum, payment) => sum + payment.amount);
    final amountDue = totalAmount - totalPaid;
    
    // Update seller's due amount for consistency
    seller.updateDueAmount(amountDue);
    sellerProvider.updateSeller(seller);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // First row: Seller info with avatar, name and actions
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left side: Avatar with seller details
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showSellerDetails(context, sellerId),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar
                        CircleAvatar(
                          backgroundColor: Colors.deepPurple,
                          child: Text(
                            seller.name[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Seller details and time ago
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                seller.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (mostRecentEntry != null)
                                Text(
                                  'Last entry: ${_timeAgo(mostRecentEntry.date)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              // Show due amount instead of default rate
                              Text(
                                'Due: ₹${amountDue.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Right side: Add Entry button and more options
                Row(
                  children: [
                    // Add Entry button
                    ElevatedButton.icon(
                      onPressed: () => _navigateToAddEntry(sellerId: sellerId),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Entry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        textStyle: const TextStyle(fontSize: 12),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                    
                    // More options menu
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        switch (value) {
                          case 'add_payment':
                            _showAddPaymentDialogForSeller(context, sellerId);
                            break;
                          case 'view_history':
                            _showSellerDetails(context, sellerId);
                            break;
                          case 'edit_seller':
                            _editSeller(context, seller);
                            break;
                          case 'delete':
                            _confirmDeleteSeller(context, seller);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem<String>(
                          value: 'add_payment',
                          child: Row(
                            children: [
                              Icon(Icons.payments, size: 20, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Add Payment'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'view_history',
                          child: Row(
                            children: [
                              Icon(Icons.history, size: 20, color: Colors.deepPurple),
                              SizedBox(width: 8),
                              Text('View History'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'edit_seller',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Edit Seller'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete Seller'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Method to show a dialog for adding payment for a specific seller
  void _showAddPaymentDialogForSeller(BuildContext context, String sellerId) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final dateController = TextEditingController(
      text: DateFormat('dd-MM-yyyy').format(DateTime.now()),
    );
    
    final sellerProvider = Provider.of<MilkSellerProvider>(context, listen: false);
    final entryProvider = Provider.of<DailyEntryProvider>(context, listen: false);
    final seller = sellerProvider.getSellerById(sellerId);
    
    if (seller == null) return;

    // Calculate due amount
    final entries = entryProvider.getEntriesForSeller(sellerId);
    final totalAmount = entries.isEmpty ? 0.0 :
      entries.fold(0.0, (sum, entry) => sum + entry.amount);
    
    final sellerPayments = sellerProvider.getPaymentsForSeller(sellerId);
    final totalPayments = sellerPayments.isEmpty ? 0.0 :
      sellerPayments.fold(0.0, (sum, payment) => sum + payment.amount);
    
    final dueAmount = totalAmount - totalPayments;
    
    // Update seller's due amount for future reference
    seller.updateDueAmount(dueAmount);
      
    // Store a reference to the current context for later use
    final BuildContext currentContext = context;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Payment for ${seller.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Due Amount: ₹${dueAmount.toStringAsFixed(2)}', 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: dueAmount > 0 ? Colors.red : Colors.green,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Date',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        dateController.text = DateFormat('dd-MM-yyyy').format(date);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (amountController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter an amount'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid amount'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              
              // Parse date
              DateTime date;
              try {
                date = DateFormat('dd-MM-yyyy').parse(dateController.text);
              } catch (e) {
                date = DateTime.now();
              }
              
              // Create payment record
              final payment = MilkPayment(
                id: const Uuid().v4(),
                sellerId: sellerId,
                amount: amount,
                date: date,
                note: noteController.text,
              );
              
              // Add payment
              sellerProvider.addPayment(payment);
              
              // Update the seller's due amount
              final updatedDueAmount = dueAmount - amount;
              seller.updateDueAmount(updatedDueAmount);
              sellerProvider.updateSeller(seller);
              
              // Show success message
              Navigator.pop(context);
              ScaffoldMessenger.of(currentContext).showSnackBar(
                SnackBar(
                  content: Text('Payment of ₹${amount.toStringAsFixed(2)} added successfully'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Add Payment', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }
  
  // Main app bar
  Widget _buildAppBar() {
    // Get status bar height
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
        return Container(
              color: AppTheme.primaryColor,
              child: Column(
                children: [
          // Status bar space
                  SizedBox(height: statusBarHeight),
                  
                  // App bar content
                  if (widget.showAppBar) 
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          // Back button when shown from More Tools
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 16),
                          
                  // Title
                          const Text(
                            'Milk Diary',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Empty space to push title to left side
                          const Spacer(),
                        ],
                      ),
                    ),
                ],
              ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove default body padding/safe area
      body: Column(
                children: [
          // App bar
          _buildAppBar(),
        
          // Main content area
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // Refresh state (no actual network refresh needed since data is local)
                setState(() {});
              },
              child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    children: [
                  // Summary card
                  _buildSummaryCard(context),
                  
                  // Pending Dues and Add Seller section (1x2 layout)
              const SizedBox(height: 16),
                  _buildPendingDuesSection(context),
                  
                  // Seller list title
                  const SizedBox(height: 24),
                  _buildSellerListTitle(),
                  const SizedBox(height: 12),
                  
                  // Seller list
                  Consumer2<DailyEntryProvider, MilkSellerProvider>(
                builder: (context, entryProvider, sellerProvider, child) {
                      final entries = entryProvider.entries;
                      final sellers = sellerProvider.sellers;
                      
                      // Group entries by seller
                      final Map<String, List<DailyEntry>> entriesBySeller = {};
                      
                      for (var entry in entries) {
                        if (!entriesBySeller.containsKey(entry.sellerId)) {
                          entriesBySeller[entry.sellerId] = [];
                        }
                        entriesBySeller[entry.sellerId]!.add(entry);
                      }
                      
                      if (sellers.isEmpty) {
                        return Center(
                    child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Column(
                        children: [
                                Icon(
                                  Icons.people_alt_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                      Text(
                                  'No sellers added yet',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _showAddSellerBottomSheet,
                                  icon: const Icon(Icons.person_add),
                                  label: const Text('Add Seller'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    foregroundColor: Colors.white,
                        ),
                      ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      return Column(
                        children: [
                          // Build a card for each seller
                          ...sellers.map((seller) => _buildSellerCard(
                            seller.id,
                            entriesBySeller[seller.id] ?? [],
                            sellerProvider,
                          )).toList(),
                        ],
                      );
                    },
                  ),
                  
                  // Space at the bottom for better UX
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // FAB for quick actions
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSellerBottomSheet,
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add Seller'),
        tooltip: 'Add Seller',
      ),
    );
  }

  // Add this method to show a dialog for selecting a seller and adding payment
  void _showAddPaymentDialog(BuildContext context) {
    final sellerProvider = Provider.of<MilkSellerProvider>(context, listen: false);
    final entryProvider = Provider.of<DailyEntryProvider>(context, listen: false);
    final sellers = sellerProvider.sellers;
    
    if (sellers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a seller first'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // Calculate due amounts for all sellers
    Map<String, double> dueAmounts = {};
    for (var seller in sellers) {
      // Calculate due amount
      final entries = entryProvider.getEntriesForSeller(seller.id);
      final totalAmount = entries.isEmpty ? 0.0 :
        entries.fold(0.0, (sum, entry) => sum + entry.amount);
      
      final sellerPayments = sellerProvider.getPaymentsForSeller(seller.id);
      final totalPayments = sellerPayments.isEmpty ? 0.0 :
        sellerPayments.fold(0.0, (sum, payment) => sum + payment.amount);
      
      dueAmounts[seller.id] = totalAmount - totalPayments;
      
      // Update the seller's due amount
      seller.updateDueAmount(dueAmounts[seller.id] ?? 0.0);
      sellerProvider.updateSeller(seller);
    }
    
    // Filter sellers to only show those with due amounts
    final sellersWithDues = sellers.where((seller) => dueAmounts[seller.id]! > 0).toList();
    
    if (sellersWithDues.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No sellers with pending dues'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // Show dialog to select seller
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.payments, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Select Seller for Payment',
          style: TextStyle(
                      fontSize: 18,
            fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: sellersWithDues.length,
                itemBuilder: (context, index) {
                  final seller = sellersWithDues[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple,
                      child: Text(
                        seller.name[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(seller.name),
                    subtitle: Text('Due: ₹${dueAmounts[seller.id]!.toStringAsFixed(2)}'),
                    onTap: () {
                      Navigator.pop(context);
                      _showAddPaymentDialogForSeller(context, seller.id);
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Add this new method to show all pending dues in a dialog
  void _showAllPendingDues(BuildContext context, List<MilkSeller> sellers, Map<String, double> pendingDues) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
                children: [
            Icon(
              Icons.account_balance_wallet,
              color: Colors.deepOrange,
              size: 20,
            ),
                  SizedBox(width: 8),
                  Text(
              'All Pending Dues',
                    style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: ListView(
            shrinkWrap: true,
            children: sellers
                .where((seller) => pendingDues[seller.id]! > 0)
                .map((seller) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
            Expanded(
                      child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                                  seller.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                if (seller.mobile != null)
                                  Text(
                                    seller.mobile!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
              ),
            ),
          ],
        ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
      children: [
            Text(
                                '₹${pendingDues[seller.id]!.toStringAsFixed(0)}',
                                style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                                  color: Colors.red,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  _showAddPaymentDialogForSeller(context, seller.id);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Pay Now',
          style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
          ),
        ),
      ],
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Add a new method for editing sellers
  void _editSeller(BuildContext context, MilkSeller seller) async {
    // Use a local variable instead of depending on the widget's mounted property
    final updatedSeller = await MilkDiaryAddSeller.showAddSellerBottomSheet(
      context,
      seller: seller,
    );
    
    // Check if the widget is still mounted using the context.mounted property
    if (updatedSeller != null && context.mounted) {
      // Use the provider from the current context
      Provider.of<MilkSellerProvider>(context, listen: false).updateSeller(updatedSeller);
    }
  }
}

class MilkSellerScreen extends StatelessWidget {
  const MilkSellerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Milk Sellers'),
      ),
      body: Consumer<MilkSellerProvider>(
        builder: (context, provider, child) {
          final sellers = provider.sellers;
          
          if (sellers.isEmpty) {
            return const Center(
              child: Text('No sellers found'),
            );
          }
          
          return ListView.builder(
            itemCount: sellers.length,
            itemBuilder: (context, index) {
              final seller = sellers[index];
              return ListTile(
                title: Text(seller.name),
                subtitle: Text('Rate: ₹${seller.defaultRate}/L'),
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: Text(seller.name[0].toUpperCase()),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SellerProfileScreen(seller: seller),
                    ),
                  );
                },
        );
      },
    );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          MilkDiaryAddSeller.showAddSellerBottomSheet(context).then((seller) {
            if (seller != null && context.mounted) {
              Provider.of<MilkSellerProvider>(context, listen: false).addSeller(seller);
            }
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class SellerProfileScreen extends StatelessWidget {
  final MilkSeller seller;
  
  const SellerProfileScreen({Key? key, required this.seller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(seller.name),
      ),
      body: Consumer2<DailyEntryProvider, MilkSellerProvider>(
        builder: (context, entryProvider, sellerProvider, child) {
          final entries = entryProvider.getEntriesForSeller(seller.id);
          
          // Calculate summary stats
          final totalQuantity = entries.isEmpty ? 0.0 :
            double.parse(entries.fold(0.0, (sum, entry) => sum + entry.quantity).toStringAsFixed(2));
          
          final totalAmount = entries.isEmpty ? 0.0 :
            double.parse(entries.fold(0.0, (sum, entry) => sum + entry.amount).toStringAsFixed(2));
          
          // Get actual payments for this seller
          final payments = sellerProvider.getPaymentsForSeller(seller.id);
          final totalPaid = payments.isEmpty ? 0.0 :
            double.parse(payments.fold(0.0, (sum, payment) => sum + payment.amount).toStringAsFixed(2));
          final amountDue = totalAmount - totalPaid;
          
          // Update seller's due amount for consistency
          seller.updateDueAmount(amountDue);
          sellerProvider.updateSeller(seller);
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Seller info card
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        seller.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (seller.mobile != null)
                        Text('Phone: ${seller.mobile}'),
                      if (seller.address != null)
                        Text('Address: ${seller.address}'),
                      const SizedBox(height: 8),
                      Text('Default Rate: ₹${seller.defaultRate}/L'),
                    ],
                  ),
                ),
              ),
              
              // Add summary stats card
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem(context, 'Total Milk', '${totalQuantity.toStringAsFixed(2)} L', Icons.water_drop, Colors.blue),
                      _buildSummaryItem(context, 'Amount', '₹${totalAmount.toStringAsFixed(0)}', Icons.currency_rupee, Colors.green),
                      _buildSummaryItem(context, 'Paid', '₹${totalPaid.toStringAsFixed(0)}', Icons.payments, Colors.purple),
                      _buildSummaryItem(context, 'Due', '₹${amountDue.toStringAsFixed(0)}', Icons.account_balance_wallet, Colors.orange),
                    ],
                  ),
                ),
              ),

              // Payment and PDF buttons in one row
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    // Add Payment Button - 50% width
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Show add payment dialog for this seller
                            _showAddPaymentDialog(context);
                          },
                          icon: const Icon(Icons.payments),
                          label: const Text('ADD PAYMENT'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ),
                    
                    // Generate PDF Button - 50% width
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _generateSellerReport(context, seller.id);
                          },
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('GENERATE PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              Text('Complete History', style: TextStyle(fontSize: 9)),
                            ],
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // History Section Tabs
              DefaultTabController(
                length: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Entry History'),
                        Tab(text: 'Payment History'),
                      ],
                      labelColor: Colors.purple,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.purple,
                    ),
                    SizedBox(
                      height: 300, // Fixed height for the tab content
                      child: TabBarView(
                        children: [
                          // Entry History Tab
                          _buildEntryHistoryTab(context, entries),
                          
                          // Payment History Tab
                          _buildPaymentHistoryTab(context, payments),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          MilkDiaryAddEntry.showAddEntryBottomSheet(
            context,
            sellerId: seller.id,
            initialDate: DateTime.now(),
          ).then((_) {
            if (context.mounted) {
              // Optionally refresh data if needed
            }
          });
        },
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Helper method to build summary item
  Widget _buildSummaryItem(BuildContext context, String title, String value, IconData icon, Color color) {
    return Column(
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
            fontSize: 10,
            color: Colors.grey[600],
            ),
          ),
        ],
    );
  }
  
  // Method to generate PDF report for a seller
  void _generateSellerReport(BuildContext context, String sellerId) async {
    try {
      // Show loading dialog with explicit message about generating full history
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text(
                  'Generating Complete History Report',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Please wait while we gather all historical data...',
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
      
      final entryProvider = Provider.of<DailyEntryProvider>(context, listen: false);
      final sellerProvider = Provider.of<MilkSellerProvider>(context, listen: false);
      
      // Get the seller object
      final seller = sellerProvider.getSellerById(sellerId);
      if (seller == null) {
        throw Exception("Seller not found");
      }
      
      final reportService = MilkDiaryReportService(
        entryProvider: entryProvider,
        sellerProvider: sellerProvider,
      );
      
      // Get the date range for the current month (only used for the "current month" section)
      // The actual report will include ALL historical data
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);
      
      // Generate seller-specific report with all history
      await reportService.generateSellerReport(
        seller,
        startDate,
        endDate,
      );
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
        
        // Show success message indicating complete history was included
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Complete history report generated successfully'),
                Text(
                  'All data for ${seller.name} included',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
  
  // Entry History Tab
  Widget _buildEntryHistoryTab(BuildContext context, List<DailyEntry> entries) {
    if (entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No entries found for this seller'),
        ),
      );
    }
    
    // Sort entries by date - most recent first
    entries.sort((a, b) => b.date.compareTo(a.date));
    
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Row(
              children: [
                Text('${entry.quantity}L'),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: entry.shift == EntryShift.morning ? Colors.orange[100] : Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    entry.shift == EntryShift.morning ? 'Morning' : 'Evening',
                    style: TextStyle(
                      fontSize: 12,
                      color: entry.shift == EntryShift.morning ? Colors.orange[800] : Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              DateFormat('dd MMM yyyy, hh:mm a').format(entry.date),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₹${entry.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editEntry(context, entry);
                    } else if (value == 'delete') {
                      _confirmDeleteEntry(context, entry);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Edit Entry'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete Entry'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Payment History Tab
  Widget _buildPaymentHistoryTab(BuildContext context, List<MilkPayment> payments) {
    if (payments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No payments found for this seller'),
        ),
      );
    }
    
    // Get the seller provider from context
    final sellerProvider = Provider.of<MilkSellerProvider>(context, listen: false);
    
    // Sort payments by date - most recent first
    payments.sort((a, b) => b.date.compareTo(a.date));
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        final seller = sellerProvider.getSellerById(payment.sellerId);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: Colors.green[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: Text(
                    seller?.name[0].toUpperCase() ?? "U",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Seller details and date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        seller?.name ?? 'Unknown Seller',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd MMM yyyy').format(payment.date),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      if (payment.note != null && payment.note!.isNotEmpty)
                        Text(
                          payment.note!,
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                
                // Amount and delete button
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₹${payment.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.only(left: 8),
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () => _confirmDeletePayment(context, payment, sellerProvider),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Method to confirm deletion of a payment
  void _confirmDeletePayment(BuildContext context, MilkPayment payment, MilkSellerProvider sellerProvider) {
    final BuildContext currentContext = context;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment'),
        content: Text('Are you sure you want to delete this payment of ₹${payment.amount.toStringAsFixed(2)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              sellerProvider.deletePayment(payment.id);
              ScaffoldMessenger.of(currentContext).showSnackBar(
                const SnackBar(
                  content: Text('Payment deleted successfully'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Show payment dialog for this seller
  void _showAddPaymentDialog(BuildContext context) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final dateController = TextEditingController(
      text: DateFormat('dd-MM-yyyy').format(DateTime.now()),
    );
    
    final sellerProvider = Provider.of<MilkSellerProvider>(context, listen: false);
    final entryProvider = Provider.of<DailyEntryProvider>(context, listen: false);

    // Calculate due amount
    final entries = entryProvider.getEntriesForSeller(seller.id);
    final totalAmount = entries.isEmpty ? 0.0 :
      entries.fold(0.0, (sum, entry) => sum + entry.amount);
    
    final sellerPayments = sellerProvider.getPaymentsForSeller(seller.id);
    final totalPayments = sellerPayments.isEmpty ? 0.0 :
      sellerPayments.fold(0.0, (sum, payment) => sum + payment.amount);
    
    final dueAmount = totalAmount - totalPayments;
    
    // Update seller's due amount for future reference
    seller.updateDueAmount(dueAmount);
    
    // Store a reference to the current context for later use
    final BuildContext currentContext = context;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Payment for ${seller.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Due Amount: ₹${dueAmount.toStringAsFixed(2)}', 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: dueAmount > 0 ? Colors.red : Colors.green,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Date',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        dateController.text = DateFormat('dd-MM-yyyy').format(date);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (amountController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter an amount'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid amount'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              
              // Parse date
              DateTime date;
              try {
                date = DateFormat('dd-MM-yyyy').parse(dateController.text);
              } catch (e) {
                date = DateTime.now();
              }
              
              // Create payment record
              final payment = MilkPayment(
                id: const Uuid().v4(),
                sellerId: seller.id,
                amount: amount,
                date: date,
                note: noteController.text,
              );
              
              // Add payment
              sellerProvider.addPayment(payment);
              
              // Update the seller's due amount
              final updatedDueAmount = dueAmount - amount;
              seller.updateDueAmount(updatedDueAmount);
              sellerProvider.updateSeller(seller);
              
              // Show success message
              Navigator.pop(context);
              ScaffoldMessenger.of(currentContext).showSnackBar(
                SnackBar(
                  content: Text('Payment of ₹${amount.toStringAsFixed(2)} added successfully'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Add Payment', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  // Method to edit an entry
  void _editEntry(BuildContext context, DailyEntry entry) {
    MilkDiaryAddEntry.showAddEntryBottomSheet(
      context,
      entry: entry,
      sellerId: seller.id,
    );
  }
  
  // Method to confirm deletion of an entry
  void _confirmDeleteEntry(BuildContext context, DailyEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteEntry(context, entry);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  // Method to delete an entry
  void _deleteEntry(BuildContext context, DailyEntry entry) {
    final entryProvider = Provider.of<DailyEntryProvider>(context, listen: false);
    entryProvider.deleteEntry(entry.id);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Entry deleted successfully'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// Add a method to confirm deletion of a seller
void _confirmDeleteSeller(BuildContext context, MilkSeller seller) {
  showDialog(
      context: context,
      builder: (context) => AlertDialog(
      title: Text('Delete ${seller.name}'),
      content: Text('Are you sure you want to delete ${seller.name}? This will delete all associated entries and cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Delete seller and associated entries
              Navigator.pop(context);
              _deleteSeller(context, seller.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

// Add a method to actually delete the seller
void _deleteSeller(BuildContext context, String sellerId) async {
  try {
    // Get provider instances
    final sellerProvider = Provider.of<MilkSellerProvider>(context, listen: false);
    final entryProvider = Provider.of<DailyEntryProvider>(context, listen: false);
    
    // Delete all entries for this seller
    final entries = entryProvider.getEntriesForSeller(sellerId);
    for (var entry in entries) {
      await entryProvider.deleteEntry(entry.id);
    }
    
    // Delete all payments for this seller
    final payments = sellerProvider.getPaymentsForSeller(sellerId);
    for (var payment in payments) {
      await sellerProvider.deletePayment(payment.id);
    }
    
    // Delete the seller
    await sellerProvider.deleteSeller(sellerId);
    
    // Force UI refresh safely without directly calling protected methods
    // The providers will automatically handle notification of changes
    
    // Additional UI refresh to ensure summary card updates properly
    if (context.mounted) {
      // To trigger a complete refresh of the UI and data
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Use appropriate method to refresh UI
      if (context.mounted) {
        // Just rely on the provider system - no direct setState needed
        
        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seller deleted successfully'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting seller: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

// Add MilkPaymentsScreen class at the end of the file
class MilkPaymentsScreen extends StatelessWidget {
  const MilkPaymentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Consumer<MilkSellerProvider>(
        builder: (context, sellerProvider, child) {
          final allPayments = sellerProvider.payments;
          
          if (allPayments.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No payment history found'),
              ),
            );
          }
          
          // Sort payments by date (newest first)
          final sortedPayments = List<MilkPayment>.from(allPayments)
              ..sort((a, b) => b.date.compareTo(a.date));
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedPayments.length,
            itemBuilder: (context, index) {
              final payment = sortedPayments[index];
              final seller = sellerProvider.getSellerById(payment.sellerId);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.green[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar
                      CircleAvatar(
                        backgroundColor: Colors.deepPurple,
                        child: Text(
                          seller?.name[0].toUpperCase() ?? "U",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Seller details and date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              seller?.name ?? 'Unknown Seller',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('dd MMM yyyy').format(payment.date),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            if (payment.note != null && payment.note!.isNotEmpty)
                              Text(
                                payment.note!,
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      
                      // Amount and delete button
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₹${payment.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.only(left: 8),
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () => _confirmDeletePayment(context, payment, sellerProvider),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  void _confirmDeletePayment(BuildContext context, MilkPayment payment, MilkSellerProvider sellerProvider) {
    final BuildContext currentContext = context;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment'),
        content: Text('Are you sure you want to delete this payment of ₹${payment.amount.toStringAsFixed(2)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              sellerProvider.deletePayment(payment.id);
              ScaffoldMessenger.of(currentContext).showSnackBar(
                const SnackBar(
                  content: Text('Payment deleted successfully'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
} 