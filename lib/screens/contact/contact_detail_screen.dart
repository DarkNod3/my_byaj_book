import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/dialogs/confirm_dialog.dart';
import '../../utils/string_extensions.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:my_byaj_book/utils/string_utils.dart';
import 'package:my_byaj_book/providers/transaction_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:my_byaj_book/services/pdf_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:my_byaj_book/screens/contact/edit_contact_screen.dart';

class ContactDetailScreen extends StatefulWidget {
  final Map<String, dynamic> contact;

  const ContactDetailScreen({Key? key, required this.contact}) : super(key: key);

  @override
  _ContactDetailScreenState createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
  List<Map<String, dynamic>> _filteredTransactions = [];
  bool _isSearching = false;
  late TransactionProvider _transactionProvider;
  String get _contactId => widget.contact['phone'] ?? '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterTransactions);
    // Debug print the contact ID
    print('ContactDetailScreen - Contact ID: ${_contactId}');
    print('ContactDetailScreen - Contact Name: ${widget.contact['name']}');
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _transactionProvider = Provider.of<TransactionProvider>(context);
    
    // Debug print transaction info
    final transactions = _transactionProvider.getTransactionsForContact(_contactId);
    print('ContactDetailScreen - Transaction count: ${transactions.length}');
    
    // Print the balance calculation
    final balance = _transactionProvider.calculateBalance(_contactId);
    print('ContactDetailScreen - Transaction balance: $balance');
    
    _filterTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterTransactions() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      final transactions = _transactionProvider.getTransactionsForContact(_contactId);
      if (query.isEmpty) {
        _filteredTransactions = List.from(transactions);
      } else {
        _filteredTransactions = transactions.where((tx) {
          return tx['note'].toString().toLowerCase().contains(query) ||
              tx['amount'].toString().contains(query);
        }).toList();
      }
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
    final balance = _calculateBalance();
    final isPositive = balance >= 0;
    final isWithInterest = widget.contact['type'] != null; // Check if it's a with-interest contact

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contact['name']),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showContactOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary card
          Card(
            margin: const EdgeInsets.all(12),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isPositive ? 'TO RECEIVE' : 'TO PAY',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                      GestureDetector(
                        onTap: _showContactInfo,
                        child: Row(
                          children: const [
                            Icon(Icons.info_outline, size: 16),
                            SizedBox(width: 4),
                            Text('DETAILS', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currencyFormat.format(balance.abs()),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isPositive ? Colors.green : Colors.red,
                            ),
                          ),
                          if (isWithInterest) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${widget.contact['interestRate']}% p.a.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.amber.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: widget.contact['type'] == 'borrower'
                                        ? Colors.red.withOpacity(0.1)
                                        : Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    StringUtils.capitalizeFirstLetter(widget.contact['type'] ?? ''),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: widget.contact['type'] == 'borrower' ? Colors.red : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  context,
                  Icons.call,
                  'Call',
                  themeProvider.primaryColor,
                  onTap: _handleCallButton,
                ),
                _buildActionButton(
                  context,
                  Icons.picture_as_pdf,
                  'PDF Report',
                  themeProvider.primaryColor,
                  onTap: _handlePdfReport,
                ),
                _buildActionButton(
                  context,
                  Icons.notifications,
                  'Reminder',
                  themeProvider.primaryColor,
                  onTap: _setReminder,
                ),
                _buildActionButton(
                  context,
                  Icons.sms,
                  'SMS',
                  themeProvider.primaryColor,
                  onTap: _handleSmsButton,
                ),
              ],
            ),
          ),

          // Transactions header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TRANSACTIONS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(_isSearching ? Icons.close : Icons.search),
                      onPressed: () {
                        setState(() {
                          _isSearching = !_isSearching;
                          if (!_isSearching) {
                            _searchController.clear();
                          }
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: () {
                        // Show filter options
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Filter coming soon')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search bar (visible only when searching)
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search transactions',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ),

          // Transactions list
          Expanded(
            child: _filteredTransactions.isEmpty
                ? const Center(child: Text('No transactions found'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
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
    {required Function onTap}
  ) {
    return InkWell(
      onTap: () => onTap(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> tx, double runningBalance) {
    final isGave = tx['type'] == 'gave';
    final hasImage = tx['imagePath'] != null;
    
    // Find the index of the transaction in the filtered list
    final txIndex = _filteredTransactions.indexOf(tx);
    
    // Create a unique key for each transaction
    final key = ValueKey('tx-$txIndex-${tx['date']}');
    
    return Dismissible(
      key: key,
      direction: DismissDirection.endToStart, // Only allow right to left swipe
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        // Show confirmation dialog
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Transaction'),
              content: const Text('Are you sure you want to delete this transaction? This cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        // Get the original index in the unfiltered list
        final allTransactions = _transactionProvider.getTransactionsForContact(_contactId);
        final originalIndex = allTransactions.indexOf(tx);
        
        // Delete the transaction
        if (originalIndex != -1) {
          _transactionProvider.deleteTransaction(_contactId, originalIndex);
          
          // Show a snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transaction deleted'),
              action: SnackBarAction(
                label: 'UNDO',
                onPressed: () {
                  // Re-add the deleted transaction
                  _transactionProvider.addTransaction(_contactId, tx);
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
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormat.format(tx['date']),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isGave ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isGave ? 'PAID' : 'RECEIVED',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isGave ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx['note'] ?? '',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        if (hasImage)
                          GestureDetector(
                            onTap: () => _showFullImage(context, tx['imagePath']),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: const [
                                  Icon(Icons.receipt_long, size: 12, color: Colors.blue),
                                  SizedBox(width: 2),
                                  Text(
                                    'View Receipt',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 10,
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
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isGave ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
              if (hasImage)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          height: 32,
                          width: 32,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Balance: ',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                  Text(
                    currencyFormat.format(runningBalance.abs()),
                    style: TextStyle(
                      fontSize: 10,
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
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text('Receipt'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
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
    String? imagePath;
    
    // Check if this is a with-interest contact
    final bool isWithInterest = widget.contact['type'] != null;
    
    // Default to principal amount
    bool isPrincipalAmount = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: type == 'gave' ? Colors.red.shade100 : Colors.green.shade100,
                        radius: 20,
                        child: Icon(
                          type == 'gave' ? Icons.arrow_upward : Icons.arrow_downward,
                          color: type == 'gave' ? Colors.red : Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        type == 'gave' ? 'Paid' : 'Received',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: type == 'gave' ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Amount Field
                  const Text(
                    'Amount',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      hintText: '0.00',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: type == 'gave' ? Colors.red : Colors.green, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  
                  // Principal/Interest Switch (Only for with-interest contacts)
                  if (isWithInterest) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          'Is this amount for:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Text(
                              'Interest',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: !isPrincipalAmount ? Colors.amber.shade800 : Colors.grey,
                              ),
                            ),
                            Switch(
                              value: isPrincipalAmount,
                              activeColor: Colors.blue,
                              thumbColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                                if (states.contains(MaterialState.selected)) {
                                  return Colors.blue;
                                }
                                return Colors.amber;
                              }),
                              trackColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                                if (states.contains(MaterialState.selected)) {
                                  return Colors.blue.withOpacity(0.5);
                                }
                                return Colors.amber.withOpacity(0.5);
                              }),
                              onChanged: (value) {
                                setState(() {
                                  isPrincipalAmount = value;
                                });
                              },
                            ),
                            Text(
                              'Principal',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isPrincipalAmount ? Colors.blue : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  
                  // Date Picker
                  const Text(
                    'Date',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today, 
                            size: 18, 
                            color: type == 'gave' ? Colors.red : Colors.green,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            dateFormat.format(selectedDate).split(',')[0],
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_drop_down, 
                            color: type == 'gave' ? Colors.red : Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Note Field
                  const Text(
                    'Note (optional)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: type == 'gave' ? Colors.red : Colors.green, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Image Upload
                  const Text(
                    'Attach Receipt/Bill (optional)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      _showImageSourceOptions(context, (path) {
                        setState(() {
                          imagePath = path;
                        });
                      });
                    },
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: imagePath != null 
                          ? Border.all(color: type == 'gave' ? Colors.red : Colors.green, width: 2) 
                          : null,
                      ),
                      child: imagePath != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.file(
                                    File(imagePath!),
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        imagePath = null;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
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
                                  size: 32,
                                  color: type == 'gave' ? Colors.red.withOpacity(0.7) : Colors.green.withOpacity(0.7),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to add photo',
                                  style: TextStyle(
                                    color: type == 'gave' ? Colors.red.withOpacity(0.7) : Colors.green.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            foregroundColor: Colors.grey[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (amountController.text.isEmpty) {
                              return;
                            }

                            final amount = double.tryParse(amountController.text);
                            if (amount == null || amount <= 0) {
                              return;
                            }

                            // Create note with principal/interest info if applicable
                            String note = noteController.text.isNotEmpty
                                ? noteController.text
                                : (type == 'gave' ? 'Payment sent' : 'Payment received');
                                
                            // Add info about principal/interest to the note
                            if (isWithInterest) {
                              note = '${isPrincipalAmount ? 'Principal' : 'Interest'}: $note';
                            }

                            // Add new transaction using the provider
                            _transactionProvider.addTransactionDetails(
                              _contactId,
                              amount,
                              type,
                              selectedDate,
                              note,
                              imagePath,
                            );
                            
                            _filterTransactions();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: type == 'gave' ? Colors.red : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1000,
      );
      
      if (pickedFile != null) {
        onImageSelected(pickedFile.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildInterestBreakdown() {
    // Calculate interest components
    final principal = widget.contact['amount'] as double;
    final interestRate = (widget.contact['interestRate'] as double) / 100; // Convert to decimal
    final daysAgo = widget.contact['daysAgo'] as int;
    
    // Calculate interest per day (simple interest)
    final interestPerDay = principal * interestRate / 365;
    final interestToDate = interestPerDay * daysAgo;
    final totalAmount = principal + interestToDate;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Principal',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            Text(
              currencyFormat.format(principal),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Interest (${daysAgo} days)',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '+ ${currencyFormat.format(interestToDate)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.orange[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Amount',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            Text(
              currencyFormat.format(totalAmount),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ],
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
    
    // Format phone number (remove spaces)
    final formattedPhone = phone.replaceAll(RegExp(r'\s+'), '');
    
    // Try with permission first
    final hasPhonePermission = await _checkPhonePermission();
    
    if (hasPhonePermission) {
      // Direct call with permission
      final phoneUrl = 'tel:$formattedPhone';
      
      try {
        if (await canLaunchUrl(Uri.parse(phoneUrl))) {
          await launchUrl(Uri.parse(phoneUrl));
          return;
        }
      } catch (e) {
        print('Error making direct call: $e');
        // Continue to alternative methods
      }
    }
    
    // If permission denied or direct call failed, show options dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Contact Options'),
          content: Text('Would you like to call ${widget.contact['name']}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Use the copy to clipboard option as fallback
                Clipboard.setData(ClipboardData(text: formattedPhone));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Phone number copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Copy Number'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                // Try to open using default URL handler
                final phoneUrl = 'tel:$formattedPhone';
                if (await canLaunchUrl(Uri.parse(phoneUrl))) {
                  await launchUrl(Uri.parse(phoneUrl), mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open phone app')),
                  );
                }
              },
              child: const Text('Open Dialer'),
            ),
          ],
        ),
      );
    }
  }
  
  Future<bool> _checkPhonePermission() async {
    // Check current permission status
    if (await Permission.phone.isGranted) {
      return true;
    }
    
    // If permission is denied but can be requested
    if (await Permission.phone.isPermanentlyDenied) {
      // Show dialog explaining how to enable permission in settings
      final bool shouldOpenSettings = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Phone Permission Required'),
          content: const Text(
            'To call contacts, this app needs phone permission. Please enable it in app settings.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ) ?? false;
      
      if (shouldOpenSettings) {
        await openAppSettings();
      }
      return false;
    }
    
    // Request permission
    final status = await Permission.phone.request();
    
    // If denied after request, show explanation
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone permission is needed to make calls directly from the app'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
    
    return status.isGranted;
  }

  void _handlePdfReport() async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating PDF report...')),
      );
      
      // Get transactions
      final transactions = _transactionProvider.getTransactionsForContact(_contactId);
      
      // Create a PDF document
      final pdf = pw.Document();
      
      // Add pages to the PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildPdfHeader(),
          footer: (context) => _buildPdfFooter(context),
          build: (context) => [
            _buildPdfSummary(),
            pw.SizedBox(height: 20),
            _buildPdfTransactionTable(transactions),
          ],
        )
      );
      
      // Save the PDF to a file
      final output = await getTemporaryDirectory();
      final contactName = widget.contact['name']
          .toString()
          .replaceAll(RegExp(r'[^\w\s]+'), '')
          .replaceAll(' ', '_');
      final date = DateFormat('yyyy_MM_dd').format(DateTime.now());
      final file = File('${output.path}/${contactName}_report_$date.pdf');
      await file.writeAsBytes(await pdf.save());
      
      // Open the PDF file
      await OpenFile.open(file.path);
      
      // Show success message
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF report generated successfully')),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF report: $e')),
      );
    }
  }
  
  pw.Widget _buildPdfHeader() {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        children: [
          pw.Text(
            'My Byaj Book',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Transaction Report',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(
          fontSize: 10,
        ),
      ),
    );
  }
  
  pw.Widget _buildPdfSummary() {
    final balance = _calculateBalance();
    final isPositive = balance >= 0;
    
    // Plain number format for PDF without rupee symbol
    final pdfNumberFormat = NumberFormat.currency(locale: 'en_IN', symbol: '');
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Contact Summary',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                DateFormat('dd MMM yyyy').format(DateTime.now()),
                style: const pw.TextStyle(
                  fontSize: 10,
                ),
              ),
            ],
          ),
          pw.Divider(),
          pw.SizedBox(height: 5),
          pw.Text(
            'Name: ${widget.contact['name']}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Phone: ${widget.contact['phone'] ?? 'N/A'}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 5),
          
          // Balance row
          pw.Row(
            children: [
              pw.Text(
                'Balance: ',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.Text(
                pdfNumberFormat.format(balance.abs()),
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: isPositive ? PdfColors.green : PdfColors.red,
                ),
              ),
              pw.SizedBox(width: 5),
              pw.Text(
                isPositive ? '(You will get)' : '(You will give)',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontStyle: pw.FontStyle.italic,
                  color: isPositive ? PdfColors.green : PdfColors.red,
                ),
              ),
            ],
          ),
          
          // Add interest information if applicable
          if (widget.contact['type'] != null) ...[
            pw.SizedBox(height: 10),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 5),
            pw.Text(
              'Interest Information',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Interest Rate: ${widget.contact['interestRate']}% p.a.',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Type: ${StringUtils.capitalizeFirstLetter(widget.contact['type'] ?? '')}',
              style: const pw.TextStyle(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
  
  pw.Widget _buildPdfTransactionTable(List<Map<String, dynamic>> transactions) {
    // Create header row
    final headers = [
      'Date',
      'Description',
      'Amount',
      'Type',
      'Balance',
    ];
    
    // Plain number format for PDF without rupee symbol
    final pdfNumberFormat = NumberFormat.currency(locale: 'en_IN', symbol: '');
    
    // Create data rows
    final rows = <List<dynamic>>[];
    final List<bool> isGaveList = [];
    double runningBalance = 0;
    
    // Process transactions in reverse order (oldest first)
    for (int i = transactions.length - 1; i >= 0; i--) {
      final tx = transactions[i];
      final isGave = tx['type'] == 'gave';
      final type = isGave ? 'You Gave' : 'You Got';
      final amount = tx['amount'] as double;
      
      // Update running balance
      if (isGave) {
        runningBalance += amount;
      } else {
        runningBalance -= amount;
      }
      
      // Store transaction type for later use
      isGaveList.add(isGave);
      
      // Store transaction data
      rows.add([
        DateFormat('dd/MM/yyyy').format(tx['date']),
        tx['note'] ?? '',
        pdfNumberFormat.format(amount),
        type,
        pdfNumberFormat.format(runningBalance.abs()),
      ]);
    }
    
    // Create the table with colored cells
    final table = pw.Table(
      border: null,
      columnWidths: {
        0: const pw.FractionColumnWidth(0.15), // Date
        1: const pw.FractionColumnWidth(0.35), // Description
        2: const pw.FractionColumnWidth(0.15), // Amount
        3: const pw.FractionColumnWidth(0.15), // Type
        4: const pw.FractionColumnWidth(0.20), // Balance
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue),
          children: headers.map((header) => pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(
              header,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              textAlign: header == 'Amount' || header == 'Balance' 
                  ? pw.TextAlign.right 
                  : header == 'Type' 
                      ? pw.TextAlign.center 
                      : pw.TextAlign.left,
            ),
          )).toList(),
        ),
        
        // Data rows
        ...List.generate(rows.length, (index) {
          final isGave = isGaveList[index];
          final isPositiveBalance = runningBalance >= 0;
          
          return pw.TableRow(
            children: [
              // Date
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(rows[index][0], textAlign: pw.TextAlign.left),
              ),
              
              // Description
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(rows[index][1], textAlign: pw.TextAlign.left),
              ),
              
              // Amount - colored based on transaction type
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  rows[index][2],
                  style: pw.TextStyle(
                    color: isGave ? PdfColors.red : PdfColors.green,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              
              // Type - colored based on transaction type
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  rows[index][3],
                  style: pw.TextStyle(
                    color: isGave ? PdfColors.red : PdfColors.green,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              
              // Balance - colored based on positive/negative
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  rows[index][4],
                  style: pw.TextStyle(
                    color: isPositiveBalance ? PdfColors.green : PdfColors.red,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          );
        }),
      ],
    );
    
    return table;
  }

  void _setReminder() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      final TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (selectedTime != null) {
        // Create a DateTime with both date and time components
        final scheduledDate = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
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

        // Show confirmation to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reminder set for ${DateFormat('MMM d, yyyy').format(scheduledDate)} at ${selectedTime.format(context)}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }
  
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // For now, show an immediate notification with details about the scheduled reminder
    // This is a simpler approach than dealing with the scheduled notifications which
    // require more complex setup
    
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
    
    // Format the scheduled date/time for display
    final formattedDateTime = DateFormat('MMM d, yyyy - h:mm a').format(scheduledDate);
    
    // Show a notification immediately with information about the scheduled reminder
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      'Reminder set for $formattedDateTime: $body',
      notificationDetails,
    );
    
    print('Notification reminder set for: $scheduledDate');
  }

  void _handleSmsButton() async {
    // Prepare payment summary message
    final balance = _calculateBalance();
    final isPositive = balance >= 0;
    
    final message = '''
Dear ${widget.contact['name']},

This is a friendly reminder regarding your account with me.

Current balance: ${currencyFormat.format(balance.abs())}
${isPositive ? 'Payment due' : 'Payment to make'} this amount to me.

Best regards,
${_getAppUserName()}
''';
    
    // Try to send via WhatsApp first
    bool whatsappOpened = await _tryOpenWhatsApp(message);
    
    // If WhatsApp not available, use SMS
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
    
    // Format phone number for WhatsApp (remove spaces and special characters)
    final formattedPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Create WhatsApp URL with encoded message
    final whatsappUrl = Uri.parse(
      'whatsapp://send?phone=$formattedPhone&text=${Uri.encodeComponent(message)}',
    );
    
    try {
      // Check if WhatsApp is installed
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error opening WhatsApp: $e');
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
    
    // Format phone for SMS (remove spaces)
    final formattedPhone = phone.replaceAll(' ', '');
    
    // Create SMS URL with encoded message
    final smsUrl = Uri.parse(
      'sms:$formattedPhone?body=${Uri.encodeComponent(message)}',
    );
    
    try {
      if (await canLaunchUrl(smsUrl)) {
        await launchUrl(smsUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch SMS app')),
        );
      }
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
    _filterTransactions();
  }
} 