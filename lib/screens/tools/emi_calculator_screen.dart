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

class EmiCalculatorScreen extends StatefulWidget {
  static const routeName = '/emi-calculator';
  
  final bool showAppBar;
  
  const EmiCalculatorScreen({
    super.key, 
    this.showAppBar = true
  });

  @override
  State<EmiCalculatorScreen> createState() => _EmiCalculatorScreenState();
}

class _EmiCalculatorScreenState extends State<EmiCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loanAmountController = TextEditingController(text: '100000');
  final _interestRateController = TextEditingController(text: '10.5');
  final _loanTenureController = TextEditingController(text: '24');

  // Live Interest Rate Finder controllers
  final _reverseLoanAmountController = TextEditingController();
  final _reverseEmiAmountController = TextEditingController();
  final _reverseTenureController = TextEditingController();
  int _reverseTenureType = 1; // 0: Years, 1: Months
  double _calculatedInterestRate = 0.0;
  bool _isCalculatingRate = false;
  bool _canCalculateRate = false;
  String _reverseCalculationError = '';

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
    
    // Set up listeners for reverse calculation
    _reverseLoanAmountController.addListener(_checkReverseInputs);
    _reverseEmiAmountController.addListener(_checkReverseInputs);
    _reverseTenureController.addListener(_checkReverseInputs);
  }

  @override
  void dispose() {
    _loanAmountController.dispose();
    _interestRateController.dispose();
    _loanTenureController.dispose();
    _reverseLoanAmountController.dispose();
    _reverseEmiAmountController.dispose();
    _reverseTenureController.dispose();
    super.dispose();
  }

  // Check if all inputs for reverse calculation are valid
  void _checkReverseInputs() {
    bool canCalculate = false;
    
    try {
      double loanAmount = double.tryParse(_reverseLoanAmountController.text) ?? 0;
      double emiAmount = double.tryParse(_reverseEmiAmountController.text) ?? 0;
      int tenure = int.tryParse(_reverseTenureController.text) ?? 0;
      
      if (loanAmount > 0 && emiAmount > 0 && tenure > 0) {
        // Convert tenure to months if needed
        if (_reverseTenureType == 0) {
          tenure *= 12;
        }
        
        // Check if the EMI is sensible (at least enough to cover the principal)
        double minEmi = loanAmount / tenure;
        
        if (emiAmount >= minEmi) {
          canCalculate = true;
          _reverseCalculationError = '';
        } else {
          _reverseCalculationError = 'EMI too low for this loan amount and tenure';
        }
      } else {
        _reverseCalculationError = '';
      }
    } catch (e) {
      _reverseCalculationError = '';
    }
    
    if (canCalculate != _canCalculateRate) {
      setState(() {
        _canCalculateRate = canCalculate;
      });
      
      if (canCalculate) {
        _calculateInterestRate();
      }
    }
  }

  // Calculate interest rate using numerical approximation
  void _calculateInterestRate() {
    if (!_canCalculateRate) {
      return;
    }
    
    setState(() {
      _isCalculatingRate = true;
    });
    
    try {
      double p = double.parse(_reverseLoanAmountController.text); // Principal
      double emi = double.parse(_reverseEmiAmountController.text); // EMI amount
      int n = int.parse(_reverseTenureController.text); // Tenure
      
      // Convert years to months if needed
      if (_reverseTenureType == 0) {
        n = n * 12;
      }
      
      // Function to calculate EMI given rate
      // We'll use Newton-Raphson method to find the rate
      double f(double r) {
        if (r <= 0) return p / n - emi; // For 0 or negative rate, EMI is just principal/tenure
        return p * r * pow(1 + r, n) / (pow(1 + r, n) - 1) - emi;
      }
      
      // Derivative of f with respect to r
      double fPrime(double r) {
        if (r <= 0.0001) return 0; // Avoid division by zero
        double numerator1 = p * pow(1 + r, n);
        double numerator2 = p * n * r * pow(1 + r, n - 1);
        double denominator = pow(1 + r, n) - 1;
        return (numerator1 + numerator2) / denominator - 
               p * r * pow(1 + r, n) * n * pow(1 + r, n - 1) / pow(denominator, 2);
      }
      
      // Implement Newton-Raphson method
      double r = 0.10 / 12; // Initial guess: 10% annually, converted to monthly
      int maxIterations = 100;
      double tolerance = 1e-10;
      
      for (int i = 0; i < maxIterations; i++) {
        double fValue = f(r);
        if (fValue.abs() < tolerance) {
          break;
        }
        
        double fPrimeValue = fPrime(r);
        if (fPrimeValue.abs() < tolerance) {
          // If derivative is close to zero, use a different approach
          r = r * 1.1; // Try a slightly higher rate
          continue;
        }
        
        double nextR = r - fValue / fPrimeValue;
        
        // Check if the method is converging
        if ((nextR - r).abs() < tolerance) {
          r = nextR;
          break;
        }
        
        // Ensure r stays positive
        r = nextR > 0 ? nextR : r / 2;
      }
      
      // Convert monthly rate to annual percentage
      double annualRate = r * 12 * 100;
      
      // Check if result is reasonable (cap at 100%)
      if (annualRate > 100 || annualRate.isNaN) {
        setState(() {
          _reverseCalculationError = 'Unable to calculate valid interest rate';
          _isCalculatingRate = false;
        });
        return;
      }
      
      setState(() {
        _calculatedInterestRate = annualRate;
        _isCalculatingRate = false;
      });
      
    } catch (e) {
      setState(() {
        _reverseCalculationError = 'Calculation error';
        _isCalculatingRate = false;
      });
    }
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
                
                // Table Rows (all entries)
                ..._paymentSchedule.map((payment) {
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
      appBar: widget.showAppBar ? AppBar(
        title: const Text('EMI Calculator'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ) : null,
      body: Column(
        children: [
          // Interest Rate Finder Button
          Material(
            color: Colors.blue.shade50,
            child: InkWell(
              onTap: () => _showInterestRateFinder(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.blue.shade200, width: 1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.amber.shade700, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Live Interest Rate Finder',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Main content
          Expanded(
            child: SingleChildScrollView(
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
          ),
        ],
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
              'Loan Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Adjust your loan parameters and see results instantly',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
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
                    decoration: const InputDecoration(
                      labelText: 'Loan Tenure',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
                  'Payment Schedule',
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
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: _paymentSchedule.length, // Show all entries
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

  // Show the interest rate finder in a bottom sheet
  void _showInterestRateFinder() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.amber.shade600),
                      const SizedBox(width: 8),
                      const Text(
                        'Live Interest Rate Finder',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (_isCalculatingRate)
                    Container(
                      height: 16,
                      width: 16,
                      margin: const EdgeInsets.only(right: 16),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            
            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'This tool helps you find the interest rate when you know the loan amount, EMI, and tenure.',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
            ),
            
            // Form fields
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Loan Amount
                    TextField(
                      controller: _reverseLoanAmountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Loan Amount (₹)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.currency_rupee),
                        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // EMI Amount
                    TextField(
                      controller: _reverseEmiAmountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Monthly EMI (₹)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.payment),
                        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Loan Tenure
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _reverseTenureController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              labelText: 'Loan Tenure',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                            ),
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
                                value: _reverseTenureType,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(value: 0, child: Text('Years')),
                                  DropdownMenuItem(value: 1, child: Text('Months')),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _reverseTenureType = value;
                                      _checkReverseInputs();
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Result display
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Calculated Interest Rate',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_reverseCalculationError.isNotEmpty)
                            Text(
                              _reverseCalculationError,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.red.shade700,
                              ),
                            )
                          else if (_isCalculatingRate)
                            Column(
                              children: [
                                const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Calculating...',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            )
                          else if (_canCalculateRate)
                            Column(
                              children: [
                                Text(
                                  '${_calculatedInterestRate.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'per annum',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                              ],
                            )
                          else
                            const Text(
                              'Enter all values to calculate interest rate',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Tips
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.amber.shade800, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Tips',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• EMI must be at least enough to cover the principal over the tenure',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '• Calculation is more accurate with higher loan amounts',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom action button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('CLOSE'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 