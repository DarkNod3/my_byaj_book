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
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
      
      // Update transaction display to include interest rate info in all views
      for (var tx in freshTransactions) {
        if (tx['hasInterest'] == true && tx['interestRate'] != null) {
          // Make sure any interest-related transaction displays its rate
          final interestRate = tx['interestRate'] as double? ?? 0.0;
          final interestPeriod = tx['interestPeriod'] as String? ?? 'Month';
          tx['interestRateDisplay'] = '$interestRate% per $interestPeriod';
        }
      }
      
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
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
            child: Row(
              children: [
                Expanded(
                    child: GestureDetector(
                      onTap: () {
      setState(() {
                          _showInterestMode = false;
                          _loadTransactions();
                        });
                      },
            child: Container(
                      decoration: BoxDecoration(
                          color: !_showInterestMode ? Colors.grey.shade400 : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Normal',
                  style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: !_showInterestMode ? Colors.black : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showInterestMode = true;
                          _loadTransactions();
                        });
                      },
                    child: Container(
                      decoration: BoxDecoration(
                          color: _showInterestMode ? Colors.grey.shade400 : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Interest',
                    style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: _showInterestMode ? Colors.black : Colors.grey.shade700,
                        ),
                      ),
                                    ),
                                  ),
                                ),
                              ],
              ),
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
    double effectiveInterestRate = 0.0;
    
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
      
      // Calculate total interest based on principal, interest rate and time period
      totalInterestAmount = _calculateTotalInterestAccrued(normalTransactions, interestTransactions);
      
      // Calculate effective interest rate if we have a positive principal
      if (normalBalance.abs() > 0) {
        effectiveInterestRate = (totalInterestAmount / normalBalance.abs()) * 100;
      }
      
      // Use the appropriate balance based on current tab
      final calculatedBalance = _showInterestMode ? interestBalance : normalBalance;
      _totalAmount = calculatedBalance.abs(); // Keep abs() only for display amount
      _isGet = calculatedBalance >= 0; // Positive balance means you will receive
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
          
          // Display total interest amount and rate in Interest tab
          if (_showInterestMode)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                  const SizedBox(height: 4),

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
  
  // Helper method to calculate total interest accrued based on principal, rate and time
  double _calculateTotalInterestAccrued(List<Map<String, dynamic>> normalTransactions, List<Map<String, dynamic>> interestTransactions) {
    double totalInterest = 0.0;
    
    // First, get all loan transactions with interest
    List<Map<String, dynamic>> loanTransactions = normalTransactions.where((tx) => 
      (tx['hasInterest'] == true || tx['interestRate'] != null) && 
      tx['amount'] != null && 
      tx['date'] != null
    ).toList();
    
    // Add explicit interest transactions too
    loanTransactions.addAll(interestTransactions);
    
    // Sort by date (oldest first)
    loanTransactions.sort((a, b) {
      final dateA = a['date'] as DateTime? ?? DateTime.now();
      final dateB = b['date'] as DateTime? ?? DateTime.now();
      return dateA.compareTo(dateB);
    });
    
    // Calculate interest for each transaction
    final now = DateTime.now();
    
    for (final tx in loanTransactions) {
      final amount = tx['amount'] as double? ?? 0.0;
      final isGet = tx['isGet'] as bool? ?? true;
      final interestRate = tx['interestRate'] as double? ?? 0.0;
      final interestPeriod = tx['interestPeriod'] as String? ?? 'Month';
      final date = tx['date'] as DateTime? ?? DateTime.now();
      
      // Skip if no interest rate
      if (interestRate <= 0) continue;
      
      // Skip interest transactions themselves
      if (tx['hasInterest'] == true && tx['loanId'] != null) continue;
      
      // Calculate time period (in months)
      int daysDifference = now.difference(date).inDays;
      double monthsDifference = daysDifference / 30;
      
      // Convert interest rate to monthly if needed
      double monthlyRate = interestPeriod == 'Year' 
          ? interestRate / 12 / 100  // Convert annual rate to monthly decimal
          : interestRate / 100;      // Convert monthly rate to decimal
      
      // Calculate interest amount
      double principal = isGet ? amount : -amount; // Negate if it's a payment
      double interest = principal * monthlyRate * monthsDifference;
      
      // Add to total
      totalInterest += interest;
    }
    
    return totalInterest;
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
    // Filter transactions based on the current mode (Normal or Interest)
    final sortedTransactions = _transactions.where((tx) {
      final hasInterest = tx['hasInterest'] as bool? ?? false;
      final loanId = tx['loanId'] as String?;
      
                          if (_showInterestMode) {
                      // In Interest mode, show all transactions but calculate interest for each
                      if (hasInterest || loanId != null) {
                        return true; // Show transactions explicitly marked as interest
                      } else {
                        // For transactions not marked as interest, check if they have an interest rate defined
                        final interestRate = tx['interestRate'] as double?;
                        return interestRate != null && interestRate > 0;
                      }
                    } else {
                      // In Normal mode, show all non-interest transactions
                      return !hasInterest && loanId == null;
                    }
    }).toList();

    // Pre-calculate running balances for all transactions
    final Map<String, double> transactionBalances = {};
    double runningBalance = 0.0;
    
    for (int i = sortedTransactions.length - 1; i >= 0; i--) {
      final tx = sortedTransactions[i];
      final amount = tx['amount'] as double? ?? 0.0;
      final isGet = tx['isGet'] as bool? ?? true;
      final txId = tx['id'] as String? ?? '';
      
      // Update running balance
      runningBalance += isGet ? amount : -amount;
      transactionBalances[txId] = runningBalance;
    }

    return Column(
                children: [
        // Header row
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                    ),
          child: Row(
                    children: [
              // Date column
              SizedBox(
                width: 110,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                  'Date',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.grey.shade800,
                  ),
                ),
                    if (_showInterestMode)
                      Text(
                        '& Calculated Interest',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: Colors.purple.shade700,
                    ),
                  ),
                  ],
                ),
              ),
              
              // Vertical dotted line
              _buildDottedLine(),
              
              // Debit column - Adjusted width
              Expanded(
                flex: 4,
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
              
              // Credit column - Adjusted width
              Expanded(
                flex: 4,
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
              final formattedAmount = '₹${amount.toStringAsFixed(2)}';
              final formattedBalance = runningBalance >= 0 
                  ? '₹${runningBalance.toStringAsFixed(2)}' 
                  : '₹-${runningBalance.abs().toStringAsFixed(2)}';
              
              // Alternating row background for better readability
              final rowColor = index % 2 == 0 ? Colors.white : Colors.grey.shade50;
              
              return GestureDetector(
                onLongPress: () => _showTransactionOptions(transaction, index),
                child: Column(
          children: [
                  // Main transaction row with ledger columns
                  Container(
                                            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                      decoration: BoxDecoration(
                        color: rowColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 3,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      child: Column(
                        children: [
                          Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                              // Date column
                        SizedBox(
                                width: 110,
                          child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                                    // Arrow icon
                    Container(
                                      width: 18,
                                      height: 18,
                                      margin: const EdgeInsets.only(right: 4, top: 1),
                      decoration: BoxDecoration(
                                        color: isGet ? Colors.green.shade50 : Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                      child: Icon(
                                      isGet ? Icons.arrow_downward : Icons.arrow_upward,
                                          color: isGet ? Colors.green : Colors.red,
                                          size: 12,
                                    ),
                                  ),
                                ),
                              
                                    // Date info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                      DateFormat('dd MMM yy').format(date),
                              style: TextStyle(
                                              fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  Text(
                                      DateFormat('hh:mm a').format(date),
                                      style: TextStyle(
                                              fontSize: 9,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                          if (note.isNotEmpty) 
                                    Text(
                                              note,
                                          style: TextStyle(
                                                fontSize: 9,
                                        color: Colors.grey.shade600,
                                            fontStyle: FontStyle.italic,
                                        ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          // Interest info shown in a different section
                                    if (imagePaths.isNotEmpty)
                                      Text(
                                        'Receipts (${imagePaths.length})',
                                        style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.blue.shade700,
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
                        
                              // Debit column - Decreased width
                        Expanded(
                                flex: 4,
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
                        
                              // Credit column - Decreased width
                        Expanded(
                                flex: 4,
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
                            ],
                          ),
                          
                                                    // Balance row without divider - moved to left
                          Padding(
                            padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Balance: ',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  transaction['hasInterest'] == true && transaction['interestRate'] != null
                                    ? Text(
                                        _calculateTotalWithInterest(transaction),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.teal.shade600,
                                        ),
                                      )
                                    : Text(
                                        formattedBalance,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: runningBalance >= 0 
                                              ? Colors.teal.shade600
                                              : Colors.deepOrange.shade600,
                                        ),
                                      ),
                                ],
                              ),
                            ),
                          ),
                      ],
                ),
                  ),
                  
                                          // Display interest details or receipt images if available
                    if (transaction['hasInterest'] == true && transaction['interestRate'] != null)
                    Container(
                                                width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.05),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Divider(height: 1, thickness: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Rate: ${transaction['interestRate']}%',
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.purple.shade700,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              ' • ',
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            Text(
                                              _getTimeDurationString(transaction['date']),
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.green.shade700,
                                                fontWeight: FontWeight.bold,
                                              ),
                ),
              ],
            ),
                                        Text(
                                          'Interest amount: ${_calculateInterestForTransaction(transaction)}',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.purple.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Right-aligned text
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'TOTAL: ${_calculateTotalWithInterest(transaction)}',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade800,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Display receipt images in a compact row if available
                    if (imagePaths.isNotEmpty)
                    Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.05),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        padding: const EdgeInsets.only(left: 44, bottom: 8),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                      child: Row(
                            children: imagePaths.map((path) => GestureDetector(
                              onTap: () => _showImageViewer(path),
                              child: Container(
                                height: 32,
                                width: 32,
                                margin: const EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.grey.shade300, width: 1),
                                  image: DecorationImage(
                                    image: FileImage(File(path)),
                                    fit: BoxFit.cover,
                              ),
                            ),
            ),
                            )).toList(),
                          ),
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
    List<String> imagePaths,
    String? loanId,
    [Map<String, dynamic>? additionalData]
  ) {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final phone = widget.contact['phone'] as String? ?? '';
    
    if (phone.isEmpty) return;
    
    try {
      // Verify image exists if path is provided
      List<String> imageList = [];
      if (imagePaths.isNotEmpty) {
        for (final path in imagePaths) {
          final file = File(path);
        if (file.existsSync()) {
            imageList.add(path);
            print("Added image to transaction: $path");
        } else {
            print("Image file doesn't exist: $path");
          }
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
      
      // Add interest relationship data if present
      if (additionalData != null) {
        // Add interest source/payment flags
        if (additionalData.containsKey('isInterestSource')) {
          newTransaction['isInterestSource'] = additionalData['isInterestSource'];
        }
        
        if (additionalData.containsKey('isInterestPayment')) {
          newTransaction['isInterestPayment'] = additionalData['isInterestPayment'];
        }
        
        // Add relationship ID if present
        if (additionalData.containsKey('interestRelatedToId')) {
          newTransaction['interestRelatedToId'] = additionalData['interestRelatedToId'];
        }
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

  // Helper method to build a vertical dotted line divider
  Widget _buildDottedLine() {
    return Container(
      height: 20,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: Colors.grey.shade300,
    );
  }

  void _showTransactionDialog(bool isGet) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    bool hasInterest = _showInterestMode;
    double interestRate = 0.0;
    String interestPeriod = 'Month'; // 'Month' or 'Year'
    DateTime selectedDate = DateTime.now();
    List<String> selectedImagePaths = []; // List to store multiple image paths
    bool isPayingInterest = false; // Variable for interest checkbox
    String? selectedLoanId; // New variable to store selected loan ID
    String? amountErrorText;
    
    // For interest relationship tracking
    bool isInterestSource = false;
    String? interestRelatedToId;
    List<Map<String, dynamic>> interestRelatedTransactions = [];
    
    // Load potential related transactions
    if (isGet) {
      // For received transactions, show paid transactions marked as interest payments
      interestRelatedTransactions = _transactions.where((tx) => 
        tx['isGet'] == false && // Only show payments
        tx['isInterestPayment'] == true // Only interest payments
      ).toList();
    } else {
      // For paid transactions, show received transactions marked as interest sources
      interestRelatedTransactions = _transactions.where((tx) => 
        tx['isGet'] == true && // Only show receipts
        tx['isInterestSource'] == true // Only interest sources
      ).toList();
    }
    
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
                                // Reset interest relationship if toggling off interest mode
                                if (!value) {
                                  isPayingInterest = false;
                                  isInterestSource = false;
                                  interestRelatedToId = null;
                                }
                });
              },
                            activeColor: Colors.blue,
                                ),
                          Text(
                                  'Interest Calc',
                        style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: _showInterestMode ? Colors.black : Colors.grey.shade700,
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
                            errorText: amountErrorText,
                  ),
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
                    
                  // Note field
                  const Text(
                              'Note (optional)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                                fontSize: 12,
                      ),
                    ),
                            const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Note field - 70% width
                      Expanded(
                        flex: 7,
                              child: TextField(
                                controller: noteController,
                                decoration: InputDecoration(
                                  hintText: 'Add a note...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                          maxLines: 3,
                              ),
                            ),
                      const SizedBox(width: 8),
                      // Receipt button - 30% width
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                  const Text(
                              'Receipts',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                                fontSize: 12,
                    ),
                  ),
                            const SizedBox(height: 4),
                            Container(
                              height: 42,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                try {
                                  final picker = ImagePicker();
                                  final pickedFile = await picker.pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 70,
                                  );
                                  
                                  if (pickedFile != null) {
                        setState(() {
                                        selectedImagePaths.add(pickedFile.path);
                        });
                                      print("Image added: ${pickedFile.path}");
                        }
                                } catch (e) {
                                  print('Image picker error: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error selecting image: $e')),
                                  );
                                }
                    },
                                icon: Icon(Icons.add_photo_alternate, size: 16),
                                label: Text('Add Receipt', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                  backgroundColor: Colors.grey.shade200,
                                  foregroundColor: Colors.black87,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Display selected images
                  if (selectedImagePaths.isNotEmpty)
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(6),
                      ),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(8),
                        itemCount: selectedImagePaths.length,
                        itemBuilder: (context, index) {
                          return Stack(
                              children: [
                              Container(
                                width: 60,
                                height: 60,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  image: DecorationImage(
                                    image: FileImage(File(selectedImagePaths[index])),
                                    fit: BoxFit.cover,
                                  ),
                                  border: Border.all(color: Colors.grey.shade300),
                                  ),
                                ),
                                Positioned(
                                top: 0,
                                right: 8,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                      selectedImagePaths.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                          );
                        },
                      ),
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
                              
                              // Add interest relationship flags based on transaction type
                              if (isGet) {
                                isInterestSource = true;
                              } else {
                                // For payments, it's an interest payment
                              }
                            } else {
                              isInterestSource = false;
                              interestRelatedToId = null;
                            }
                          });
                        },
                        activeColor: Colors.blue,
                      ),
                    ],
                  ),
                  
                  // Show related transactions selection if in interest mode
                  if ((isPayingInterest || hasInterest) && interestRelatedTransactions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      isGet 
                        ? 'Select payment this interest relates to:' 
                        : 'Select loan this interest payment is for:',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  const SizedBox(height: 8),
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(4),
                        itemCount: interestRelatedTransactions.length,
                        itemBuilder: (context, index) {
                          final tx = interestRelatedTransactions[index];
                          final amount = tx['amount'] as double? ?? 0.0;
                          final date = tx['date'] as DateTime? ?? DateTime.now();
                          final id = tx['id'] as String? ?? '';
                          
                          return RadioListTile<String>(
                            title: Text(
                              '${DateFormat('dd MMM yyyy').format(date)} - ₹${amount.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: Text(
                              tx['note'] as String? ?? 'No note',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            value: id,
                            groupValue: interestRelatedToId,
                            onChanged: (value) {
                              setState(() {
                                interestRelatedToId = value;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          );
                        },
                      ),
                    ),
                  ],
                  
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
                            
                            // Determine interest flags
                            final finalHasInterest = isPayingInterest || hasInterest;
                            
                            // Add transaction with interest relationship flags
                            Map<String, dynamic> additionalData = {
                              'isInterestSource': isGet && (isPayingInterest || hasInterest),
                              'isInterestPayment': !isGet && (isPayingInterest || hasInterest),
                            };
                            
                            // Add interest relation if selected
                            if (interestRelatedToId != null) {
                              additionalData['interestRelatedToId'] = interestRelatedToId;
                            }
                            
                            // Pass the multiple image paths to the addTransaction method
                            _addTransaction(
                              amount,
                              isGet,
                              noteController.text,
                              finalHasInterest,
                              interestRate,
                              interestPeriod,
                              selectedDate,
                              selectedImagePaths,
                              selectedLoanId,
                              additionalData,
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
    List<String> selectedImagePaths = List.from(imagePaths);
    
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Note field - 70% width
                      Expanded(
                        flex: 7,
                        child: TextField(
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
                      ),
                      const SizedBox(width: 8),
                      // Receipt button - 30% width
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Receipts',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 42,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    final picker = ImagePicker();
                                    final pickedFile = await picker.pickImage(
                                      source: ImageSource.gallery,
                                      imageQuality: 70,
                                    );
                                    
                                    if (pickedFile != null) {
                                      setState(() {
                                        selectedImagePaths.add(pickedFile.path);
                                      });
                                    }
                                  } catch (e) {
                                    print('Image picker error: $e');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error selecting image: $e')),
                                    );
                                  }
                                },
                                icon: Icon(Icons.add_photo_alternate, size: 16),
                                label: Text('Add Receipt', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                  backgroundColor: Colors.grey.shade200,
                                  foregroundColor: Colors.black87,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Display selected images
                  if (selectedImagePaths.isNotEmpty)
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(8),
                        itemCount: selectedImagePaths.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  image: DecorationImage(
                                    image: FileImage(File(selectedImagePaths[index])),
                                    fit: BoxFit.cover,
                                  ),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedImagePaths.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
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
                            updatedTransaction['imagePaths'] = selectedImagePaths;
                            
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
                
                // Close dialog immediately to improve user experience
                Navigator.pop(context);
                
                // Show a loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const AlertDialog(
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 20),
                        Text("Deleting contact..."),
                      ],
                    ),
                  ),
                );

                // Get providers
                final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
                final contactProvider = Provider.of<ContactProvider>(context, listen: false);
                
                // First delete from TransactionProvider (which handles transactions and more data)
                final success = await transactionProvider.deleteContact(contactId);
                
                // Only if the transaction deletion was successful, delete from ContactProvider
                if (success) {
                  await contactProvider.deleteContact(contactId);
                  
                  // Ensure contact is properly saved immediately
                  await contactProvider.saveContactsNow();
                  
                  // Add a delay to ensure the change is persisted
                  await Future.delayed(const Duration(milliseconds: 300));
                }
                
                // Dismiss the progress dialog
                if (context.mounted) {
                  Navigator.pop(context);
                }
                
                if (success) {
                  // Navigate back to home screen
                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    
                    // Schedule a delayed refresh after navigation
                    // This ensures the home screen is fully mounted before refreshing
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (context.mounted) {
                        try {
                          final rootContext = Navigator.of(context, rootNavigator: true).context;
                          HomeScreen.refreshHomeContent(rootContext);
                          print("Home screen refreshed after contact deletion");
                        } catch (e) {
                          print("Error refreshing home screen: $e");
                        }
                      }
                    });
                  }
                  
                  // Show success message
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contact deleted successfully')),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error deleting contact')),
                    );
                  }
                }
              } catch (e) {
                print('Error deleting contact: $e');
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog if still open
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Method to show a full-screen image viewer
  void _showImageViewer(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.black.withOpacity(0.85),
        child: Stack(
          children: [
            InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 3.0,
              child: Center(
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                  height: double.infinity,
                  width: double.infinity,
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                radius: 18,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                radius: 18,
                child: IconButton(
                  icon: const Icon(Icons.download, color: Colors.white, size: 18),
                  onPressed: () {
                    _downloadImage(imagePath);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get a formatted time duration string
  String _getTimeDurationString(DateTime? date) {
    if (date == null) return '0 days';
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    final days = difference.inDays;
    final months = days ~/ 30;
    final remainingDays = days % 30;
    
    if (months > 0) {
      return '$months months, $remainingDays days';
    } else {
      return '$days days';
    }
  }
  
  // Helper method to calculate interest amount for a single transaction
  String _calculateInterestForTransaction(Map<String, dynamic> transaction) {
    final amount = transaction['amount'] as double? ?? 0.0;
    final interestRate = transaction['interestRate'] as double? ?? 0.0;
    final interestPeriod = transaction['interestPeriod'] as String? ?? 'Month';
    final date = transaction['date'] as DateTime? ?? DateTime.now();
    final now = DateTime.now();
    
    // Calculate time period (in months)
    int daysDifference = now.difference(date).inDays;
    double monthsDifference = daysDifference / 30.0;
    
    // Convert interest rate to monthly if needed
    double monthlyRate = interestPeriod == 'Year' 
        ? interestRate / 12 / 100  // Convert annual rate to monthly decimal
        : interestRate / 100;      // Convert monthly rate to decimal
    
    // Calculate interest amount
    double interestAmount = amount * monthlyRate * monthsDifference;
    
    // Format the interest amount with the currency formatter only
    return currencyFormat.format(interestAmount);
  }
  
  // Helper method to calculate total amount (principal + interest)
  String _calculateTotalWithInterest(Map<String, dynamic> transaction) {
    final amount = transaction['amount'] as double? ?? 0.0;
    final interestRate = transaction['interestRate'] as double? ?? 0.0;
    final interestPeriod = transaction['interestPeriod'] as String? ?? 'Month';
    final date = transaction['date'] as DateTime? ?? DateTime.now();
    final now = DateTime.now();
    
    // Calculate time period (in months)
    int daysDifference = now.difference(date).inDays;
    double monthsDifference = daysDifference / 30.0;
    
    // Convert interest rate to monthly if needed
    double monthlyRate = interestPeriod == 'Year' 
        ? interestRate / 12 / 100  // Convert annual rate to monthly decimal
        : interestRate / 100;      // Convert monthly rate to decimal
    
    // Calculate interest amount
    double interestAmount = amount * monthlyRate * monthsDifference;
    
    // Calculate total amount (principal + interest)
    double totalAmount = amount + interestAmount;
    
    // Format with currency formatter
    return currencyFormat.format(totalAmount);
  }
} 