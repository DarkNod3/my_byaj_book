import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';

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
  
  // Custom input formatters
  TextInputFormatter get _loanAmountFormatter => TextInputFormatter.withFunction(
    (oldValue, newValue) {
      // Allow backspace/deletion
      if (oldValue.text.length > newValue.text.length) {
        return newValue;
      }
      
      // Check if new value exceeds 10 Crore
      if (newValue.text.isNotEmpty) {
        final value = double.tryParse(newValue.text) ?? 0;
        if (value > 100000000) { // 10 Crore = 10,00,00,000
          return oldValue;
        }
      }
      return newValue;
    },
  );
  
  TextInputFormatter get _interestRateFormatter => TextInputFormatter.withFunction(
    (oldValue, newValue) {
      // Allow backspace/deletion
      if (oldValue.text.length > newValue.text.length) {
        return newValue;
      }
      
      // Check if new value exceeds 60%
      if (newValue.text.isNotEmpty) {
        final value = double.tryParse(newValue.text) ?? 0;
        if (value > 60) {
          return oldValue;
        }
      }
      
      // Allow only valid decimal format (up to 2 decimal places)
      if (newValue.text.isEmpty) {
        return newValue;
      }
      
      if (RegExp(r'^\d+\.?\d{0,2}$').hasMatch(newValue.text)) {
        return newValue;
      }
      
      return oldValue;
    },
  );
  
  TextInputFormatter get _loanTenureFormatter => TextInputFormatter.withFunction(
    (oldValue, newValue) {
      // Allow backspace/deletion
      if (oldValue.text.length > newValue.text.length) {
        return newValue;
      }
      
      // Check if new value exceeds max tenure based on type
      if (newValue.text.isNotEmpty) {
        final value = int.tryParse(newValue.text) ?? 0;
        if (_selectedTenureType == 0 && value > 50) { // Years
          return oldValue;
        } else if (_selectedTenureType == 1 && value > 600) { // Months
          return oldValue;
        }
      }
      return newValue;
    },
  );
  
  // Format currency in Indian Rupees
  final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs. ',
    decimalDigits: 0,
  );
  
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
    String newError = '';
    
    try {
      // Use tryParse with null check to avoid exceptions
      final loanAmountText = _reverseLoanAmountController.text.trim();
      final emiAmountText = _reverseEmiAmountController.text.trim();
      final tenureText = _reverseTenureController.text.trim();
      
      // Only proceed if all fields have values
      if (loanAmountText.isEmpty || emiAmountText.isEmpty || tenureText.isEmpty) {
        newError = '';
      } else {
        double loanAmount = double.tryParse(loanAmountText) ?? 0;
        double emiAmount = double.tryParse(emiAmountText) ?? 0;
        int tenure = int.tryParse(tenureText) ?? 0;
        
        if (loanAmount > 0 && emiAmount > 0 && tenure > 0) {
          // Convert tenure to months if needed
          final tenureMonths = (_reverseTenureType == 0) ? tenure * 12 : tenure;
          
          // Check if the EMI is sensible (at least enough to cover the principal)
          double minEmi = loanAmount / tenureMonths;
          
          if (emiAmount >= minEmi) {
            canCalculate = true;
          } else {
            newError = 'EMI too low for this loan amount and tenure';
          }
        }
      }
    } catch (e) {
      // In case of any errors, we won't be able to calculate
      newError = '';
    }
    
    // Only update state and trigger calculation if something changed
    if (canCalculate != _canCalculateRate || newError != _reverseCalculationError) {
      setState(() {
        _canCalculateRate = canCalculate;
        _reverseCalculationError = newError;
      });
      
      // Only calculate if we can and there is no error
      if (canCalculate && newError.isEmpty) {
        // Add a small delay before calculating to allow UI to update first
        // and prevent input lag during typing
        Future.delayed(const Duration(milliseconds: 300), () {
          // Check if the input values are still the same before calculating
          if (mounted && canCalculate == _canCalculateRate) {
            _calculateInterestRate();
          }
        });
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
      _calculatedInterestRate = 0; // Reset previous result
    });
    
    // Use Future.delayed to prevent UI freezing and give time for loading indicator to appear
    Future.delayed(const Duration(milliseconds: 50), () {
      try {
        double p = double.tryParse(_reverseLoanAmountController.text) ?? 1.0; // Principal
        double emi = double.tryParse(_reverseEmiAmountController.text) ?? 1.0; // EMI amount
        
        // Ensure minimum values are 1
        p = p < 1.0 ? 1.0 : p;
        emi = emi < 1.0 ? 1.0 : emi;
        
        int n = int.tryParse(_reverseTenureController.text) ?? 1; // Tenure
        // Ensure minimum tenure is 1
        n = n < 1 ? 1 : n;
        
        // Convert years to months if needed
        if (_reverseTenureType == 0) {
          n = n * 12;
        }
        
        // Simplified approach using binary search for better stability
        // This is more reliable than Newton-Raphson for this specific calculation
        double rateMin = 0.0;  // 0% monthly
        double rateMax = 1.0;  // 100% monthly (1200% annually) - reasonable upper bound
        double r = 0.01;       // Initial guess: 1% monthly
        double calculatedEmi;
        double epsilon = 0.0000001; // Precision threshold
        int maxIterations = 50;
        
        // Binary search for finding the rate
        for (int i = 0; i < maxIterations; i++) {
          // Special case: 0% interest rate
          if (r < epsilon) {
            calculatedEmi = p / n;
          } else {
            // EMI formula: P * r * (1 + r)^n / ((1 + r)^n - 1)
            calculatedEmi = p * r * pow(1 + r, n) / (pow(1 + r, n) - 1);
          }
          
          // If we're close enough to the target EMI, stop iterating
          if ((calculatedEmi - emi).abs() < 0.01) {
            break;
          }
          
          // Update our search range based on whether calculated EMI is higher or lower
          if (calculatedEmi > emi) {
            rateMax = r;
            r = (rateMin + r) / 2;
          } else {
            rateMin = r;
            r = (r + rateMax) / 2;
          }
          
          // If the range is very small, we've converged
          if ((rateMax - rateMin) < epsilon) {
            break;
          }
        }
        
        // Convert monthly rate to annual percentage
        double annualRate = r * 12 * 100;
        
        // Round to 2 decimal places
        annualRate = double.parse(annualRate.toStringAsFixed(2));
        
        // Check if result is reasonable (cap at 100%)
        if (annualRate > 100 || annualRate.isNaN || !annualRate.isFinite) {
          if (mounted) {
            setState(() {
              _reverseCalculationError = 'Unable to calculate valid interest rate';
              _isCalculatingRate = false;
            });
          }
          return;
        }
        
        if (mounted) {
          setState(() {
            _calculatedInterestRate = annualRate;
            _isCalculatingRate = false;
          });
        }
        
      } catch (e) {
        if (mounted) {
          setState(() {
            _reverseCalculationError = 'Calculation error';
            _isCalculatingRate = false;
          });
        }
      }
    });
  }

  void _calculateEMI() {
    // Check validations first
    String? loanAmountError = _validateLoanAmount();
    String? interestRateError = _validateInterestRate();
    String? loanTenureError = _validateLoanTenure();
    
    // If validation fails, don't proceed with calculation but keep existing values
    if (loanAmountError != null || interestRateError != null || loanTenureError != null) {
      setState(() {}); // Just update the UI to show error messages
      return;
    }
    
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
      
      // Ensure minimum principal is 1
      principal = principal < 1 ? 1 : principal;
      
      // Safely parse interest rate with validation
      if (_interestRateController.text.isNotEmpty) {
        rate = double.tryParse(_interestRateController.text) ?? 10.5;
      } else {
        rate = 10.5; // Default
      }
      
      // Ensure minimum rate is 0 (allow 0% interest)
      rate = rate < 0 ? 0 : rate;
      
      rate = rate / 12 / 100; // Monthly interest rate
      
      // Safely parse tenure with validation
      if (_loanTenureController.text.isNotEmpty) {
        tenure = int.tryParse(_loanTenureController.text) ?? 24;
      } else {
        tenure = 24; // Default
      }
      
      // Ensure minimum tenure is 1
      tenure = tenure < 1 ? 1 : tenure;
      
      // Convert years to months if years is selected
      if (_selectedTenureType == 0) {
        tenure = tenure * 12;
      }

      // Ensure tenure is at least 1 month and at most 600 months (50 years)
      tenure = tenure.clamp(1, 600);

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
      });
    } catch (e) {
      // If any calculation fails, use default values
      setState(() {
        _emiAmount = 0;
        _totalInterest = 0;
        _totalAmount = 0;
        _paymentSchedule = [];
      });
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
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
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
      
      final pdf = pw.Document();
      
      // Create a currency format without the rupee symbol for the PDF report
      final pdfCurrencyFormat = NumberFormat.currency(
        locale: 'en_IN',
        symbol: 'Rs. ',  // Use Rs. instead of rupee symbol
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
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 20),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(width: 1, color: PdfColors.grey300)),
              ),
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
                          color: PdfColors.blue600,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'EMI Calculation Report',
                        style: const pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Generated on',
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          footer: (pw.Context context) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(top: 10),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated using My Byaj Book App',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            );
          },
          build: (pw.Context context) {
            return [
              // Loan Summary Section
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
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
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
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
      
      // Close the loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Save the PDF
      final output = await getApplicationDocumentsDirectory(); // Use app documents directory instead of temp
      final file = File('${output.path}/emi_calculation_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
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
      // Close the loading dialog if it's still showing
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
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
                      // Add EMI breakdown and tips
                      const SizedBox(height: 16),
                      _buildBreakdownCard(),
                      const SizedBox(height: 16),
                      _buildTipsCard(),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                    controller: _loanAmountController,
                    keyboardType: TextInputType.number,
                        inputFormatters: [_loanAmountFormatter],
                        decoration: InputDecoration(
                      labelText: 'Loan Amount (₹)',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.currency_rupee),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          errorText: _validateLoanAmount(),
                    ),
                    onChanged: (value) {
                      // Allow any value, just prevent "0" as the only digit
                      if (value == "0") {
                        _loanAmountController.text = '1';
                      }
                      _calculateEMI();
                    },
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
            
            // Interest Rate
            TextField(
              controller: _interestRateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [_interestRateFormatter],
              decoration: InputDecoration(
                labelText: 'Interest Rate (% p.a.)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.percent),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                errorText: _validateInterestRate(),
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
                    inputFormatters: [_loanTenureFormatter],
                    decoration: InputDecoration(
                      labelText: 'Loan Tenure',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.calendar_today),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      errorText: _validateLoanTenure(),
                    ),
                    onChanged: (value) {
                      // Allow any value, just prevent "0" as the only digit
                      if (value == "0") {
                        _loanTenureController.text = '1';
                      }
                      _calculateEMI();
                    },
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
                              // Store current value to convert
                              int? currentTenure = int.tryParse(_loanTenureController.text);
                              if (currentTenure != null) {
                                // Convert value when switching tenure types
                                if (_selectedTenureType == 1 && value == 0) {
                                  // Converting months to years
                                  int years = (currentTenure / 12).floor();
                                  _loanTenureController.text = years > 0 ? years.toString() : '1';
                                } else if (_selectedTenureType == 0 && value == 1) {
                                  // Converting years to months
                                  _loanTenureController.text = (currentTenure * 12).toString();
                                }
                              }
                              _selectedTenureType = value;
                            });
                            _calculateEMI(); // This will check validation and update UI
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
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  _currencyFormat.format(_emiAmount),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
    return Expanded(
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ],
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
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
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
    double principal = double.tryParse(_loanAmountController.text) ?? 1.0;
    // Ensure minimum value is 1
    principal = principal < 1.0 ? 1.0 : principal;
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
            Column(
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
            
            // Calculated Interest Rate Box - NOW AT THE TOP
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Calculated Interest Rate',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_reverseCalculationError.isNotEmpty)
                      Text(
                        _reverseCalculationError,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.red.shade700,
                        ),
                        textAlign: TextAlign.center,
                      )
                    else if (_isCalculatingRate)
                      const Column(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Calculating...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      )
                    else if (_canCalculateRate)
                      AnimatedOpacity(
                        opacity: _calculatedInterestRate > 0 ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${_calculatedInterestRate.toStringAsFixed(2)}%',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'per annum',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const Text(
                        'Enter all values to calculate interest rate',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
            
            // Form fields
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Loan Amount and Tenure in one row (60:40 ratio)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Loan Amount (60%)
                        Expanded(
                          flex: 60,
                          child: TextField(
                            controller: _reverseLoanAmountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              TextInputFormatter.withFunction(
                                (oldValue, newValue) {
                                  // Allow backspace/deletion
                                  if (oldValue.text.length > newValue.text.length) {
                                    return newValue;
                                  }
                                  
                                  // Check if new value exceeds 10 Crore
                                  if (newValue.text.isNotEmpty) {
                                    final value = double.tryParse(newValue.text) ?? 0;
                                    if (value > 100000000) { // 10 Crore = 10,00,00,000
                                      return oldValue;
                                    }
                                  }
                                  return newValue;
                                },
                              )
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Loan Amount (Rs.)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.currency_rupee),
                              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                            ),
                            onChanged: (value) {
                              // Allow any value, just prevent "0" as the only digit
                              if (value == "0") {
                                _reverseLoanAmountController.text = '1';
                              }
                              _checkReverseInputs();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Tenure (40%) - Years only
                        Expanded(
                          flex: 40,
                          child: TextField(
                            controller: _reverseTenureController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              TextInputFormatter.withFunction(
                                (oldValue, newValue) {
                                  // Allow backspace/deletion
                                  if (oldValue.text.length > newValue.text.length) {
                                    return newValue;
                                  }
                                  
                                  // Check if new value exceeds max tenure
                                  if (newValue.text.isNotEmpty) {
                                    final value = int.tryParse(newValue.text) ?? 0;
                                    if (value > 50) { // Max 50 years
                                      return oldValue;
                                    }
                                  }
                                  return newValue;
                                },
                              )
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Years',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                            ),
                            onChanged: (value) {
                              // Allow any value, just prevent "0" as the only digit
                              if (value == "0") {
                                _reverseTenureController.text = '1';
                              }
                              
                              // Always set tenure type to years (0)
                              setState(() {
                                _reverseTenureType = 0;
                              });
                              
                              _checkReverseInputs();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // EMI Amount
                    TextField(
                      controller: _reverseEmiAmountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        TextInputFormatter.withFunction(
                          (oldValue, newValue) {
                            // Allow backspace/deletion
                            if (oldValue.text.length > newValue.text.length) {
                              return newValue;
                            }
                            
                            // Check if new value exceeds 10 Crore (as a reasonable max EMI)
                            if (newValue.text.isNotEmpty) {
                              final value = double.tryParse(newValue.text) ?? 0;
                              if (value > 100000000) { // 10 Crore
                                return oldValue;
                              }
                            }
                            return newValue;
                          },
                        )
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Monthly EMI (Rs.)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.payment),
                        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      ),
                      onChanged: (value) {
                        // Allow any value, just prevent "0" as the only digit
                        if (value == "0") {
                          _reverseEmiAmountController.text = '1';
                        }
                        _checkReverseInputs();
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // EMI Breakdown as per live interest
                    if (_canCalculateRate && _calculatedInterestRate > 0)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'EMI Breakdown',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildBreakdownRow(
                              label: 'Principal Amount',
                              value: _reverseLoanAmountController.text.isNotEmpty
                                  ? _currencyFormat.format(double.tryParse(_reverseLoanAmountController.text) ?? 0)
                                  : '-',
                            ),
                            const SizedBox(height: 8),
                            _buildBreakdownRow(
                              label: 'Interest Rate',
                              value: '${_calculatedInterestRate.toStringAsFixed(2)}% p.a.',
                            ),
                            const SizedBox(height: 8),
                            _buildBreakdownRow(
                              label: 'Loan Tenure',
                              value: '${_reverseTenureController.text} Years',
                            ),
                            const SizedBox(height: 8),
                            _buildBreakdownRow(
                              label: 'Monthly EMI',
                              value: _reverseEmiAmountController.text.isNotEmpty
                                  ? _currencyFormat.format(double.tryParse(_reverseEmiAmountController.text) ?? 0)
                                  : '-',
                              isBold: true,
                            ),
                            const SizedBox(height: 8),
                            const Divider(),
                            const SizedBox(height: 8),
                            _buildBreakdownRow(
                              label: 'Total Interest',
                              value: _calculateTotalInterest(),
                              showColor: true,
                            ),
                            const SizedBox(height: 8),
                            _buildBreakdownRow(
                              label: 'Total Amount',
                              value: _calculateTotalAmount(),
                              isBold: true,
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

  // Add a tips card for EMI calculation
  Widget _buildTipsCard() {
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
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                const Text(
                  'EMI Calculation Tips',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTipItem(
              icon: Icons.check_circle_outline,
              text: 'Lower interest rates can significantly reduce your EMI',
            ),
            const SizedBox(height: 8),
            _buildTipItem(
              icon: Icons.check_circle_outline,
              text: 'Increasing down payment reduces loan amount and EMI',
            ),
            const SizedBox(height: 8),
            _buildTipItem(
              icon: Icons.check_circle_outline,
              text: 'Longer tenure reduces EMI but increases total interest paid',
            ),
            const SizedBox(height: 8),
            _buildTipItem(
              icon: Icons.check_circle_outline,
              text: 'Prepayment of loan can reduce total interest burden',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'EMI = [P × R × (1+R)^N]/[(1+R)^N-1], where P is principal, R is monthly interest rate, and N is number of months',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.green),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  String? _validateLoanAmount() {
    try {
      double? amount = double.tryParse(_loanAmountController.text);
      if (amount != null && amount > 100000000) { // 10 Crore = 10,00,00,000
        return 'Amount cannot exceed 10 Crore (₹10,00,00,000)';
      }
    } catch (_) {}
    return null;
  }

  String? _validateInterestRate() {
    try {
      double? rate = double.tryParse(_interestRateController.text);
      if (rate != null && rate > 60) {
        return 'Interest rate cannot exceed 60% per annum';
      }
    } catch (_) {}
    return null;
  }

  String? _validateLoanTenure() {
    try {
      int? tenure = int.tryParse(_loanTenureController.text);
      if (tenure != null) {
        // Convert to months if in years
        if (_selectedTenureType == 0 && tenure > 50) {
          return 'Loan period cannot exceed 50 years';
        } else if (_selectedTenureType == 1 && tenure > 600) {
          return 'Loan period cannot exceed 600 months';
        }
      }
    } catch (_) {}
    return null;
  }

  String _calculateTotalInterest() {
    try {
      double principal = double.tryParse(_reverseLoanAmountController.text) ?? 0;
      double emi = double.tryParse(_reverseEmiAmountController.text) ?? 0;
      int years = int.tryParse(_reverseTenureController.text) ?? 0;
      int months = years * 12;
      
      // Total amount paid over the loan period
      double totalAmount = emi * months;
      
      // Interest is the difference between total amount and principal
      double totalInterest = totalAmount - principal;
      
      // Prevent negative values
      if (totalInterest < 0) totalInterest = 0;
      
      return _currencyFormat.format(totalInterest);
    } catch (e) {
      return '-';
    }
  }

  String _calculateTotalAmount() {
    try {
      double emi = double.tryParse(_reverseEmiAmountController.text) ?? 0;
      int years = int.tryParse(_reverseTenureController.text) ?? 0;
      int months = years * 12;
      
      double totalAmount = emi * months;
      
      return _currencyFormat.format(totalAmount);
    } catch (e) {
      return '-';
    }
  }

  Widget _buildBreakdownRow({
    required String label,
    required String value,
    bool showColor = false,
    bool isBold = false,
  }) {
    return Row(
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
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: showColor ? Colors.orange : Colors.grey[800],
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }
} 