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

class SipCalculatorScreen extends StatefulWidget {
  static const routeName = '/sip-calculator';
  
  const SipCalculatorScreen({super.key});

  @override
  State<SipCalculatorScreen> createState() => _SipCalculatorScreenState();
}

class _SipCalculatorScreenState extends State<SipCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _monthlyInvestmentController = TextEditingController(text: '10000');
  final _expectedReturnController = TextEditingController(text: '12');
  final _investmentPeriodController = TextEditingController(text: '10');

  double _totalInvestment = 0;
  double _totalReturns = 0;
  double _maturityValue = 0;
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
      // Safe parsing of values with defaults
      double monthlyInvestment = _monthlyInvestmentController.text.isEmpty 
          ? 10000 : double.tryParse(_monthlyInvestmentController.text) ?? 10000;
      
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
        _totalReturns = totalReturns;
        _maturityValue = maturityValue;
        _showResult = true;
      });
    } catch (e) {
      // Set defaults if calculation fails
      setState(() {
        _totalInvestment = 0;
        _totalReturns = 0;
        _maturityValue = 0;
        _investmentSchedule = [];
        _showResult = true;
      });
      print('SIP calculation error: $e');
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

  Future<void> _generatePDF() async {
    final pdf = pw.Document();
    
    // Create a currency format without the rupee symbol for the PDF report
    final pdfCurrencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '',  // Empty symbol
      decimalDigits: 0,
    );
    
    // Get basic investment details for the report
    double monthlyInvestment = double.tryParse(_monthlyInvestmentController.text) ?? 10000;
    double expectedReturn = double.tryParse(_expectedReturnController.text) ?? 12;
    int years = int.tryParse(_investmentPeriodController.text) ?? 10;
    
    // Create a PDF document
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Text(
              'SIP Investment Report',
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
            // Investment Summary Section
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
                    'Investment Summary',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 15),
                  _buildPdfSummaryRow('Monthly Investment', pdfCurrencyFormat.format(monthlyInvestment)),
                  _buildPdfSummaryRow('Expected Return Rate', '$expectedReturn% per annum'),
                  _buildPdfSummaryRow('Investment Period', '$years Years'),
                  _buildPdfSummaryRow('Total Investment', pdfCurrencyFormat.format(_totalInvestment)),
                  _buildPdfSummaryRow('Total Returns', pdfCurrencyFormat.format(_totalReturns)),
                  _buildPdfSummaryRow('Maturity Value', pdfCurrencyFormat.format(_maturityValue)),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Investment Schedule Section
            pw.Text(
              'Year-wise Growth',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            
            // Investment Schedule Table
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                // Table Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _buildPdfTableHeader('Year'),
                    _buildPdfTableHeader('Amount Invested'),
                    _buildPdfTableHeader('Est. Returns'),
                    _buildPdfTableHeader('Est. Value'),
                  ],
                ),
                
                // Table Rows
                ..._investmentSchedule.map((investment) {
                  return pw.TableRow(
                    children: [
                      _buildPdfTableCell('${investment['year']}'),
                      _buildPdfTableCell(pdfCurrencyFormat.format(investment['investedAmount'])),
                      _buildPdfTableCell(pdfCurrencyFormat.format(investment['estimatedReturns'])),
                      _buildPdfTableCell(pdfCurrencyFormat.format(investment['estimatedValue'])),
                    ],
                  );
                }).toList(),
              ],
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
                'Disclaimer: This is an approximate calculation based on the provided interest rate compounded monthly. Actual returns may vary based on market conditions, fees, and tax implications. This report is for informational purposes only and should not be considered as investment advice.',
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
      final file = File('${output.path}/sip_investment_report.pdf');
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
    _monthlyInvestmentController.text = '10000';
    _expectedReturnController.text = '12';
    _investmentPeriodController.text = '10';
    
    // Recalculate immediately after reset
    _calculateSIP();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SIP Calculator'),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
      ),
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
                _buildPdfButton(),
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
            const SizedBox(height: 8),
            Text(
              _currencyFormat.format(_maturityValue),
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
                  title: 'Invested',
                  value: _currencyFormat.format(_totalInvestment),
                ),
                _buildResultDetail(
                  title: 'Returns',
                  value: _currencyFormat.format(_totalReturns),
                ),
                _buildResultDetail(
                  title: 'Growth',
                  value: _totalInvestment > 0 
                      ? '${((_totalReturns / _totalInvestment) * 100).toStringAsFixed(1)}%' 
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
                  child: TextField(
                    controller: _monthlyInvestmentController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Monthly Investment (₹)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.currency_rupee),
                      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    ),
                    onChanged: (_) => _calculateSIP(),
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
              decoration: const InputDecoration(
                labelText: 'Investment Period (Years)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
                contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              ),
              onChanged: (_) => _calculateSIP(),
            ),
          ],
        ),
      ),
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
          backgroundColor: Colors.indigo.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
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
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Year-wise Growth',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
    // Calculate the percentage of invested amount and returns
    double investedPercent = 0;
    double returnsPercent = 0;
    
    if (_maturityValue > 0) {
      investedPercent = _totalInvestment / _maturityValue;
      returnsPercent = _totalReturns / _maturityValue;
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
                        value: _currencyFormat.format(_totalReturns),
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
                            ? '${(_totalReturns / _totalInvestment).toStringAsFixed(2)}x' 
                            : '0x',
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
                        // Placeholder for a proper pie chart
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
                                    '${(investedPercent * 100).toStringAsFixed(0)}%',
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
                                    '${(returnsPercent * 100).toStringAsFixed(0)}%',
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