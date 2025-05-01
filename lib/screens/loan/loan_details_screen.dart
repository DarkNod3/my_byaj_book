import 'package:flutter/material.dart';
import '../../providers/loan_provider.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../utils/string_extensions.dart';
import 'add_loan_screen.dart';

class LoanDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> loanData;
  final int initialTab;

  const LoanDetailsScreen({
    Key? key,
    required this.loanData,
    this.initialTab = 0,
  }) : super(key: key);

  @override
  State<LoanDetailsScreen> createState() => _LoanDetailsScreenState();
}

class _LoanDetailsScreenState extends State<LoanDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _installments = [];
  int _paidInstallments = 0;
  bool _showAllInstallments = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    _generateInstallments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _generateInstallments() {
    final loanAmount = double.parse(widget.loanData['loanAmount'] ?? '50000');
    final interestRate = double.parse(widget.loanData['interestRate'] ?? '12.0') / 100;
    final loanTerm = int.parse(widget.loanData['loanTerm'] ?? '12');
    final startDate = widget.loanData['startDate'] ?? DateTime(2025, 4, 25);
    final firstPaymentDate = widget.loanData['firstPaymentDate'] ?? DateTime(2025, 5, 25);

    // Calculate EMI: P * r * (1+r)^n / ((1+r)^n - 1)
    final monthlyRate = interestRate / 12;
    final emi = loanAmount * monthlyRate * pow(1 + monthlyRate, loanTerm) / (pow(1 + monthlyRate, loanTerm) - 1);

    double remainingAmount = loanAmount;
    DateTime paymentDate = firstPaymentDate;

    for (int i = 0; i < loanTerm; i++) {
      final interestForMonth = remainingAmount * monthlyRate;
      final principalForMonth = emi - interestForMonth;
      
      remainingAmount -= principalForMonth;

      _installments.add({
        'installmentNumber': i + 1,
        'dueDate': paymentDate,
        'totalAmount': emi,
        'principal': principalForMonth,
        'interest': interestForMonth,
        'isPaid': false,
        'paidDate': null,
        'remainingAmount': remainingAmount > 0 ? remainingAmount : 0,
      });

      // Next payment date is one month later
      paymentDate = DateTime(
        paymentDate.year,
        paymentDate.month + 1,
        paymentDate.day,
      );
    }
  }

  void _markAsPaid(int index) {
    setState(() {
      _installments[index]['isPaid'] = true;
      _installments[index]['paidDate'] = DateTime.now();
      _paidInstallments++;
      
      // Update the loan data
      final loanProvider = Provider.of<LoanProvider>(context, listen: false);
      final updatedLoanData = Map<String, dynamic>.from(widget.loanData);
      updatedLoanData['installments'] = _installments;
      loanProvider.updateLoan(updatedLoanData);
    });
    
    // Show date picker to select payment date
    _selectPaymentDate(index);
  }

  void _undoPayment(int index) {
    setState(() {
      _installments[index]['isPaid'] = false;
      _installments[index]['paidDate'] = null;
      _paidInstallments--;
      
      // Update the loan data
      final loanProvider = Provider.of<LoanProvider>(context, listen: false);
      final updatedLoanData = Map<String, dynamic>.from(widget.loanData);
      updatedLoanData['installments'] = _installments;
      loanProvider.updateLoan(updatedLoanData);
    });
    
    // Show a confirmation snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment for Installment ${_installments[index]['installmentNumber']} was reset'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _selectPaymentDate(int index) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _installments[index]['paidDate'] ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _installments[index]['paidDate'] = picked;
        
        // Update the loan data with the new payment date
        final loanProvider = Provider.of<LoanProvider>(context, listen: false);
        final updatedLoanData = Map<String, dynamic>.from(widget.loanData);
        updatedLoanData['installments'] = _installments;
        loanProvider.updateLoan(updatedLoanData);
      });
    }
  }

  double _getTotalPaidAmount() {
    double total = 0;
    for (var installment in _installments) {
      if (installment['isPaid']) {
        total += installment['totalAmount'];
      }
    }
    return total;
  }

  double _getTotalRemainingAmount() {
    double total = 0;
    for (var installment in _installments) {
      if (!installment['isPaid']) {
        total += installment['totalAmount'];
      }
    }
    return total;
  }

  double _getTotalInterest() {
    double total = 0;
    for (var installment in _installments) {
      total += installment['interest'];
    }
    return total;
  }

  double get _progressPercentage {
    if (_installments.isEmpty) return 0.0;
    return _paidInstallments / _installments.length;
  }

  @override
  Widget build(BuildContext context) {
    final loanName = widget.loanData['loanName'] ?? 'Car Loan';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade600,
        elevation: 0,
        title: Text(
          loanName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
            ),
            onPressed: () => _showOptionsMenu(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'SUMMARY'),
            Tab(text: 'PAYMENTS'),
            Tab(text: 'DETAILS'),
          ],
        ),
      ),
      body: Container(
        color: Colors.blue.shade50.withOpacity(0.5),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildSummaryTab(),
            _buildPaymentsTab(),
            _buildDetailsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTab() {
    final totalEMIs = _installments.length;
    final loanAmount = double.parse(widget.loanData['loanAmount'] ?? '50000');
    final emi = _installments.isNotEmpty ? _installments[0]['totalAmount'] : 0.0;
    final paidSoFar = _getTotalPaidAmount();
    final remainingAmount = _getTotalRemainingAmount();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Loan Progress
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Loan Progress',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(_progressPercentage * 100).toStringAsFixed(1)}% Paid',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$_paidInstallments of $totalEMIs EMIs',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _progressPercentage,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(Colors.blue.shade600),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 24),
                  // Loan summary cards in grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          icon: Icons.account_balance,
                          iconColor: Colors.blue,
                          backgroundColor: Colors.blue.shade50,
                          title: 'Loan Amount',
                          amount: '₹${loanAmount.toStringAsFixed(2)}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          icon: Icons.calendar_today,
                          iconColor: Colors.purple,
                          backgroundColor: Colors.purple.shade50,
                          title: 'Monthly EMI',
                          amount: '₹${emi.toStringAsFixed(2)}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          icon: Icons.check_circle,
                          iconColor: Colors.green,
                          backgroundColor: Colors.green.shade50,
                          title: 'Paid So Far',
                          amount: '₹${paidSoFar.toStringAsFixed(2)}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          icon: Icons.timelapse,
                          iconColor: Colors.orange,
                          backgroundColor: Colors.orange.shade50,
                          title: 'Remaining',
                          amount: '₹${remainingAmount.toStringAsFixed(2)}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Upcoming payments
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upcoming Payments',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Show next 3 unpaid installments
                  Column(
                    children: _getUpcomingInstallments()
                        .take(3)
                        .map((installment) => _buildUpcomingPaymentItem(installment))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Payment breakdown
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Breakdown',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Payment breakdown table
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Principal',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        'Interest',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${loanAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹${_getTotalInterest().toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹${(loanAmount + _getTotalInterest()).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getUpcomingInstallments() {
    return _installments.where((installment) => !installment['isPaid']).toList();
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
    required String amount,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingPaymentItem(Map<String, dynamic> installment) {
    final installmentNumber = installment['installmentNumber'];
    final dueDate = installment['dueDate'] as DateTime;
    final amount = installment['totalAmount'] as double;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.calendar_today,
              color: Colors.blue.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Installment #$installmentNumber',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Due on ${dueDate.day} ${_getMonthShortName(dueDate.month)} ${dueDate.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Upcoming',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab() {
    final totalPayments = _installments.length;
    final displayCount = _showAllInstallments ? totalPayments : (totalPayments <= 10 ? totalPayments : 10);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Showing x of y payments
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing $displayCount of $totalPayments payments',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              if (totalPayments > 10) // Only show the button if there are more than 10 installments
                TextButton(
                  onPressed: () {
                    // Show all payments logic
                    setState(() {
                      _showAllInstallments = !_showAllInstallments;
                    });
                  },
                  child: Text(
                    _showAllInstallments ? 'Show Less' : 'Show All',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Payment cards
          Column(
            children: _installments
                .take(_showAllInstallments ? totalPayments : 10)
                .map((installment) => _buildPaymentCard(installment))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> installment) {
    final int index = _installments.indexOf(installment);
    final bool isPaid = installment['isPaid'] == true;
    final String formattedDueDate = _formatDate(installment['dueDate']);
    final String? formattedPaidDate = installment['paidDate'] != null 
        ? _formatDate(installment['paidDate']) 
        : null;
        
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPaid ? Colors.green.shade200 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Installment ${installment['installmentNumber']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPaid ? Colors.green.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPaid ? 'Paid' : 'Pending',
                    style: TextStyle(
                      color: isPaid ? Colors.green.shade800 : Colors.orange.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Amount',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${installment['totalAmount'].toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Due Date',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDueDate,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isPaid ? Colors.black87 : Colors.red,
                      ),
                    ),
                  ],
                ),
                if (isPaid && formattedPaidDate != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Paid On',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            formattedPaidDate,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _selectPaymentDate(index),
                            child: const Icon(
                              Icons.edit,
                              size: 14,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (!isPaid)
              ElevatedButton.icon(
                onPressed: () => _markAsPaid(index),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Mark as Paid'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _selectPaymentDate(index),
                      icon: const Icon(Icons.edit_calendar),
                      label: const Text('Edit Date'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        minimumSize: const Size(0, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _undoPayment(index),
                      icon: const Icon(Icons.undo),
                      label: const Text('Undo'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        minimumSize: const Size(0, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    final loanName = widget.loanData['loanName'] ?? 'Car Loan';
    final loanType = widget.loanData['loanType'] ?? 'Home Loan';
    final loanAmount = double.parse(widget.loanData['loanAmount'] ?? '50000');
    final interestRate = double.parse(widget.loanData['interestRate'] ?? '12.0');
    final loanTerm = int.parse(widget.loanData['loanTerm'] ?? '12');
    final startDate = widget.loanData['startDate'] ?? DateTime(2025, 4, 25);
    final firstPaymentDate = widget.loanData['firstPaymentDate'] ?? DateTime(2025, 5, 25);
    final emi = _installments.isNotEmpty ? _installments[0]['totalAmount'] : 0.0;
    final totalInterest = _getTotalInterest();
    final totalAmount = loanAmount + totalInterest;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Loan Details
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Loan Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildDetailRow('Loan Name', loanName),
                  _buildDetailRow('Loan Type', loanType),
                  _buildDetailRow('Loan Amount', '₹${loanAmount.toStringAsFixed(2)}'),
                  _buildDetailRow('Interest Rate', '${interestRate.toStringAsFixed(1)}% (Fixed)'),
                  _buildDetailRow('Loan Term', '$loanTerm months'),
                  _buildDetailRow('EMI Amount', '₹${emi.toStringAsFixed(2)}'),
                  _buildDetailRow('Total Interest', '₹${totalInterest.toStringAsFixed(2)}'),
                  _buildDetailRow('Total Amount', '₹${totalAmount.toStringAsFixed(2)}'),
                  _buildDetailRow(
                    'Start Date', 
                    '${startDate.day} ${_getMonthShortName(startDate.month)} ${startDate.year}'
                  ),
                  _buildDetailRow(
                    'First Payment', 
                    '${firstPaymentDate.day} ${_getMonthShortName(firstPaymentDate.month)} ${firstPaymentDate.year}'
                  ),
                  _buildDetailRow('Status', 'Active'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Payment Statistics
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Statistics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildDetailRow('Total EMIs', '${_installments.length}'),
                  _buildDetailRow('EMIs Paid', '$_paidInstallments'),
                  _buildDetailRow('EMIs Remaining', '${_installments.length - _paidInstallments}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: Colors.blue.shade700),
                title: const Text('Edit Loan'),
                onTap: () {
                  Navigator.pop(context);
                  _editLoan();
                },
              ),
              ListTile(
                leading: Icon(Icons.pause_circle_outline, color: Colors.orange.shade700),
                title: const Text('Mark as Inactive'),
                onTap: () {
                  Navigator.pop(context);
                  _markLoanAsInactive();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete Loan'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _markLoanAsInactive() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Mark Loan as Inactive'),
          content: const Text('Are you sure you want to mark this loan as inactive? You can reactivate it later from the archive.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                
                // Update loan status to inactive
                final loanProvider = Provider.of<LoanProvider>(context, listen: false);
                final updatedLoanData = Map<String, dynamic>.from(widget.loanData);
                updatedLoanData['status'] = 'Inactive';
                
                loanProvider.updateLoan(updatedLoanData);
                
                // Show confirmation and navigate back
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Loan marked as inactive'),
                    backgroundColor: Colors.blue,
                  ),
                );
                
                Navigator.pop(context, true); // Return to previous screen with refresh flag
              },
              child: const Text('CONFIRM'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Loan'),
          content: const Text('Are you sure you want to delete this loan? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteLoan();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );
  }
  
  void _deleteLoan() {
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);
    final loanId = widget.loanData['id'];
    
    // Delete the loan
    loanProvider.deleteLoan(loanId);
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Loan deleted successfully'),
        backgroundColor: Colors.red,
      ),
    );
    
    // Navigate back to previous screen
    Navigator.pop(context, true);
  }

  String _getMonthShortName(int month) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return monthNames[month - 1];
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day} ${_getMonthShortName(date.month)} ${date.year}';
  }

  void _updateLoanStatus() {
    _paidInstallments = _installments.where((inst) => inst['isPaid'] == true).length;
    
    // Update the loan provider
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);
    final updatedLoanData = Map<String, dynamic>.from(widget.loanData);
    updatedLoanData['installments'] = _installments;
    
    // Update progress
    final progress = _paidInstallments / _installments.length;
    updatedLoanData['progress'] = progress;
    
    // Update status if all installments are paid
    if (_paidInstallments == _installments.length) {
      updatedLoanData['status'] = 'Completed';
    }
    
    loanProvider.updateLoan(updatedLoanData);
  }

  void _editLoan() async {
    // Navigate to the add/edit loan screen with the current loan data
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddLoanScreen(
          isEditing: true,
          loanData: widget.loanData,
        ),
      ),
    );

    // If loan was edited successfully, refresh the screen
    if (result == true) {
      final loanProvider = Provider.of<LoanProvider>(context, listen: false);
      final updatedLoan = loanProvider.getLoanById(widget.loanData['id']);
      
      if (updatedLoan != null) {
        setState(() {
          // Update the installments based on the new loan data
          _installments = [];
          _generateInstallments();
          _updateLoanStatus();
        });
        
        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loan updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}

// Helper function for power calculation
double pow(double x, int y) {
  double result = 1.0;
  for (int i = 0; i < y; i++) {
    result *= x;
  }
  return result;
} 