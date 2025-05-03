import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/milk_diary/milk_seller.dart';
import '../../models/milk_diary/daily_entry.dart';
import '../../providers/milk_diary/daily_entry_provider.dart';
import '../../constants/app_theme.dart';
import 'add_entry_screen.dart';

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
                  
                  // Entries for selected date
                  Consumer<DailyEntryProvider>(
                    builder: (context, entryProvider, child) {
                      // Filter entries for this seller and date
                      final allSellerEntries = entryProvider.getEntriesForSeller(widget.seller.id);
                      final entries = allSellerEntries.where((entry) => 
                        entry.date.year == _selectedDate.year && 
                        entry.date.month == _selectedDate.month && 
                        entry.date.day == _selectedDate.day
                      ).toList();
                      
                      if (entries.isEmpty) {
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
                              ],
                            ),
                          ),
                        );
                      }
                      
                      // Sort entries by shift
                      entries.sort((a, b) => a.shift.index.compareTo(b.shift.index));
                      
                      return Column(
                        children: entries.map((entry) => _buildEntryCard(entry)).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Monthly summary section
            _buildMonthlySummary(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEntry(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
        tooltip: 'Add Milk Entry',
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
                      Text(
                        widget.seller.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.seller.isActive ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.seller.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: widget.seller.isActive ? Colors.green.shade800 : Colors.red.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem('Default Rate', '₹${widget.seller.defaultRate.toStringAsFixed(2)}/L'),
                _buildInfoItem('Status', widget.seller.isActive ? 'Active' : 'Inactive'),
              ],
            ),
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

  Widget _buildEntryCard(DailyEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => _navigateToAddEntry(entry: entry),
                      tooltip: 'Edit Entry',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18),
                      onPressed: () => _confirmDeleteEntry(entry),
                      tooltip: 'Delete Entry',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEntryDetail('Quantity', '${entry.quantity} L'),
                    _buildEntryDetail('Fat', '${entry.fat}%'),
                    _buildEntryDetail('Rate', '₹${entry.rate}/L'),
                  ],
                ),
                Text(
                  '₹${entry.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEntryScreen(entry: entry),
      ),
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
} 