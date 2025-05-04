import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/milk_diary/daily_entry.dart';
import '../../models/milk_diary/milk_seller.dart';
import '../../providers/milk_diary/daily_entry_provider.dart';
import '../../providers/milk_diary/milk_seller_provider.dart';
import '../../constants/app_theme.dart';
import 'package:uuid/uuid.dart';
import 'milk_seller_dialog.dart';
import 'milk_diary_screen.dart';
import 'add_entry_bottom_sheet.dart';

// Keep the original class for backward compatibility, but make it use the bottom sheet
class AddEntryScreen extends StatelessWidget {
  final DailyEntry? entry;
  final String? initialSellerId;
  final DateTime? initialDate;
  
  const AddEntryScreen({Key? key, this.entry, this.initialSellerId, this.initialDate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If initialSellerId is not provided, show an error
    if (initialSellerId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
                    ),
        body: const Center(
          child: Text('Seller ID is required'),
      ),
    );
  }
  
    // Show the bottom sheet and return a scaffold that will be dismissed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AddEntryBottomSheet.show(
        context,
        entry: entry,
        sellerId: initialSellerId!,
        initialDate: initialDate,
      ).then((_) {
        // Navigate back after the bottom sheet is closed
        Navigator.of(context).pop();
                            });
    });
    
    // Return a temporary scaffold
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
} 