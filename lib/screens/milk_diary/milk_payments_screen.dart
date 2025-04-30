import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/milk_diary/milk_seller.dart';
import '../../models/milk_diary/daily_entry.dart';
import '../../providers/milk_diary/milk_seller_provider.dart';
import '../../providers/milk_diary/daily_entry_provider.dart';
import '../../constants/app_theme.dart';

class MilkPaymentsScreen extends StatefulWidget {
  final String? sellerId; // Optional: If we want to show payments for a specific seller
  
  const MilkPaymentsScreen({Key? key, this.sellerId}) : super(key: key);

  @override
  State<MilkPaymentsScreen> createState() => _MilkPaymentsScreenState();
}

class _MilkPaymentsScreenState extends State<MilkPaymentsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String? _selectedSellerId;
  bool _isCalculating = false;
  
  @override
  void initState() {
    super.initState();
    _selectedSellerId = widget.sellerId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Milk Payments'),
      ),
      body: Column(
        children: [
          _buildDateRangeSelector(),
          _buildSellerSelector(),
          const Divider(),
          Expanded(
            child: _selectedSellerId == null
                ? _buildSellersList()
                : _buildSellerPaymentDetails(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Date Range',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(isStartDate: true),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'From',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: Text(
                      DateFormat('dd MMM yyyy').format(_startDate),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(isStartDate: false),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'To',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: Text(
                      DateFormat('dd MMM yyyy').format(_endDate),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSellerSelector() {
    return Consumer<MilkSellerProvider>(
      builder: (context, sellerProvider, child) {
        final sellers = sellerProvider.sellers;
        
        if (_selectedSellerId != null && !sellers.any((s) => s.id == _selectedSellerId)) {
          // Reset selected seller if it doesn't exist anymore
          _selectedSellerId = null;
        }
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: _selectedSellerId == null
                    ? const Text(
                        'All Sellers',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : DropdownButton<String>(
                        value: _selectedSellerId,
                        isExpanded: true,
                        hint: const Text('Select Seller'),
                        items: sellers.map((seller) {
                          return DropdownMenuItem<String>(
                            value: seller.id,
                            child: Text(seller.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSellerId = value;
                          });
                        },
                      ),
              ),
              if (_selectedSellerId != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedSellerId = null;
                    });
                  },
                  child: const Text('Show All'),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSellersList() {
    return Consumer2<MilkSellerProvider, DailyEntryProvider>(
      builder: (context, sellerProvider, entryProvider, child) {
        final sellers = sellerProvider.sellers;
        
        if (sellers.isEmpty) {
          return const Center(
            child: Text('No sellers found'),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sellers.length,
          itemBuilder: (context, index) {
            final seller = sellers[index];
            return _buildSellerSummaryCard(seller, entryProvider);
          },
        );
      },
    );
  }

  Widget _buildSellerSummaryCard(MilkSeller seller, DailyEntryProvider entryProvider) {
    final entries = entryProvider.getEntriesForSellerInRange(
      seller.id,
      _startDate,
      _endDate,
    );
    
    if (entries.isEmpty) {
      return const SizedBox.shrink(); // Don't show sellers with no entries
    }
    
    final totalQuantity = entries.fold(0.0, (sum, entry) => sum + entry.quantity);
    final totalAmount = entries.fold(0.0, (sum, entry) => sum + entry.amount);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedSellerId = seller.id;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      seller.name,
                      style: const TextStyle(
                        fontSize: 18,
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
                      '${entries.length} entries',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Quantity:',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${totalQuantity.toStringAsFixed(2)} L',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total Amount:',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
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

  Widget _buildSellerPaymentDetails() {
    return Consumer2<MilkSellerProvider, DailyEntryProvider>(
      builder: (context, sellerProvider, entryProvider, child) {
        final seller = sellerProvider.getSellerById(_selectedSellerId!);
        
        if (seller == null) {
          return const Center(
            child: Text('Seller not found'),
          );
        }
        
        final entries = entryProvider.getEntriesForSellerInRange(
          seller.id,
          _startDate,
          _endDate,
        );
        
        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No entries found for ${seller.name} in the selected date range',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        
        // Group entries by date
        final entriesByDate = <DateTime, List<DailyEntry>>{};
        for (var entry in entries) {
          final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
          if (!entriesByDate.containsKey(date)) {
            entriesByDate[date] = [];
          }
          entriesByDate[date]!.add(entry);
        }
        
        // Sort dates in descending order
        final sortedDates = entriesByDate.keys.toList()
          ..sort((a, b) => b.compareTo(a));
        
        final totalQuantity = entries.fold(0.0, (sum, entry) => sum + entry.quantity);
        final totalAmount = entries.fold(0.0, (sum, entry) => sum + entry.amount);
        
        return Column(
          children: [
            // Summary card
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        seller.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM').format(_startDate) + 
                        ' - ' + 
                        DateFormat('dd MMM yyyy').format(_endDate),
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSummaryItem('Total Entries', '${entries.length}'),
                          _buildSummaryItem('Total Quantity', '${totalQuantity.toStringAsFixed(2)} L'),
                          _buildSummaryItem('Total Amount', '₹${totalAmount.toStringAsFixed(2)}', isHighlighted: true),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Daily entries list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sortedDates.length,
                itemBuilder: (context, index) {
                  final date = sortedDates[index];
                  final dayEntries = entriesByDate[date]!;
                  
                  return _buildDayEntriesCard(date, dayEntries);
                },
              ),
            ),
            
            // Payment Actions
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Navigate to payment screen or show payment dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment feature coming soon!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: AppTheme.primary,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.payment),
                    const SizedBox(width: 8),
                    Text(
                      'Pay ₹${totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16),
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

  Widget _buildSummaryItem(String label, String value, {bool isHighlighted = false}) {
    return Column(
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isHighlighted ? AppTheme.primary : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDayEntriesCard(DateTime date, List<DailyEntry> entries) {
    // Calculate day totals
    final dayQuantity = entries.fold(0.0, (sum, entry) => sum + entry.quantity);
    final dayAmount = entries.fold(0.0, (sum, entry) => sum + entry.amount);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd MMM yyyy (EEEE)').format(date),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹${dayAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            ...entries.map((entry) => _buildEntryRow(entry)),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ${dayQuantity.toStringAsFixed(2)} L',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${dayAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryRow(DailyEntry entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: entry.shift == EntryShift.morning
                      ? Colors.orange.shade100
                      : Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.shift == EntryShift.morning ? 'Morning' : 'Evening',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: entry.shift == EntryShift.morning
                        ? Colors.orange.shade800
                        : Colors.purple.shade800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${entry.quantity} L'),
              const SizedBox(width: 4),
              if (entry.fat != null)
                Text('(${entry.fat}%)', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              const SizedBox(width: 8),
              Text('@ ₹${entry.rate}/L', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
          Text(
            '₹${entry.amount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate({required bool isStartDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }
} 