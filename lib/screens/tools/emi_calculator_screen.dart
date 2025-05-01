import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:my_byaj_book/widgets/header/app_header.dart';

class EmiCalculatorScreen extends StatefulWidget {
  static const routeName = '/emi-calculator';
  final bool showAppBar;
  
  const EmiCalculatorScreen({super.key, this.showAppBar = true});

  @override
  State<EmiCalculatorScreen> createState() => _EmiCalculatorScreenState();
}

class _EmiCalculatorScreenState extends State<EmiCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loanAmountController = TextEditingController(text: '100000');
  final _interestRateController = TextEditingController(text: '10.5');
  final _loanTenureController = TextEditingController(text: '24');

  int _selectedTenureType = 1; // 0: Years, 1: Months
  double _emiAmount = 0;
  double _totalInterest = 0;
  double _totalAmount = 0;
  bool _showResult = true; // Always show results
  
  // Format currency in Indian Rupees
  final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  
  // Alternative formatter to ensure proper Rupee symbol
  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},'
    )}';
  }
  
  // Payment schedule for amortization table
  List<Map<String, dynamic>> _paymentSchedule = [];

  @override
  void initState() {
    super.initState();
    // Calculate EMI automatically on init
    _calculateEMI();
  }

  @override
  void dispose() {
    _loanAmountController.dispose();
    _interestRateController.dispose();
    _loanTenureController.dispose();
    super.dispose();
  }

  void _calculateEMI() {
    // Calculate even if validation fails to give immediate feedback
    double principal = 0;
    double rate = 0;
    int tenure = 0;
    
    try {
      // Safely parse principal with validation
      if (_loanAmountController.text.isNotEmpty) {
        principal = double.tryParse(_loanAmountController.text) ?? 100000;
      } else {
        principal = 100000; // Default
      }
      
      // Safely parse interest rate with validation
      if (_interestRateController.text.isNotEmpty) {
        rate = double.tryParse(_interestRateController.text) ?? 10.5;
      } else {
        rate = 10.5; // Default
      }
      
      rate = rate / 12 / 100; // Monthly interest rate
      
      // Safely parse tenure with validation
      if (_loanTenureController.text.isNotEmpty) {
        tenure = int.tryParse(_loanTenureController.text) ?? 24;
      } else {
        tenure = 24; // Default
      }
      
      // Convert years to months if years is selected
      if (_selectedTenureType == 0) {
        tenure = tenure * 12;
      }

      // Ensure tenure is at least 1 month
      tenure = tenure.clamp(1, 1000);

      // EMI calculation formula: P * r * (1 + r)^n / ((1 + r)^n - 1)
      double emi = 0;
      if (rate > 0) {
        emi = principal * rate * pow(1 + rate, tenure) / (pow(1 + rate, tenure) - 1);
      } else {
        // For 0% interest rate
        emi = principal / tenure;
      }
      
      double totalAmount = emi * tenure;
      double totalInterest = totalAmount - principal;

      // Generate payment schedule
      _generatePaymentSchedule(principal, rate, tenure, emi);

      setState(() {
        _emiAmount = emi;
        _totalInterest = totalInterest;
        _totalAmount = totalAmount;
        _showResult = true;
      });
    } catch (e) {
      // If any calculation fails, use default values
      setState(() {
        _emiAmount = 0;
        _totalInterest = 0;
        _totalAmount = 0;
        _paymentSchedule = [];
        _showResult = true;
      });
      print('Calculation error: $e');
    }
  }
  
  void _generatePaymentSchedule(double principal, double rate, int tenure, double emi) {
    _paymentSchedule = [];
    double balance = principal;
    double totalPrincipal = 0;
    double totalInterest = 0;
    
    // Reset the schedule
    _paymentSchedule.clear();
    
    for (int i = 1; i <= tenure; i++) {
      // Calculate interest for this month
      double interest = balance * rate;
      
      // Calculate principal for this month
      double monthlyPrincipal = emi - interest;
      
      // Update remaining balance
      balance = balance - monthlyPrincipal;
      if (balance < 0) balance = 0; // Ensure balance doesn't go negative
      
      // Update totals
      totalPrincipal += monthlyPrincipal;
      totalInterest += interest;
      
      // Add to payment schedule
      _paymentSchedule.add({
        'month': i,
        'payment': emi,
        'principal': monthlyPrincipal,
        'interest': interest,
        'balance': balance,
        'totalPrincipal': totalPrincipal,
        'totalInterest': totalInterest,
      });
    }
  }

  Future<void> _generatePDF() async {
    final pdf = pw.Document();
    
    // Create a currency format without the rupee symbol for the PDF report
    final pdfCurrencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '',  // Empty symbol
      decimalDigits: 0,
    );
    
    // Get basic loan details for the report
    double principal = double.tryParse(_loanAmountController.text) ?? 100000;
    double interestRate = double.tryParse(_interestRateController.text) ?? 10.5;
    int tenure = int.tryParse(_loanTenureController.text) ?? 24;
    String tenureType = _selectedTenureType == 0 ? 'Years' : 'Months';
    
    // Create a PDF document
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Text(
              'EMI Calculation Report',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          );
        },
        footer: (pw.Context context) {
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
        },
        build: (pw.Context context) {
          return [
            // Loan Summary Section
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 1),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Loan Summary',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 15),
                  _buildPdfSummaryRow('Loan Amount', pdfCurrencyFormat.format(principal)),
                  _buildPdfSummaryRow('Interest Rate', '$interestRate% per annum'),
                  _buildPdfSummaryRow('Loan Tenure', '$tenure $tenureType'),
                  _buildPdfSummaryRow('Monthly EMI', pdfCurrencyFormat.format(_emiAmount)),
                  _buildPdfSummaryRow('Total Interest', pdfCurrencyFormat.format(_totalInterest)),
                  _buildPdfSummaryRow('Total Payment', pdfCurrencyFormat.format(_totalAmount)),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Payment Schedule Section
            pw.Text(
              'Payment Schedule',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            
            // Payment Schedule Table
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(2),
              },
              children: [
                // Table Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _buildPdfTableHeader('Month'),
                    _buildPdfTableHeader('EMI'),
                    _buildPdfTableHeader('Principal'),
                    _buildPdfTableHeader('Interest'),
                    _buildPdfTableHeader('Balance'),
                  ],
                ),
                
                // Table Rows (first 12 months or less)
                ..._paymentSchedule.take(12).map((payment) {
                  return pw.TableRow(
                    children: [
                      _buildPdfTableCell('${payment['month']}'),
                      _buildPdfTableCell(pdfCurrencyFormat.format(payment['payment'])),
                      _buildPdfTableCell(pdfCurrencyFormat.format(payment['principal'])),
                      _buildPdfTableCell(pdfCurrencyFormat.format(payment['interest'])),
                      _buildPdfTableCell(pdfCurrencyFormat.format(payment['balance'])),
                    ],
                  );
                }).toList(),
              ],
            ),
            
            pw.SizedBox(height: 20),
            
            // Note about complete schedule
            pw.Text(
              'Note: This is a summary of your first 12 monthly payments. The complete payment schedule is available upon request.',
              style: const pw.TextStyle(
                fontSize: 10,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Disclaimer
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
              child: pw.Text(
                'Disclaimer: This is an approximate calculation and may vary from the actual EMI charged by financial institutions. Factors such as processing fees, insurance premiums, and other charges are not included in this calculation.',
                style: const pw.TextStyle(
                  fontSize: 10,
                ),
              ),
            ),
          ];
        },
      ),
    );
    
    try {
      // Save the PDF
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/emi_calculation_report.pdf');
      await file.writeAsBytes(await pdf.save());
      
      // Open the PDF
      await OpenFile.open(file.path);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF report generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  pw.Widget _buildPdfSummaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  pw.Widget _buildPdfTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 10,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }
  
  pw.Widget _buildPdfTableCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  void _resetCalculator() {
    _loanAmountController.text = '100000';
    _interestRateController.text = '10.5';
    _loanTenureController.text = '24';
    _selectedTenureType = 1;
    
    // Recalculate immediately after reset
    _calculateEMI();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar ? AppHeader(
        title: 'EMI Calculator',
        showBackButton: true,
        showMenuIcon: false,
      ) : null,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Form(
            key: _formKey,
            onChanged: _calculateEMI, // Recalculate on any form change
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildResultCard(),
                const SizedBox(height: 16),
                _buildCalculatorCard(),
                const SizedBox(height: 16),
                _buildPdfButton(),
                const SizedBox(height: 16),
                _buildPaymentSchedule(),
                const SizedBox(height: 16),
                _buildBreakdownCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalculatorCard() {
    // Get the actual tenure in months for display
    int actualTenureInMonths = _selectedTenureType == 0 
        ? int.tryParse(_loanTenureController.text) != null 
            ? int.parse(_loanTenureController.text) * 12 
            : 0
        : int.tryParse(_loanTenureController.text) ?? 0;
        
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
            const SizedBox(height: 4),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Adjust your loan parameters and see results instantly',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (_selectedTenureType == 0 && actualTenureInMonths > 0)
                  Text(
                    '($actualTenureInMonths months)',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Loan Amount with Reset button
            Row(
              children: [
                // Loan Amount (80%)
                Expanded(
                  flex: 80,
                  child: TextField(
                    controller: _loanAmountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Loan Amount (₹)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.currency_rupee),
                      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    ),
                    onChanged: (_) => _calculateEMI(),
                  ),
                ),
                const SizedBox(width: 8),
                // Reset button (20%)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: _resetCalculator,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Interest Rate
            TextField(
              controller: _interestRateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Interest Rate (% p.a.)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.percent),
                contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              ),
              onChanged: (_) => _calculateEMI(),
            ),
            const SizedBox(height: 16),
            
            // Loan Tenure
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _loanTenureController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Loan Tenure',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.calendar_today),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      hintText: _selectedTenureType == 0 ? 'Enter years' : 'Enter months',
                    ),
                    onChanged: (_) => _calculateEMI(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedTenureType,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('Years')),
                          DropdownMenuItem(value: 1, child: Text('Months')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedTenureType = value;
                              _calculateEMI();
                            });
                          }
                        },
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

  Widget _buildResultCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade600, Colors.blue.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Your Monthly EMI',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currencyFormat.format(_emiAmount),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildResultDetail(
                  title: 'Principal',
                  value: _currencyFormat.format(double.tryParse(_loanAmountController.text) ?? 0),
                ),
                _buildResultDetail(
                  title: 'Interest',
                  value: _currencyFormat.format(_totalInterest),
                ),
                _buildResultDetail(
                  title: 'Total Amount',
                  value: _currencyFormat.format(_totalAmount),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultDetail({
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPdfButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _generatePDF,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('GENERATE PDF REPORT'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildPaymentSchedule() {
    // Get the input tenure for the description
    String tenureInput = _loanTenureController.text.isEmpty ? '0' : _loanTenureController.text;
    String tenureDescription = _selectedTenureType == 0 
        ? '$tenureInput years (${int.tryParse(tenureInput) != null ? int.parse(tenureInput) * 12 : 0} months)' 
        : '$tenureInput months';
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Schedule',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Loan tenure: $tenureDescription',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _generatePDF,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Download PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  _buildTableHeader('#', flex: 1),
                  _buildTableHeader('EMI', flex: 2),
                  _buildTableHeader('Principal', flex: 2),
                  _buildTableHeader('Interest', flex: 2),
                  _buildTableHeader('Balance', flex: 2),
                ],
              ),
            ),
          ),
          // Table rows
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5, // Increased height to accommodate more entries
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: _paymentSchedule.length, // Show all entries, removed the clamp
              itemBuilder: (context, index) {
                final payment = _paymentSchedule[index];
                return Container(
                  decoration: BoxDecoration(
                    color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        _buildTableCell('${payment['month']}', flex: 1),
                        _buildTableCell(_currencyFormat.format(payment['payment']), flex: 2),
                        _buildTableCell(_currencyFormat.format(payment['principal']), flex: 2),
                        _buildTableCell(_currencyFormat.format(payment['interest']), flex: 2),
                        _buildTableCell(_currencyFormat.format(payment['balance']), flex: 2),
                      ],
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

  Widget _buildTableHeader(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildBreakdownCard() {
    // Calculate the principal and interest ratio for the pie chart
    double principal = double.parse(_loanAmountController.text);
    double principalRatio = principal / _totalAmount;
    double interestRatio = _totalInterest / _totalAmount;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Loan Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBreakdownItem(
                        title: 'Principal Amount',
                        value: _currencyFormat.format(principal),
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _buildBreakdownItem(
                        title: 'Total Interest',
                        value: _currencyFormat.format(_totalInterest),
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      _buildBreakdownItem(
                        title: 'Total Amount',
                        value: _currencyFormat.format(_totalAmount),
                        color: Colors.green,
                        isBold: true,
                      ),
                      const SizedBox(height: 12),
                      _buildBreakdownItem(
                        title: 'Interest to Principal Ratio',
                        value: '${(_totalInterest / principal * 100).toStringAsFixed(2)}%',
                        color: Colors.purple,
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Stack(
                      children: [
                        // Simple pie chart representation
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(principalRatio * 100).toStringAsFixed(0)}%',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(interestRatio * 100).toStringAsFixed(0)}%',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLegendItem(
                      color: Colors.blue,
                      label: 'Principal',
                      percentage: '${(principalRatio * 100).toStringAsFixed(0)}%',
                    ),
                    _buildLegendItem(
                      color: Colors.orange,
                      label: 'Interest',
                      percentage: '${(interestRatio * 100).toStringAsFixed(0)}%',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItem({
    required String title,
    required String value,
    required Color color,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String percentage,
  }) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label ($percentage)',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
} 