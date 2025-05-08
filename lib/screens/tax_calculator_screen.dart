import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:intl/intl.dart';

// Create the missing services and controllers
class PdfTemplateService {
  static String formatCurrency(double value) {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 2);
    return formatter.format(value);
  }
}

class TaxCalculatorScreen extends StatefulWidget {
  const TaxCalculatorScreen({super.key});

  @override
  State<TaxCalculatorScreen> createState() => _TaxCalculatorScreenState();
}

class _TaxCalculatorScreenState extends State<TaxCalculatorScreen> {
  // Controllers
  final TextEditingController _incomeController = TextEditingController(text: '500000');
  final TextEditingController _investmentsController = TextEditingController(text: '50000');
  final TextEditingController _deductionsController = TextEditingController(text: '50000');
  
  // Tax regime selection
  bool _isOldRegime = true;
  
  // Tax calculation results
  double _taxableIncome = 450000;
  double _taxAmount = 0;
  double _cessAmount = 0;
  double _totalTaxLiability = 0;
  double _effectiveTaxRate = 0;
  List<Map<String, dynamic>> _taxSlabBreakdown = [];
  
  // Define tax slabs
  final Map<String, List<Map<String, dynamic>>> _taxSlabs = {
    'OldRegime': [
      {'start': 0, 'end': 250000, 'rate': 0},
      {'start': 250000, 'end': 500000, 'rate': 5},
      {'start': 500000, 'end': 1000000, 'rate': 20},
      {'start': 1000000, 'end': double.infinity, 'rate': 30},
    ],
    'NewRegime': [
      {'start': 0, 'end': 300000, 'rate': 0},
      {'start': 300000, 'end': 600000, 'rate': 5},
      {'start': 600000, 'end': 900000, 'rate': 10},
      {'start': 900000, 'end': 1200000, 'rate': 15},
      {'start': 1200000, 'end': 1500000, 'rate': 20},
      {'start': 1500000, 'end': double.infinity, 'rate': 30},
    ],
  };
  
  @override
  void initState() {
    super.initState();
    _calculateTax();
  }
  
  @override
  void dispose() {
    _incomeController.dispose();
    _investmentsController.dispose();
    _deductionsController.dispose();
    super.dispose();
  }
  
  // Calculate tax based on inputs
  void _calculateTax() {
    // Parse input values
    double income = double.tryParse(_incomeController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    double investments = double.tryParse(_investmentsController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    double deductions = double.tryParse(_deductionsController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    
    // Calculate taxable income
    double taxableIncome = income;
    
    // Apply deductions based on regime
    if (_isOldRegime) {
      // In old regime, apply standard deduction of 50,000
      taxableIncome -= 50000;
      
      // Apply section 80C and other deductions
      double totalDeductions = investments + deductions;
      totalDeductions = totalDeductions > 150000 ? 150000 : totalDeductions;
      taxableIncome -= totalDeductions;
    } else {
      // In new regime, only apply standard deduction of 50,000
      taxableIncome -= 50000;
    }
    
    // Ensure taxable income is not negative
    taxableIncome = taxableIncome < 0 ? 0 : taxableIncome;
    
    // Get appropriate tax slabs based on selected regime
    final slabs = _isOldRegime ? _taxSlabs['OldRegime']! : _taxSlabs['NewRegime']!;
    
    // Calculate tax amount
    double taxAmount = 0;
    List<Map<String, dynamic>> breakdown = [];
    
    for (var slab in slabs) {
      double start = slab['start'].toDouble();
      double end = slab['end'].toDouble();
      int rate = slab['rate'];
      
      if (taxableIncome > start) {
        double slabAmount = taxableIncome > end ? end - start : taxableIncome - start;
        double slabTax = slabAmount * rate / 100;
        
        if (slabTax > 0) {
          taxAmount += slabTax;
          
          breakdown.add({
            'slab': 'Rs. ${PdfTemplateService.formatCurrency(start)} to Rs. ${end < double.infinity ? PdfTemplateService.formatCurrency(end) : "∞"}',
            'rate': '$rate%',
            'tax': slabTax,
          });
        }
      }
    }
    
    // Calculate cess (4% of tax amount)
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
      _taxSlabBreakdown = breakdown;
    });
  }
  
  Future<void> _generatePdfReport() async {
    // Create a PDF document
    final pdf = pw.Document();
    
    // Get PDF content
    final content = await _createPdfContent();
    
    // Add the content to the PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => content,
      ),
    );
    
    // Save the PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/tax_report.pdf');
    await file.writeAsBytes(await pdf.save());
    
    // Open the PDF
    OpenFile.open(file.path);
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

    // Create PDF content
    final List<pw.Widget> content = [
      // Title
      pw.Center(
        child: pw.Text(
          'Income Tax Calculation Report',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
      pw.SizedBox(height: 20),
      
      // Date and Regime
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
            style: const pw.TextStyle(
              fontSize: 12,
            ),
          ),
          pw.Text(
            'Tax Regime: $regime',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 20),
      
      // Summary Section
      pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Tax Calculation Summary',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            ...summaryItems.map((item) {
              final bool highlight = item['highlight'] == true;
              
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      item['label'],
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: highlight ? pw.FontWeight.bold : null,
                      ),
                    ),
                    pw.Text(
                      item['value'],
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: highlight ? pw.FontWeight.bold : null,
                        color: highlight 
                            ? (item['isPositive'] == true ? PdfColors.green700 : PdfColors.red700)
                            : null,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
      pw.SizedBox(height: 20),
      
      // Tax Breakdown Table
      pw.Text(
        'Tax Slab Breakdown',
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      pw.SizedBox(height: 10),
      
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        children: [
          // Table header
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: tableColumns.map((column) {
              return pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  column,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
          // Table rows
          ...tableRows.map((row) {
            return pw.TableRow(
              children: row.map((cell) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    cell,
                    style: const pw.TextStyle(
                      fontSize: 10,
                    ),
                  ),
                );
              }).toList(),
            );
          }).toList(),
        ],
      ),
      
      pw.SizedBox(height: 30),
      
      // Disclaimer
      pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: const pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Text(
          'Disclaimer: This is an estimated tax calculation. Please consult a tax professional for official advice. Tax calculations are based on rates for Assessment Year 2023-24.',
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey700,
          ),
        ),
      ),
      
      pw.SizedBox(height: 20),
      
      // Footer
      pw.Center(
        child: pw.Text(
          'Generated by My Byaj Book App',
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
          ),
        ),
      ),
    ];
    
    return content;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Income Tax Calculator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePdfReport,
            tooltip: 'Generate PDF Report',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Income Input
            _buildInputField(
              label: 'Annual Income (₹)',
              controller: _incomeController,
              prefixIcon: Icons.currency_rupee,
              onChanged: (_) => _calculateTax(),
            ),
            const SizedBox(height: 16),
            
            // Investments Input
            _buildInputField(
              label: 'Investments - Sec 80C (₹)',
              controller: _investmentsController,
              prefixIcon: Icons.savings,
              onChanged: (_) => _calculateTax(),
            ),
            const SizedBox(height: 16),
            
            // Other Deductions Input
            _buildInputField(
              label: 'Other Deductions (₹)',
              controller: _deductionsController,
              prefixIcon: Icons.receipt_long,
              onChanged: (_) => _calculateTax(),
            ),
            const SizedBox(height: 24),
            
            // Tax Regime Selection
            _buildTaxRegimeSelector(),
            const SizedBox(height: 32),
            
            // Results Section
            _buildResultsSection(),
            const SizedBox(height: 32),
            
            // Tax Breakdown Section
            _buildTaxBreakdownSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData prefixIcon,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      keyboardType: TextInputType.number,
      onChanged: onChanged,
    );
  }

  Widget _buildTaxRegimeSelector() {
    return Card(
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
              'Select Tax Regime',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Old Regime'),
                    value: true,
                    groupValue: _isOldRegime,
                    onChanged: (value) {
                      setState(() {
                        _isOldRegime = value!;
                        _calculateTax();
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('New Regime'),
                    value: false,
                    groupValue: _isOldRegime,
                    onChanged: (value) {
                      setState(() {
                        _isOldRegime = value!;
                        _calculateTax();
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _isOldRegime
                  ? 'Old Regime allows deductions but has higher tax rates.'
                  : 'New Regime has lower tax rates but fewer deductions.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tax Calculation Results',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildResultRow('Taxable Income', 'Rs. ${PdfTemplateService.formatCurrency(_taxableIncome)}'),
            _buildResultRow('Income Tax', 'Rs. ${PdfTemplateService.formatCurrency(_taxAmount)}'),
            _buildResultRow('Health & Education Cess (4%)', 'Rs. ${PdfTemplateService.formatCurrency(_cessAmount)}'),
            const Divider(thickness: 1),
            _buildResultRow(
              'Total Tax Liability',
              'Rs. ${PdfTemplateService.formatCurrency(_totalTaxLiability)}',
              isTotal: true,
            ),
            _buildResultRow(
              'Effective Tax Rate',
              '${_effectiveTaxRate.toStringAsFixed(2)}%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxBreakdownSection() {
    if (_taxSlabBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
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
              'Tax Slab Breakdown',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(2),
              },
              border: TableBorder.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Income Slab',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Rate',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Tax Amount',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                ..._taxSlabBreakdown.map((slab) {
                  double taxAmount = slab['tax'] is double ? slab['tax'] : slab['tax'].toDouble();
                  
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(slab['slab'].toString()),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(slab['rate'].toString()),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text('Rs. ${PdfTemplateService.formatCurrency(taxAmount)}'),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 