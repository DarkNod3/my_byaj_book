import 'package:flutter/material.dart';
import 'package:my_byaj_book/constants/app_theme.dart';
import 'package:my_byaj_book/widgets/header/app_header.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'All';

  // Sample data - in a real app, this would come from a provider or service
  final List<Map<String, dynamic>> _transactions = [
    {
      'id': '1',
      'title': 'Home Loan EMI Payment',
      'amount': '₹12,500',
      'date': '15 April 2025',
      'type': 'Payment',
      'isCredit': false,
      'category': 'Loan',
    },
    {
      'id': '2',
      'title': 'Car Loan EMI',
      'amount': '₹8,200',
      'date': '10 April 2025',
      'type': 'Payment',
      'isCredit': false,
      'category': 'Loan',
    },
    {
      'id': '3',
      'title': 'Loan Repayment Received',
      'amount': '₹5,000',
      'date': '05 April 2025',
      'type': 'Receipt',
      'isCredit': true,
      'category': 'Loan',
    },
    {
      'id': '4',
      'title': 'Credit Card Bill Payment',
      'amount': '₹15,700',
      'date': '02 April 2025',
      'type': 'Payment',
      'isCredit': false,
      'category': 'Card',
    },
    {
      'id': '5',
      'title': 'Interest Earned',
      'amount': '₹2,500',
      'date': '01 April 2025',
      'type': 'Receipt',
      'isCredit': true,
      'category': 'Interest',
    },
    {
      'id': '6',
      'title': 'Personal Loan EMI',
      'amount': '₹5,200',
      'date': '28 March 2025',
      'type': 'Payment',
      'isCredit': false,
      'category': 'Loan',
    },
    {
      'id': '7',
      'title': 'Credit Card Purchase',
      'amount': '₹3,800',
      'date': '25 March 2025',
      'type': 'Purchase',
      'isCredit': false,
      'category': 'Card',
    },
  ];

  List<Map<String, dynamic>> get filteredTransactions {
    if (_selectedFilter == 'All') {
      return _transactions;
    } else if (_selectedFilter == 'Payments') {
      return _transactions.where((t) => t['type'] == 'Payment').toList();
    } else if (_selectedFilter == 'Receipts') {
      return _transactions.where((t) => t['type'] == 'Receipt').toList();
    } else if (_selectedFilter == 'Cards') {
      return _transactions.where((t) => t['category'] == 'Card').toList();
    } else {
      return _transactions.where((t) => t['category'] == 'Loan').toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Transaction History',
            showBackButton: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list, color: Colors.white),
                onPressed: () {
                  _showFilterDialog(context);
                },
              ),
            ],
          ),
          _buildFilterChips(),
          Expanded(
            child: filteredTransactions.isEmpty
                ? const Center(
                    child: Text(
                      'No transactions to show',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = filteredTransactions[index];
                      return _buildTransactionItem(transaction);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
            const SizedBox(width: 8),
            _buildFilterChip('Loans'),
            const SizedBox(width: 8),
            _buildFilterChip('Cards'),
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
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
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

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          _showTransactionDetails(context, transaction);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: transaction['isCredit'] 
                      ? Colors.green.withOpacity(0.1) 
                      : Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconForTransaction(transaction),
                  color: transaction['isCredit'] ? Colors.green : Colors.red,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          transaction['date'],
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            transaction['type'],
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                transaction['amount'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: transaction['isCredit'] ? Colors.green : Colors.red,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForTransaction(Map<String, dynamic> transaction) {
    if (transaction['category'] == 'Card') {
      return Icons.credit_card;
    } else if (transaction['category'] == 'Loan') {
      return transaction['isCredit'] 
          ? Icons.arrow_downward 
          : Icons.arrow_upward;
    } else if (transaction['category'] == 'Interest') {
      return Icons.attach_money;
    } else {
      return Icons.swap_horiz;
    }
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Transactions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Transactions'),
              leading: Radio<String>(
                value: 'All',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                  Navigator.pop(context);
                },
                activeColor: AppTheme.primaryColor,
              ),
            ),
            ListTile(
              title: const Text('Payments Only'),
              leading: Radio<String>(
                value: 'Payments',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                  Navigator.pop(context);
                },
                activeColor: AppTheme.primaryColor,
              ),
            ),
            ListTile(
              title: const Text('Receipts Only'),
              leading: Radio<String>(
                value: 'Receipts',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                  Navigator.pop(context);
                },
                activeColor: AppTheme.primaryColor,
              ),
            ),
            ListTile(
              title: const Text('Loans Only'),
              leading: Radio<String>(
                value: 'Loans',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                  Navigator.pop(context);
                },
                activeColor: AppTheme.primaryColor,
              ),
            ),
            ListTile(
              title: const Text('Cards Only'),
              leading: Radio<String>(
                value: 'Cards',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                  Navigator.pop(context);
                },
                activeColor: AppTheme.primaryColor,
              ),
            ),
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

  void _showTransactionDetails(BuildContext context, Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transaction Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Transaction ID', '#${transaction['id']}'),
            _buildDetailRow('Title', transaction['title']),
            _buildDetailRow('Amount', transaction['amount']),
            _buildDetailRow('Date', transaction['date']),
            _buildDetailRow('Type', transaction['type']),
            _buildDetailRow('Category', transaction['category']),
            _buildDetailRow('Status', 'Completed'),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
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
} 