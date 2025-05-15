import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:my_byaj_book/providers/notification_provider.dart';
import 'package:my_byaj_book/providers/transaction_provider.dart';
import 'package:my_byaj_book/utils/string_utils.dart';
import 'package:my_byaj_book/utils/image_picker_helper.dart';
import 'package:my_byaj_book/screens/contact/edit_contact_screen.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class ContactDetailScreen extends StatefulWidget {
  final Map<String, dynamic> contact;
  final bool showTransactionDialogOnLoad;

  const ContactDetailScreen({
    Key? key, 
    required this.contact,
    this.showTransactionDialogOnLoad = false,
  }) : super(key: key);

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  List<Map<String, dynamic>> _transactions = [];
  late TransactionProvider _transactionProvider;
  String _contactId = '';
  double _totalAmount = 0.0;
  bool _isGet = true;
  bool _showInterestMode = false;
  int tenureMonths = 3;
  DateTime dueDate = DateTime.now().add(const Duration(days: 90));

  @override
  void initState() {
    super.initState();
    _contactId = widget.contact['phone'] ?? '';
    
    // Add this to show transaction dialog when screen loads if requested
    if (widget.showTransactionDialogOnLoad) {
      // Use a small delay to ensure the screen is fully built before showing dialog
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _showTransactionDialog(true); // Default to "Received" dialog
        }
      });
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _transactionProvider = Provider.of<TransactionProvider>(context);
    _loadTransactions();
    
    // Add a delayed reload to ensure we have the latest data
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _loadTransactions();
      }
    });
  }

  void _loadTransactions() {
    final phone = widget.contact['phone'] as String? ?? '';
    
    if (phone.isNotEmpty) {
      setState(() {
        _transactions = _transactionProvider.getTransactionsForContact(phone);
        // Use calculateBalance method to get the correct total amount
        final calculatedBalance = _transactionProvider.calculateBalance(phone);
        _totalAmount = calculatedBalance.abs();
        // Determine if you'll get or give based on the balance sign
        _isGet = calculatedBalance >= 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.contact['name'] as String? ?? 'Unknown';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: Row(
        children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                initials,
                style: const TextStyle(color: Colors.deepPurple),
              ),
            ),
            const SizedBox(width: 12),
            Text(name),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editContact(),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDeleteContact(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary card
          _buildSummaryCard(),
          
          // Toggle for Normal/Interest mode
                Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
      setState(() {
                          _showInterestMode = false;
                        });
                      },
                      borderRadius: BorderRadius.circular(30),
            child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                          color: !_showInterestMode ? Colors.grey.shade400 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          'Normal',
                          textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                            color: !_showInterestMode ? Colors.black : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _showInterestMode = true;
                        });
                      },
                      borderRadius: BorderRadius.circular(30),
                    child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                          color: _showInterestMode ? Colors.blue : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          'Interest',
                          textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                            color: _showInterestMode ? Colors.white : Colors.grey.shade700,
                          ),
                        ),
                      ),
                                    ),
                                  ),
                                ),
                              ],
              ),
            ),

          // Transactions list
          Expanded(
            child: _transactions.isEmpty
                ? _buildEmptyTransactionState()
                : _buildTransactionList(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
              child: MaterialButton(
                onPressed: () => _showTransactionDialog(false),
                color: Colors.red,
                textColor: Colors.white,
                            shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
          children: [
                    const Icon(Icons.arrow_upward, size: 20),
                    const SizedBox(width: 8),
            const Text(
                      'PAID',
              style: TextStyle(
                        fontSize: 16,
                fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
            const SizedBox(width: 16),
            Expanded(
              child: MaterialButton(
                onPressed: () => _showTransactionDialog(true),
                color: Colors.green,
                textColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
          children: [
                    const Icon(Icons.arrow_downward, size: 20),
                    const SizedBox(width: 8),
                        const Text(
                      'RECEIVED',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                                    ),
                  ),
                ],
              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    // Recalculate balance right before showing it to ensure accuracy
    final phone = widget.contact['phone'] as String? ?? '';
    if (phone.isNotEmpty) {
      final calculatedBalance = _transactionProvider.calculateBalance(phone);
      _totalAmount = calculatedBalance.abs(); // Keep abs() only for display amount
      _isGet = calculatedBalance >= 0; // Positive balance means you will receive
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isGet ? Colors.green : Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
              const Icon(Icons.payments_outlined, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                  Text(
                _isGet ? 'You Will RECEIVE' : 'You Will PAY',
                          style: const TextStyle(
                  fontSize: 14,
                      fontWeight: FontWeight.w500,
                            color: Colors.white,
                ),
              ),
              const Spacer(),
              const Icon(Icons.info_outline, color: Colors.white, size: 18),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            currencyFormat.format(_totalAmount),
                        style: const TextStyle(
                          fontSize: 32,
                        fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
          ),
          const SizedBox(height: 4),
            Text(
                      'Last updated: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
              _buildActionButton(
                  Icons.call,
                  'Call',
                  Colors.blue,
                () => _makeCall(),
                  ),
              _buildActionButton(
                  Icons.picture_as_pdf,
                  'PDF Report',
                  Colors.red,
                () => _generatePdfReport(),
                  ),
              _buildActionButton(
                  Icons.notifications,
                  'Reminder',
                  Colors.orange,
                () => _setReminder(),
                  ),
              _buildActionButton(
                  Icons.sms,
                  'SMS',
                  Colors.green,
                () => _sendSms(),
                ),
              ],
                  ),
                ],
              ),
      );
    }
  
  Widget _buildActionButton(IconData icon, String label, Color color, Function() onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
                    children: [
          Container(
            padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
                  ),
                ),
              const SizedBox(height: 6),
                  Text(
            label,
            style: const TextStyle(
                      fontSize: 12,
              color: Colors.white,
                    ),
                  ),
                ],
      ),
    );
  }

  Widget _buildEmptyTransactionState() {
    return Center(
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
              Text(
            'No transactions yet',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
          ),
            const SizedBox(height: 8),
              Text(
            'Use the buttons below to add a transaction',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    // Calculate running balance for each transaction
    double runningBalance = 0.0;
    
    // First, create a chronologically sorted copy (oldest first) for balance calculation
    final chronologicalTransactions = List<Map<String, dynamic>>.from(_transactions);
    chronologicalTransactions.sort((a, b) {
      final dateA = a['date'] as DateTime? ?? DateTime.now();
      final dateB = b['date'] as DateTime? ?? DateTime.now();
      return dateA.compareTo(dateB); // Ascending order (oldest first)
    });
    
    // Calculate running balances based on chronological order
    final Map<String, double> transactionBalances = {};
    
    for (final tx in chronologicalTransactions) {
      final amount = tx['amount'] as double? ?? 0.0;
      final isGet = tx['isGet'] as bool? ?? true;
      final id = tx['id'] as String? ?? '';
      
      // Update running balance based on transaction type
      if (isGet) {
        runningBalance += amount; // Credit increases balance
          } else {
        runningBalance -= amount; // Debit decreases balance
      }
      
      // Store the balance for this transaction ID
      transactionBalances[id] = runningBalance;
    }
    
    // Now create our display list with correct balances
    final transactionsWithBalance = _transactions.map((tx) {
      final id = tx['id'] as String? ?? '';
      final txWithBalance = Map<String, dynamic>.from(tx);
      
      // Get the pre-calculated balance for this transaction
      txWithBalance['runningBalance'] = transactionBalances[id] ?? 0.0;
      return txWithBalance;
    }).toList();

    return Column(
                children: [
        // Ledger header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
            color: Colors.grey.shade200,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade400, width: 1),
                      ),
                    ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
              // Date column (with space for icon)
              SizedBox(width: 90, 
                child: Text(
                  'Date',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              
              // Vertical dotted line
              _buildDottedLine(),
              
              // Debit column
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Debit',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ),
              
              // Vertical dotted line
              _buildDottedLine(),
              
              // Credit column
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Credit',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ),
              
              // Vertical dotted line
              _buildDottedLine(),
              
              // Balance column
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Balance',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.blue.shade700,
                    ),
                  ),
                                  ),
                                ),
                              ],
          ),
        ),
        
        // Transaction list
                      Expanded(
          child: ListView.builder(
            itemCount: transactionsWithBalance.length,
            padding: const EdgeInsets.only(bottom: 80), // Space for FABs
            itemBuilder: (context, index) {
              final transaction = transactionsWithBalance[index];
              final amount = transaction['amount'] as double? ?? 0.0;
              final isGet = transaction['isGet'] as bool? ?? true;
              final date = transaction['date'] as DateTime? ?? DateTime.now();
              final note = transaction['note'] as String? ?? '';
              final hasInterest = transaction['hasInterest'] as bool? ?? false;
              
              // Update to handle multiple images
              List<String> imagePaths = [];
              if (transaction['imagePaths'] != null) {
                // New format - list of images
                imagePaths = List<String>.from(transaction['imagePaths'] as List? ?? []);
              } else if (transaction['imagePath'] != null) {
                // Legacy format - single image path
                final singleImagePath = transaction['imagePath'] as String?;
                if (singleImagePath != null && singleImagePath.isNotEmpty) {
                  imagePaths = [singleImagePath];
                }
              }
              
              final runningBalance = transaction['runningBalance'] as double;
              
              // Format amounts with the Indian Rupee symbol
              final formattedAmount = '₹ ${amount.toStringAsFixed(2)}';
              final formattedBalance = runningBalance >= 0 
                  ? '₹ ${runningBalance.toStringAsFixed(2)}' 
                  : '₹ -${runningBalance.abs().toStringAsFixed(2)}';
              
              // Alternating row background for better readability
              final rowColor = index % 2 == 0 ? Colors.white : Colors.grey.shade50;
              
              return Column(
          children: [
                  // Main transaction row with ledger columns
                  Container(
                    color: rowColor,
                    padding: EdgeInsets.fromLTRB(12, 8, 12, note.isNotEmpty || imagePaths.isNotEmpty ? 0 : 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                        // Date column with 45-degree arrow icon
                        SizedBox(
                          width: 90,
                          child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                              // 45-degree arrow icon
                    Container(
                                width: 24,
                                height: 24,
                                margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                                  color: isGet 
                                      ? const Color(0xFFE8F5E9) 
                                      : const Color(0xFFFFEBEE),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Transform.rotate(
                                    angle: isGet ? -0.785 : 0.785, // 45 degrees in radians (π/4)
                      child: Icon(
                                      isGet ? Icons.arrow_downward : Icons.arrow_upward,
                                      color: isGet 
                                          ? const Color(0xFF4CAF50) 
                                          : const Color(0xFFE57373),
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              
                              // Date and details in a column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                                    // Date in format: 15 Jan 25 09:25 AM
                            Text(
                                      DateFormat('dd MMM yy').format(date),
                              style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                    // Time in 12-hour format with AM/PM
                                  Text(
                                      DateFormat('hh:mm a').format(date),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    
                                    // Note if available - directly under the date
                                    if (note.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          note,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade700,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    
                                    // Interest badge if applicable
                                    if (hasInterest)
            Container(
                                        margin: const EdgeInsets.only(top: 2),
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                                          color: const Color(0xFFE3F2FD),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Interest',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
                        
                        // Vertical dotted line
                        _buildDottedLine(),
                        
                        // Debit column (show amount if it's a payment/debit)
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: !isGet 
                                ? Text(
                                    formattedAmount,
          style: TextStyle(
                                      fontSize: 13,
            fontWeight: FontWeight.w500,
                                      color: Colors.red.shade700,
                                    ),
                                  )
                                : const Text(''),
                          ),
                        ),
                        
                        // Vertical dotted line
                        _buildDottedLine(),
                        
                        // Credit column (show amount if it's a receipt/credit)
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: isGet 
                                ? Text(
              formattedAmount,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green.shade700,
                                    ),
                                  )
                                : const Text(''),
                          ),
                        ),
                        
                        // Vertical dotted line
                        _buildDottedLine(),
                        
                        // Balance column
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.centerRight,
      child: Text(
                              formattedBalance,
        style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: runningBalance >= 0 
                                    ? Colors.blue.shade700 
                                    : Colors.orange.shade800,
                              ),
                            ),
                          ),
                  ),
                      ],
                ),
                  ),
                  
                  // Update image preview to handle multiple images
                  if (imagePaths.isNotEmpty)
                    Container(
                      color: rowColor,
                      padding: const EdgeInsets.only(left: 44, right: 16, bottom: 8),
                      child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                          Row(
                  children: [
            Text(
                                'Receipts (${imagePaths.length})',
              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 40,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: imagePaths.length,
                              itemBuilder: (context, imgIndex) {
                                return GestureDetector(
                                  onTap: () {
                                    // Show full-screen image view
                                    showDialog(
                                      context: context,
                                      builder: (context) => Dialog(
                                        insetPadding: EdgeInsets.zero,
                                        child: Stack(
              children: [
                                            // Image
                                            InteractiveViewer(
                                              boundaryMargin: const EdgeInsets.all(20),
                                              minScale: 0.5,
                                              maxScale: 3.0,
                                              child: Image.file(
                                                File(imagePaths[imgIndex]),
                                                fit: BoxFit.contain,
                                                height: double.infinity,
                                                width: double.infinity,
                                              ),
                                            ),
                                            // Close button
                                            Positioned(
                                              top: 10,
                                              right: 10,
                                              child: CircleAvatar(
                                                backgroundColor: Colors.black54,
                                                radius: 20,
                                                child: IconButton(
                                                  icon: const Icon(Icons.close, color: Colors.white),
                                                  onPressed: () => Navigator.pop(context),
                                                ),
                                              ),
                                            ),
                                            // Download button
                                            Positioned(
                                              bottom: 10,
                                              right: 10,
                                              child: CircleAvatar(
                                                backgroundColor: Colors.black54,
                                                radius: 20,
                                                child: IconButton(
                                                  icon: const Icon(Icons.download, color: Colors.white),
                                                  onPressed: () {
                                                    _downloadImage(imagePaths[imgIndex]);
                                                    Navigator.pop(context);
                                                  },
                                                ),
                                              ),
                ),
              ],
            ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    height: 40,
                                    width: 40,
                                    margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      image: DecorationImage(
                                        image: FileImage(File(imagePaths[imgIndex])),
                                        fit: BoxFit.cover,
                                      ),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
                    ),
                  
                  // Divider between transaction rows
                  Divider(height: 1, color: Colors.grey.shade300),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
  
  String _formatTimeAgo(DateTime date) {
    return timeago.format(date);
  }
  
  void _confirmDeleteTransaction(Map<String, dynamic> transaction, int index) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                
                // Delete the transaction
              final txId = transaction['id'] as String? ?? '';
              if (txId.isNotEmpty) {
                _transactionProvider.deleteTransaction(_contactId, txId);
              }
                
                // Refresh the transactions list
      _loadTransactions();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showTransactionDialog(bool isGet) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    bool hasInterest = _showInterestMode;
    double interestRate = 0.0;
    String interestPeriod = 'Month'; // 'Month' or 'Year'
    DateTime selectedDate = DateTime.now();
    String? imagePath;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                  // Header with Paid/Received toggle
                Row(
                  children: [
                      CircleAvatar(
                        backgroundColor: isGet ? Colors.green.shade100 : Colors.red.shade100,
                        radius: 16,
                        child: Icon(
                          isGet ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isGet ? Colors.green : Colors.red,
                      size: 16,
                    ),
                      ),
                      const SizedBox(width: 8),
                    Text(
                        isGet ? 'Received' : 'Paid',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isGet ? Colors.green : Colors.red,
                        ),
                      ),
                      const Spacer(),
                      // Normal/Interest toggle
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
                            GestureDetector(
                              onTap: () {
                setState(() {
                                  hasInterest = false;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: !hasInterest ? Colors.blue : Colors.transparent,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  'Normal',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: !hasInterest ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                setState(() {
                                  hasInterest = true;
                });
              },
            child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                                  color: hasInterest ? Colors.blue : Colors.transparent,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  'Interest',
                        style: TextStyle(
                                    fontSize: 12,
                                    color: hasInterest ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Amount field
                  const Text(
                    'Amount',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                    controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                            prefixText: '₹ ',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                        ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                    onTap: () async {
                            final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                        setState(() {
                                selectedDate = date;
                        });
                      }
                    },
                    child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    DateFormat('dd MMM yyyy').format(selectedDate),
                                    style: TextStyle(color: Colors.grey.shade700),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                      ),
                    ),
                  ),
                    ],
                  ),
                  
                  // Interest settings
                  if (hasInterest) ...[
                    const SizedBox(height: 24),
                  
                  const Text(
                      'Interest Settings',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        // Interest rate field
                        Expanded(
                          flex: 3,
                          child: TextField(
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                              hintText: '0.0',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                              ),
                              suffixText: '%',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                            onChanged: (value) {
                              interestRate = double.tryParse(value) ?? 0.0;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Month/Year toggle
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        interestPeriod = 'Month';
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: interestPeriod == 'Month' ? Colors.blue : Colors.transparent,
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Month',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: interestPeriod == 'Month' ? Colors.white : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        interestPeriod = 'Year';
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: interestPeriod == 'Year' ? Colors.blue : Colors.transparent,
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Year',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: interestPeriod == 'Year' ? Colors.white : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Tenure
                  const Text(
                      'Tenure',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildTenureButton(setState, 3, tenureMonths),
                        const SizedBox(width: 8),
                        _buildTenureButton(setState, 6, tenureMonths),
                        const SizedBox(width: 8),
                        _buildTenureButton(setState, 12, tenureMonths),
                        const SizedBox(width: 8),
                        _buildTenureButton(setState, 24, tenureMonths),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Attach receipt
                  const Text(
                    'Attach Receipt/Bill',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      final imagePickerHelper = ImagePickerHelper();
                      imagePickerHelper.showImageSourceDialog(
                        context,
                        currentImage: imagePath != null ? File(imagePath!) : null,
                      ).then((selectedImage) {
                        if (selectedImage != null) {
                        setState(() {
                            imagePath = selectedImage.path;
                        });
                        }
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: imagePath != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: Image.file(
                                    File(imagePath!),
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        imagePath = null;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.add_photo_alternate, size: 24, color: Colors.grey),
                                  SizedBox(height: 4),
                                Text(
                                  'Tap to add photo',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                    ),
                  ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Note
                    const Text(
                    'Note (optional)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      hintText: 'Add a note...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    maxLines: 3,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (amountController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter an amount')),
                              );
                              return;
                            }
                            
                            final amount = double.tryParse(amountController.text) ?? 0.0;
                            if (amount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Amount must be greater than 0')),
                              );
                              return;
                            }
                            
                            // Add transaction
                            _addTransaction(
                              amount,
                              isGet,
                              noteController.text,
                              hasInterest,
                              interestRate,
                              interestPeriod,
                              tenureMonths,
                              selectedDate,
                              imagePath,
                            );
                            
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isGet ? Colors.green : Colors.red,
                          ),
                          child: const Text('Save'),
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
  
  Widget _buildTenureButton(StateSetter setState, int months, int selectedMonths) {
    final isSelected = months == selectedMonths;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
                              setState(() {
            tenureMonths = months;
            dueDate = DateTime.now().add(Duration(days: 30 * months));
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(30),
            border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
          ),
          alignment: Alignment.center,
          child: Text(
            months < 12 ? '$months Month${months == 1 ? '' : 's'}' : (months == 12 ? '1 Year' : '${months ~/ 12} Years'),
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
  
  void _addTransaction(
    double amount,
    bool isGet,
    String note,
    bool hasInterest,
    double interestRate,
    String interestPeriod,
    int tenureMonths,
    DateTime dueDate,
    String? imagePath,
  ) {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final phone = widget.contact['phone'] as String? ?? '';
    
    if (phone.isEmpty) return;
    
    // Create transaction map
    final Map<String, dynamic> newTransaction = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'amount': amount,
      'isGet': isGet,
      'date': DateTime.now(),
      'note': note,
      'hasInterest': hasInterest,
      'interestRate': hasInterest ? interestRate : 0.0,
      'interestPeriod': interestPeriod,
      'tenureMonths': tenureMonths,
      'dueDate': dueDate,
      'imagePaths': imagePath != null ? [imagePath] : [],
    };
    
    // Add transaction to provider
    transactionProvider.addTransaction(phone, newTransaction);
    
    // Calculate new balance immediately
    final newBalance = transactionProvider.calculateBalance(phone);
    
    // Update the state with new values
    setState(() {
      _totalAmount = newBalance.abs();
      _isGet = newBalance >= 0;
    });
    
    // Schedule transaction loading after the current frame completes
    // This ensures the UI updates first with the new balance
    Future.microtask(() {
      if (mounted) {
        _loadTransactions();
      }
    });
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transaction of ₹${amount.toStringAsFixed(2)} added')),
    );
  }
  
  void _editTransaction(Map<String, dynamic> transaction) {
    // Implement transaction editing functionality
  }
  
  void _makeCall() {
    final phone = widget.contact['phone'] as String? ?? '';
    
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available')),
      );
      return;
    }
    
    launchUrl(Uri.parse('tel:$phone'));
  }
  
  void _generatePdfReport() async {
    try {
      final name = widget.contact['name'] as String? ?? 'Unknown';
      
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating PDF report...')),
      );
      
      // Get app directory
      final directory = await getApplicationDocumentsDirectory();
      final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final String filePath = '${directory.path}/MyByajBook_${name.replaceAll(' ', '_')}_$timestamp.pdf';
      
      // Generate PDF document
      final pdf = pw.Document();
      
      // Add pages to the PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildPdfHeader(name),
          footer: (context) => _buildPdfFooter(context),
          build: (context) => [
            _buildPdfSummary(),
            pw.SizedBox(height: 20),
            _buildPdfTransactionTable(),
          ],
        ),
      );
      
      // Save the PDF file
      final File file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      
      // Show success message and open file
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('PDF report generated successfully'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () async {
                // Open the generated PDF file
                await OpenFile.open(filePath);
              },
            ),
          ),
        );
        
        // Show a dialog with share option
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Report Generated'),
              content: const Text('Your transaction report has been generated successfully.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    // Share the file
                    await Share.shareXFiles(
                      [XFile(filePath)],
                      subject: 'Transaction Report for $name',
                      text: 'My Byaj Book - Transaction Report',
                    );
                  },
                  child: const Text('Share'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    // Open the file
                    await OpenFile.open(filePath);
                  },
                  child: const Text('View'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }
  
  // Build PDF header with app name and contact info
  pw.Widget _buildPdfHeader(String contactName) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 1, color: PdfColors.grey300))
      ),
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'My Byaj Book',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.purple700,
                ),
              ),
              pw.Text(
                'Transaction Report',
                style: pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.grey800,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                contactName,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              pw.Text(
                'Generated on: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Build PDF footer with page numbers
  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(
          fontSize: 10,
          color: PdfColors.grey600,
        ),
      ),
    );
  }
  
  // Build PDF summary section with balance info
  pw.Widget _buildPdfSummary() {
    // Determine card color based on balance direction
    final summaryColor = _isGet ? PdfColors.green700 : PdfColors.red400;
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: summaryColor,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                _isGet ? 'You Will RECEIVE' : 'You Will PAY',
                style: const pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                'Last updated: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Rs. ${_totalAmount.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          // Count total transactions
          pw.SizedBox(height: 8),
          pw.Text(
            'Total transactions: ${_transactions.length}',
            style: const pw.TextStyle(
              fontSize: 12,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  // Build PDF transaction table
  pw.Widget _buildPdfTransactionTable() {
    // Sort transactions by date (newest first)
    final sortedTransactions = List<Map<String, dynamic>>.from(_transactions);
    sortedTransactions.sort((a, b) {
      final dateA = a['date'] as DateTime? ?? DateTime.now();
      final dateB = b['date'] as DateTime? ?? DateTime.now();
      return dateB.compareTo(dateA); // Descending order (newest first)
    });
    
    // Calculate running balance for each transaction
    double runningBalance = 0.0;
    
    // First, create a chronologically sorted copy (oldest first) for balance calculation
    final chronologicalTransactions = List<Map<String, dynamic>>.from(sortedTransactions);
    chronologicalTransactions.sort((a, b) {
      final dateA = a['date'] as DateTime? ?? DateTime.now();
      final dateB = b['date'] as DateTime? ?? DateTime.now();
      return dateA.compareTo(dateB); // Ascending order (oldest first)
    });
    
    // Calculate running balances based on chronological order
    final Map<String, double> transactionBalances = {};
    
    for (final tx in chronologicalTransactions) {
      final amount = tx['amount'] as double? ?? 0.0;
      final isGet = tx['isGet'] as bool? ?? true;
      final id = tx['id'] as String? ?? '';
      
      // Update running balance based on transaction type
      if (isGet) {
        runningBalance += amount;
      } else {
        runningBalance -= amount;
      }
      
      // Store the balance for this transaction ID
      transactionBalances[id] = runningBalance;
    }
    
    // Create table headers
    final tableHeaders = [
      'Date',
      'Type',
      'Amount (Rs.)',
      'Note',
      'Balance (Rs.)',
    ];
    
    // Create table rows
    final tableRows = sortedTransactions.map((transaction) {
      final date = transaction['date'] as DateTime? ?? DateTime.now();
      final amount = transaction['amount'] as double? ?? 0.0;
      final isGet = transaction['isGet'] as bool? ?? true;
      final note = transaction['note'] as String? ?? '';
      final id = transaction['id'] as String? ?? '';
      final balance = transactionBalances[id] ?? 0.0;
      
      return [
        DateFormat('dd MMM yyyy').format(date),
        isGet ? 'Received' : 'Paid',
        amount.toStringAsFixed(2),
        note.isNotEmpty ? note : '-',
        balance.toStringAsFixed(2),
      ];
    }).toList();
    
    // Build the table
    return pw.Table.fromTextArray(
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.purple700),
      headers: tableHeaders,
      data: tableRows,
      border: pw.TableBorder.all(color: PdfColors.grey400),
      headerAlignment: pw.Alignment.center,
      cellAlignment: pw.Alignment.center,
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerLeft,
        4: pw.Alignment.centerRight,
      },
      cellPadding: const pw.EdgeInsets.all(5),
    );
  }
  
  void _setReminder() {
    // Implement reminder setting functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reminder setting not implemented yet')),
    );
  }
  
  void _sendSms() {
    final phone = widget.contact['phone'] as String? ?? '';
    
    if (phone.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available')),
      );
      return;
    }
    
    launchUrl(Uri.parse('sms:$phone'));
  }
  
  void _editContact() async {
    // Navigate to edit contact screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditContactScreen(
          contact: widget.contact,
          transactionProvider: _transactionProvider,
        ),
      ),
    );
    
    if (result == true) {
      _loadTransactions();
    }
  }
  
  void _confirmDeleteContact() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Are you sure you want to delete ${widget.contact['name']}? All transactions will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteContact();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteContact() {
    final phone = widget.contact['phone'] as String? ?? '';
    
    if (phone.isEmpty) return;
    
    // Delete contact from provider
    _transactionProvider.deleteContact(phone);
    
    // Show success message and pop screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.contact['name']} deleted')),
    );
    
    Navigator.pop(context);
  }

  // Add a helper method to download images
  void _downloadImage(String imagePath) {
    try {
      // Create a copy in the downloads folder
      final originalFile = File(imagePath);
      final fileName = imagePath.split('/').last;
      final downloadsDir = '/storage/emulated/0/Download';
      final newPath = '$downloadsDir/$fileName';
      
      // Copy the file
      if (originalFile.existsSync()) {
        originalFile.copySync(newPath);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Receipt saved to Downloads folder')),
        );
      }
    } catch (e) {
      print('Error downloading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save receipt: $e')),
      );
    }
  }

  // Helper method to create a dotted vertical line
  Widget _buildDottedLine() {
    return Container(
      height: 20,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Colors.grey.shade400,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
      ),
    );
  }
} 