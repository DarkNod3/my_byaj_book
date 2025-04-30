import 'package:flutter/material.dart';

class LoanSummaryCard extends StatelessWidget {
  final String userName;
  final int activeLoans;
  final double totalAmount;
  final double dueAmount;

  const LoanSummaryCard({
    Key? key,
    required this.userName,
    required this.activeLoans,
    required this.totalAmount,
    required this.dueAmount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get current month and year for the display
    final String monthYear = '${_getCurrentMonthName()} ${DateTime.now().year}';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade500,
            Colors.blue.shade700,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User greeting section - without icon
          Text(
            'Welcome, $userName',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Have a great day!',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Loan summary with month and year text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your loan summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                monthYear,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 10),
          
          // Loan details in row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetail('Active Loans', activeLoans.toString()),
              _buildDetail('Total Amount', '₹${_formatAmount(totalAmount)}'),
              _buildDetail('Due this month', '₹${_formatAmount(dueAmount)}'),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatAmount(double amount) {
    return amount.toInt().toString();
  }
  
  String _getCurrentMonthName() {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[DateTime.now().month - 1];
  }
} 