import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_theme.dart';
import '../../widgets/milk_diary/milk_diary_ui.dart';
import '../../models/milk_diary/daily_entry.dart';
import '../../providers/milk_diary/daily_entry_provider.dart';
import '../../providers/milk_diary/milk_seller_provider.dart';
import 'add_entry_screen.dart';
import 'milk_seller_screen.dart';
import 'milk_payments_screen.dart';
import 'package:provider/provider.dart';
import 'package:my_byaj_book/widgets/header/app_header.dart';

class MilkDiaryScreenFixed extends StatefulWidget {
  const MilkDiaryScreenFixed({Key? key}) : super(key: key);

  @override
  State<MilkDiaryScreenFixed> createState() => _MilkDiaryScreenFixedState();
}

class _MilkDiaryScreenFixedState extends State<MilkDiaryScreenFixed> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Only define the AppBar title, not duplicating in the body
      appBar: AppHeader(
        title: 'Milk Diary',
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
      ),
      // Use our custom UI component
      body: MilkDiaryUI(
        dailyEntriesTab: _buildDailyEntriesTab(),
        monthlySummaryTab: _buildMonthlySummaryTab(),
        onAddEntry: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEntryScreen()),
          );
        },
      ),
    );
  }

  Widget _buildDailyEntriesTab() {
    return Column(
      children: [
        // Use the DateSelector component
        DateSelector(
          selectedDate: _selectedDate,
          onDateChanged: (date) {
            setState(() {
              _selectedDate = date;
            });
          },
        ),
        Expanded(
          child: Consumer2<DailyEntryProvider, MilkSellerProvider>(
            builder: (context, entryProvider, sellerProvider, child) {
              final entriesForDate = entryProvider.getEntriesForDate(_selectedDate);
              
              if (entriesForDate.isEmpty) {
                return const Center(
                  child: Text('No entries for this date'),
                );
              }
              
              // Group entries by seller
              final Map<String, List<DailyEntry>> entriesBySeller = {};
              for (var entry in entriesForDate) {
                if (!entriesBySeller.containsKey(entry.sellerId)) {
                  entriesBySeller[entry.sellerId] = [];
                }
                entriesBySeller[entry.sellerId]!.add(entry);
              }
              
              return ListView.builder(
                itemCount: entriesBySeller.length,
                itemBuilder: (context, index) {
                  final sellerId = entriesBySeller.keys.elementAt(index);
                  final sellerEntries = entriesBySeller[sellerId]!;
                  final seller = sellerProvider.getSellerById(sellerId);
                  
                  // Calculate seller totals
                  final totalQuantity = sellerEntries.fold(0.0, (sum, e) => sum + e.quantity);
                  final totalAmount = sellerEntries.fold(0.0, (sum, e) => sum + e.amount);
                  
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        // Seller Header
                        Container(
                          padding: const EdgeInsets.all(12),
                          color: Colors.deepPurple.withOpacity(0.1),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Use HorizontalText to ensure text is never rotated
                              HorizontalText(
                                text: seller?.name ?? 'Unknown Seller',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              HorizontalText(
                                text: 'Total: ${totalQuantity.toStringAsFixed(1)} L | ₹${totalAmount.toStringAsFixed(1)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Entries List
                        ...sellerEntries.map((entry) {
                          return ListTile(
                            leading: Icon(
                              entry.shift == EntryShift.morning 
                                  ? Icons.wb_sunny 
                                  : Icons.nightlight_round,
                              color: entry.shift == EntryShift.morning 
                                  ? Colors.orange 
                                  : Colors.indigo,
                            ),
                            title: Row(
                              children: [
                                HorizontalText(
                                  text: '${entry.quantity.toStringAsFixed(1)} L × ₹${entry.rate.toStringAsFixed(1)} = ',
                                ),
                                HorizontalText(
                                  text: '₹${entry.amount.toStringAsFixed(1)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            subtitle: HorizontalText(
                              text: 'Fat: ${entry.fat.toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () {
                                    // Edit entry
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20),
                                  onPressed: () {
                                    // Delete entry
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlySummaryTab() {
    return Center(
      child: Text(
        'Monthly Summary for ${DateFormat('MMMM yyyy').format(_selectedDate)}',
        style: const TextStyle(fontSize: 18),
      ),
    );
  }
} 