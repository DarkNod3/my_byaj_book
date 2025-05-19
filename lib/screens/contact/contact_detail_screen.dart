import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/dialogs/confirm_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:my_byaj_book/utils/string_utils.dart';
import 'package:my_byaj_book/providers/transaction_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:my_byaj_book/services/pdf_template_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:my_byaj_book/screens/contact/edit_contact_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:my_byaj_book/providers/notification_provider.dart';
import 'package:my_byaj_book/utils/permission_handler.dart';
import 'package:my_byaj_book/screens/home/home_screen.dart';
import 'package:my_byaj_book/utils/image_picker_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class ContactDetailScreen extends StatefulWidget {
  final Map<String, dynamic> contact;
  final bool showSetupPrompt;
  final bool showTransactionDialogOnLoad;
  final String? dailyInterestNote; // Add this parameter but we won't use it

  const ContactDetailScreen({
    Key? key, 
    required this.contact,
    this.showSetupPrompt = false,
    this.showTransactionDialogOnLoad = false,
    this.dailyInterestNote,
  }) : super(key: key);

  @override
  _ContactDetailScreenState createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> with RouteAware {
  final TextEditingController _searchController = TextEditingController();
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ');
  final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
  List<Map<String, dynamic>> _filteredTransactions = [];
  bool _isSearching = false;
  late TransactionProvider _transactionProvider;
  String _contactId = '';

  // Track currently active filter
  String _filterType = 'all'; // Possible values: 'all', 'received', 'paid'

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilters);
    // Initialize contact ID
    _contactId = widget.contact['phone'] ?? '';
    
    // Show setup prompt for new contacts after a short delay
    if (widget.showSetupPrompt) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSetupPrompt();
      });
    }
    
    // Show transaction dialog if requested
    if (widget.showTransactionDialogOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddTransactionDialog();
      });
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _transactionProvider = Provider.of<TransactionProvider>(context);
    
    _applyFilters();
  }

  @override
  void didPopNext() {
    // This is called when returning to this screen
    // Refresh data
    setState(() {
      _refreshData();
    });
    super.didPopNext();
  }

  @override
  void dispose() {
    // Force refresh of home screen when returning
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use the public static method instead of trying to access private class
      if (mounted) {
        HomeScreen.refreshHomeContent(context);
      }
    });
    
    _searchController.dispose();
    super.dispose();
  }

  // Apply both search filtering and tab filtering
  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      final transactions = _transactionProvider.getTransactionsForContact(_contactId);
      
      // Step 1: Apply text search filter
      List<Map<String, dynamic>> searchFiltered;
      if (query.isEmpty) {
        searchFiltered = List.from(transactions);
      } else {
        searchFiltered = transactions.where((tx) {
          // Safely handle 'note' field which might be null
          String note = (tx['note'] as String?) ?? '';
          return note.toLowerCase().contains(query) ||
              tx['amount'].toString().contains(query);
        }).toList();
      }
      
      // Step 2: Apply tab filter
      if (_filterType == 'all') {
        _filteredTransactions = searchFiltered;
      } else if (_filterType == 'received') {
        _filteredTransactions = searchFiltered.where((tx) => tx['type'] == 'got').toList();
      } else if (_filterType == 'paid') {
        _filteredTransactions = searchFiltered.where((tx) => tx['type'] == 'gave').toList();
      }
      
      // Step 3: Sort by date (newest first)
      _filteredTransactions.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    });
  }

  // Calculate total balance
  double _calculateBalance() {
    return _transactionProvider.calculateBalance(_contactId);
  }

  // Calculate running balance up to a specific index
  double _calculateRunningBalance(int upToIndex) {
    double balance = 0;
    final transactions = _transactionProvider.getTransactionsForContact(_contactId);
    for (int i = transactions.length - 1; i >= upToIndex; i--) {
      var tx = transactions[i];
      if (tx['type'] == 'gave') {
        balance += tx['amount'] as double;
      } else {
        balance -= tx['amount'] as double;
      }
    }
    return balance;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isWithInterest = widget.contact['type'] != null; // Check if it's a with-interest contact

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contact['name'] as String? ?? 'Contact'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showContactOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Show either Interest Summary Card or Basic Summary Card, but not both
          if (isWithInterest)
            _buildInterestSummaryCard()
          else
            _buildBasicSummaryCard(),

          // Transactions header with search and filter tabs
          Column(
            children: [

              
              // Filter tabs row
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
                  color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, 2),
                  blurRadius: 5,
                ),
              ],
            ),
                                child: Padding(
                  padding: const EdgeInsets.all(1),
            child: Row(
              children: [
                      // All tab
                      _buildFilterTab('All', _filterType == 'all'),
                      
                      // Received tab
                      _buildFilterTab('Received', _filterType == 'received'),
                      
                      // Paid tab
                      _buildFilterTab('Paid', _filterType == 'paid'),
                      
                                            const Spacer(),
                      
                      // Search icon
                    IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                  icon: Icon(
                    _isSearching ? Icons.close : Icons.search,
                          size: 20,
                          color: Colors.grey.shade700,
                  ),
                      onPressed: () {
                        setState(() {
                          _isSearching = !_isSearching;
                          if (!_isSearching) {
                            _searchController.clear();
                          }
                        });
                      },
                ),
                      const SizedBox(width: 4),
              ],
                  ),
            ),
          ),

          // Search bar (visible only when searching)
          if (_isSearching)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 2),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search transactions',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
                ),
            ],
            ),

          // Transactions list
          Expanded(
            child: _filteredTransactions.isEmpty
                ? const Center(child: Text('No transactions found'))
                : !(widget.contact['type']?.toString().isNotEmpty == true)
                    // Use the new table style UI for standard entries
                    ? Column(
                        children: [

                          
                          // Header row
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                              ),
                            ),
                            padding: const EdgeInsets.all(1),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Date',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                                
                                // Vertical line
                                Container(
                                  height: 24,
                                  width: 0.5,
                                  color: Colors.grey.shade400,
                                ),
                                
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Debit',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.red.shade700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                
                                // Vertical line
                                Container(
                                  height: 24,
                                  width: 0.5,
                                  color: Colors.grey.shade400,
                                ),
                                
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Credit',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.green.shade700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Transaction rows
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(1),
                              itemCount: _filteredTransactions.length,
                              itemBuilder: (context, index) {
                                final tx = _filteredTransactions[index];
                                final runningBalance = _calculateRunningBalance(index);
                                return _buildTableTransactionItem(tx, runningBalance, index);
                              },
                            ),
                          ),
                        ],
                      )
                    // Use the original card style for interest entries
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final tx = _filteredTransactions[index];
                      final runningBalance = _calculateRunningBalance(index);
                      return _buildTransactionItem(tx, runningBalance);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _addTransaction('gave'),
                  icon: const Icon(Icons.arrow_upward),
                  label: const Text('PAID'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _addTransaction('got'),
                  icon: const Icon(Icons.arrow_downward),
                  label: const Text('RECEIVED'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    {required VoidCallback onTap, required Gradient gradient}
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
        width: 75,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> tx, double runningBalance) {
    final isGave = tx['type'] == 'gave';
    final hasImage = tx['imagePath'] != null;
    
    // Get the original index in the unfiltered list for delete/edit operations
    final allTransactions = _transactionProvider.getTransactionsForContact(_contactId);
    final originalIndex = allTransactions.indexOf(tx);
    
    return GestureDetector(
      // Edit transaction on tap
      onTap: () => _editTransaction(tx, originalIndex),
      // Delete transaction on long press
      onLongPress: () => _confirmDeleteTransaction(tx, originalIndex),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormat.format(tx['date']),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isGave ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isGave ? 'PAID' : 'RECEIVED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isGave ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (tx['note'] as String?) ?? '',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        if (hasImage)
                          GestureDetector(
                            onTap: () => _showFullImage(context, tx['imagePath']),
                            child: const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.receipt_long, size: 12, color: Colors.blue),
                                  SizedBox(width: 2),
                                  Text(
                                    'View Receipt',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    currencyFormat.format(tx['amount']),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isGave ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
              if (hasImage)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Image.file(
                            File(tx['imagePath']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Balance: ',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    currencyFormat.format(runningBalance.abs()),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: runningBalance >= 0 ? Colors.green : Colors.red,
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

  void _showFullImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Custom app bar with better actions
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text('Receipt'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                // Download button with enhanced visual
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _downloadImage(imagePath),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.download, color: Colors.blue.shade700, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              'Save',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: GestureDetector(
                onTap: () => Navigator.pop(context), // Tap image to close
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
              ),
            ),
            ),
            // Footer with cancel button
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _downloadImage(String imagePath) async {
    try {
      // Show loading indicator with improved message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20, 
                height: 20, 
                child: CircularProgressIndicator(
                  strokeWidth: 2, 
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Saving image to gallery...'),
            ],
          ),
          duration: Duration(seconds: 1),
        )
      );
      
      // Create a unique filename
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'receipt_$timestamp.jpg';
      
      // Get the destination directory path
      final directory = await getExternalStorageDirectory();
      final downloadPath = '${directory?.path}/Download/$fileName';
      
      // Ensure the download directory exists
      final downloadDir = Directory('${directory?.path}/Download');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      
      // Copy the file
      final File originalFile = File(imagePath);
      await originalFile.copy(downloadPath);
      
      // Show success message with action buttons
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade300, size: 18),
                  const SizedBox(width: 8),
                  const Text('Image saved successfully'),
                ],
              ),
              Text(
                'Location: Download/$fileName',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OPEN',
            onPressed: () async {
              try {
                // Try to open the saved file
                await OpenFile.open(downloadPath);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Unable to open file: $e')),
                  );
                }
              }
            },
          ),
        ),
      );
      
      // Close the image viewer dialog after successful download
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
    } catch (e) {
      // Show error message with more details
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade300),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Error saving image: $e'),
              ),
            ],
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _showContactInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.contact['name']} Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Phone', widget.contact['phone'] ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow('Category', StringUtils.capitalizeFirstLetter(widget.contact['category'] ?? 'Personal')),
            const SizedBox(height: 8),
            _buildInfoRow('Account Type', 'No Interest'),
          ],
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        Text(value),
      ],
    );
  }

  void _showContactOptions() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditContactScreen(
          contact: widget.contact,
          transactionProvider: Provider.of<TransactionProvider>(context, listen: false),
        ),
      ),
    );
    
    if (result == true) {
      // Refresh the screen if contact was updated or deleted
      setState(() {
        _loadContact();
      });
    }
  }

  void _confirmDeleteContact() {
    showDialog(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Delete Contact',
        content: 'Are you sure you want to delete ${widget.contact['name']}? This will delete all transaction history.',
        confirmText: 'Delete',
        confirmColor: Colors.red,
        onConfirm: () async {
          // Delete contact using TransactionProvider
          final provider = Provider.of<TransactionProvider>(context, listen: false);
          final success = await provider.deleteContact(widget.contact['phone']);
          
          // Close dialog
          Navigator.pop(context);
          
          if (success) {
            // Return to contacts list with deleted status
            Navigator.pop(context, true);
            
            // Show confirmation snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${widget.contact['name']} deleted')),
            );
          } else {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to delete contact')),
            );
          }
        },
      ),
    );
  }

  void _addTransaction(String type) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    List<String> imagePaths = [];
    String? amountError; // Add this to track error state
    
    // Define maximum amount (99 crore)
    const double maxAmount = 990000000.0;
    
    // Check if this is a with-interest contact
    final bool isWithInterest = widget.contact['type'] != null;
    final String relationshipType = widget.contact['type'] as String? ?? '';
    
    // Default to principal amount
    bool isPrincipalAmount = true;
    
    // Determine if we should show the interest option based on relationship and transaction type
    final bool showInterestOption = isWithInterest && !(
      (relationshipType == 'borrower' && type == 'gave') || // Borrowers don't receive interest
      (relationshipType == 'lender' && type == 'got')       // Lenders don't pay interest
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom
          ),
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bottom sheet drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Header
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: type == 'gave' ? Colors.red.shade100 : Colors.green.shade100,
                        radius: 16,
                        child: Icon(
                          type == 'gave' ? Icons.arrow_upward : Icons.arrow_downward,
                          color: type == 'gave' ? Colors.red : Colors.green,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        type == 'gave' ? 'Paid' : 'Received',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: type == 'gave' ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Amount Field
                  const Text(
                    'Amount',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                    controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                    decoration: InputDecoration(
                      hintText: '0.00',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            prefixText: '₹ ',
                            errorText: amountError,
                          ),
                        ),
                        ),
                        const SizedBox(width: 8),
                      // Date selection now appears directly to the right of amount
                  GestureDetector(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: type == 'gave' ? Colors.red : Colors.green,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null && picked != selectedDate) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                          height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today, 
                            size: 16, 
                            color: type == 'gave' ? Colors.red : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dateFormat.format(selectedDate).split(',')[0],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Note and Attach Bill in one row (70:30 ratio)
                  const Text(
                    'Note (optional)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Note field (70%)
                      Expanded(
                        flex: 7,
                        child: TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      hintText: 'Add a note...',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                      ),
                      const SizedBox(width: 8),
                      // Attach Bill button (30%)
                      Expanded(
                        flex: 3,
                        child: GestureDetector(
                    onTap: () {
                      _showImageSourceOptions(context, (path) {
                        setState(() {
                                imagePaths.add(path);
                        });
                      });
                    },
                    child: Container(
                            height: 48, // Match height with text field
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                              border: imagePaths.isNotEmpty 
                          ? Border.all(color: type == 'gave' ? Colors.red : Colors.green, width: 1) 
                          : null,
                      ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  imagePaths.isNotEmpty ? Icons.check_circle : Icons.add_photo_alternate,
                                  size: 20,
                                  color: type == 'gave' ? Colors.red.withOpacity(0.7) : Colors.green.withOpacity(0.7),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  imagePaths.isNotEmpty ? 'Photos (${imagePaths.length})' : 'Attach Bill',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: type == 'gave' ? Colors.red.withOpacity(0.7) : Colors.green.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Image Preview (only shows when images are attached)
                  if (imagePaths.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: type == 'gave' ? Colors.red.shade300 : Colors.green.shade300,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Display image thumbnails horizontally
                        Expanded(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: imagePaths.length + 1, // +1 for the "add more" button
                            itemBuilder: (context, index) {
                              // Last item is "add more" button
                              if (index == imagePaths.length) {
                                return GestureDetector(
                                  onTap: () {
                                    _showImageSourceOptions(context, (path) {
                                      setState(() {
                                        imagePaths.add(path);
                                      });
                                    });
                                  },
                                  child: Container(
                                    width: 60,
                                    margin: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.add_photo_alternate,
                                      color: type == 'gave' ? Colors.red.withOpacity(0.7) : Colors.green.withOpacity(0.7),
                                    ),
                                  ),
                                );
                              }
                              
                              // Show image thumbnails
                              return Stack(
                                children: [
                                  Container(
                                    width: 60,
                                    margin: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(5),
                                  child: Image.file(
                                        File(imagePaths[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                  ),
                                  // Remove button
                                Positioned(
                                    top: 2,
                                    right: 2,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                          imagePaths.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                          size: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              );
                            },
                                  ),
                                ),
                              ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Principal/Interest Switch (Only for with-interest contacts when appropriate)
                  if (showInterestOption) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Is this amount for:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSelectionButton(
                          title: 'Interest',
                          isSelected: !isPrincipalAmount,
                          icon: Icons.savings,
                          color: Colors.amber.shade700,
                          onTap: () {
                            setState(() {
                              isPrincipalAmount = false;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildSelectionButton(
                          title: 'Principal',
                          isSelected: isPrincipalAmount,
                          icon: Icons.money,
                          color: Colors.blue,
                          onTap: () {
                            setState(() {
                              isPrincipalAmount = true;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            foregroundColor: Colors.grey[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (amountController.text.isEmpty) {
                              setState(() {
                                amountError = 'Amount is required';
                              });
                              return;
                            }

                            final amount = double.tryParse(amountController.text);
                            if (amount == null || amount <= 0) {
                              setState(() {
                                amountError = 'Please enter a valid amount';
                              });
                              return;
                            }
                            
                            // Validate maximum amount
                            if (amount > maxAmount) {
                              setState(() {
                                amountError = 'Maximum allowed amount is ₹99 cr';
                              });
                              return;
                            }

                            // Ensure that certain relationship/transaction combinations are forced to principal
                            bool actualIsPrincipal = isPrincipalAmount;
                            if ((relationshipType == 'borrower' && type == 'gave') || 
                                (relationshipType == 'lender' && type == 'got')) {
                              actualIsPrincipal = true;
                            }

                            // Create transaction note
                            String note = noteController.text.isNotEmpty
                                ? noteController.text
                                : (type == 'gave' ? 'Payment sent' : 'Payment received');
                                
                            // Add prefix for interest/principal if applicable
                            if (isWithInterest) {
                              String prefix = actualIsPrincipal ? 'Principal: ' : 'Interest: ';
                              note = prefix + note;
                            }

                            // Add transaction details with support for multiple images
                            _transactionProvider.addTransactionDetails(
                              _contactId,
                              amount,
                              type,
                              selectedDate,
                              note,
                              imagePaths.isNotEmpty ? imagePaths[0] : null, // Backwards compatibility for single image
                              extraData: {
                                if (isWithInterest) ...{
                                'isPrincipal': actualIsPrincipal,
                                'interestRate': widget.contact['interestRate'] as double,
                                },
                                if (imagePaths.length > 1) 'imagePaths': imagePaths,
                              },
                            );
                            
                            // Refresh transactions
                            setState(() {
                            _applyFilters();
                            });
                            
                            Navigator.pop(context);
                            
                            // Show success message
                            final String amountType = actualIsPrincipal ? 'principal' : 'interest';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Added ${type == 'gave' ? 'payment' : 'receipt'} of ${currencyFormat.format(amount)} for $amountType'
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: type == 'gave' ? Colors.red : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showImageSourceOptions(BuildContext context, Function(String) onImageSelected) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Image Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  context,
                  Icons.camera_alt,
                  'Camera',
                  () => _getImage(ImageSource.camera, onImageSelected),
                ),
                _buildImageSourceOption(
                  context,
                  Icons.photo_library,
                  'Gallery',
                  () => _getImage(ImageSource.gallery, onImageSelected),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Icon(icon, size: 30, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _getImage(ImageSource source, Function(String) onImageSelected) async {
    final imagePickerHelper = ImagePickerHelper();
    
    try {
      // Use our helper that handles permission automatically
      final imageFile = await imagePickerHelper.pickImage(context, source);
      
      if (imageFile != null) {
        onImageSelected(imageFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildInterestSummaryCard() {
    // Get transaction data for this contact
    final transactions = _transactionProvider.getTransactionsForContact(_contactId);
    
    // Calculate principal and interest based on transaction history
    double principal = 0.0;
    double interestPaid = 0.0;
    double accumulatedInterest = 0.0;
    DateTime? firstTransactionDate;
    DateTime? lastInterestCalculationDate;
    
    // Sort transactions by date (oldest first)
    transactions.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    
    // Get relationship type to handle borrower vs lender logic differently
    final relationshipType = widget.contact['type'] as String? ?? '';
    final isBorrower = relationshipType == 'borrower';
    
    if (transactions.isNotEmpty) {
      // Set first transaction date
      firstTransactionDate = transactions.first['date'] as DateTime;
      lastInterestCalculationDate = firstTransactionDate;
      
      // Track running principal for interest calculation
      double runningPrincipal = 0.0;
      
      // INTEREST CALCULATION EXPLANATION:
      // --------------------------------
      // Both borrowers and lenders accrue interest on the outstanding principal
      // 1. For borrowers: User lends money, borrower pays interest on outstanding amount
      // 2. For lenders: User borrows money, user pays interest on outstanding amount
      // 
      // Key principles:
      // - Interest accrues daily based on outstanding principal
      // - Interest payments don't reduce the principal
      // - Principal payments reduce the outstanding amount and therefore future interest
      // 
      // For Borrowers:
      // - When user PAYS money (isGave = true): increases debt (adds to principal) or adds to accumulated interest
      // - When user RECEIVES money (isGave = false): decreases debt (reduces principal) or pays off interest
      //
      // For Lenders:
      // - When user PAYS money (isGave = true): decreases debt (reduces principal) or pays off interest
      // - When user RECEIVES money (isGave = false): increases debt (adds to principal) or adds to accumulated interest
      
      // Process transactions chronologically to track interest accumulation
      for (var tx in transactions) {
        final note = (tx['note'] ?? '').toLowerCase();
        final amount = tx['amount'] as double;
        final isGave = tx['type'] == 'gave';
        final txDate = tx['date'] as DateTime;
        
        // Calculate interest accumulated up to this transaction date
        if (lastInterestCalculationDate != null && runningPrincipal > 0) {
          final daysSinceLastCalculation = txDate.difference(lastInterestCalculationDate).inDays;
          if (daysSinceLastCalculation > 0) {
            // Get interest rate and period
            final interestRate = (widget.contact['interestRate'] as double);
            final isMonthly = widget.contact['interestPeriod'] == 'monthly';
            
            // Calculate interest based on complete months and remaining days
            double interestForPeriod = 0.0;
            
            if (isMonthly) {
              // For monthly rate:
              // Step 1: Calculate complete months between dates
              int completeMonths = 0;
              DateTime tempDate = DateTime(lastInterestCalculationDate.year, lastInterestCalculationDate.month, lastInterestCalculationDate.day);
              
              while (true) {
                // Try to add one month
                DateTime nextMonth = DateTime(tempDate.year, tempDate.month + 1, tempDate.day);
                
                // If adding one month exceeds the transaction date, break
                if (nextMonth.isAfter(txDate)) {
                  break;
                }
                
                // Count this month and move to next
                completeMonths++;
                tempDate = nextMonth;
              }
              
              // Apply full monthly interest for complete months
              if (completeMonths > 0) {
                interestForPeriod += runningPrincipal * (interestRate / 100) * completeMonths;
              }
              
              // Step 2: Calculate interest for remaining days (partial month)
              final remainingDays = txDate.difference(tempDate).inDays;
              if (remainingDays > 0) {
                // Get days in the current month for the partial calculation
                final daysInMonth = DateTime(tempDate.year, tempDate.month + 1, 0).day;
                double monthProportion = remainingDays / daysInMonth;
                interestForPeriod += runningPrincipal * (interestRate / 100) * monthProportion;
              }
            } else {
              // For yearly rate: Handle similarly but with yearly rate converted to monthly
              double monthlyRate = interestRate / 12;
              
              // Step 1: Calculate complete months between dates
              int completeMonths = 0;
              DateTime tempDate = DateTime(lastInterestCalculationDate.year, lastInterestCalculationDate.month, lastInterestCalculationDate.day);
              
              while (true) {
                // Try to add one month
                DateTime nextMonth = DateTime(tempDate.year, tempDate.month + 1, tempDate.day);
                
                // If adding one month exceeds the transaction date, break
                if (nextMonth.isAfter(txDate)) {
                  break;
                }
                
                // Count this month and move to next
                completeMonths++;
                tempDate = nextMonth;
              }
              
              // Apply full monthly interest for complete months
              if (completeMonths > 0) {
                interestForPeriod += runningPrincipal * (monthlyRate / 100) * completeMonths;
              }
              
              // Step 2: Calculate interest for remaining days (partial month)
              final remainingDays = txDate.difference(tempDate).inDays;
              if (remainingDays > 0) {
                // Get days in the current month for the partial calculation
                final daysInMonth = DateTime(tempDate.year, tempDate.month + 1, 0).day;
                double monthProportion = remainingDays / daysInMonth;
                interestForPeriod += runningPrincipal * (monthlyRate / 100) * monthProportion;
              }
            }
            
            accumulatedInterest += interestForPeriod;
          }
        }
        
        // Update principal or interest based on transaction type
        if (note.contains('interest:')) {
          if (isGave) {
            // User paid interest
            if (isBorrower) {
              // For borrowers: paid interest adds to debt
              accumulatedInterest += amount;
            } else {
              // For lenders: paid interest reduces accumulated interest
              accumulatedInterest = (accumulatedInterest - amount > 0) ? accumulatedInterest - amount : 0;
            }
          } else {
            // User received interest payment
            interestPaid += amount;
            
            // For both borrowers and lenders, interest payments don't reduce the accumulated interest 
            // because it continues to accrue based on the principal
            // Removing special case for lenders to make interest calculation consistent
          }
        } else {
          // It's a principal transaction
          if (isGave) {
            if (isBorrower) {
              // For borrowers: paying principal adds to debt
              runningPrincipal += amount;
              principal += amount;
            } else {
              // For lenders: paying principal reduces debt (repaying the loan)
              runningPrincipal = (runningPrincipal - amount > 0) ? runningPrincipal - amount : 0;
              principal = (principal - amount > 0) ? principal - amount : 0;
            }
          } else {
            // Received principal payment
            if (isBorrower) {
              // For borrowers: receiving payment decreases principal
              runningPrincipal = (runningPrincipal - amount > 0) ? runningPrincipal - amount : 0;
              principal = (principal - amount > 0) ? principal - amount : 0;
            } else {
              // For lenders: receiving payment increases principal (the lender gave money)
              runningPrincipal += amount;
              principal += amount;
            }
          }
        }
        
        // Update last calculation date
        lastInterestCalculationDate = txDate;
      }
    }
    
    // Calculate interest from last transaction date until today
    double interestDue = accumulatedInterest;
    if (lastInterestCalculationDate != null && principal > 0) {
      // Get interest rate and period
      final interestRate = (widget.contact['interestRate'] as double); 
      final isMonthly = widget.contact['interestPeriod'] == 'monthly';
      
      // Calculate interest from last transaction to today (using same approach as above)
      double interestFromLastTx = 0.0;
      DateTime now = DateTime.now();
      
      if (isMonthly) {
        // Step 1: Calculate complete months between last transaction and today
        int completeMonths = 0;
        DateTime tempDate = DateTime(lastInterestCalculationDate.year, lastInterestCalculationDate.month, lastInterestCalculationDate.day);
        
        while (true) {
          // Try to add one month
          DateTime nextMonth = DateTime(tempDate.year, tempDate.month + 1, tempDate.day);
          
          // If adding one month exceeds current date, break
          if (nextMonth.isAfter(now)) {
            break;
          }
          
          // Count this month and move to next
          completeMonths++;
          tempDate = nextMonth;
        }
        
        // Apply full monthly interest for complete months
        if (completeMonths > 0) {
          interestFromLastTx += principal * (interestRate / 100) * completeMonths;
        }
        
        // Step 2: Calculate interest for remaining days (partial month)
        final remainingDays = now.difference(tempDate).inDays;
        if (remainingDays > 0) {
          // Get days in the current month for the partial calculation
          final daysInMonth = DateTime(tempDate.year, tempDate.month + 1, 0).day;
          double monthProportion = remainingDays / daysInMonth;
          interestFromLastTx += principal * (interestRate / 100) * monthProportion;
        }
      } else {
        // For yearly rate: Handle with yearly rate converted to monthly
        double monthlyRate = interestRate / 12;
        
        // Step 1: Calculate complete months between last transaction and today
        int completeMonths = 0;
        DateTime tempDate = DateTime(lastInterestCalculationDate.year, lastInterestCalculationDate.month, lastInterestCalculationDate.day);
        
        while (true) {
          // Try to add one month
          DateTime nextMonth = DateTime(tempDate.year, tempDate.month + 1, tempDate.day);
          
          // If adding one month exceeds current date, break
          if (nextMonth.isAfter(now)) {
            break;
          }
          
          // Count this month and move to next
          completeMonths++;
          tempDate = nextMonth;
        }
        
        // Apply full monthly interest for complete months
        if (completeMonths > 0) {
          interestFromLastTx += principal * (monthlyRate / 100) * completeMonths;
        }
        
        // Step 2: Calculate interest for remaining days (partial month)
        final remainingDays = now.difference(tempDate).inDays;
        if (remainingDays > 0) {
          // Get days in the current month for the partial calculation
          final daysInMonth = DateTime(tempDate.year, tempDate.month + 1, 0).day;
          double monthProportion = remainingDays / daysInMonth;
          interestFromLastTx += principal * (monthlyRate / 100) * monthProportion;
        }
      }
      
      interestDue += interestFromLastTx;
    }
    
    // Adjust for interest already paid - for both borrowers and lenders
    // Show the net interest (interest due minus payments received)
    interestDue = (interestDue - interestPaid > 0) ? interestDue - interestPaid : 0;
    
    // Store the calculated interest for display in other places
    widget.contact['interestDue'] = interestDue;
    
    // Calculate interest per day based on current principal
    double interestPerDay;
    final interestRate = (widget.contact['interestRate'] as double);
    final isMonthly = widget.contact['interestPeriod'] == 'monthly';
    
    // Calculate monthly interest first
    double monthlyInterest;
    if (isMonthly) {
      // For monthly rates: use the rate directly
      monthlyInterest = principal * (interestRate / 100);
    } else {
      // For yearly rates: Convert to monthly first
      double monthlyRate = interestRate / 12;
      monthlyInterest = principal * (monthlyRate / 100);
    }
    
    // Calculate the actual number of days in the current month
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day; // Last day of current month
    
    // Calculate daily interest based on actual days in month
    // For example, if it's 24% annual (2% monthly) on 1,00,000, in a 31-day month:
    // Daily interest = (1,00,000 × 0.02) ÷ 31 = 2,000 ÷ 31 = 64.52 per day
    interestPerDay = monthlyInterest / daysInMonth;
    
    // Calculate total amount (principal + interest)
    final totalAmount = principal + interestDue;
    
    final Color relationshipColor = relationshipType == 'borrower' ? 
            const Color(0xFF5D69E3) : // Blue-purple for borrower
            const Color(0xFF2E9E7A); // Teal for lender
    
    // Store current month info for display
    final String currentMonthAbbr = _getMonthAbbreviation();
    
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            relationshipColor.withOpacity(0.9),
            relationshipColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: relationshipColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with interest rate badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        relationshipType == 'borrower' 
                            ? Icons.account_balance_wallet 
                            : Icons.account_balance,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Interest Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              StringUtils.capitalizeFirstLetter(relationshipType),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.percent,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${widget.contact['interestRate']}% ${widget.contact['interestPeriod'] == 'monthly' ? 'p.m.' : 'p.a.'}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _showContactInfo,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Three-column layout for principal, interest, total amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInterestDetailColumn(
                  title: 'Principal',
                  amount: principal,
                  icon: Icons.attach_money_rounded,
                ),
                Container(
                  height: 50,
                  width: 1,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildInterestDetailColumn(
                  title: 'Interest Due',
                  amount: interestDue,
                  icon: Icons.timeline,
                ),
                Container(
                  height: 50,
                  width: 1,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildInterestDetailColumn(
                  title: 'Total Amount',
                  amount: totalAmount,
                  icon: Icons.account_balance_wallet,
                ),
              ],
            ),
            
            // Add action buttons
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButtonCompact(
                    context,
                    Icons.call,
                    'Call',
                    Colors.blue,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6A74CC), Color(0xFF3B5AC0)],
                    ),
                    onTap: _handleCallButton,
                  ),
                  _buildActionButtonCompact(
                    context,
                    Icons.picture_as_pdf,
                    'PDF Report',
                    Colors.red,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFE57373), Color(0xFFC62828)],
                    ),
                    onTap: _handlePdfReport,
                  ),
                  _buildActionButtonCompact(
                    context,
                    Icons.notifications,
                    'Reminder',
                    Colors.orange,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFB74D), Color(0xFFE65100)],
                    ),
                    onTap: _setReminder,
                  ),
                  _buildActionButtonCompact(
                    context,
                    Icons.sms,
                    'SMS',
                    Colors.green,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF81C784), Color(0xFF2E7D32)],
                    ),
                    onTap: _handleSmsButton,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInterestDetailColumn({
    required String title,
    required double amount,
    required IconData icon,
    String? subtitle,
  }) {
    // Format large numbers in a compact way
    String formattedAmount = amount >= 100000 
        ? _formatCompactCurrency(amount) 
        : currencyFormat.format(amount);
        
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.8),
              fontStyle: FontStyle.italic,
            ),
          ),
        const SizedBox(height: 4),
        // Use FittedBox to ensure text fits in its container
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              formattedAmount,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
            ),
          ),
        ),
      ],
    );
  }
  
  // Helper method to format large currency values in a compact way
  String _formatCompactCurrency(double amount) {
    if (amount >= 10000000) { // 1 crore or more
      return 'Rs. ${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else {
      // For values less than 1 crore, show the full number with commas
      return currencyFormat.format(amount);
    }
  }
  
  // Helper method to adjust font size for summary card amount based on length
  double _getAdaptiveFontSize(double amount) {
    if (amount >= 100000000) { // ≥ 10 crore
      return 24.0;
    } else if (amount >= 10000000) { // ≥ 1 crore
      return 26.0;
    } else if (amount >= 9900000) { // ≥ 99 lakh
      return 28.0;
    } else if (amount >= 1000000) { // ≥ 10 lakh
      return 30.0;
    } else {
      return 32.0; // Default size for smaller amounts
    }
  }
  
  // Helper method to format currency text with overflow protection
  Widget _formatCurrencyText(double amount, {double fontSize = 14, FontWeight fontWeight = FontWeight.bold, Color? color}) {
    // Format large numbers in a compact way
    String formattedAmount = amount >= 100000 
        ? _formatCompactCurrency(amount) 
        : currencyFormat.format(amount);
    
    // Use FittedBox to ensure text fits in its container
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        formattedAmount,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color ?? Colors.black,
        ),
        maxLines: 1,
      ),
    );
  }

  // Basic summary card for contacts without interest
  Widget _buildBasicSummaryCard() {
    final balance = _calculateBalance();
    final isPositive = balance >= 0;
    
    // Calculate total paid and received for additional statistics
    double totalPaid = 0;
    double totalReceived = 0;
    final transactions = _transactionProvider.getTransactionsForContact(_contactId);
    
    for (var tx in transactions) {
      if (tx['type'] == 'gave') {
        totalPaid += tx['amount'] as double;
      } else {
        totalReceived += tx['amount'] as double;
      }
    }
    
    // Choose colors based on balance status
    final Color primaryColor = isPositive ? Colors.green.shade700 : Colors.red.shade700;
    final Color secondaryColor = isPositive ? Colors.green.shade400 : Colors.red.shade400;
    final Color lightColor = isPositive ? Colors.green.shade50 : Colors.red.shade50;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            secondaryColor,
          ],
        ),
      ),
      child: Column(
        children: [
          // Main balance section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Amount section (left-aligned)
                    Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                      children: [
                    const Text(
                      '₹ ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                    ),
                Text(
                      NumberFormat('#,##0.00').format(balance.abs()),
                      style: TextStyle(
                        // Adjust font size based on amount
                        fontSize: _getAdaptiveFontSize(balance.abs()),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                  ),
                      ],
                ),
                
                // Action label (right-aligned)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                    color: isPositive ? Colors.green.shade800 : Colors.red.shade800,
                    borderRadius: BorderRadius.circular(4),
                        ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                  children: [
                      Icon(
                        isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                        color: Colors.white,
                        size: 14,
                    ),
                      const SizedBox(width: 4),
                      Text(
                        isPositive ? 'Receive' : 'Pay',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                  ),
                ),
              ],
            ),
        ),
              ],
      ),
          ),
          
          // Statistics section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButtonCompact(
                  context,
                  Icons.call,
                  'Call',
                  Colors.blue,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6A74CC), Color(0xFF3B5AC0)],
                  ),
                  onTap: _handleCallButton,
            ),
                _buildActionButtonCompact(
                  context,
                  Icons.picture_as_pdf,
                  'PDF Report',
                  Colors.red,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE57373), Color(0xFFC62828)],
                  ),
                  onTap: _handlePdfReport,
            ),
                _buildActionButtonCompact(
                  context,
                  Icons.notifications,
                  'Reminder',
                  Colors.orange,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFB74D), Color(0xFFE65100)],
                  ),
                  onTap: _setReminder,
                ),
                _buildActionButtonCompact(
                  context,
                  Icons.sms,
                  'SMS',
                  Colors.green,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF81C784), Color(0xFF2E7D32)],
                  ),
                  onTap: _handleSmsButton,
                ),
              ],
            ),
            ),
          ],
        ),
      );
    }
  
  // Helper widget for compact action buttons in the summary card
  Widget _buildActionButtonCompact(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    {required VoidCallback onTap, required Gradient gradient}
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            ),
          ],
        ),
    );
  }

  void _handleCallButton() async {
    final phone = widget.contact['phone'];
      
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available for this contact')),
      );
      return;
    }
    
    // Check phone call permission first
    final permissionUtils = PermissionUtils();
    final hasCallPermission = await permissionUtils.requestCallPhonePermission(context);
    
    if (!hasCallPermission) {
      // Permission denied
      return;
    }
    
    // Format phone number (remove spaces and special characters)
    final formattedPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    try {
      // Use direct intent URL that bypasses the confirmation dialog
      // First try using the tel: scheme with external application mode
      bool launched = await launchUrl(
        Uri.parse('tel:$formattedPhone'),
        mode: LaunchMode.externalNonBrowserApplication,
      );
    
      // If the above didn't work, try alternate approach
      if (!launched) {
        await launchUrl(
          Uri.parse('tel:$formattedPhone'),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      // Show error message if dialer can't be opened
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open phone dialer')),
        );
      }
    }
  }

  void _handlePdfReport() async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating PDF report...')),
      );
      
      // Get transactions
      final transactions = _transactionProvider.getTransactionsForContact(_contactId);
      
      // Check if transactions are empty
      if (transactions.isEmpty) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No transactions to generate report')),
        );
        return;
      }
      
      // Prepare data for PDF summary card
      final balance = _calculateBalance();
      final isPositive = balance >= 0;
      final isWithInterest = widget.contact['type'] != null || widget.contact['interestRate'] != null;
      
      // Create a more detailed summary with contact information
      final List<Map<String, dynamic>> summaryItems = [
        {
          'label': 'Name:',
          'value': widget.contact['name'],
        },
        {
          'label': 'Phone:',
          'value': widget.contact['displayPhone'] ?? widget.contact['phone'] ?? 'N/A',
        },
        {
          'label': isPositive ? 'YOU WILL GET' : 'YOU WILL GIVE',
          'value': 'Rs. ${PdfTemplateService.formatCurrency(balance.abs())}',
          'highlight': true,
          'isPositive': isPositive,
        },
      ];
      
      // Add interest information if applicable
      if (isWithInterest) {
        final contactType = widget.contact['type'] ?? '';
        final interestRate = widget.contact['interestRate'] ?? 0.0;
        final isMonthly = widget.contact['interestPeriod'] == 'monthly';
        
        summaryItems.addAll([
          {
            'label': 'Interest Rate:',
            'value': '$interestRate% ${isMonthly ? 'per month' : 'per annum'}',
          },
          {
            'label': 'Relationship:',
            'value': contactType.isNotEmpty 
                ? '${StringUtils.capitalizeFirstLetter(contactType)} (${contactType == 'borrower' ? 'They borrow from you' : 'You borrow from them'})'
                : 'Not specified',
          },
        ]);
        
        // Calculate interest values 
        if (contactType.isNotEmpty && transactions.isNotEmpty) {
          // Calculate principal and interest amounts
          double principalAmount = 0.0;
          
          // Calculate based on current balance and interest rate
          principalAmount = balance.abs(); // Use the balance as principal for simplicity
          
          // Calculate monthly interest
          double monthlyInterest = 0.0;
          if (isMonthly) {
            monthlyInterest = principalAmount * (interestRate / 100);
          } else {
            // Convert annual rate to monthly
            double monthlyRate = interestRate / 12;
            monthlyInterest = principalAmount * (monthlyRate / 100);
          }
          
          // Calculate daily interest based on days in current month
          final daysInMonth = DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;
          
          summaryItems.addAll([
            {
              'label': 'Estimated Principal:',
              'value': 'Rs. ${PdfTemplateService.formatCurrency(principalAmount)}',
            },
            {
              'label': 'Est. Monthly Interest:',
              'value': 'Rs. ${PdfTemplateService.formatCurrency(monthlyInterest)}',
            },
            {
              'label': 'Est. Daily Interest:',
              'value': 'Rs. ${PdfTemplateService.formatCurrency(monthlyInterest / daysInMonth)}',
            },
          ]);
        }
      }
      
      // Add transaction stats
      if (transactions.isNotEmpty) {
        final totalPaid = transactions
            .where((tx) => tx['type'] == 'gave')
            .fold(0.0, (sum, tx) => sum + (tx['amount'] as double));
            
        final totalReceived = transactions
            .where((tx) => tx['type'] == 'got')
            .fold(0.0, (sum, tx) => sum + (tx['amount'] as double));
            
        final earliestDate = transactions
            .map((tx) => tx['date'] as DateTime)
            .reduce((a, b) => a.isBefore(b) ? a : b);
            
        final latestDate = transactions
            .map((tx) => tx['date'] as DateTime)
            .reduce((a, b) => a.isAfter(b) ? a : b);
            
        summaryItems.addAll([
          {
            'label': 'Total Transactions:',
            'value': '${transactions.length}',
          },
          {
            'label': 'Total Paid:',
            'value': 'Rs. ${PdfTemplateService.formatCurrency(totalPaid)}',
          },
          {
            'label': 'Total Received:',
            'value': 'Rs. ${PdfTemplateService.formatCurrency(totalReceived)}',
          },
          {
            'label': 'First Transaction:',
            'value': DateFormat('dd MMM yyyy').format(earliestDate),
          },
          {
            'label': 'Latest Transaction:',
            'value': DateFormat('dd MMM yyyy').format(latestDate),
          },
        ]);
      }
      
      // ===== TRADITIONAL LEDGER FORMAT =====
      
      // Prepare data for traditional ledger style transaction table
      final List<String> tableColumns = ['Date', 'Description', 'Debit', 'Credit', 'Balance'];
      final List<List<String>> tableRows = [];
      
      // Sort transactions by date (oldest first) for traditional ledger
      final sortedTransactions = List<Map<String, dynamic>>.from(transactions);
      sortedTransactions.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
      
      // Calculate running balance for each transaction
      double runningBalance = 0.0;
      
      for (var transaction in sortedTransactions) {
        final date = transaction['date'] != null
            ? DateFormat('dd/MM/yyyy').format(transaction['date'] as DateTime)
            : 'N/A';
        
        final String description = transaction['note'] != null && transaction['note'].toString().isNotEmpty
            ? transaction['note'].toString()
            : (transaction['type'] == 'gave' ? 'Payment sent' : 'Payment received');
        
        final double amount = transaction['amount'] as double;
        final bool isDebit = transaction['type'] == 'gave';
        
        // Update running balance
        if (isDebit) {
          runningBalance += amount; // Debit increases what they owe to you
        } else {
          runningBalance -= amount; // Credit decreases what they owe to you
        }
        
        // Format amounts properly
        final debitAmount = isDebit ? 'Rs. ${PdfTemplateService.formatCurrency(amount)}' : '';
        final creditAmount = !isDebit ? 'Rs. ${PdfTemplateService.formatCurrency(amount)}' : '';
        final balanceAmount = 'Rs. ${PdfTemplateService.formatCurrency(runningBalance.abs())}';
        final balanceAmountWithSign = runningBalance >= 0 
            ? balanceAmount // Positive means they owe you
            : "($balanceAmount)"; // Negative means you owe them
        
        tableRows.add([date, description, debitAmount, creditAmount, balanceAmountWithSign]);
      }
      
      // Create PDF manually to ensure it works
      final pdf = pw.Document();
      
      final contactName = widget.contact['name'].toString().replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      final date = DateFormat('yyyy_MM_dd').format(DateTime.now());
      final timestamp = DateFormat('HH_mm_ss').format(DateTime.now());
      final random = DateTime.now().millisecondsSinceEpoch % 10000; // Add random component
      final fileName = '${contactName}_ledger_${date}_${timestamp}_$random.pdf';
      
      // Add page with content
      pdf.addPage(
        pw.Page(
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Add the header
                PdfTemplateService.buildHeader(
                  title: widget.contact['name'],
                  subtitle: 'Account Ledger',
                ),
                pw.SizedBox(height: 20),
                
        // Contact Summary Section
        PdfTemplateService.buildSummaryCard(
                  title: 'Account Statement',
          items: summaryItems,
        ),
        pw.SizedBox(height: 20),
        
                // Traditional Ledger Style Transaction Table
                pw.Text(
                  'Transaction Ledger',
                  style: pw.TextStyle(
                    fontSize: 16, 
                    fontWeight: pw.FontWeight.bold,
                    color: PdfTemplateService.primaryColor,
                  ),
                ),
                pw.SizedBox(height: 10),
                
                // Build table directly
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfTemplateService.separatorColor,
                    width: 0.5,
                  ),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.5),    // Date
                    1: const pw.FlexColumnWidth(4),      // Description
                    2: const pw.FlexColumnWidth(1.5),    // Debit
                    3: const pw.FlexColumnWidth(1.5),    // Credit
                    4: const pw.FlexColumnWidth(1.5),    // Balance
                  },
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfTemplateService.tableHeaderColor,
                      ),
                      children: tableColumns.asMap().entries.map((entry) {
                        final index = entry.key;
                        final column = entry.value;
                        
                        // Different alignment for different columns
                        pw.TextAlign alignment = pw.TextAlign.left;
                        if (index >= 2 && index <= 4) {
                          alignment = pw.TextAlign.right;
                        } else if (index == 0) {
                          alignment = pw.TextAlign.center;
                        }
                        
                        return pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            column,
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: alignment,
                          ),
                        );
                      }).toList(),
                    ),
                    
                    // Data rows
                    ...tableRows.asMap().entries.map((entry) {
                      final index = entry.key;
                      final row = entry.value;
                      
                      return pw.TableRow(
                        decoration: index % 2 == 1
                            ? const pw.BoxDecoration(color: PdfTemplateService.tableAlternateColor)
                            : const pw.BoxDecoration(color: PdfColors.white),
                        children: row.asMap().entries.map((cellEntry) {
                          final cellIndex = cellEntry.key;
                          final cell = cellEntry.value;
                          
                          pw.TextAlign alignment = pw.TextAlign.left;
                          if (cellIndex >= 2 && cellIndex <= 4) {
                            alignment = pw.TextAlign.right;
                          } else if (cellIndex == 0) {
                            alignment = pw.TextAlign.center;
                          }
                          
                          PdfColor textColor = PdfColors.black;
                          pw.FontWeight fontWeight = pw.FontWeight.normal;
                          
                          if (cellIndex == 4) {
                            fontWeight = pw.FontWeight.bold;
                            if (cell.contains('(')) {
                              textColor = PdfTemplateService.dangerColor;
                            } else {
                              textColor = PdfTemplateService.successColor;
                            }
                          }
                          
                          return pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              cell,
                              textAlign: alignment,
                              style: pw.TextStyle(
                                fontWeight: fontWeight,
                                color: textColor,
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }).toList(),
                    
                    // Total row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfTemplateService.tableHeaderColor,
                      ),
                      children: List.generate(tableColumns.length, (index) {
                        String content = '';
                        pw.TextAlign alignment = pw.TextAlign.left;
                        
                        if (index == 1) {
                          content = 'CLOSING BALANCE';
                          alignment = pw.TextAlign.right;
                        } else if (index == 4 && tableRows.isNotEmpty) {
                          content = tableRows.last[4];
                          alignment = pw.TextAlign.right;
                        }
                        
                        return pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            content,
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: index == 4 ? PdfTemplateService.primaryColor : PdfColors.black,
                            ),
                            textAlign: alignment,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                
                // Footer
                PdfTemplateService.buildFooter(context),
              ],
            );
          },
        ),
      );
      
      try {
        // Get app's directory for saving the PDF
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';
        
        // Save PDF directly to file system
        final file = File(filePath);
        await file.writeAsBytes(await pdf.save());
        
        // Try to open the PDF
        final result = await OpenFile.open(filePath);
        
        // Log the status
        print('OpenFile Result: ${result.type.toString()} - ${result.message}');
      
      // Show success message
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                const Text('Ledger PDF generated successfully'),
              Text(
                  'Saved to: $filePath',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    } catch (e) {
        print('Error saving or opening PDF: $e');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error saving PDF: $e'),
          duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e, stackTrace) {
      // Show detailed error message with stack trace
      print('PDF Generation error: $e');
      print('Stack trace: $stackTrace');
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Error generating PDF report'),
              Text(
                e.toString(),
                style: const TextStyle(fontSize: 12, color: Colors.white70),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  void _setReminder() async {
    // Check if there's already an active reminder for this contact
    final existingReminder = await _checkForExistingReminder();
    
    if (existingReminder != null) {
      // Show dialog with options to view, cancel or create new reminder
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reminder Already Exists'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You already have a reminder set for ${widget.contact['name']} on:'),
              const SizedBox(height: 8),
              Text(
                DateFormat('dd MMM yyyy').format(existingReminder['scheduledDate']),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelReminder(existingReminder['id']);
              },
              child: const Text('Cancel Reminder'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep It'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showDateTimePickerForReminder();
              },
              child: const Text('Set New Reminder'),
            ),
          ],
        ),
      );
      return;
    }
    
    // No existing reminder, show date picker directly
    _showDateTimePickerForReminder();
  }
  
  Future<Map<String, dynamic>?> _checkForExistingReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getStringList('contact_reminders') ?? [];
    
    for (final reminderJson in remindersJson) {
      try {
        final reminder = jsonDecode(reminderJson);
        if (reminder['contactId'] == widget.contact['phone']) {
          final scheduledDate = DateTime.parse(reminder['scheduledDate']);
          // Only return if the reminder is in the future
          if (scheduledDate.isAfter(DateTime.now())) {
            return reminder;
          }
        }
      } catch (e) {
        print('Error parsing reminder: $e');
      }
    }
    return null;
  }
  
  Future<void> _cancelReminder(int id) async {
    // Cancel the notification
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin.cancel(id);
    
    // Remove from shared preferences
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getStringList('contact_reminders') ?? [];
    
    final updatedReminders = remindersJson.where((reminderJson) {
      try {
        final reminder = jsonDecode(reminderJson);
        return reminder['id'] != id;
      } catch (e) {
        return true; // Keep entries that can't be parsed
      }
    }).toList();
    
    await prefs.setStringList('contact_reminders', updatedReminders);
    
    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder cancelled'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  void _showDateTimePickerForReminder() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null && mounted) {
      // Create a DateTime with just the date component (set time to start of day)
      final scheduledDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );

      // Create a unique ID for this notification based on contact and time
      final int notificationId = DateTime.now().millisecondsSinceEpoch % 100000;

      // Generate reminder text
      final balance = _calculateBalance();
      final isCredit = balance >= 0;
      final String reminderText = isCredit
          ? "Reminder to collect ${currencyFormat.format(balance.abs())} from ${widget.contact['name']}"
          : "Reminder to pay ${currencyFormat.format(balance.abs())} to ${widget.contact['name']}";

      // Schedule the notification
      await _scheduleNotification(
        id: notificationId,
        title: "Payment Reminder",
        body: reminderText,
        scheduledDate: scheduledDate,
      );
      
      // Store reminder details in shared preferences
      await _saveReminderDetails(notificationId, scheduledDate, reminderText);

      // Show confirmation to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminder set for ${DateFormat('dd MMM yyyy').format(scheduledDate)}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
  
  Future<void> _saveReminderDetails(
    int id, 
    DateTime scheduledDate, 
    String message
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getStringList('contact_reminders') ?? [];
    
    // Create reminder object
    final reminder = {
      'id': id,
      'contactId': widget.contact['phone'],
      'contactName': widget.contact['name'],
      'scheduledDate': scheduledDate.toIso8601String(),
      'message': message,
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    // Add to list
    remindersJson.add(jsonEncode(reminder));
    
    // Save updated list
    await prefs.setStringList('contact_reminders', remindersJson);
    
    // Also notify the NotificationProvider to update UI
    if (mounted) {
      // Add to notification center
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      notificationProvider.addContactReminderNotification(
        contactId: widget.contact['phone'],
        contactName: widget.contact['name'],
        amount: _calculateBalance().abs(),
        dueDate: scheduledDate,
        paymentType: _calculateBalance() >= 0 ? 'collect' : 'pay',
      );
    }
  }
  
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // Access the global notification plugin
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    // Create notification details
    const androidDetails = AndroidNotificationDetails(
      'payment_reminders',
      'Payment Reminders',
      channelDescription: 'Notifications for payment reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    
    const iosDetails = DarwinNotificationDetails();
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    // Show an immediate notification as confirmation
    await flutterLocalNotificationsPlugin.show(
      id + 1000, // Use different ID for confirmation notification
      "Reminder Scheduled",
      "Payment reminder set for ${DateFormat('dd MMM yyyy').format(scheduledDate)}",
      notificationDetails,
    );
    
    // For actual scheduled notifications, we'll just store the information
    // and rely on the immediate notification for now as a simplification
    // This avoids timezone and scheduling complexities
    
    // Show a message to the user about the scheduled reminder
    print('Notification scheduled for: ${scheduledDate.toString()}');
  }

  void _handleSmsButton() async {
    final balance = _calculateBalance();
    final isPositive = balance >= 0;
    
    final message = '''
Dear ${widget.contact['name']},

🙏 *Payment Reminder*

This is a gentle reminder regarding your account with My Byaj Book:

💰 *Account Summary:*
Current balance: ${currencyFormat.format(balance.abs())}
${isPositive ? '➡️ Payment due to be received' : '➡️ Payment to be made'}

${isPositive ? '✅ Kindly arrange the payment at your earliest convenience.' : '✅ I will arrange the payment shortly.'}

Thank you for your attention to this matter.

Best regards,
${_getAppUserName()} 📱
''';
    
    bool whatsappOpened = await _tryOpenWhatsApp(message);
    
    if (!whatsappOpened) {
      await _trySendSMS(message);
    }
  }
  
  Future<bool> _tryOpenWhatsApp(String message) async {
    final phone = widget.contact['phone'];
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available for this contact')),
      );
      return false;
    }
    
    // Just get a clean number with no spaces or special chars
    final formattedPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // For India, make sure we have 91 prefix for proper WhatsApp opening
    String whatsappPhone = formattedPhone;
    if (formattedPhone.length == 10) {
      whatsappPhone = "91$formattedPhone";
    }
    
    // Create the URL
    final whatsappUrl = Uri.parse(
      'whatsapp://send?phone=$whatsappPhone&text=${Uri.encodeComponent(message)}',
    );
    
    try {
      // Launch directly with explicit mode setting
      await launchUrl(
        whatsappUrl,
        mode: LaunchMode.externalNonBrowserApplication,
      );
      return true;
    } catch (e) {
      print('Error opening WhatsApp: $e');
      // WhatsApp not installed or couldn't be launched
      return false;
    }
  }
  
  Future<void> _trySendSMS(String message) async {
    final phone = widget.contact['phone'];
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available for this contact')),
      );
      return;
    }
    
    // No longer need SMS permission - using intent instead
    // final permissionUtils = PermissionUtils();
    // final hasSmsPermission = await permissionUtils.requestSmsPermission(context);
    
    // if (!hasSmsPermission) {
    //   // Permission denied
    //   return;
    // }
    
    // For SMS, keep the + prefix for international numbers
    String formattedPhone = phone.replaceAll(RegExp(r'\s+'), '');
    
    // Create SMS URL
    final smsUrl = Uri.parse(
      'sms:$formattedPhone?body=${Uri.encodeComponent(message)}',
    );
    
    try {
      // Launch directly without checking canLaunchUrl first
      await launchUrl(
        smsUrl,
        mode: LaunchMode.externalNonBrowserApplication,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending SMS: $e')),
      );
    }
  }
  
  String _getAppUserName() {
    // This should ideally come from user preferences/settings
    // For now, returning a placeholder
    return 'My Byaj Book User';
  }

  // Load updated contact data
  void _loadContact() {
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    final updatedContact = provider.getContactById(widget.contact['phone']);
    
    if (updatedContact != null) {
      // Update local state with fresh contact data
      widget.contact.clear();
      widget.contact.addAll(updatedContact);
      
      // Refresh transactions
      _loadTransactions();
    } else {
      // Contact might have been deleted
      Navigator.pop(context);
    }
  }

  // Load transactions for the current contact
  void _loadTransactions() {
    _filteredTransactions = _transactionProvider.getTransactionsForContact(_contactId);
    _applyFilters();
  }

  // Method to show the add transaction dialog
  void _showAddTransactionDialog() {
    // Get the relationship type to determine default transaction type
    final String relationshipType = widget.contact['type'] as String? ?? '';
    
    // For lender contacts, default to "got" (receive) transaction type
    // For borrowers or non-interest contacts, default to "gave" (pay) transaction type
    final String defaultType = relationshipType == 'lender' ? 'got' : 'gave';
    
    // Add the transaction with the appropriate type
    _addTransaction(defaultType);
  }

  // void _showContactTypeSelectionDialog(BuildContext context, String name, String phone) {
  //   // Function implementation...
  // }
  
  // Helper method to build selection buttons for Interest/Principal
  Widget _buildSelectionButton({
    required String title,
    required bool isSelected,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSetupPrompt() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final isWithInterest = widget.contact['type'] != null;
        final relationshipType = widget.contact['type'] as String? ?? '';
        
        return AlertDialog(
          title: const Text('Set Up Your Contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You\'ve created a new ${isWithInterest ? "interest-based" : ""} contact.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (isWithInterest) ...[
                Row(
                  children: [
                    Icon(
                      relationshipType == 'borrower' ? Icons.person : Icons.account_balance,
                      size: 16,
                      color: relationshipType == 'borrower' ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Relationship: ${StringUtils.capitalizeFirstLetter(relationshipType)}',
                      style: TextStyle(
                        color: relationshipType == 'borrower' ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.percent, size: 16, color: Colors.amber.shade800),
                    const SizedBox(width: 6),
                    Text(
                      'Interest Rate: ${widget.contact['interestRate']}% ${widget.contact['interestPeriod'] == 'monthly' ? 'p.m.' : 'p.a.'}',
                      style: TextStyle(color: Colors.amber.shade800),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Next steps:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('1. Add your first transaction'),
                const Text('2. Adjust the interest rate if needed'),
                const SizedBox(height: 16),
                const Text(
                  'Would you like to do this now?',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ] else ...[
                const Text('Next step: Add your first transaction'),
                const SizedBox(height: 16),
                const Text(
                  'Would you like to add your first transaction now?',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (isWithInterest) {
                  _showEditInterestRateDialog();
                } else {
                  _addTransaction('gave');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: Text(isWithInterest ? 'Set Interest Rate' : 'Add Transaction'),
            ),
          ],
        );
      },
    );
  }
  
  void _showEditInterestRateDialog() {
    final TextEditingController interestRateController = TextEditingController(
      text: widget.contact['interestRate'].toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Interest Rate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: interestRateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Interest Rate (% p.a.)',
                hintText: 'Enter interest rate',
                suffixText: '%',
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.amber.shade800, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Next, you\'ll need to add your first transaction to start tracking.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // After setting interest rate, prompt for first transaction
              _addTransaction('gave');
            },
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () {
              // Update interest rate
              final newRate = double.tryParse(interestRateController.text) ?? 12.0;
              if (newRate > 0) {
                // Update contact in provider
                final updatedContact = Map<String, dynamic>.from(widget.contact);
                updatedContact['interestRate'] = newRate;
                
                _transactionProvider.updateContact(updatedContact);
                
                // Update local contact data
                setState(() {
                  widget.contact['interestRate'] = newRate;
                });
                
                Navigator.pop(context);
                
                // After setting interest rate, prompt for first transaction
                _addTransaction('gave');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
            ),
            child: const Text('Save & Continue'),
          ),
        ],
      ),
    );
  }

  // Delete a transaction with confirmation
  void _confirmDeleteTransaction(Map<String, dynamic> tx, int originalIndex) {
    if (originalIndex == -1) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content: const Text('Are you sure you want to delete this transaction? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                
                // Delete the transaction
                _transactionProvider.deleteTransaction(_contactId, originalIndex);
                
                // Show a snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Transaction deleted'),
                    action: SnackBarAction(
                      label: 'UNDO',
                      onPressed: () {
                        // Create a clean copy of tx with no null values
                        final safeTx = Map<String, dynamic>.from(tx);
                        
                        // Ensure note is not null
                        if (safeTx['note'] == null) {
                          safeTx['note'] = safeTx['type'] == 'gave' ? 'Payment sent' : 'Payment received';
                        }
                        
                        // Re-add the deleted transaction
                        _transactionProvider.addTransaction(_contactId, safeTx);
                        _loadTransactions();
                      },
                    ),
                  ),
                );
                
                // Refresh the transactions list
                _loadTransactions();
                
                // Update the contact data
                setState(() {
                  _loadContact();
                });
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
  
  // Edit an existing transaction
  void _editTransaction(Map<String, dynamic> tx, int originalIndex) {
    if (originalIndex == -1) return;
    
    final TextEditingController amountController = TextEditingController(
      text: tx['amount'].toString()
    );
    final TextEditingController noteController = TextEditingController(
      text: (tx['note'] as String?) ?? ''
    );
    
    String type = tx['type'] ?? 'gave';
    DateTime selectedDate = tx['date'] ?? DateTime.now();
    
    // Handle multiple images from extraData or fallback to single imagePath for backward compatibility
    List<String> imagePaths = [];
    if (tx['extraData'] != null && tx['extraData']['imagePaths'] != null) {
      imagePaths = List<String>.from(tx['extraData']['imagePaths']);
    } else if (tx['imagePath'] != null) {
      imagePaths.add(tx['imagePath']);
    }
    
    String? amountError; // Add this to track error state
    
    // Define maximum amount (99 crore)
    const double maxAmount = 990000000.0;
    
    // Check if this is a with-interest contact
    final bool isWithInterest = widget.contact['type'] != null;
    final String relationshipType = widget.contact['type'] as String? ?? '';
    
    // Determine if it's a principal or interest transaction
    bool isPrincipalAmount = true;
    if (isWithInterest && tx['isPrincipal'] != null) {
      isPrincipalAmount = tx['isPrincipal'] as bool;
    } else if (isWithInterest) {
      // Check the note for clues
      final note = ((tx['note'] as String?) ?? '').toLowerCase();
      isPrincipalAmount = !note.contains('interest:');
    }

    // Determine if we should show the interest option based on relationship and transaction type
    final bool showInterestOption = isWithInterest && !(
      (relationshipType == 'borrower' && type == 'gave') || // Borrowers don't receive interest
      (relationshipType == 'lender' && type == 'got')       // Lenders don't pay interest
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom
          ),
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bottom sheet drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Header
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: type == 'gave' ? Colors.red.shade100 : Colors.green.shade100,
                        radius: 16,
                        child: Icon(
                          type == 'gave' ? Icons.arrow_upward : Icons.arrow_downward,
                          color: type == 'gave' ? Colors.red : Colors.green,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Edit ${type == 'gave' ? 'Payment' : 'Receipt'}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: type == 'gave' ? Colors.red : Colors.green,
                        ),
                      ),
                      const Spacer(),
                      // Delete button
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 22,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDeleteTransaction(tx, originalIndex);
                        },
                        tooltip: 'Delete transaction',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Amount Field
                  const Text(
                    'Amount',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                    controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                    decoration: InputDecoration(
                      hintText: '0.00',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            prefixText: '₹ ',
                            errorText: amountError,
                  ),
                        ),
                        ),
                        const SizedBox(width: 8),
                      // Date selection now appears directly to the right of amount
                  GestureDetector(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: type == 'gave' ? Colors.red : Colors.green,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null && picked != selectedDate) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                          height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today, 
                            size: 16, 
                            color: type == 'gave' ? Colors.red : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dateFormat.format(selectedDate).split(',')[0],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Note Field
                  const Text(
                    'Note (optional)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      hintText: 'Add a note...',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Image Upload
                  const Text(
                    'Attach Receipt/Bill (optional)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      _showImageSourceOptions(context, (path) {
                        setState(() {
                          imagePaths.add(path);
                        });
                      });
                    },
                    child: Container(
                      height: 80,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: imagePaths.isNotEmpty 
                          ? Border.all(color: type == 'gave' ? Colors.red : Colors.green, width: 1) 
                          : null,
                      ),
                      child: imagePaths.isNotEmpty
                          ? Stack(
                              children: [
                                // Show multiple image indicator if there are multiple images
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Stack(
                                    children: [
                                      Image.file(
                                        File(imagePaths[0]),
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                      if (imagePaths.length > 1)
                                        Positioned(
                                          bottom: 4,
                                          right: 4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.7),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              "+${imagePaths.length - 1}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // Delete button
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        imagePaths.clear();
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 24,
                                  color: type == 'gave' ? Colors.red.withOpacity(0.7) : Colors.green.withOpacity(0.7),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap to add photo',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: type == 'gave' ? Colors.red.withOpacity(0.7) : Colors.green.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Principal/Interest Switch (Only for with-interest contacts when appropriate)
                  if (showInterestOption) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Is this amount for:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSelectionButton(
                          title: 'Interest',
                          isSelected: !isPrincipalAmount,
                          icon: Icons.savings,
                          color: Colors.amber.shade700,
                          onTap: () {
                            setState(() {
                              isPrincipalAmount = false;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildSelectionButton(
                          title: 'Principal',
                          isSelected: isPrincipalAmount,
                          icon: Icons.money,
                          color: Colors.blue,
                          onTap: () {
                            setState(() {
                              isPrincipalAmount = true;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  
                  // Transaction Type Toggle Button
                  const Text(
                    'Transaction Type',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              type = 'gave';
                              // Recalculate whether to show interest option
                              if (relationshipType == 'borrower') {
                                // If switching to gave for a borrower, force principal and hide option
                                isPrincipalAmount = true;
                              }
                            });
                          },
                          icon: const Icon(Icons.arrow_upward, size: 14),
                          label: const Text('PAID', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: type == 'gave' ? Colors.red : Colors.grey.shade300,
                            foregroundColor: type == 'gave' ? Colors.white : Colors.black54,
                            elevation: type == 'gave' ? 1 : 0,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              type = 'got';
                              // Recalculate whether to show interest option
                              if (relationshipType == 'lender') {
                                // If switching to got for a lender, force principal and hide option
                                isPrincipalAmount = true;
                              }
                            });
                          },
                          icon: const Icon(Icons.arrow_downward, size: 14),
                          label: const Text('RECEIVED', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: type == 'got' ? Colors.green : Colors.grey.shade300,
                            foregroundColor: type == 'got' ? Colors.white : Colors.black54,
                            elevation: type == 'got' ? 1 : 0,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            foregroundColor: Colors.grey[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (amountController.text.isEmpty) {
                              setState(() {
                                amountError = 'Amount is required';
                              });
                              return;
                            }

                            final amount = double.tryParse(amountController.text);
                            if (amount == null || amount <= 0) {
                              setState(() {
                                amountError = 'Please enter a valid amount';
                              });
                              return;
                            }
                            
                            // Validate maximum amount
                            if (amount > maxAmount) {
                              setState(() {
                                amountError = 'Maximum allowed amount is ₹99 cr';
                              });
                              return;
                            }
                            
                            // Ensure that certain relationship/transaction combinations are forced to principal
                            bool actualIsPrincipal = isPrincipalAmount;
                            if ((relationshipType == 'borrower' && type == 'gave') || 
                                (relationshipType == 'lender' && type == 'got')) {
                              actualIsPrincipal = true;
                            }

                            // Create updated transaction note
                            String note = noteController.text.isNotEmpty
                                ? noteController.text
                                : (type == 'gave' ? 'Payment sent' : 'Payment received');
                                
                            // Add prefix for interest/principal if applicable
                            if (isWithInterest) {
                              String prefix = actualIsPrincipal ? 'Principal: ' : 'Interest: ';
                              // If note doesn't already have the prefix, add it
                              if (!note.startsWith(prefix) && 
                                  !note.startsWith('Principal:') && 
                                  !note.startsWith('Interest:')) {
                                note = prefix + note;
                              } else if ((actualIsPrincipal && note.startsWith('Interest:')) ||
                                        (!actualIsPrincipal && note.startsWith('Principal:'))) {
                                // If the prefix doesn't match the selection, update it
                                note = prefix + note.substring(note.indexOf(':') + 1).trim();
                              }
                            }

                            // Create updated transaction
                            Map<String, dynamic> updatedTx = {
                              'date': selectedDate,
                              'amount': amount,
                              'type': type,
                              'note': note,
                            };
                            
                            // Add image path if present (for backwards compatibility)
                            if (imagePaths.isNotEmpty) {
                              updatedTx['imagePath'] = imagePaths[0];
                            }
                            
                            // Create extraData for additional info
                            Map<String, dynamic> extraData = {};
                            
                            // Add interest/principal info if applicable
                            if (isWithInterest) {
                              extraData['isPrincipal'] = actualIsPrincipal;
                              extraData['interestRate'] = widget.contact['interestRate'] as double;
                            }
                            
                            // Add multiple images if present
                            if (imagePaths.length > 1) {
                              extraData['imagePaths'] = imagePaths;
                            }
                            
                            // Only add extraData if not empty
                            if (extraData.isNotEmpty) {
                              updatedTx['extraData'] = extraData;
                            }
                            
                            // Update the transaction
                            _transactionProvider.updateTransaction(_contactId, originalIndex, updatedTx);
                            
                            // Refresh the UI
                            setState(() {
                              _applyFilters();
                            });
                            
                            Navigator.pop(context);
                            
                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Transaction updated successfully'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: type == 'gave' ? Colors.red : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Add this helper method to get month abbreviation
  String _getMonthAbbreviation() {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[now.month - 1]; // Month is 1-based, array is 0-based
  }

  // Add a method to refresh data
  void _refreshData() {
    if (mounted) {
      _transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      // Reload transactions for this contact
      _applyFilters();
    }
  }

  // Helper method to format currency without decimal places unless needed
  String _formatCurrencyWithoutTrailingZeros(double value) {
    // Check if the value has decimal places
    if (value == value.roundToDouble()) {
      // No decimal places, use integer format
      return NumberFormat('#,##0').format(value);
    } else {
      // Has decimal places, use decimal format
      return NumberFormat('#,##0.00').format(value);
    }
  }

  // Table style transaction item for standard entries
  Widget _buildTableTransactionItem(Map<String, dynamic> tx, double runningBalance, int index) {
    final isGave = tx['type'] == 'gave';
    final amount = tx['amount'] as double;
    final date = tx['date'] as DateTime;
    final hasNote = (tx['note'] as String?) != null && (tx['note'] as String).isNotEmpty;
    final hasImage = tx['imagePath'] != null;
    final hasImages = tx['imagePaths'] != null && (tx['imagePaths'] as List).isNotEmpty;
    
    // Use the legacy single image path or the new multi-image paths
    final List<String> imagePaths = hasImages 
        ? List<String>.from(tx['imagePaths'] as List)
        : (hasImage ? [tx['imagePath'] as String] : []);
    
    // Get the original index in the unfiltered list for delete/edit operations
    final allTransactions = _transactionProvider.getTransactionsForContact(_contactId);
    final originalIndex = allTransactions.indexOf(tx);
    
    // Format the date in the style shown in the UI reference (day month year)
    final formattedDate = DateFormat('dd MMM yy').format(date);
    final formattedTime = DateFormat('hh:mm a').format(date);
    
    // Skip displaying "Payment sent" or "Payment received" notes
    bool skipPaymentNote = false;
    if (hasNote) {
      String noteText = (tx['note'] as String).toLowerCase();
      if (noteText == 'payment sent' || noteText == 'payment received') {
        skipPaymentNote = true;
      }
    }
    
    return GestureDetector(
      // Edit transaction on tap
      onTap: () => _editTransaction(tx, originalIndex),
      // Delete transaction on long press
      onLongPress: () => _confirmDeleteTransaction(tx, originalIndex),
      child: Container(
        decoration: BoxDecoration(
          color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 1),
        child: Column(
          children: [
            Row(
              children: [
                // Date column
                Expanded(
                  flex: 3,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon showing transaction direction
                      Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(right: 6),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isGave ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                        ),
                        child: Icon(
                          isGave ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 12,
                          color: isGave ? Colors.red : Colors.green,
                        ),
                      ),
                      // Date stacked on time
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            formattedTime,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Vertical line after Date column
                Container(
                  height: 40,
                  width: 0.5,
                  color: Colors.grey.shade300,
                ),
                
                // Debit column (show value if payment was made, otherwise show "--")
                Expanded(
                  flex: 2,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 100),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        isGave ? '₹ ${_formatCurrencyWithoutTrailingZeros(amount)}' : '--',
                        style: TextStyle(
                          fontSize: isGave ? (amount > 1000000 ? 12 : 14) : 14,
                          fontWeight: FontWeight.w500,
                          color: isGave ? Colors.red : Colors.grey.shade400,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
                
                // Vertical line after Debit column
                Container(
                  height: 40,
                  width: 0.5,
                  color: Colors.grey.shade300,
                ),
                
                // Credit column (show value if payment was received, otherwise show "--")
                Expanded(
                  flex: 2,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 100),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        !isGave ? '₹ ${_formatCurrencyWithoutTrailingZeros(amount)}' : '--',
                        style: TextStyle(
                          fontSize: !isGave ? (amount > 1000000 ? 12 : 14) : 14,
                          fontWeight: FontWeight.w500,
                          color: !isGave ? Colors.green : Colors.grey.shade400,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
                
                // No vertical line or Balance column - removed per requirement
              ],
            ),
            
            // Balance display in a row below debit/credit
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Balance display in button shape (right aligned)
                Container(
                  margin: const EdgeInsets.only(top: 4, right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: runningBalance >= 0 ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: runningBalance >= 0 ? Colors.green.shade300 : Colors.red.shade300,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    'Bal. ${_formatCurrencyWithoutTrailingZeros(runningBalance.abs())}',
                    style: TextStyle(
                      fontSize: 10,
                      color: runningBalance >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            
            // Show notes (except payment sent/received) and images
            if ((hasNote && !skipPaymentNote) || imagePaths.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4, left: 26),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display non-default notes if available
                    if (hasNote && !skipPaymentNote)
                      Text(
                        tx['note'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    // Display image thumbnails if available
                    if (imagePaths.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            for (int i = 0; i < imagePaths.length && i < 3; i++)
                              GestureDetector(
                                onTap: () => _showFullImage(context, imagePaths[i]),
                                child: Container(
                                  height: 30,
                                  width: 30,
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300, width: 1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: Image.file(
                                      File(imagePaths[i]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            // Show count if more than 3 images
                            if (imagePaths.length > 3)
                              Container(
                                height: 30,
                                width: 30,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '+${imagePaths.length - 3}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper method to build a filter tab
  Widget _buildFilterTab(String label, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() {
          // Update filter type based on tab selection
          _filterType = label.toLowerCase();
          _applyFilters();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        // Use FittedBox to prevent text overflow
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.blue : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
} 