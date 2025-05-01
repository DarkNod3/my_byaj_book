import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import 'package:my_byaj_book/widgets/header/app_header.dart';

class TaxCalculatorScreen extends StatefulWidget {
  static const routeName = '/tax-calculator';
  final bool showAppBar;
  
  const TaxCalculatorScreen({super.key, this.showAppBar = true});

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

  // Tax calculation results
  double _taxableIncome = 0;
  double _taxAmount = 0;
  double _cessAmount = 0;
  double _totalTaxLiability = 0;
  double _effectiveTaxRate = 0;
  
  // Format currency in Indian Rupees
  final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  
  // Alternative formatter if the locale doesn't work correctly
  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(0).replaceAllMapped(
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
          _taxSlabBreakdown.add({'slab': '0 - 2.5L', 'rate': '0%', 'tax': 0});
        } else {
          // Up to 2.5L - 0%
          _taxSlabBreakdown.add({'slab': '0 - 2.5L', 'rate': '0%', 'tax': 0});
          
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
          _taxSlabBreakdown.add({'slab': '0 - 3L', 'rate': '0%', 'tax': 0});
        } else {
          // Up to 3L - 0%
          _taxSlabBreakdown.add({'slab': '0 - 3L', 'rate': '0%', 'tax': 0});
          
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
      print('Tax calculation error: $e');
    }
  }

  Future<void> _generatePDF() async {
    final pdf = pw.Document();
    
    // Create a custom formatter for the PDF report to ensure proper Rupee symbol
    String formatCurrencyForPdf(double amount) {
      return '₹${amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},'
      )}';
    }
    
    // Get basic tax details for the report
    double income = double.tryParse(_incomeController.text) ?? 500000;
    double investments = double.tryParse(_investmentsController.text) ?? 50000;
    double deductions = double.tryParse(_deductionsController.text) ?? 50000;
    String regime = _isOldRegime ? 'Old Tax Regime' : 'New Tax Regime';
    
    // Create a PDF document
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Text(
              'Income Tax Calculation Report',
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
            // Tax Summary Section
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
                    'Tax Summary',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 15),
                  _buildPdfSummaryRow('Total Income', formatCurrencyForPdf(income)),
                  _buildPdfSummaryRow('Investments (Sec 80C)', formatCurrencyForPdf(investments)),
                  _buildPdfSummaryRow('Other Deductions', formatCurrencyForPdf(deductions)),
                  _buildPdfSummaryRow('Tax Regime', regime),
                  _buildPdfSummaryRow('Taxable Income', formatCurrencyForPdf(_taxableIncome)),
                  _buildPdfSummaryRow('Income Tax', formatCurrencyForPdf(_taxAmount)),
                  _buildPdfSummaryRow('Cess (4%)', formatCurrencyForPdf(_cessAmount)),
                  _buildPdfSummaryRow('Total Tax Liability', formatCurrencyForPdf(_totalTaxLiability)),
                  _buildPdfSummaryRow('Effective Tax Rate', '${_effectiveTaxRate.toStringAsFixed(2)}%'),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Tax Slab Breakdown Section
            pw.Text(
              'Tax Slab Breakdown',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            
            // Tax Slab Table
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
              },
              children: [
                // Table Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _buildPdfTableHeader('Income Slab'),
                    _buildPdfTableHeader('Tax Rate'),
                    _buildPdfTableHeader('Tax Amount'),
                  ],
                ),
                
                // Table Rows
                ..._taxSlabBreakdown.map((slab) {
                  return pw.TableRow(
                    children: [
                      _buildPdfTableCell(slab['slab']),
                      _buildPdfTableCell(slab['rate']),
                      _buildPdfTableCell(formatCurrencyForPdf(slab['tax'])),
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
                'Disclaimer: This is an approximate calculation based on the information provided. Actual tax liability may vary based on other deductions, exemptions, and income sources. Please consult a tax professional for personalized advice.',
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
      final file = File('${output.path}/tax_calculation_report.pdf');
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
      appBar: widget.showAppBar ? AppHeader(title: 'Income Tax Calculator') : null,
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
            Text(
              _formatCurrency(_totalTaxLiability),
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
                  title: 'Taxable Income',
                  value: _formatCurrency(_taxableIncome),
                ),
                _buildResultDetail(
                  title: 'Income Tax',
                  value: _formatCurrency(_taxAmount),
                ),
                _buildResultDetail(
                  title: 'Effective Rate',
                  value: '${_effectiveTaxRate.toStringAsFixed(1)}%',
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
                  child: TextField(
                    controller: _incomeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Total Income (₹)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.currency_rupee),
                      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    ),
                    onChanged: (_) => _calculateTax(),
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
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Investments (80C) (₹)',
                helperText: 'PF, PPF, LIC, ELSS, etc. Max: ₹1,50,000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.savings),
                contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              ),
              onChanged: (_) => _calculateTax(),
            ),
            const SizedBox(height: 16),
            
            // Other Deductions
            TextField(
              controller: _deductionsController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Other Deductions (₹)',
                helperText: 'HRA, Medical Insurance, NPS, etc.',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.money_off),
                contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _generatePDF,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('GENERATE TAX REPORT'),
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
                          color: slab['tax'] > 0 ? Colors.red.shade700 : Colors.grey.shade800,
                          fontWeight: slab['tax'] > 0 ? FontWeight.w500 : FontWeight.normal,
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
              description: 'Invest in PPF, ELSS, EPF, etc. to claim deduction up to ₹1.5 lakhs',
            ),
            _buildTaxTip(
              icon: Icons.local_hospital,
              title: 'Health Insurance Premium',
              description: 'Claim deduction up to ₹25,000 under Section 80D for health insurance premiums',
            ),
            _buildTaxTip(
              icon: Icons.account_balance,
              title: 'National Pension Scheme',
              description: 'Invest in NPS to claim additional deduction up to ₹50,000 under Section 80CCD(1B)',
            ),
            _buildTaxTip(
              icon: Icons.home,
              title: 'Home Loan Benefits',
              description: 'Claim interest up to ₹2 lakhs under Section 24(b) and principal under Section 80C',
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