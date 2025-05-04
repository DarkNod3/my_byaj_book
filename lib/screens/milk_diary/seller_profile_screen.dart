import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/milk_diary/milk_seller.dart';
import '../../models/milk_diary/daily_entry.dart';
import '../../providers/milk_diary/daily_entry_provider.dart';
import '../../constants/app_theme.dart';
import 'add_entry_screen.dart';
import 'add_entry_bottom_sheet.dart';

class SellerProfileScreen extends StatefulWidget {
  final MilkSeller seller;

  const SellerProfileScreen({
    Key? key,
    required this.seller,
  }) : super(key: key);

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  DateTime _selectedDate = DateTime.now();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.seller.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
            tooltip: 'Select Date',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seller profile card
            _buildProfileCard(),
            
            // Daily entries section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Milk Entries (${DateFormat('dd MMM yyyy').format(_selectedDate)})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showAllEntries(),
                        icon: const Icon(Icons.history, size: 16),
                        label: const Text('All Entries'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Entries for selected date using the new method
                  _buildEntriesByDate(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddEntry(),
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                  radius: 30,
                  child: Text(
                    widget.seller.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.seller.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Add Payment button
                          ElevatedButton.icon(
                            onPressed: () => _showAddPaymentDialog(),
                            icon: const Icon(Icons.add_card, size: 18),
                            label: const Text('Add Payment'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade100,
                              foregroundColor: Colors.blue.shade800,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              textStyle: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      if (widget.seller.mobile != null && widget.seller.mobile!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.phone, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                widget.seller.mobile!,
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.seller.address != null && widget.seller.address!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.seller.address!,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 24),
            
            // Summary section - right below the divider
            _buildQuickSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickSummary() {
    return Consumer<DailyEntryProvider>(
      builder: (context, entryProvider, child) {
        // Get all entries for this seller
        final allEntries = entryProvider.getEntriesForSeller(widget.seller.id);
        
        // Today's entries
        final today = DateTime.now();
        final todayEntries = allEntries.where((e) => 
          e.date.year == today.year && 
          e.date.month == today.month && 
          e.date.day == today.day
        ).toList();
        
        // Calculate summary statistics with proper precision
        double totalQuantity = 0.0;
        double totalAmount = 0.0;
        
        // Sum with proper rounding to prevent floating point errors
        for (var entry in allEntries) {
          totalQuantity += entry.quantity;
          totalAmount += entry.amount;
        }
        
        // Ensure proper rounding
        totalQuantity = double.parse(totalQuantity.toStringAsFixed(2));
        totalAmount = double.parse(totalAmount.toStringAsFixed(2));
        
        // Calculate active days (days with at least one entry)
        final activeDaysSet = allEntries.map((e) => 
          '${e.date.year}-${e.date.month}-${e.date.day}'
        ).toSet();
        
        final activeDays = activeDaysSet.length;
        
        // Get payments data from provider
        // TODO: In a real implementation, this would come from a payment provider
        final paidAmount = 0.0;  
        final dueAmount = totalAmount - paidAmount;
        
        // Calculate today's totals with proper precision
        double todayQuantity = 0.0;
        double todayAmount = 0.0;
        
        // Sum with proper rounding
        for (var entry in todayEntries) {
          todayQuantity += entry.quantity;
          todayAmount += entry.amount;
        }
        
        // Ensure proper rounding
        todayQuantity = double.parse(todayQuantity.toStringAsFixed(2));
        todayAmount = double.parse(todayAmount.toStringAsFixed(2));
        
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Summary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCompactSummaryTile(
                    icon: Icons.water_drop,
                    iconColor: Colors.blue,
                    label: 'Total Milk',
                    value: '${totalQuantity.toStringAsFixed(1)} L',
                  ),
                  _buildCompactSummaryTile(
                    icon: Icons.currency_rupee,
                    iconColor: Colors.green,
                    label: 'Total Amount',
                    value: '₹${totalAmount.toStringAsFixed(0)}',
                  ),
                  _buildCompactSummaryTile(
                    icon: Icons.account_balance_wallet,
                    iconColor: Colors.red,
                    label: 'Due Amount',
                    value: '₹${dueAmount.toStringAsFixed(0)}',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCompactSummaryTile(
                    icon: Icons.calendar_today,
                    iconColor: Colors.purple,
                    label: 'Active Days',
                    value: '$activeDays days',
                  ),
                  _buildCompactSummaryTile(
                    icon: Icons.price_change,
                    iconColor: Colors.amber,
                    label: 'Price/Unit',
                    value: '₹${widget.seller.defaultRate}/L',
                  ),
                  _buildCompactSummaryTile(
                    icon: Icons.payments,
                    iconColor: Colors.teal,
                    label: 'Today',
                    value: '₹${todayAmount.toStringAsFixed(0)}',
                    tooltip: '${todayQuantity.toStringAsFixed(1)}L today',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildCompactSummaryTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    String? tooltip,
  }) {
    return Expanded(
      child: Tooltip(
        message: tooltip ?? label,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
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

  Widget _buildEntryCard(DailyEntry entry) {
    // Get shift icon and color
    final shiftIcon = entry.shift == EntryShift.morning ? Icons.wb_sunny_outlined : Icons.nightlight_outlined;
    final shiftColor = entry.shift == EntryShift.morning ? Colors.orange : Colors.indigo;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Shift icon
            Icon(shiftIcon, size: 16, color: shiftColor),
            const SizedBox(width: 8),
            
            // Time and shift
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('hh:mm a').format(entry.date),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    entry.shift == EntryShift.morning ? 'Morning' : 'Evening',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            
            // Quantity
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  const Icon(Icons.water_drop, size: 14, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.quantity} L',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            
            // Amount
            Expanded(
              flex: 2,
              child: Text(
                '₹${entry.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            
            // Menu button
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.more_vert, size: 18),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _navigateToAddEntry(entry: entry);
                } else if (value == 'delete') {
                  _confirmDeleteEntry(entry);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlySummary() {
    return Consumer<DailyEntryProvider>(
      builder: (context, entryProvider, child) {
        // Get start and end of current month
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        
        // Use existing method for date range
        final entries = entryProvider.getEntriesForSellerInRange(
          widget.seller.id,
          startOfMonth,
          endOfMonth,
        );
        
        // Calculate monthly stats
        final totalQuantity = entries.fold(0.0, (sum, entry) => sum + entry.quantity);
        final totalAmount = entries.fold(0.0, (sum, entry) => sum + entry.amount);
        final avgRate = entries.isEmpty ? 0.0 : totalAmount / totalQuantity;
        final daysWithEntries = entries.map((e) => 
          '${e.date.year}-${e.date.month}-${e.date.day}'
        ).toSet().length;
        
        return Card(
          margin: const EdgeInsets.all(16),
          color: Colors.teal[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Summary (${DateFormat('MMMM yyyy').format(now)})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryItem('Total Quantity', '${totalQuantity.toStringAsFixed(2)} L', Icons.water_drop),
                    _buildSummaryItem('Total Amount', '₹${totalAmount.toStringAsFixed(2)}', Icons.currency_rupee),
                    _buildSummaryItem('Avg. Rate', '₹${avgRate.toStringAsFixed(2)}/L', Icons.trending_up),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryItem('Active Days', '$daysWithEntries/${endOfMonth.day}', Icons.calendar_today),
                    _buildSummaryItem('Total Entries', '${entries.length}', Icons.receipt_long),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.teal, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteEntry(DailyEntry entry) async {
    final entryProvider = Provider.of<DailyEntryProvider>(context, listen: false);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: Text(
          'Are you sure you want to delete this ${entry.shift == EntryShift.morning ? 'morning' : 'evening'} '
          'entry for ${DateFormat('dd MMM yyyy').format(entry.date)}?\n\n'
          'Quantity: ${entry.quantity} L\n'
          'Amount: ₹${entry.amount.toStringAsFixed(2)}'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await entryProvider.deleteEntry(entry.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry deleted successfully')),
        );
      }
    }
  }

  void _navigateToAddEntry({DailyEntry? entry}) {
    AddEntryBottomSheet.show(
      context,
      entry: entry,
      sellerId: widget.seller.id,
      initialDate: entry != null ? entry.date : _selectedDate,
    );
  }

  void _showAllEntries() {
    // Navigate to a screen showing all entries for this seller
    // Implementation will depend on your app's navigation structure
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All entries view will be implemented')),
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

  // Update the entries section to organize entries more compactly
  Widget _buildEntriesByDate() {
    return Consumer<DailyEntryProvider>(
      builder: (context, entryProvider, child) {
        // Filter entries for this seller and selected date
        final allSellerEntries = entryProvider.getEntriesForSeller(widget.seller.id);
        final entriesForDate = allSellerEntries.where((entry) => 
          entry.date.year == _selectedDate.year && 
          entry.date.month == _selectedDate.month && 
          entry.date.day == _selectedDate.day
        ).toList();
        
        if (entriesForDate.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Icon(Icons.water_drop_outlined, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No milk entries for ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  // Check if we already have both morning and evening entries
                  if(_canAddMoreEntries(entryProvider))
                    ElevatedButton.icon(
                      onPressed: () => _navigateToAddEntry(),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Entry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          );
        }
        
        // Sort entries by time
        entriesForDate.sort((a, b) => a.date.compareTo(b.date));
        
        // Calculate daily total with proper rounding
        final dailyTotalQuantity = entriesForDate.isEmpty ? 0.0 : 
          double.parse(entriesForDate.fold(0.0, (sum, e) => sum + e.quantity).toStringAsFixed(2));
        
        final dailyTotalAmount = entriesForDate.isEmpty ? 0.0 : 
          double.parse(entriesForDate.fold(0.0, (sum, e) => sum + e.amount).toStringAsFixed(2));
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // List all entries
            ...entriesForDate.map((entry) => _buildEntryCard(entry)).toList(),
            
            // Add button if we don't have both morning and evening entries yet
            if(_canAddMoreEntries(entryProvider))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToAddEntry(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Entry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            
            // Daily total
            if (entriesForDate.isNotEmpty)
              Card(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Daily Total:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${dailyTotalQuantity.toStringAsFixed(1)} L  ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '₹${dailyTotalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ],
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
  
  // Check if we can add more entries for the selected date
  bool _canAddMoreEntries(DailyEntryProvider provider) {
    final entriesForDate = provider.getEntriesForSeller(widget.seller.id).where((entry) => 
      entry.date.year == _selectedDate.year && 
      entry.date.month == _selectedDate.month && 
      entry.date.day == _selectedDate.day
    ).toList();
    
    final hasMorningEntry = entriesForDate.any((e) => e.shift == EntryShift.morning);
    final hasEveningEntry = entriesForDate.any((e) => e.shift == EntryShift.evening);
    
    // Allow adding entries if either morning or evening is missing
    return !(hasMorningEntry && hasEveningEntry);
  }

  void _showAddPaymentDialog() {
    final paymentAmountController = TextEditingController();
    final remarksController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Payment for ${widget.seller.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              if (paymentAmountController.text.isNotEmpty) {
                try {
                  final amount = double.parse(paymentAmountController.text);
                  // Here you would save the payment to your payment provider
                  // This is a placeholder - implement actual payment saving
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Payment of ₹$amount added for ${widget.seller.name}'),
                      backgroundColor: Colors.green,
                    ),
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
                  const SnackBar(content: Text('Please enter an amount')),
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
} 