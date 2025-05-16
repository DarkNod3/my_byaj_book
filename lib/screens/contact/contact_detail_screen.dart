import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'package:my_byaj_book/providers/notification_provider.dart';
import 'package:my_byaj_book/providers/transaction_provider.dart';
import 'package:my_byaj_book/providers/contact_provider.dart';
import 'package:my_byaj_book/utils/string_utils.dart';
import 'package:my_byaj_book/utils/image_picker_helper.dart';
import 'package:my_byaj_book/screens/contact/edit_contact_screen.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_byaj_book/screens/home/home_screen.dart';
import 'package:my_byaj_book/providers/loan_provider.dart';

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
  String? imagePath;

  @override
  void initState() {
    super.initState();
    _contactId = widget.contact['phone'] ?? '';
    
    // Add this to show transaction dialog when screen loads if requested
    if (widget.showTransactionDialogOnLoad) {
      // Use a small delay to ensure the screen is fully built before showing dialog
      Future.delayed(const Duration(milliseconds: 500), () {
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
      // Get fresh transactions from provider
      final freshTransactions = _transactionProvider.getTransactionsForContact(phone);
      
      // Ensure transactions are sorted by date (newest first)
      freshTransactions.sort((a, b) {
        final dateA = a['date'] as DateTime? ?? DateTime.now();
        final dateB = b['date'] as DateTime? ?? DateTime.now();
        return dateB.compareTo(dateA); // Descending order (newest first)
      });
      
      // Separate normal and interest transactions
      final normalTransactions = freshTransactions.where(
        (tx) => tx['hasInterest'] != true && tx['loanId'] == null
      ).toList();
      
      final interestTransactions = freshTransactions.where(
        (tx) => tx['hasInterest'] == true || tx['loanId'] != null
      ).toList();
      
      // Calculate normal balance
      double normalBalance = 0.0;
      for (final tx in normalTransactions) {
        final amount = tx['amount'] as double? ?? 0.0;
        final isGet = tx['isGet'] as bool? ?? true;
        normalBalance += isGet ? amount : -amount;
      }
      
      // Calculate interest balance
      double interestBalance = 0.0;
      for (final tx in interestTransactions) {
        final amount = tx['amount'] as double? ?? 0.0;
        final isGet = tx['isGet'] as bool? ?? true;
        interestBalance += isGet ? amount : -amount;
      }
      
      // Use the appropriate balance based on the current tab
      final calculatedBalance = _showInterestMode ? interestBalance : normalBalance;
      
      setState(() {
        _transactions = freshTransactions;
        // Store absolute value for amount display
        _totalAmount = calculatedBalance.abs();
        // Determine if it's "get" (receive) or "give" (pay) based on balance sign
        _isGet = calculatedBalance >= 0;
      });
      
      // Debug print to help with troubleshooting
      print("Loaded ${freshTransactions.length} transactions for $phone");
      print("Normal balance: $normalBalance, Interest balance: $interestBalance");
      print("Current tab: ${_showInterestMode ? 'Interest' : 'Normal'}, Final balance: $calculatedBalance (_isGet: $_isGet)");
      
      // Update UI immediately with the latest data
      if (mounted) {
        setState(() {});
      }
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
            Expanded(
              child: Text(
                name.length > 18 ? '${name.substring(0, 18)}...' : name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18),
              ),
            ),
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
      bottomNavigationBar: _buildAnimatedBottomBar(),
    );
  }

  Widget _buildAnimatedBottomBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
          child: Row(
            children: [
              Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutQuart,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - value)),
                  child: Opacity(
                    opacity: value,
              child: MaterialButton(
                onPressed: () => _showTransactionDialog(false),
                color: Colors.red,
                textColor: Colors.white,
                      elevation: 3,
                      height: 54,
                            shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.arrow_upward, size: 20),
                          SizedBox(width: 8),
                          Text(
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
                );
              },
            ),
          ),
          const SizedBox(width: 8),
            Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutQuart,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - value)),
                  child: Opacity(
                    opacity: value,
              child: MaterialButton(
                onPressed: () => _showTransactionDialog(true),
                color: Colors.green,
                textColor: Colors.white,
                      elevation: 3,
                      height: 54,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.arrow_downward, size: 20),
                          SizedBox(width: 8),
                          Text(
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
                );
              },
        ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    // Recalculate balance right before showing it to ensure accuracy
    final phone = widget.contact['phone'] as String? ?? '';
    double normalBalance = 0.0;
    double interestBalance = 0.0;
    double totalInterestAmount = 0.0;
    
    if (phone.isNotEmpty) {
      // Calculate balances separately for normal and interest transactions
      List<Map<String, dynamic>> normalTransactions = _transactions.where(
        (tx) => tx['hasInterest'] != true && tx['loanId'] == null
      ).toList();
      
      List<Map<String, dynamic>> interestTransactions = _transactions.where(
        (tx) => tx['hasInterest'] == true || tx['loanId'] != null
      ).toList();
      
      // Calculate normal transactions balance
      normalBalance = _calculateBalanceFromTransactions(normalTransactions);
      
      // Calculate interest transactions balance
      interestBalance = _calculateBalanceFromTransactions(interestTransactions);
      
      // Calculate total interest amount (sum of all interest transactions)
      totalInterestAmount = interestTransactions.fold(0.0, (sum, tx) {
        final amount = tx['amount'] as double? ?? 0.0;
        return sum + amount;
      });
      
      // Use the appropriate balance based on current tab
      final calculatedBalance = _showInterestMode ? interestBalance : normalBalance;
      _totalAmount = calculatedBalance.abs(); // Keep abs() only for display amount
      _isGet = calculatedBalance >= 0; // Positive balance means you will receive
      
      print("Summary card balance: $calculatedBalance (_isGet: $_isGet)");
      print("Normal balance: $normalBalance, Interest balance: $interestBalance");
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _isGet ? Color(0xFFF0FFF0) : Color(0xFFFFF0F0), // Light green for receive, light red for pay
          borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isGet ? Colors.green.shade600 : Colors.red.shade600, 
          width: 2
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
                children: [
              // Amount on the left now
                  Text(
                currencyFormat.format(_totalAmount),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _isGet ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
              
              // RECEIVE/PAY MONEY text on the right now, smaller size
              Row(
                children: [
                  Icon(
                    _isGet ? Icons.arrow_downward : Icons.arrow_upward,
                    color: _isGet ? Colors.green.shade700 : Colors.red.shade700,
                    size: 16
                  ),
                  const SizedBox(width: 4),
          Text(
                    _isGet ? 'RECEIVE MONEY' : 'PAY MONEY',
                    style: TextStyle(
                      fontSize: 12,
                        fontWeight: FontWeight.bold,
                      color: _isGet ? Colors.green.shade800 : Colors.red.shade800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Display total interest amount in Interest tab
          if (_showInterestMode)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.percent, 
                    color: Colors.blue.shade600,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
            Text(
                    'Total Interest: ${currencyFormat.format(totalInterestAmount)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 12),
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
  
  // Helper method to calculate balance from a list of transactions
  double _calculateBalanceFromTransactions(List<Map<String, dynamic>> transactions) {
    double balance = 0.0;
    for (final tx in transactions) {
      final amount = tx['amount'] as double? ?? 0.0;
      final isGet = tx['isGet'] as bool? ?? true;
      
      if (isGet) {
        balance += amount; // Credit increases balance
      } else {
        balance -= amount; // Debit decreases balance
      }
    }
    return balance;
    }
  
  Widget _buildActionButton(IconData icon, String label, Color color, Function() onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
                    children: [
          Container(
            padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 18,
                  ),
                ),
          const SizedBox(height: 4),
                  Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
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
    // Filter transactions based on the selected mode (normal or interest)
    final filteredTransactions = _showInterestMode 
        ? _transactions.where((tx) => tx['hasInterest'] == true || tx['loanId'] != null).toList()
        : _transactions.where((tx) => tx['hasInterest'] != true && tx['loanId'] == null).toList();
    
    // Sort transactions by date (newest first)
    final sortedTransactions = List<Map<String, dynamic>>.from(filteredTransactions);
    sortedTransactions.sort((a, b) {
      final dateA = a['date'] as DateTime? ?? DateTime.now();
      final dateB = b['date'] as DateTime? ?? DateTime.now();
      return dateB.compareTo(dateA); // Descending order (newest first)
    });
    
    // Pre-calculate running balances (working chronologically from oldest to newest)
    // First, create a chronologically sorted copy (oldest first) for balance calculation
    final chronologicalTransactions = List<Map<String, dynamic>>.from(filteredTransactions);
    chronologicalTransactions.sort((a, b) {
      final dateA = a['date'] as DateTime? ?? DateTime.now();
      final dateB = b['date'] as DateTime? ?? DateTime.now();
      return dateA.compareTo(dateB); // Ascending order (oldest first)
    });
    
    // Calculate running balances based on chronological order
    final Map<String, double> transactionBalances = {};
    double runningBalance = 0.0;
    
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
    
    // Show a message if no transactions are found in interest mode
    if (_showInterestMode && sortedTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.blue.shade200),
            const SizedBox(height: 16),
            const Text(
              'No interest transactions found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a transaction with interest enabled',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Show a message if no normal transactions are found
    if (!_showInterestMode && sortedTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No regular transactions found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a transaction using the buttons below',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

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
            itemCount: sortedTransactions.length,
            padding: const EdgeInsets.only(bottom: 80), // Space for FABs
            itemBuilder: (context, index) {
              final transaction = sortedTransactions[index];
              final amount = transaction['amount'] as double? ?? 0.0;
              final isGet = transaction['isGet'] as bool? ?? true;
              final date = transaction['date'] as DateTime? ?? DateTime.now();
              final note = transaction['note'] as String? ?? '';
              final hasInterest = transaction['hasInterest'] as bool? ?? false;
              final interestRate = transaction['interestRate'] as double? ?? 0.0;
              final interestPeriod = transaction['interestPeriod'] as String? ?? 'Month';
              final loanId = transaction['loanId'] as String?;
              final id = transaction['id'] as String? ?? '';
              
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
              
              // Get the pre-calculated running balance for this transaction
              final runningBalance = transactionBalances[id] ?? 0.0;
              
              // Format amounts with the Indian Rupee symbol
              final formattedAmount = '₹ ${amount.toStringAsFixed(2)}';
              final formattedBalance = runningBalance >= 0 
                  ? '₹ ${runningBalance.toStringAsFixed(2)}' 
                  : '₹ -${runningBalance.abs().toStringAsFixed(2)}';
              
              // Alternating row background for better readability
              final rowColor = index % 2 == 0 ? Colors.white : Colors.grey.shade50;
              
              return GestureDetector(
                onLongPress: () => _showTransactionOptions(transaction, index),
                child: Column(
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
                                      // Date in format: 15 Jan 25
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
                                    
                                    // Add "online" text if available
                                    Text(
                                      'online',
                                          style: TextStyle(
                                            fontSize: 10,
                                        color: Colors.grey.shade600,
                                            fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    
                                    // Interest badge if applicable - shown only in interest tab
                                    if (_showInterestMode && (hasInterest || loanId != null))
            Container(
                                        margin: const EdgeInsets.only(top: 2),
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                                          color: const Color(0xFFE3F2FD),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          loanId != null 
                                            ? 'Loan Interest' 
                                            : 'Interest ${interestRate.toStringAsFixed(1)}% ${interestPeriod == 'Month' ? '/month' : '/year'}',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                  ),
                                      
                                  // Receipt count if available
                                  if (imagePaths.isNotEmpty)
                                    Text(
                                      'Receipts (${imagePaths.length})',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
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
                      child: SizedBox(
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
                    ),
                  
                  // Add note display if there's a note
                  if (note.isNotEmpty)
                    Container(
                      color: rowColor,
                      padding: const EdgeInsets.only(left: 44, right: 16, bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              note,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
            ),
          ],
        ),
                    ),
                ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  void _addTransaction(
    double amount,
    bool isGet,
    String note,
    bool hasInterest,
    double interestRate,
    String interestPeriod,
    DateTime selectedDate,
    String? imagePath,
    String? loanId,  // Add loanId parameter
  ) {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final phone = widget.contact['phone'] as String? ?? '';
    
    if (phone.isEmpty) return;
    
    try {
      // Verify image exists if path is provided
      List<String> imageList = [];
      if (imagePath != null && imagePath.isNotEmpty) {
        final file = File(imagePath);
        if (file.existsSync()) {
          imageList.add(imagePath);
          print("Added image to transaction: $imagePath");
        } else {
          print("Image file doesn't exist: $imagePath");
        }
      }
      
    // Create transaction map
      final Map<String, dynamic> newTransaction = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'amount': amount,
      'isGet': isGet,
      'date': selectedDate,
      'note': note,
      'hasInterest': hasInterest,
      'interestRate': hasInterest ? interestRate : 0.0,
      'interestPeriod': interestPeriod,
      'imagePaths': imageList,
    };
    
      // Add loan ID if present
      if (loanId != null && loanId.isNotEmpty) {
        newTransaction['loanId'] = loanId;
      }
      
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
        SnackBar(
          content: Text('Transaction of ${currencyFormat.format(amount)} added'),
          backgroundColor: Colors.green,
        ),
    );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding transaction: $e'),
          backgroundColor: Colors.red,
        ),
    );
    }
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
      final hasInterest = transaction['hasInterest'] as bool? ?? false;
      final interestRate = transaction['interestRate'] as double? ?? 0.0;
      final interestPeriod = transaction['interestPeriod'] as String? ?? 'Month';
      final loanId = transaction['loanId'] as String?;
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
    _showDeleteConfirmationDialog();
  }

  void _deleteContact() async {
    final phone = widget.contact['phone'] as String? ?? '';
    final name = widget.contact['name'] as String? ?? 'Unknown';
    
    if (phone.isEmpty) {
      print("Error: Cannot delete contact with empty phone");
      return;
    }
    
    print("Attempting to delete contact: $name, phone: $phone");
    
    try {
      // Delete contact from provider - properly await the Future
      final success = await _transactionProvider.deleteContact(phone);
      print("Contact deletion result: $success");
      
      if (success) {
        // Force the providers to refresh their data
        await Provider.of<ContactProvider>(context, listen: false).loadContacts();
        
        // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name deleted')),
        );
        
        // Use a delay to ensure SharedPreferences is updated before refreshing the home screen
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Return to the previous screen with a result to trigger refresh
        Navigator.of(context).pop(true);
        
        // Use a post-frame callback to ensure we refresh the home screen after popping
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            final navigatorContext = Navigator.of(context, rootNavigator: true).context;
            HomeScreen.refreshHomeContent(navigatorContext);
          } catch (e) {
            print("Error refreshing home content: $e");
          }
        });
      } else {
        // Show error message if deletion failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete $name. Please try again.')),
    );
      }
    } catch (e) {
      print("Error in _deleteContact: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting contact: $e')),
      );
    }
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

  void _showTransactionDialog(bool isGet) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    bool hasInterest = _showInterestMode;
    double interestRate = 0.0;
    String interestPeriod = 'Month'; // 'Month' or 'Year'
    DateTime selectedDate = DateTime.now();
    String? imagePath;
    bool isPayingInterest = false; // Variable for interest checkbox
    String? selectedLoanId; // New variable to store selected loan ID
    // Add an error text state variable
    String? amountErrorText;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Get available loans for the user
          final loanProvider = Provider.of<LoanProvider>(context, listen: false);
          final activeLoans = loanProvider.activeLoans;
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            width: MediaQuery.of(context).size.width,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 12,
              left: 12,
              right: 12,
            ),
          child: SingleChildScrollView(
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
                      // Normal/Interest toggle switch
                      Row(
          children: [
                          Text(
                                  'Normal',
                                  style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: !hasInterest ? Colors.black : Colors.grey,
                            ),
                          ),
                          Switch(
                            value: hasInterest,
                            onChanged: (value) {
                setState(() {
                                hasInterest = value;
                });
              },
                            activeColor: Colors.blue,
                          ),
                          Text(
                                  'Interest',
                        style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: hasInterest ? Colors.blue : Colors.grey,
                              ),
                      ),
                    ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Amount field
                  const Text(
                    'Amount',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                    controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                    decoration: InputDecoration(
                      hintText: '0.00',
                      border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                      ),
                            prefixText: '₹ ',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            // Display error text if amount exceeds 1 crore
                            errorText: amountErrorText,
                  ),
                          // Add onChanged to validate max amount
                          onChanged: (value) {
                            final amount = double.tryParse(value) ?? 0.0;
                            if (amount > 10000000) { // 1 crore = 10,000,000
                              setState(() {
                                amountErrorText = "You can't enter more than 1cr";
                              });
                            } else {
                              setState(() {
                                amountErrorText = null;
                              });
                            }
                          },
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(6),
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
                  
                  const SizedBox(height: 16),
                  
                  // Move Interest settings here - show ONLY if hasInterest is true AND isPayingInterest is false
                  if (hasInterest && !isPayingInterest) ...[
                  const Text(
                      'Interest Settings',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    
                    Row(
                      children: [
                        // Interest rate field
                        Expanded(
                          flex: 3,
                          child: TextField(
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                    decoration: InputDecoration(
                              hintText: '0.0',
                      border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              suffixText: '%',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                                      padding: const EdgeInsets.symmetric(vertical: 6),
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
                                      padding: const EdgeInsets.symmetric(vertical: 6),
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
                  ],
                  
                  // Note and Receipt fields with 75:25 ratio
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Note field - with 75% width
                      Expanded(
                        flex: 75,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                  const Text(
                              'Note (optional)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 90, // Same height as receipt container
                              child: TextField(
                                controller: noteController,
                                decoration: InputDecoration(
                                  hintText: 'Add a note...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                                maxLines: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Receipt field - with 25% width
                      Expanded(
                        flex: 25,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                  const Text(
                              'Receipts',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                                fontSize: 12,
                    ),
                  ),
                            const SizedBox(height: 4),
                  GestureDetector(
                              onTap: () async {
                                try {
                                  final picker = ImagePicker();
                                  final pickedFile = await picker.pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 70,
                                  );
                                  
                                  if (pickedFile != null) {
                        setState(() {
                                      imagePath = pickedFile.path;
                                    });
                                    print("Image selected: ${pickedFile.path}");
                                  }
                                } catch (e) {
                                  print('Image picker error: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error selecting image: $e')),
                                  );
                                }
                    },
                    child: Container(
                      width: double.infinity,
                                height: 90,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(6),
                      ),
                                child: imagePath != null && File(imagePath!).existsSync()
                          ? Stack(
                              children: [
                                ClipRRect(
                                          borderRadius: BorderRadius.circular(5),
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
                                  : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.add_photo_alternate, size: 24, color: Colors.grey),
                                  SizedBox(height: 4),
                                Text(
                                          'Add receipt',
                                          style: TextStyle(color: Colors.grey, fontSize: 10),
                                          textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                    ),
                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Are you receiving/paying interest toggle - only show in Normal mode
                  if (!hasInterest) // Only show this toggle when in Normal mode
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isGet ? 'Are you receiving interest?' : 'Are you paying interest?',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              isGet 
                                ? 'Enable if you are receiving interest on a loan you have given'
                                : 'Enable if you are paying interest on a loan you have taken',
                      style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isPayingInterest,
                        onChanged: (value) {
                          setState(() {
                            isPayingInterest = value;
                            if (value) {
                              // When interest toggle is enabled, force interest mode
                              hasInterest = true;
                            }
                          });
                        },
                        activeColor: Colors.blue,
                      ),
                    ],
                  ),
                  
                  // Display loans section when isPayingInterest is true
                  if (isPayingInterest) ...[
                    const SizedBox(height: 16),
                    
                    Text(
                      isGet ? 'Select Loan (Lent)' : 'Select Loan (Borrowed)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    
                    // Show list of loans or "No loans" message
                    Container(
                      width: double.infinity,
                      height: activeLoans.isEmpty ? 60 : 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: activeLoans.isEmpty
                        ? Center(
                            child: Text(
                              isGet ? 'No loans lent found' : 'No loans borrowed found',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: activeLoans.length,
                            itemBuilder: (context, index) {
                              final loan = activeLoans[index];
                              
                              // Filter loans based on transaction type (received vs paid)
                              final bool isLentLoan = (loan['type'] as String?)?.toLowerCase() == 'lent' || 
                                                     (loan['loanType'] as String?)?.toLowerCase().contains('lent') == true;
                              
                              // Skip loans that don't match the transaction type
                              // For receiving interest, show lent loans; for paying interest, show borrowed loans
                              if ((isGet && !isLentLoan) || (!isGet && isLentLoan)) {
                                return const SizedBox.shrink(); // Hide non-matching loans
                              }
                              
                              final loanId = loan['id'] as String;
                              final loanName = loan['loanName'] as String? ?? 'Loan';
                              final loanAmount = loan['loanAmount'] as String? ?? '0';
                              final loanInterestRate = loan['interestRate'] as String? ?? '0';
                              
                              return RadioListTile<String>(
                                title: Text(loanName, style: const TextStyle(fontSize: 14)),
                                subtitle: Text(
                                  '₹$loanAmount | Interest: $loanInterestRate%',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                                value: loanId,
                                groupValue: selectedLoanId,
                                onChanged: (value) {
                                  setState(() {
                                    selectedLoanId = value;
                                    
                                    // Set interest rate from the selected loan
                                    if (value != null) {
                                      final selectedLoan = loanProvider.getLoanById(value);
                                      if (selectedLoan != null) {
                                        interestRate = double.tryParse(selectedLoan['interestRate'] ?? '0') ?? 0.0;
                                      }
                                    }
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              );
                            },
                          ),
                    ),
                  ],
                    
                    const SizedBox(height: 16),
                  
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
                            
                            // Check if amount exceeds 1 crore
                            if (amount > 10000000) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Amount cannot exceed 1 crore')),
                              );
                              return;
                            }
                            
                            // Use isPayingInterest to set hasInterest
                            final finalHasInterest = isPayingInterest || hasInterest;
                            
                            // Add transaction
                            _addTransaction(
                              amount,
                              isGet,
                              noteController.text,
                              finalHasInterest,
                              interestRate,
                              interestPeriod,
                              selectedDate,
                              imagePath,
                              selectedLoanId,  // Pass selected loan ID 
                            );
                            
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isGet ? Colors.green : Colors.red,
                            minimumSize: const Size(double.infinity, 44),
                          ),
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                      ),
                  
                  // Add extra bottom padding for better spacing with keyboard
                  const SizedBox(height: 12),
                    ],
                  ),
            ),
          );
        },
      ),
    );
  }

  void _showTransactionOptions(Map<String, dynamic> transaction, int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit Transaction'),
              onTap: () {
                Navigator.pop(context); // Close the bottom sheet
                _editTransaction(transaction);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Transaction'),
              onTap: () {
                Navigator.pop(context); // Close the bottom sheet
                _confirmDeleteTransaction(transaction, index);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _editTransaction(Map<String, dynamic> transaction) {
    // Get the transaction data
    final amount = transaction['amount'] as double? ?? 0.0;
    final isGet = transaction['isGet'] as bool? ?? true;
    final date = transaction['date'] as DateTime? ?? DateTime.now();
    final note = transaction['note'] as String? ?? '';
    final hasInterest = transaction['hasInterest'] as bool? ?? false;
    final interestRate = transaction['interestRate'] as double? ?? 0.0;
    final interestPeriod = transaction['interestPeriod'] as String? ?? 'Month';
    
    // Get image paths if available
    List<String> imagePaths = [];
    if (transaction['imagePaths'] != null) {
      imagePaths = List<String>.from(transaction['imagePaths'] as List? ?? []);
    } else if (transaction['imagePath'] != null) {
      final singleImagePath = transaction['imagePath'] as String?;
      if (singleImagePath != null && singleImagePath.isNotEmpty) {
        imagePaths = [singleImagePath];
      }
    }
    
    // Set up controllers
    final amountController = TextEditingController(text: amount.toString());
    final noteController = TextEditingController(text: note);
    DateTime selectedDate = date;
    String? editedImagePath = imagePaths.isNotEmpty ? imagePaths.first : null;
    
    // Show edit dialog
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            width: MediaQuery.of(context).size.width,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 12,
              left: 12,
              right: 12,
            ),
            child: SingleChildScrollView(
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
                        'Edit ${isGet ? 'Received' : 'Paid'} Transaction',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isGet ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Amount field
                  const Text(
                    'Amount',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
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
                  
                  const SizedBox(height: 16),
                  
                  // Note field
                    const Text(
                    'Note',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 6),
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
                  
                  const SizedBox(height: 16),
                  
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
                            
                            final newAmount = double.tryParse(amountController.text) ?? 0.0;
                            if (newAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Amount must be greater than 0')),
      );
      return;
    }
    
                            // Create updated transaction
                            final updatedTransaction = Map<String, dynamic>.from(transaction);
                            updatedTransaction['amount'] = newAmount;
                            updatedTransaction['date'] = selectedDate;
                            updatedTransaction['note'] = noteController.text;
                            
                            // Update transaction through provider
                            _updateTransaction(updatedTransaction);
                            
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isGet ? Colors.green : Colors.red,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: const Text('Save Changes'),
                        ),
                      ),
                    ],
                      ),
                  
                  const SizedBox(height: 12),
                    ],
        ),
      ),
    );
        },
      ),
    );
  }
  
  void _updateTransaction(Map<String, dynamic> updatedTransaction) {
    try {
      // Get the transaction ID and index
    final phone = widget.contact['phone'] as String? ?? '';
      final transactions = _transactionProvider.getTransactionsForContact(phone);
      final transactionId = updatedTransaction['id'] as String? ?? '';
      final index = transactions.indexWhere((tx) => tx['id'] == transactionId);
      
      if (index != -1) {
        // Update through provider
        _transactionProvider.updateTransaction(phone, index, updatedTransaction);
    
    // Refresh the transactions list
    _loadTransactions();
    
    // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction updated successfully')),
        );
      } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Transaction not found')),
        );
      }
    } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating transaction: $e')),
      );
    }
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

  // Show delete confirmation dialog
  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: const Text('Are you sure you want to delete this contact and all their transaction history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final contactId = widget.contact['phone'] as String? ?? '';
                if (contactId.isEmpty) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error: Invalid contact ID')),
                  );
                  return;
                }

                print('Deleting contact with ID: $contactId');
                
                // First delete from ContactProvider
                final contactProvider = Provider.of<ContactProvider>(context, listen: false);
                await contactProvider.deleteContact(contactId);
                
                // Then delete from TransactionProvider
                final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
                final success = await transactionProvider.deleteContact(contactId);
                
                Navigator.pop(context); // Close dialog
                
                if (success) {
                  // Force the home screen to refresh
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    HomeScreen.refreshHomeContent(context);
                  });
                  
                  // Navigate back to home
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  
                  // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contact deleted successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error deleting contact')),
        );
      }
    } catch (e) {
                print('Error during contact deletion: $e');
                Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
} 