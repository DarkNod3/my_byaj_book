import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:my_byaj_book/services/pdf_template_service.dart';

class TaxCalculatorScreen extends StatefulWidget {
  static const routeName = '/tax-calculator';
  
  final bool showAppBar;
  
  const TaxCalculatorScreen({
    super.key, 
    this.showAppBar = true
  });

  @override
  State<TaxCalculatorScreen> createState() => _TaxCalculatorScreenState();
}

class _TaxCalculatorScreenState extends State<TaxCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _incomeController = TextEditingController(text: '500000');
  final _investmentsController = TextEditingController(text: '50000');
  final _deductionsController = TextEditingController(text: '50000');

  // Tax regime selection
  bool _isOldRegime = true; // Default to old regime
  bool _isGeneratingPdf = false; // Added for PDF generation status

  // Tax calculation results
  double _taxableIncome = 0;
  double _taxAmount = 0;
  double _cessAmount = 0;
  double _totalTaxLiability = 0;
  double _effectiveTaxRate = 0;
  
  // Custom input formatters
  TextInputFormatter get _incomeFormatter => TextInputFormatter.withFunction(
    (oldValue, newValue) {
      // Allow backspace/deletion
      if (oldValue.text.length > newValue.text.length) {
        return newValue;
      }
      
      // Check if new value exceeds 200 Crore (20,000,000,000)
      if (newValue.text.isNotEmpty) {
        final value = double.tryParse(newValue.text) ?? 0;
        if (value > 20000000000) { // 200 Crore
          return oldValue;
        }
      }
      return newValue;
    },
  );
  
  TextInputFormatter get _investmentsFormatter => TextInputFormatter.withFunction(
    (oldValue, newValue) {
      // Allow backspace/deletion
      if (oldValue.text.length > newValue.text.length) {
        return newValue;
      }
      
      // Check if new value exceeds 150000 (limit for 80C)
      if (newValue.text.isNotEmpty) {
        final value = double.tryParse(newValue.text) ?? 0;
        if (value > 150000) { // 1.5 Lakh
          return oldValue;
        }
      }
      return newValue;
    },
  );
  
  TextInputFormatter get _deductionsFormatter => TextInputFormatter.withFunction(
    (oldValue, newValue) {
      // Allow backspace/deletion
      if (oldValue.text.length > newValue.text.length) {
        return newValue;
      }
      
      // Check if new value exceeds 1 Crore (100,000,000)
      if (newValue.text.isNotEmpty) {
        final value = double.tryParse(newValue.text) ?? 0;
        if (value > 100000000) { // 1 Crore
          return oldValue;
        }
      }
      return newValue;
    },
  );
  
  // Validation methods
  String? _validateIncome() {
    try {
      double? amount = double.tryParse(_incomeController.text);
      if (amount != null && amount > 20000000000) { // 200 Crore
        return 'Amount cannot exceed 200 Crore (Rs. 200,00,00,000)';
      }
    } catch (_) {}
    return null;
  }
  
  String? _validateInvestments() {
    try {
      double? amount = double.tryParse(_investmentsController.text);
      if (amount != null && amount > 150000) { // 1.5 Lakh
        return 'Investments under 80C cannot exceed Rs. 1,50,000';
      }
    } catch (_) {}
    return null;
  }
  
  String? _validateDeductions() {
    try {
      double? amount = double.tryParse(_deductionsController.text);
      if (amount != null && amount > 100000000) { // 1 Crore
        return 'Deductions cannot exceed 1 Crore (Rs. 1,00,00,000)';
      }
    } catch (_) {}
    return null;
  }
  
  // Format currency in Indian Rupees
  // final _currencyFormat = NumberFormat.currency(
  //   locale: 'en_IN',
  //   symbol: 'Rs. ',
  //   decimalDigits: 0,
  // );
  
  // Alternative formatter if the locale doesn't work correctly
  String _formatCurrency(dynamic amount) {
    // Convert to double if not already a double
    double amountDouble = amount is double ? amount : amount.toDouble();
    return 'Rs. ${amountDouble.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},'
    )}';
  }
  
  // Tax slab breakdowns
  List<Map<String, dynamic>> _taxSlabBreakdown = [];

  @override
  void initState() {
    super.initState();
    // Calculate tax automatically on init
    _calculateTax();
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _investmentsController.dispose();
    _deductionsController.dispose();
    super.dispose();
  }

  void _calculateTax() {
    try {
      // Check validations first
      String? incomeError = _validateIncome();
      String? investmentsError = _validateInvestments();
      String? deductionsError = _validateDeductions();
      
      // If validation fails, don't proceed with calculation but keep existing values
      if (incomeError != null || investmentsError != null || deductionsError != null) {
        setState(() {}); // Just update the UI to show error messages
        return;
      }
      
      // Parse input values
      double income = double.tryParse(_incomeController.text) ?? 500000;
      double investments = double.tryParse(_investmentsController.text) ?? 50000;
      double deductions = double.tryParse(_deductionsController.text) ?? 50000;

      // Calculate taxable income
      double taxableIncome = _isOldRegime 
          ? income - investments.clamp(0, 150000) - deductions
          : income - deductions;
      
      // Ensure taxable income is not negative
      taxableIncome = taxableIncome > 0 ? taxableIncome : 0;
      
      // Calculate tax based on regime
      double taxAmount = 0;
      _taxSlabBreakdown = [];
      
      if (_isOldRegime) {
        // Old Tax Regime Calculation
        if (taxableIncome <= 250000) {
          taxAmount = 0;
          _taxSlabBreakdown.add({'slab': '0 - 2.5L', 'rate': '0%', 'tax': 0.0});
        } else {
          // Up to 2.5L - 0%
          _taxSlabBreakdown.add({'slab': '0 - 2.5L', 'rate': '0%', 'tax': 0.0});
          
          // 2.5L to 5L - 5%
          if (taxableIncome > 250000) {
            double slabAmount = taxableIncome > 500000 ? 250000 : taxableIncome - 250000;
            double slabTax = slabAmount * 0.05;
            taxAmount += slabTax;
            _taxSlabBreakdown.add({'slab': '2.5L - 5L', 'rate': '5%', 'tax': slabTax});
          }
          
          // 5L to 10L - 20%
          if (taxableIncome > 500000) {
            double slabAmount = taxableIncome > 1000000 ? 500000 : taxableIncome - 500000;
            double slabTax = slabAmount * 0.2;
            taxAmount += slabTax;
            _taxSlabBreakdown.add({'slab': '5L - 10L', 'rate': '20%', 'tax': slabTax});
          }
          
          // Above 10L - 30%
          if (taxableIncome > 1000000) {
            double slabAmount = taxableIncome - 1000000;
            double slabTax = slabAmount * 0.3;
            taxAmount += slabTax;
            _taxSlabBreakdown.add({'slab': 'Above 10L', 'rate': '30%', 'tax': slabTax});
          }
        }
      } else {
        // New Tax Regime Calculation
        if (taxableIncome <= 300000) {
          taxAmount = 0;
          _taxSlabBreakdown.add({'slab': '0 - 3L', 'rate': '0%', 'tax': 0.0});
        } else {
          // Up to 3L - 0%
          _taxSlabBreakdown.add({'slab': '0 - 3L', 'rate': '0%', 'tax': 0.0});
          
          // 3L to 6L - 5%
          if (taxableIncome > 300000) {
            double slabAmount = taxableIncome > 600000 ? 300000 : taxableIncome - 300000;
            double slabTax = slabAmount * 0.05;
            taxAmount += slabTax;
            _taxSlabBreakdown.add({'slab': '3L - 6L', 'rate': '5%', 'tax': slabTax});
          }
          
          // 6L to 9L - 10%
          if (taxableIncome > 600000) {
            double slabAmount = taxableIncome > 900000 ? 300000 : taxableIncome - 600000;
            double slabTax = slabAmount * 0.1;
            taxAmount += slabTax;
            _taxSlabBreakdown.add({'slab': '6L - 9L', 'rate': '10%', 'tax': slabTax});
          }
          
          // 9L to 12L - 15%
          if (taxableIncome > 900000) {
            double slabAmount = taxableIncome > 1200000 ? 300000 : taxableIncome - 900000;
            double slabTax = slabAmount * 0.15;
            taxAmount += slabTax;
            _taxSlabBreakdown.add({'slab': '9L - 12L', 'rate': '15%', 'tax': slabTax});
          }
          
          // 12L to 15L - 20%
          if (taxableIncome > 1200000) {
            double slabAmount = taxableIncome > 1500000 ? 300000 : taxableIncome - 1200000;
            double slabTax = slabAmount * 0.2;
            taxAmount += slabTax;
            _taxSlabBreakdown.add({'slab': '12L - 15L', 'rate': '20%', 'tax': slabTax});
          }
          
          // Above 15L - 30%
          if (taxableIncome > 1500000) {
            double slabAmount = taxableIncome - 1500000;
            double slabTax = slabAmount * 0.3;
            taxAmount += slabTax;
            _taxSlabBreakdown.add({'slab': 'Above 15L', 'rate': '30%', 'tax': slabTax});
          }
        }
      }
      
      // Calculate cess (4% on tax amount)
      double cessAmount = taxAmount * 0.04;
      
      // Calculate total tax liability
      double totalTaxLiability = taxAmount + cessAmount;
      
      // Calculate effective tax rate
      double effectiveTaxRate = income > 0 ? (totalTaxLiability / income) * 100 : 0;

      setState(() {
        _taxableIncome = taxableIncome;
        _taxAmount = taxAmount;
        _cessAmount = cessAmount;
        _totalTaxLiability = totalTaxLiability;
        _effectiveTaxRate = effectiveTaxRate;
      });
    } catch (e) {
      // Set defaults if calculation fails
      setState(() {
        _taxableIncome = 0;
        _taxAmount = 0;
        _cessAmount = 0;
        _totalTaxLiability = 0;
        _effectiveTaxRate = 0;
        _taxSlabBreakdown = [];
      });
    }
  }

  Future<void> _generatePdfReport() async {
    try {
      setState(() {
        _isGeneratingPdf = true;
      });
      
      // Create content for PDF
      final content = await _createPdfContent();
      
      // Create the PDF
      final fileName = 'tax_calculation_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final pdf = await PdfTemplateService.createDocument(
        title: 'Income Tax',
        subtitle: 'Calculation Report',
        content: content,
      );
      
      // Save and open the PDF
      await PdfTemplateService.saveAndOpenPdf(pdf, fileName);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PDF report generated successfully!'),
                SizedBox(height: 4),
                Text(
                  'If the PDF didn\'t open automatically, it was saved to your device\'s temporary folder.',
                  style: TextStyle(fontSize: 12),
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

  Future<List<pw.Widget>> _createPdfContent() async {
    // Get basic tax details for the report
    double income = double.tryParse(_incomeController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 500000;
    double investments = double.tryParse(_investmentsController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 50000;
    double deductions = double.tryParse(_deductionsController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 50000;
    String regime = _isOldRegime ? 'Old Tax Regime' : 'New Tax Regime';
    
    // Prepare summary card items
    final List<Map<String, dynamic>> summaryItems = [
      {'label': 'Total Income', 'value': 'Rs. ${PdfTemplateService.formatCurrency(income)}'},
      {'label': 'Investments (Sec 80C)', 'value': 'Rs. ${PdfTemplateService.formatCurrency(investments)}'},
      {'label': 'Other Deductions', 'value': 'Rs. ${PdfTemplateService.formatCurrency(deductions)}'},
      {'label': 'Tax Regime', 'value': regime},
      {'label': 'Taxable Income', 'value': 'Rs. ${PdfTemplateService.formatCurrency(_taxableIncome)}'},
      {'label': 'Income Tax', 'value': 'Rs. ${PdfTemplateService.formatCurrency(_taxAmount)}'},
      {'label': 'Cess (4%)', 'value': 'Rs. ${PdfTemplateService.formatCurrency(_cessAmount)}'},
      {
        'label': 'Total Tax Liability', 
        'value': 'Rs. ${PdfTemplateService.formatCurrency(_totalTaxLiability)}',
        'highlight': true,
        'isPositive': false
      },
      {'label': 'Effective Tax Rate', 'value': '${_effectiveTaxRate.toStringAsFixed(2)}%'},
    ];
    
    // Prepare tax slab breakdown table
    final List<String> tableColumns = ['Income Slab', 'Tax Rate', 'Tax Amount'];
    final List<List<String>> tableRows = [];
    
    for (var slab in _taxSlabBreakdown) {
      if (slab['slab'] != null && slab['rate'] != null) {
        double taxAmount = 0;
        if (slab['tax'] != null) {
          taxAmount = slab['tax'] is double ? slab['tax'] : slab['tax'].toDouble();
        }
        
        tableRows.add([
          slab['slab'].toString(),
          slab['rate'].toString(),
          'Rs. ${PdfTemplateService.formatCurrency(taxAmount)}'
        ]);
      }
    }
    
    // PDF content
    final content = [
      // Tax Summary
      PdfTemplateService.buildSummaryCard(
        title: 'Tax Summary',
        items: summaryItems,
      ),
      
      pw.SizedBox(height: 20),
      
      // Tax Slab Breakdown Table
      PdfTemplateService.buildDataTable(
        title: 'Tax Slab Breakdown',
        columns: tableColumns,
        rows: tableRows,
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
          'Disclaimer: This is an approximate calculation based on the information provided. Actual tax liability may vary based on other deductions, exemptions, and income sources. Please consult a tax professional for personalized advice.',
          style: const pw.TextStyle(
            fontSize: 10,
          ),
        ),
      ),
    ];
    
    return content;
  }

  void _resetCalculator() {
    _incomeController.text = '500000';
    _investmentsController.text = '50000';
    _deductionsController.text = '50000';
    _isOldRegime = true;
    
    // Recalculate immediately after reset
    _calculateTax();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar ? AppBar(
        title: const Text('Income Tax Calculator'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ) : null,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Form(
            key: _formKey,
            onChanged: _calculateTax, // Recalculate on any form change
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildResultCard(),
                const SizedBox(height: 16),
                _buildCalculatorCard(),
                const SizedBox(height: 16),
                _buildPdfButton(),
                const SizedBox(height: 16),
                _buildTaxSlabBreakdown(),
                const SizedBox(height: 16),
                _buildTaxTips(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildResultCard() {
    // Determine font size based on amount value - smaller font for large amounts
    double fontSize = 36;
    if (_totalTaxLiability >= 1000000) { // More than 10 lakhs
      fontSize = 28;
    } else if (_totalTaxLiability >= 100000) { // More than 1 lakh
      fontSize = 32;
    }
    
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
            colors: [Colors.red.shade600, Colors.red.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Total Tax Liability',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
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
                    _formatCurrency(_totalTaxLiability),
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Use a more flexible layout for the bottom row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildResultDetail(
                      title: 'Taxable Income',
                      value: _formatCurrency(_taxableIncome),
                    ),
                  ),
                  Expanded(
                    child: _buildResultDetail(
                      title: 'Income Tax',
                      value: _formatCurrency(_taxAmount),
                    ),
                  ),
                  Expanded(
                    child: _buildResultDetail(
                      title: 'Effective Rate',
                      value: '${_effectiveTaxRate.toStringAsFixed(1)}%',
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

  Widget _buildResultDetail({
    required String title,
    required String value,
  }) {
    // Determine font size based on value length
    double fontSize = 16;
    if (value.length > 14) {
      fontSize = 12;
    } else if (value.length > 10) {
      fontSize = 14;
    }
    
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 100,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: fontSize,
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
              'Income Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Enter your income and deduction details',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            
            // Tax Regime Selector
            Row(
              children: [
                const Text('Tax Regime:'),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text('Old', style: TextStyle(fontSize: 14)),
                          value: true,
                          groupValue: _isOldRegime,
                          onChanged: (value) {
                            setState(() {
                              _isOldRegime = value!;
                              _calculateTax();
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text('New', style: TextStyle(fontSize: 14)),
                          value: false,
                          groupValue: _isOldRegime,
                          onChanged: (value) {
                            setState(() {
                              _isOldRegime = value!;
                              _calculateTax();
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Total Income with Reset button
            Row(
              children: [
                // Total Income (80%)
                Expanded(
                  flex: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                    controller: _incomeController,
                    keyboardType: TextInputType.number,
                        inputFormatters: [_incomeFormatter],
                        decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blue, width: 2),
                      ),
                      labelText: 'Total Income (Rs.)',
                      errorText: _validateIncome(),
                    ),
                    onChanged: (_) => _calculateTax(),
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
            
            // Investments (80C)
            TextField(
              controller: _investmentsController,
              keyboardType: TextInputType.number,
              inputFormatters: [_investmentsFormatter],
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                labelText: 'Investments (80C) (Rs.)',
                helperText: 'PF, PPF, LIC, ELSS, etc. Max: Rs. 1,50,000',
                errorText: _validateInvestments(),
              ),
              onChanged: (_) => _calculateTax(),
            ),
            const SizedBox(height: 16),
            
            // Other Deductions
            TextField(
              controller: _deductionsController,
              keyboardType: TextInputType.number,
              inputFormatters: [_deductionsFormatter],
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                labelText: 'Other Deductions (Rs.)',
                helperText: 'HRA, Medical Insurance, NPS, etc.',
                errorText: _validateDeductions(),
              ),
              onChanged: (_) => _calculateTax(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfButton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isGeneratingPdf ? null : _generatePdfReport,
        icon: _isGeneratingPdf 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.picture_as_pdf),
        label: Text(_isGeneratingPdf ? 'GENERATING PDF...' : 'GENERATE TAX REPORT'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildTaxSlabBreakdown() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tax Slab Breakdown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isOldRegime ? 'Old Regime' : 'New Regime',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
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
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Income Slab',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Rate',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Tax Amount',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey.shade800,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
          // Table rows
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _taxSlabBreakdown.length,
            itemBuilder: (context, index) {
              final slab = _taxSlabBreakdown[index];
              return Container(
                decoration: BoxDecoration(
                  color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        slab['slab'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        slab['rate'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _formatCurrency(slab['tax']),
                        style: TextStyle(
                          fontSize: 14,
                          color: (slab['tax'] is double ? slab['tax'] : slab['tax'].toDouble()) > 0 ? Colors.red.shade700 : Colors.grey.shade800,
                          fontWeight: (slab['tax'] is double ? slab['tax'] : slab['tax'].toDouble()) > 0 ? FontWeight.w500 : FontWeight.normal,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Cess (4%)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    '4%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _formatCurrency(_cessAmount),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.red.shade50,
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Total Tax Liability',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _formatCurrency(_totalTaxLiability),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxTips() {
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
              'Tax Saving Tips',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTaxTip(
              icon: Icons.savings,
              title: 'Maximize Section 80C',
              description: 'Invest in PPF, ELSS, EPF, etc. to claim deduction up to Rs. 1.5 lakhs',
            ),
            _buildTaxTip(
              icon: Icons.local_hospital,
              title: 'Health Insurance Premium',
              description: 'Claim deduction up to Rs. 25,000 under Section 80D for health insurance premiums',
            ),
            _buildTaxTip(
              icon: Icons.account_balance,
              title: 'National Pension Scheme',
              description: 'Invest in NPS to claim additional deduction up to Rs. 50,000 under Section 80CCD(1B)',
            ),
            _buildTaxTip(
              icon: Icons.home,
              title: 'Home Loan Benefits',
              description: 'Claim interest up to Rs. 2 lakhs under Section 24(b) and principal under Section 80C',
            ),
            const SizedBox(height: 8),
            const Text(
              'Note: The new tax regime offers lower tax rates but fewer deductions. Choose based on your specific financial situation.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxTip({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.red.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 