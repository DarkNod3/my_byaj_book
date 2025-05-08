import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../models/milk_diary/daily_entry.dart';
import '../../providers/milk_diary/daily_entry_provider.dart';
import '../../providers/milk_diary/milk_seller_provider.dart';
import 'milk_diary_add_entry.dart';
import 'milk_diary_add_seller.dart';
import 'seller_profile_screen.dart';

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

  // Select date method
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
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
          builder: (context) => SellerProfileScreen(sellerId: sellerId, sellerName: seller.name, sellerData: seller.toMap()),
        ),
      );
    }
  }
  
  // Navigate to seller management screen
  /*
  void _navigateToSellerScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MilkSellerScreen(),
      ),
    );
  }
  */
  
  // Show add seller dialog
  void _showAddSellerBottomSheet() {
    MilkDiaryAddSeller.showAddSellerBottomSheet(context).then((seller) {
      if (seller != null) {
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
  
  // Delete entry confirmation
  void _confirmDeleteEntry(DailyEntry entry) {
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
              _deleteEntry(entry);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  // Delete entry
  void _deleteEntry(DailyEntry entry) async {
    final entryProvider = Provider.of<DailyEntryProvider>(context, listen: false);
    await entryProvider.deleteEntry(entry.id);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entry deleted successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  // Generate reports
  /*
  void _generateDailyReport() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      final entryProvider = Provider.of<DailyEntryProvider>(context, listen: false);
      final sellerProvider = Provider.of<MilkSellerProvider>(context, listen: false);
      
      final reportService = MilkDiaryReportService(
        entryProvider: entryProvider,
        sellerProvider: sellerProvider,
      );
      
      final reportPath = await reportService.generateDailyReport(_selectedDate);
      
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Report generated successfully'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                // Open report
                if (File(reportPath).existsSync()) {
                  OpenFile.open(reportPath);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report file not found'),
                    ),
                  );
                }
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar 
          ? AppBar(
              title: const Text('Milk Diary'),
              backgroundColor: Colors.blue.shade700,
            ) 
          : null,
      body: Column(
        children: [
          const Text('Milk Diary Screen - Placeholder Implementation'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _showAddSellerBottomSheet,
            child: const Text('Add New Seller'),
          ),
        ],
      ),
    );
  }
} 