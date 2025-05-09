import 'package:flutter/material.dart';
import 'package:my_byaj_book/constants/app_theme.dart';
import 'package:my_byaj_book/widgets/header/app_header.dart';
import 'package:my_byaj_book/providers/transaction_provider.dart';
import 'package:my_byaj_book/services/pdf_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Get transaction data from provider
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final allTransactions = transactionProvider.getAllTransactions();
    final filteredTransactions = _filterTransactions(allTransactions);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          AppHeader(
            title: !_isSearching ? 'Transaction History' : '',
            showBackButton: !_isSearching,
            actions: [
              if (!_isSearching)
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                ),
              if (_isSearching)
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search by name or amount...',
                      hintStyle: const TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      prefixIcon: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _isSearching = false;
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
            ],
          ),
          _buildFilterChips(),
          Expanded(
            child: filteredTransactions.isEmpty
                ? _buildEmptyState()
                : _buildTransactionList(filteredTransactions),
          ),
        ],
      ),
    );
  }
  
  // Filter transactions based on selected filter and search query
  List<Map<String, dynamic>> _filterTransactions(List<Map<String, dynamic>> transactions) {
    // First filter by type (Payments/Receipts)
    List<Map<String, dynamic>> filtered = [];
    
    if (_selectedFilter == 'All') {
      filtered = transactions;
    } else if (_selectedFilter == 'Payments') {
      filtered = transactions.where((t) => t['type'] == 'gave').toList();
    } else if (_selectedFilter == 'Receipts') {
      filtered = transactions.where((t) => t['type'] == 'got').toList();
    }
    
    // Then apply search filter if any
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((t) {
        final name = (t['contactName'] ?? '').toString().toLowerCase();
        final amount = (t['amount'] ?? 0.0).toString();
        final note = (t['note'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery.toLowerCase()) || 
               amount.contains(_searchQuery) ||
               note.contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    return filtered;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history,
                size: 72,
                color: AppTheme.primaryColor.withAlpha(179),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Transactions Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Add some transactions to see your history',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTransactionList(List<Map<String, dynamic>> transactions) {
    return ListView.builder(
      itemCount: transactions.length,
      padding: const EdgeInsets.only(bottom: 16),
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionItem(transaction);
      },
    );
  }
  
  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    // Format transaction date
    final date = transaction['date'] as DateTime;
    final formattedDate = DateFormat('dd MMM yyyy').format(date);
    
    // Determine if this is a debit or credit transaction
    final isDebit = transaction['type'] == 'gave';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 2,
      shadowColor: AppTheme.primaryColor.withAlpha(77),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppTheme.primaryColor.withAlpha(25)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          _showTransactionDetails(context, transaction);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDebit 
                      ? Colors.red.withAlpha(25)
                      : Colors.green.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDebit ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isDebit ? Colors.red : Colors.green,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            transaction['contactName'] ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '₹${(transaction['amount'] as double).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDebit ? Colors.red : Colors.green,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isDebit ? 'You\'ll Get' : 'You\'ll Give',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDebit ? Colors.red : Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (transaction['note'] != null && transaction['note'].toString().isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              transaction['note'].toString(),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            spreadRadius: 1,
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            _buildFilterChip('All'),
            const SizedBox(width: 8),
            _buildFilterChip('Payments'),
            const SizedBox(width: 8),
            _buildFilterChip('Receipts'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
        });
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: AppTheme.primaryColor.withAlpha(51),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
        ),
      ),
    );
  }

  // Intentionally keeping this method for future use
  // ignore: unused_element
  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter By'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption('All Transactions', 'All'),
            const SizedBox(height: 8),
            _buildFilterOption('Payments Only', 'Payments'),
            const SizedBox(height: 8),
            _buildFilterOption('Receipts Only', 'Receipts'),
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
  
  Widget _buildFilterOption(String title, String value) {
    final isSelected = _selectedFilter == value;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withAlpha(25) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryColor : null,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetails(BuildContext context, Map<String, dynamic> transaction) {
    // Format date properly
    final date = transaction['date'] as DateTime;
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);
    final isDebit = transaction['type'] == 'gave';
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDebit 
                          ? Colors.red.withAlpha(25)
                          : Colors.green.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDebit ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isDebit ? Colors.red : Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDebit ? 'You\'ll Get' : 'You\'ll Give',
                          style: TextStyle(
                            color: isDebit ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${(transaction['amount'] as double).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildDetailRow('Contact', transaction['contactName'] ?? 'Unknown'),
              _buildDetailRow('Date', formattedDate),
              if (transaction['note'] != null && transaction['note'].toString().isNotEmpty)
                _buildDetailRow('Note', transaction['note'].toString()),
              if (transaction['isPaid'] != null)
                _buildDetailRow('Status', transaction['isPaid'] ? 'Paid' : 'Pending'),
              if (transaction['contactType'] != null && transaction['contactType'].toString().isNotEmpty)
                _buildDetailRow('Contact Type', transaction['contactType'].toString().capitalize()),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Intentionally keeping this method for future use
  // ignore: unused_element
  Future<void> _generatePdfReport() async {
    if (!mounted) return;
    
    // Get filtered transactions
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final allTransactions = transactionProvider.getAllTransactions();
    final filteredTransactions = _filterTransactions(allTransactions);
    
    if (filteredTransactions.isEmpty) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to generate report'))
      );
      return;
    }
    
    // Store context-dependent objects before any async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigatorState = Navigator.of(context);
    
    // Show a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating PDF report...'),
            ],
          ),
        );
      },
    );
    
    try {
      // Get application document directory for saving the PDF
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/transaction_history_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      // Call PDF Service to generate the PDF
      await PDFService.generateContactReport(
        filePath,
        'Transaction History',  // Title
        'All Transactions',     // Subtitle
        filteredTransactions,   // Transactions
        0.0,                    // Balance (not relevant for all transactions)
        0.0,                    // Interest rate (not relevant for all transactions)
        '',                     // Relationship type (not relevant for all transactions)
      );
      
      // Close loading dialog
      if (!mounted) return;
      navigatorState.pop();
      
      // Show success message with options
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Report Generated'),
              content: const Text('Your transaction report has been generated successfully.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Close'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Open the generated PDF
                    OpenFile.open(filePath);
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('View'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Share the generated PDF
                    _sharePdf(filePath);
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            );
          }
        );
      }
    } catch (e) {
      // Close loading dialog
      if (!mounted) return;
      navigatorState.pop();
      
      // Show error message
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e'))
        );
      }
    }
  }
  
  // Separate method for sharing to handle SharePlus deprecation
  void _sharePdf(String filePath) {
    final file = XFile(filePath);
    Share.shareXFiles([file], subject: 'Transaction History Report');
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
} 