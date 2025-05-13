import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:my_byaj_book/services/pdf_template_service.dart';
import '../../widgets/safe_area_wrapper.dart';

class SipCalculatorScreen extends StatefulWidget {
  static const routeName = '/sip-calculator';
  
  final bool showAppBar;
  
  const SipCalculatorScreen({
    super.key, 
    this.showAppBar = true
  });

  @override
  State<SipCalculatorScreen> createState() => _SipCalculatorScreenState();
}

class _SipCalculatorScreenState extends State<SipCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _monthlyInvestmentController = TextEditingController(text: '5000');
  final _expectedReturnController = TextEditingController(text: '12');
  final _investmentPeriodController = TextEditingController(text: '10');

  double _totalInvestment = 0;
  double _estimatedReturns = 0;
  double _maturityValue = 0;
  // ignore: unused_field
  bool _isGeneratingPdf = false; // Added state variable for PDF generation
  
  // Format currency in Indian Rupees
  final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs. ',
    decimalDigits: 0,
  );
  
  // Investment schedule for the table
  List<Map<String, dynamic>> _investmentSchedule = [];

  @override
  void initState() {
    super.initState();
    // Calculate SIP returns automatically on init
    _calculateSIP();
  }

  @override
  void dispose() {
    _monthlyInvestmentController.dispose();
    _expectedReturnController.dispose();
    _investmentPeriodController.dispose();
    super.dispose();
  }

  void _calculateSIP() {
    try {
      // Check validations first
      String? monthlyInvestmentError = _validateMonthlyInvestment();
      String? investmentPeriodError = _validateInvestmentPeriod();
      
      // If validation fails, don't proceed with calculation but keep existing values
      if (monthlyInvestmentError != null || investmentPeriodError != null) {
        setState(() {}); // Just update the UI to show error messages
        return;
      }
      
      // Safe parsing of values with defaults
      double monthlyInvestment = _monthlyInvestmentController.text.isEmpty 
          ? 5000 : double.tryParse(_monthlyInvestmentController.text) ?? 5000;
      
      double expectedReturnRate = _expectedReturnController.text.isEmpty 
          ? 12 : double.tryParse(_expectedReturnController.text) ?? 12;
      
      int investmentPeriodYears = _investmentPeriodController.text.isEmpty 
          ? 10 : int.tryParse(_investmentPeriodController.text) ?? 10;

      // Convert yearly rate to monthly
      double monthlyRate = expectedReturnRate / 12 / 100;
      
      // Calculate total months
      int totalMonths = investmentPeriodYears * 12;
      
      // Calculate maturity value using SIP formula: P × ({[1 + i]^n - 1} / i) × (1 + i)
      // Where P is monthly investment, i is monthly interest rate, n is number of payments
      double maturityValue = 0;
      
      if (monthlyRate > 0) {
        maturityValue = monthlyInvestment * 
            ((pow(1 + monthlyRate, totalMonths) - 1) / monthlyRate) * 
            (1 + monthlyRate);
      } else {
        // For 0% return rate
        maturityValue = monthlyInvestment * totalMonths;
      }
      
      double totalInvestment = monthlyInvestment * totalMonths;
      double totalReturns = maturityValue - totalInvestment;

      // Generate investment schedule
      _generateInvestmentSchedule(
        monthlyInvestment, 
        monthlyRate, 
        totalMonths
      );

      setState(() {
        _totalInvestment = totalInvestment;
        _estimatedReturns = totalReturns;
        _maturityValue = maturityValue;
      });
    } catch (e) {
      // Set defaults if calculation fails
      setState(() {
        _totalInvestment = 0;
        _estimatedReturns = 0;
        _maturityValue = 0;
        _investmentSchedule = [];
      });
    }
  }
  
  void _generateInvestmentSchedule(double monthlyInvestment, double monthlyRate, int totalMonths) {
    // Reset schedule
    _investmentSchedule = [];
    
    double investedAmount = 0;
    double estimatedReturns = 0;
    
    // Generate yearly reports (not monthly to keep it concise)
    for (int year = 1; year <= (totalMonths / 12).ceil(); year++) {
      // Calculate values at the end of each year
      int monthsCompleted = year * 12 > totalMonths ? totalMonths : year * 12;
      
      // Calculate invested amount
      investedAmount = monthlyInvestment * monthsCompleted;
      
      // Calculate estimated returns using SIP formula
      double estimatedValue = 0;
      if (monthlyRate > 0) {
        estimatedValue = monthlyInvestment * 
            ((pow(1 + monthlyRate, monthsCompleted) - 1) / monthlyRate) * 
            (1 + monthlyRate);
      } else {
        estimatedValue = investedAmount;
      }
      
      estimatedReturns = estimatedValue - investedAmount;
      
      // Add to schedule
      _investmentSchedule.add({
        'year': year,
        'investedAmount': investedAmount,
        'estimatedReturns': estimatedReturns,
        'estimatedValue': estimatedValue,
      });
    }
  }

  // ignore: unused_element
  Future<void> _generatePdfReport() async {
    try {
      setState(() {
        _isGeneratingPdf = true;
      });
      
      // Recalculate values based on current inputs to ensure latest data
      _calculateSIP();
      
      // Create PDF content with current values
      final content = await _createPdfContent();
      
      // Create a unique filename with date, time, and random component
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final random = DateTime.now().millisecondsSinceEpoch % 10000; // Add random component
      final fileName = 'sip_report_${timestamp}_$random.pdf';
      
      // Create the PDF
      final pdf = await PdfTemplateService.createDocument(
        title: 'SIP Calculator',
        subtitle: 'Investment Report',
        content: content,
      );
      
      // Save and open the PDF
      await PdfTemplateService.saveAndOpenPdf(pdf, fileName);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PDF report generated successfully!'),
                const SizedBox(height: 4),
                Text(
                  'Filename: $fileName',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  double _calculateSIPValue(double monthlyInvestment, double expectedReturn, int year) {
    // Calculate the SIP maturity value for a specific year
    double monthlyRate = expectedReturn / (12 * 100);
    int months = year * 12;
    
    // Formula: P × ((1 + r)^n - 1) / r × (1 + r)
    return monthlyInvestment * ((pow(1 + monthlyRate, months) - 1) / monthlyRate) * (1 + monthlyRate);
  }

  void _resetCalculator() {
    _monthlyInvestmentController.text = '5000';
    _expectedReturnController.text = '12';
    _investmentPeriodController.text = '10';
    
    // Recalculate immediately after reset
    _calculateSIP();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar ? AppBar(
        title: const Text('SIP Calculator'),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
      ) : null,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Form(
            key: _formKey,
            onChanged: _calculateSIP, // Recalculate on any form change
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildResultCard(),
                const SizedBox(height: 16),
                _buildCalculatorCard(),
                const SizedBox(height: 16),
                _buildInvestmentSchedule(),
                const SizedBox(height: 16),
                _buildBreakdownCard(),
              ],
            ),
          ),
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
            colors: [Colors.indigo.shade600, Colors.indigo.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Expected Maturity Value',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 280,
                maxWidth: double.infinity,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    _currencyFormat.format(_maturityValue),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildResultDetail(
                  title: 'Invested',
                  value: _currencyFormat.format(_totalInvestment),
                ),
                _buildResultDetail(
                  title: 'Returns',
                  value: _currencyFormat.format(_estimatedReturns),
                ),
                _buildResultDetail(
                  title: 'Growth',
                  value: _totalInvestment > 0 
                      ? '${((_estimatedReturns / _totalInvestment) * 100).toStringAsFixed(1)}%' 
                      : '0%',
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
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 70),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorCard() {
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
              'Investment Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Adjust parameters to see how your investment could grow',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            
            // Monthly Investment with Reset button
            Row(
              children: [
                // Monthly Investment (80%)
                Expanded(
                  flex: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                    controller: _monthlyInvestmentController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                      labelText: 'Monthly Investment (₹)',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.currency_rupee),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          errorText: _validateMonthlyInvestment(),
                    ),
                    onChanged: (_) => _calculateSIP(),
                      ),
                    ],
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
            
            // Expected Return Rate
            TextField(
              controller: _expectedReturnController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Expected Return Rate (% p.a.)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.percent),
                contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              ),
              onChanged: (_) => _calculateSIP(),
            ),
            const SizedBox(height: 16),
            
            // Investment Period
            TextField(
              controller: _investmentPeriodController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Investment Period (Years)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.calendar_today),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                errorText: _validateInvestmentPeriod(),
              ),
              onChanged: (_) => _calculateSIP(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestmentSchedule() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Year-wise Growth',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
                  _buildTableHeader('Year', flex: 1),
                  _buildTableHeader('Invested', flex: 2),
                  _buildTableHeader('Returns', flex: 2),
                  _buildTableHeader('Value', flex: 2),
                ],
              ),
            ),
          ),
          // Table rows
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.3,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: _investmentSchedule.length,
              itemBuilder: (context, index) {
                final investment = _investmentSchedule[index];
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
                        _buildTableCell('${investment['year']}', flex: 1),
                        _buildTableCell(_currencyFormat.format(investment['investedAmount']), flex: 2),
                        _buildTableCell(_currencyFormat.format(investment['estimatedReturns']), flex: 2),
                        _buildTableCell(_currencyFormat.format(investment['estimatedValue']), flex: 2),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 50),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBreakdownCard() {
    // Calculate the percentage of invested amount and returns
    double investedPercent = 0;
    double returnsPercent = 0;
    
    if (_maturityValue > 0) {
      investedPercent = _totalInvestment / _maturityValue;
      returnsPercent = _estimatedReturns / _maturityValue;
    }

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
              'Investment Breakdown',
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
                        title: 'Total Investment',
                        value: _currencyFormat.format(_totalInvestment),
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _buildBreakdownItem(
                        title: 'Estimated Returns',
                        value: _currencyFormat.format(_estimatedReturns),
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      _buildBreakdownItem(
                        title: 'Maturity Value',
                        value: _currencyFormat.format(_maturityValue),
                        color: Colors.green,
                        isBold: true,
                      ),
                      const SizedBox(height: 12),
                      _buildBreakdownItem(
                        title: 'Wealth Gain Ratio',
                        value: _totalInvestment > 0 
                            ? '${(_estimatedReturns / _totalInvestment).toStringAsFixed(2)}x' 
                            : '0x',
                        color: Colors.purple,
                      ),
                    ],
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
                      label: 'Investment',
                      percentage: '${(investedPercent * 100).toStringAsFixed(0)}%',
                    ),
                    _buildLegendItem(
                      color: Colors.orange,
                      label: 'Returns',
                      percentage: '${(returnsPercent * 100).toStringAsFixed(0)}%',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'The power of compounding helps your money grow over time. Start early to maximize your returns.',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
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
        Expanded(
          flex: 2,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 100),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: color,
                  fontSize: isBold ? 16 : 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
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

  String? _validateMonthlyInvestment() {
    try {
      double? amount = double.tryParse(_monthlyInvestmentController.text);
      if (amount != null && amount > 10000000) { // 1 Crore = 10,000,000
        return 'Amount cannot exceed 1 Crore (₹1,00,00,000)';
      }
    } catch (_) {}
    return null; // Return null if validation passes
  }

  String? _validateInvestmentPeriod() {
    try {
      int? years = int.tryParse(_investmentPeriodController.text);
      if (years != null && years > 50) {
        return 'Investment period cannot exceed 50 years';
      }
    } catch (_) {}
    return null; // Return null if validation passes
  }

  // ignore: unused_element
  Future<List<pw.Widget>> _createPdfContent() async {
    // Get values from current state or calculate them fresh
    final double monthlyInvestment = double.tryParse(_monthlyInvestmentController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    final int years = int.tryParse(_investmentPeriodController.text) ?? 0;
    final double expectedReturn = double.tryParse(_expectedReturnController.text) ?? 0;
    
    // Calculate key values
    final double totalInvested = monthlyInvestment * 12 * years;
    final double totalValue = _calculateSIPValue(monthlyInvestment, expectedReturn, years);
    final double estimatedReturns = totalValue - totalInvested;
    final double growthPercentage = totalInvested > 0 ? (estimatedReturns / totalInvested) * 100 : 0;
    
    // Prepare summary data - ensure we use "Rs." instead of rupee symbol
    final List<Map<String, dynamic>> summaryItems = [
      {'label': 'Monthly Investment', 'value': 'Rs. ${PdfTemplateService.formatCurrency(monthlyInvestment)}'},
      {'label': 'Time Period', 'value': '$years Years'},
      {'label': 'Expected Return', 'value': '$expectedReturn% p.a.'},
      {'label': 'Total Amount Invested', 'value': 'Rs. ${PdfTemplateService.formatCurrency(totalInvested)}'},
      {
        'label': 'Estimated Returns', 
        'value': 'Rs. ${PdfTemplateService.formatCurrency(estimatedReturns)}',
        'highlight': true,
        'isPositive': true,
      },
      {
        'label': 'Growth Percentage', 
        'value': '${growthPercentage.toStringAsFixed(1)}%',
        'highlight': true,
        'isPositive': true,
      },
      {
        'label': 'Total Maturity Value', 
        'value': 'Rs. ${PdfTemplateService.formatCurrency(totalValue)}',
        'highlight': true,
        'isPositive': true,
      },
    ];
    
    // Prepare yearly breakdown table
    final List<String> tableColumns = ['Year', 'Amount Invested', 'Est. Returns', 'Total Value'];
    final List<List<String>> tableRows = [];
    
    // Add yearly breakdown data - ensure we use "Rs." instead of rupee symbol
    for (int year = 1; year <= years; year++) {
      final double amountInvested = monthlyInvestment * 12 * year;
      final double totalValue = _calculateSIPValue(monthlyInvestment, expectedReturn, year);
      final double estimatedReturns = totalValue - amountInvested;
      
      tableRows.add([
        year.toString(),
        'Rs. ${PdfTemplateService.formatCurrency(amountInvested)}',
        'Rs. ${PdfTemplateService.formatCurrency(estimatedReturns)}',
        'Rs. ${PdfTemplateService.formatCurrency(totalValue)}',
      ]);
    }
    
    // Create PDF content
    return [
      // SIP Summary
      PdfTemplateService.buildSummaryCard(
        title: 'SIP Investment Summary',
        items: summaryItems,
      ),
      
      pw.SizedBox(height: 20),
      
      // Yearly breakdown table
      PdfTemplateService.buildDataTable(
        title: 'Year-wise Breakdown',
        columns: tableColumns,
        rows: tableRows,
      ),
      
      pw.SizedBox(height: 20),
      
      // Add an investment breakdown chart explanation
      pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: const pw.BoxDecoration(
          color: PdfTemplateService.lightBackgroundColor,
          borderRadius: PdfTemplateService.roundedBorder,
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Investment Breakdown',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfTemplateService.primaryColor,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Total Investment: Rs. ${PdfTemplateService.formatCurrency(totalInvested)}'),
                    pw.SizedBox(height: 4),
                    pw.Text('Estimated Returns: Rs. ${PdfTemplateService.formatCurrency(estimatedReturns)}'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Investment: ${(totalInvested / totalValue * 100).toStringAsFixed(0)}%'),
                    pw.SizedBox(height: 4),
                    pw.Text('Returns: ${(estimatedReturns / totalValue * 100).toStringAsFixed(0)}%'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      
      pw.SizedBox(height: 20),
      
      // Disclaimer
      pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: const pw.BoxDecoration(
          color: PdfTemplateService.lightBackgroundColor,
          borderRadius: PdfTemplateService.roundedBorder,
        ),
        child: pw.Text(
          'Disclaimer: This is only an illustrative example. Actual returns may vary depending on market conditions and may not be guaranteed. Please consult a financial advisor before making investment decisions.',
          style: const pw.TextStyle(
            fontSize: 10,
          ),
        ),
      ),
    ];
  }
} 