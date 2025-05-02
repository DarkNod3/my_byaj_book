import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';

class LandCalculatorScreen extends StatefulWidget {
  static const routeName = '/land-calculator';
  
  final bool showAppBar;
  
  const LandCalculatorScreen({
    super.key, 
    this.showAppBar = true
  });

  @override
  State<LandCalculatorScreen> createState() => _LandCalculatorScreenState();
}

class _LandCalculatorScreenState extends State<LandCalculatorScreen> with SingleTickerProviderStateMixin {
  // Tab controller for calculation methods
  late TabController _tabController;
  
  // Form keys
  final _areaFormKey = GlobalKey<FormState>();
  final _dimensionFormKey = GlobalKey<FormState>();
  
  // Text controllers for area calculation
  final _areaController = TextEditingController(text: '1000');
  
  // Text controllers for dimension calculation
  final _lengthController = TextEditingController(text: '50');
  final _widthController = TextEditingController(text: '20');

  // Input and output unit selections
  String _areaInputUnit = 'Square Feet';
  String _areaOutputUnit = 'Square Meter';
  String _lengthUnit = 'Feet';
  String _widthUnit = 'Feet';
  String _resultUnit = 'Square Feet';
  
  // Current value for price calculator
  double _pricePerUnit = 1000;
  String _priceUnit = 'Square Feet';
  
  // Available unit options
  final List<String> _areaUnitOptions = [
    'Square Feet',
    'Square Meter',
    'Square Yard',
    'Acre',
    'Hectare',
    'Bigha',
    'Biswa',
    'Marla',
    'Kanal',
  ];
  
  final List<String> _lengthUnitOptions = [
    'Feet',
    'Meter',
    'Yard',
    'Inch',
    'Centimeter',
    'Kilometer',
    'Mile',
  ];

  // Hindi translations for units
  final Map<String, String> _hindiUnitNames = {
    'Square Feet': 'वर्ग फुट',
    'Square Meter': 'वर्ग मीटर',
    'Square Yard': 'वर्ग गज',
    'Acre': 'एकड़',
    'Hectare': 'हेक्टेयर',
    'Bigha': 'बीघा',
    'Biswa': 'बिस्वा',
    'Marla': 'मरला',
    'Kanal': 'कनाल',
    'Feet': 'फुट',
    'Meter': 'मीटर',
    'Yard': 'गज',
    'Inch': 'इंच',
    'Centimeter': 'सेंटीमीटर',
    'Kilometer': 'किलोमीटर',
    'Mile': 'मील',
  };

  // Conversion results
  double _areaInputValue = 1000;
  double _areaOutputValue = 92.903;
  double _dimensionResult = 1000;
  double _totalPrice = 1000000;
  
  // Comparison areas for visualization
  List<Map<String, dynamic>> _comparisons = [];
  
  // Number formatter for output
  final _numberFormat = NumberFormat('#,##0.000');
  
  // Format value with commas for Indian number system
  String _formatNumber(double value) {
    return _numberFormat.format(value);
  }
  
  // Conversion chart for reference
  List<Map<String, dynamic>> _conversionChart = [];

  @override
  void initState() {
    super.initState();
    // Initialize tab controller
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    
    // Calculate conversion on init
    _calculateAreaConversion();
    _calculateDimensionArea();
    _generateConversionChart();
    _generateComparisons();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _areaController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      // Force re-calculation when tab changes
      setState(() {});
    }
  }

  void _calculateAreaConversion() {
    try {
      // Parse input value
      double inputValue = double.tryParse(_areaController.text) ?? 1000;
      
      // Convert to base unit (sq meters)
      double baseValue = _convertToSquareMeters(inputValue, _areaInputUnit);
      
      // Convert from base unit to output unit
      double outputValue = _convertFromSquareMeters(baseValue, _areaOutputUnit);
      
      // Calculate price
      double pricePerUnitInTargetUnit = _convertPricePerUnit(_pricePerUnit, _priceUnit, _areaOutputUnit);
      double totalPrice = outputValue * pricePerUnitInTargetUnit;
      
      setState(() {
        _areaInputValue = inputValue;
        _areaOutputValue = outputValue;
        _totalPrice = totalPrice;
      });
    } catch (e) {
      // Use defaults if calculation fails
      setState(() {
        _areaInputValue = double.tryParse(_areaController.text) ?? 1000;
        _areaOutputValue = 0;
        _totalPrice = 0;
      });
      print('Area land calculation error: $e');
    }
  }
  
  void _calculateDimensionArea() {
    try {
      // Parse length and width values
      double length = double.tryParse(_lengthController.text) ?? 50;
      double width = double.tryParse(_widthController.text) ?? 20;
      
      // Convert length and width to meters
      double lengthInMeters = _convertLengthToMeters(length, _lengthUnit);
      double widthInMeters = _convertLengthToMeters(width, _widthUnit);
      
      // Calculate area in square meters
      double areaInSqMeters = lengthInMeters * widthInMeters;
      
      // Convert to result unit
      double resultArea = _convertFromSquareMeters(areaInSqMeters, _resultUnit);
      
      // Calculate price
      double pricePerUnitInTargetUnit = _convertPricePerUnit(_pricePerUnit, _priceUnit, _resultUnit);
      double totalPrice = resultArea * pricePerUnitInTargetUnit;
      
      setState(() {
        _dimensionResult = resultArea;
        _totalPrice = totalPrice;
      });
    } catch (e) {
      // Use defaults if calculation fails
      setState(() {
        _dimensionResult = 0;
        _totalPrice = 0;
      });
      print('Dimension land calculation error: $e');
    }
  }
  
  double _convertLengthToMeters(double value, String fromUnit) {
    switch (fromUnit) {
      case 'Feet':
        return value * 0.3048;
      case 'Meter':
        return value;
      case 'Yard':
        return value * 0.9144;
      case 'Inch':
        return value * 0.0254;
      case 'Centimeter':
        return value * 0.01;
      case 'Kilometer':
        return value * 1000;
      case 'Mile':
        return value * 1609.34;
      default:
        return value;
    }
  }
  
  double _convertLengthFromMeters(double meters, String toUnit) {
    switch (toUnit) {
      case 'Feet':
        return meters / 0.3048;
      case 'Meter':
        return meters;
      case 'Yard':
        return meters / 0.9144;
      case 'Inch':
        return meters / 0.0254;
      case 'Centimeter':
        return meters / 0.01;
      case 'Kilometer':
        return meters / 1000;
      case 'Mile':
        return meters / 1609.34;
      default:
        return meters;
    }
  }
  
  double _convertToSquareMeters(double value, String fromUnit) {
    switch (fromUnit) {
      case 'Square Feet':
        return value * 0.092903;
      case 'Square Meter':
        return value;
      case 'Square Yard':
        return value * 0.836127;
      case 'Acre':
        return value * 4046.86;
      case 'Hectare':
        return value * 10000;
      case 'Bigha':
        return value * 1618.74; // Standard North Indian Bigha
      case 'Biswa':
        return value * 125.42; // Standard North Indian Biswa
      case 'Marla':
        return value * 25.29; // Standard Marla
      case 'Kanal':
        return value * 505.86; // Standard Kanal
      default:
        return value;
    }
  }
  
  double _convertFromSquareMeters(double sqMeters, String toUnit) {
    switch (toUnit) {
      case 'Square Feet':
        return sqMeters / 0.092903;
      case 'Square Meter':
        return sqMeters;
      case 'Square Yard':
        return sqMeters / 0.836127;
      case 'Acre':
        return sqMeters / 4046.86;
      case 'Hectare':
        return sqMeters / 10000;
      case 'Bigha':
        return sqMeters / 1618.74; // Standard North Indian Bigha
      case 'Biswa':
        return sqMeters / 125.42; // Standard North Indian Biswa
      case 'Marla':
        return sqMeters / 25.29; // Standard Marla
      case 'Kanal':
        return sqMeters / 505.86; // Standard Kanal
      default:
        return sqMeters;
    }
  }
  
  double _convertPricePerUnit(double price, String fromUnit, String toUnit) {
    // Convert price per unit from one unit to another
    if (fromUnit == toUnit) return price;
    
    // First, convert price to price per square meter
    double pricePerSqMeter = price / _convertFromSquareMeters(1, fromUnit);
    
    // Then convert price per square meter to price per target unit
    return pricePerSqMeter * _convertFromSquareMeters(1, toUnit);
  }
  
  void _generateConversionChart() {
    _conversionChart = [];
    
    // Use 1 unit of input as reference
    String sourceUnit = _tabController.index == 0 ? _areaInputUnit : _resultUnit;
    double baseValue = _convertToSquareMeters(1.0, sourceUnit);
    
    // Generate conversion for all area units
    for (String unit in _areaUnitOptions) {
      double convertedValue = _convertFromSquareMeters(baseValue, unit);
      _conversionChart.add({
        'unit': unit,
        'hindi_unit': _hindiUnitNames[unit] ?? unit,
        'value': convertedValue,
      });
    }
  }
  
  void _generateComparisons() {
    _comparisons = [];
    
    // Determine the current area based on active tab
    double areaSqMeters = _tabController.index == 0
        ? _convertToSquareMeters(_areaInputValue, _areaInputUnit)
        : _convertToSquareMeters(_dimensionResult, _resultUnit);
    
    // Tennis court (about 260 sq meters)
    _comparisons.add({
      'name': 'Tennis Court',
      'hindi_name': 'टेनिस कोर्ट',
      'area': 260.0,
      'icon': Icons.sports_tennis,
      'color': Colors.green,
      'ratio': areaSqMeters / 260.0,
    });
    
    // Basketball court (about 420 sq meters)
    _comparisons.add({
      'name': 'Basketball Court',
      'hindi_name': 'बास्केटबॉल कोर्ट',
      'area': 420.0,
      'icon': Icons.sports_basketball,
      'color': Colors.orange,
      'ratio': areaSqMeters / 420.0,
    });
    
    // Football field (about 7000 sq meters)
    _comparisons.add({
      'name': 'Football Field',
      'hindi_name': 'फुटबॉल मैदान',
      'area': 7000.0,
      'icon': Icons.sports_football,
      'color': Colors.blue,
      'ratio': areaSqMeters / 7000.0,
    });
    
    // 2BHK apartment (about 80 sq meters)
    _comparisons.add({
      'name': '2BHK Apartment',
      'hindi_name': '2BHK अपार्टमेंट',
      'area': 80.0,
      'icon': Icons.apartment,
      'color': Colors.purple,
      'ratio': areaSqMeters / 80.0,
    });
  }
  
  void _resetCalculator() {
    if (_tabController.index == 0) {
      // Reset area calculator
      _areaController.text = '1000';
      _areaInputUnit = 'Square Feet';
      _areaOutputUnit = 'Square Meter';
    } else {
      // Reset dimension calculator
      _lengthController.text = '50';
      _widthController.text = '20';
      _lengthUnit = 'Feet';
      _widthUnit = 'Feet';
      _resultUnit = 'Square Feet';
    }
    
    // Reset price calculator
    _pricePerUnit = 1000;
    _priceUnit = 'Square Feet';
    
    // Recalculate immediately after reset
    if (_tabController.index == 0) {
      _calculateAreaConversion();
    } else {
      _calculateDimensionArea();
    }
    _generateConversionChart();
    _generateComparisons();
  }

  Future<void> _generatePDF() async {
    final pdf = pw.Document();
    
    // Create a custom formatter for the PDF report
    String formatNumberForPdf(double value) {
      return NumberFormat('#,##0.000').format(value);
    }
    
    // Get basic conversion details for the report based on active tab
    String calculationMethod = _tabController.index == 0 ? 'Area-based' : 'Dimension-based';
    double resultValue = _tabController.index == 0 ? _areaOutputValue : _dimensionResult;
    String resultUnit = _tabController.index == 0 ? _areaOutputUnit : _resultUnit;
    
    // Create a PDF document
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Column(
              children: [
                pw.Text(
              'Land Measurement Conversion Report',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'भूमि माप रूपांतरण रिपोर्ट',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    font: pw.Font.helvetica(),
                  ),
                ),
              ],
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
            // Calculation Method
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
              child: pw.Row(
                children: [
                  pw.Text(
                    'Calculation Method: $calculationMethod',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Conversion Summary Section
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
                    'Land Measurement Summary / भूमि माप सारांश',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 15),
                  
                  // Different content based on calculation method
                  if (_tabController.index == 0) ...[
                    _buildPdfSummaryRow('Input Value', 
                      '$_areaInputValue ${_hindiUnitNames[_areaInputUnit] ?? _areaInputUnit} ($_areaInputUnit)'),
                    _buildPdfSummaryRow('Converted Value', 
                      '${formatNumberForPdf(_areaOutputValue)} ${_hindiUnitNames[_areaOutputUnit] ?? _areaOutputUnit} ($_areaOutputUnit)'),
                  ] else ...[
                    _buildPdfSummaryRow('Length', 
                      '${_lengthController.text} ${_hindiUnitNames[_lengthUnit] ?? _lengthUnit} ($_lengthUnit)'),
                    _buildPdfSummaryRow('Width', 
                      '${_widthController.text} ${_hindiUnitNames[_widthUnit] ?? _widthUnit} ($_widthUnit)'),
                    _buildPdfSummaryRow('Calculated Area', 
                      '${formatNumberForPdf(_dimensionResult)} ${_hindiUnitNames[_resultUnit] ?? _resultUnit} ($_resultUnit)'),
                  ],
                  
                  pw.Divider(),
                  _buildPdfSummaryRow('Price Per Unit', 
                    '₹${formatNumberForPdf(_pricePerUnit)} per ${_hindiUnitNames[_priceUnit] ?? _priceUnit}'),
                  _buildPdfSummaryRow('Total Price', 
                    '₹${formatNumberForPdf(_totalPrice)}',
                    isHighlighted: true),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Conversion Chart Section
            pw.Text(
              'Conversion Chart / रूपांतरण चार्ट',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              _tabController.index == 0 
                  ? '1 $_areaInputUnit equals (1 ${_hindiUnitNames[_areaInputUnit] ?? _areaInputUnit} बराबर है)'
                  : '1 $_resultUnit equals (1 ${_hindiUnitNames[_resultUnit] ?? _resultUnit} बराबर है)',
              style: const pw.TextStyle(
                fontSize: 12,
              ),
            ),
            pw.SizedBox(height: 10),
            
            // Conversion Chart Table
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1.5),
              },
              children: [
                // Table Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _buildPdfTableHeader('Unit (English)'),
                    _buildPdfTableHeader('Unit (Hindi)'),
                    _buildPdfTableHeader('Value'),
                  ],
                ),
                
                // Table Rows
                ..._conversionChart.map((conversion) {
                  return pw.TableRow(
                    children: [
                      _buildPdfTableCell(conversion['unit']),
                      _buildPdfTableCell(conversion['hindi_unit']),
                      _buildPdfTableCell(formatNumberForPdf(conversion['value'])),
                    ],
                  );
                }).toList(),
              ],
            ),
            
            pw.SizedBox(height: 20),
            
            // Area Comparison Visualization
            pw.Text(
              'Area Comparison / क्षेत्र तुलना',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: _comparisons.map((comparison) {
                  double ratio = comparison['ratio'];
                  String comparisonText = ratio < 1 
                      ? '${formatNumberForPdf(1/ratio)} times smaller than' 
                      : '${formatNumberForPdf(ratio)} times larger than';
                  
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 5),
                    child: pw.Text('$resultUnit ($resultValue) is $comparisonText a ${comparison['name']} (${comparison['hindi_name']})'),
                  );
                }).toList(),
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Regional Variations Note
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                'Note: Units like Bigha, Biswa, Marla, and Kanal may vary in different regions of India. This calculator uses standard North Indian measurements. Please verify the exact conversion rates applicable to your specific region.',
                style: const pw.TextStyle(
                  fontSize: 10,
                  fontStyle: pw.FontStyle.italic,
                ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'नोट: बीघा, बिस्वा, मरला और कनाल जैसी इकाइयाँ भारत के विभिन्न क्षेत्रों में अलग-अलग हो सकती हैं। यह कैलकुलेटर मानक उत्तर भारतीय माप का उपयोग करता है। कृपया अपने विशिष्ट क्षेत्र के लिए लागू सटीक रूपांतरण दरों की पुष्टि करें।',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );
    
    try {
      // Save the PDF
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/land_conversion_report.pdf');
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
  
  pw.Widget _buildPdfSummaryRow(String label, String value, {bool isHighlighted = false}) {
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
              fontSize: isHighlighted ? 14 : 12,
              fontWeight: pw.FontWeight.bold,
              color: isHighlighted ? PdfColors.green800 : PdfColors.black,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar ? AppBar(
        title: const Text('Land Calculator'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.square_foot),
              text: 'Area Based',
            ),
            Tab(
              icon: Icon(Icons.straighten),
              text: 'Dimension Based',
            ),
          ],
        ),
      ) : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          // Area-based calculator
          _buildAreaCalculator(),
          
          // Dimension-based calculator
          _buildDimensionCalculator(),
        ],
      ),
    );
  }
  
  Widget _buildAreaCalculator() {
    return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Form(
          key: _areaFormKey,
            onChanged: () {
            _calculateAreaConversion();
              _generateConversionChart();
            _generateComparisons();
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              _buildResultCard(_areaOutputValue, _areaOutputUnit),
                const SizedBox(height: 16),
              _buildAreaCalculatorCard(),
              const SizedBox(height: 16),
              _buildPriceCalculator(),
                const SizedBox(height: 16),
                _buildPdfButton(),
              const SizedBox(height: 16),
              _buildAreaComparison(),
                const SizedBox(height: 16),
                _buildConversionChart(),
                const SizedBox(height: 16),
                _buildRegionalNote(),
              ],
            ),
        ),
      ),
    );
  }
  
  Widget _buildDimensionCalculator() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _dimensionFormKey,
          onChanged: () {
            _calculateDimensionArea();
            _generateConversionChart();
            _generateComparisons();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildResultCard(_dimensionResult, _resultUnit),
              const SizedBox(height: 16),
              _buildDimensionCalculatorCard(),
              const SizedBox(height: 16),
              _buildPriceCalculator(),
              const SizedBox(height: 16),
              _buildPdfButton(),
              const SizedBox(height: 16),
              _buildAreaComparison(),
              const SizedBox(height: 16),
              _buildConversionChart(),
              const SizedBox(height: 16),
              _buildRegionalNote(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(double value, String unit) {
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
            colors: [Colors.green.shade600, Colors.green.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Calculated Area',
                  style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message: 'This is the converted/calculated area value in the selected unit',
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatNumber(value),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${_hindiUnitNames[unit] ?? unit})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Estimated Price:',
                        style: TextStyle(
                      fontSize: 14,
                          fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                        '₹${_formatNumber(_totalPrice)}',
                        style: TextStyle(
                          fontSize: 16,
                      fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'At ₹${_formatNumber(_pricePerUnit)} per ${_priceUnit}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
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

  Widget _buildAreaCalculatorCard() {
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
              crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
                  'Area Conversion',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Enter the area value and select the units to convert between different measurement systems',
                  child: Icon(
                    Icons.help_outline,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Convert between different land measurement units',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            
            // Area input with Reset button
            Row(
              children: [
                // Area input (80%)
                Expanded(
                  flex: 80,
                  child: TextField(
                    controller: _areaController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Enter Area',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.straighten),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      suffixText: _areaInputUnit,
                    ),
                    onChanged: (_) {
                      _calculateAreaConversion();
                      _generateConversionChart();
                      _generateComparisons();
                    },
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
            
            // From Unit Dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                  'From Unit:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'इनपुट इकाई',
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: ButtonTheme(
                            alignedDropdown: true,
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _areaInputUnit,
                              items: _areaUnitOptions.map((String unit) {
                                return DropdownMenuItem<String>(
                                  value: unit,
                                  child: Row(
                                    children: [
                                      Text(unit),
                                      const SizedBox(width: 4),
                                      Text(
                                        '(${_hindiUnitNames[unit] ?? unit})',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _areaInputUnit = newValue;
                                    _calculateAreaConversion();
                                    _generateConversionChart();
                                    _generateComparisons();
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // To Unit Dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                  'To Unit:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'आउटपुट इकाई',
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: ButtonTheme(
                            alignedDropdown: true,
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _areaOutputUnit,
                              items: _areaUnitOptions.map((String unit) {
                                return DropdownMenuItem<String>(
                                  value: unit,
                                  child: Row(
                                    children: [
                                      Text(unit),
                                      const SizedBox(width: 4),
                                      Text(
                                        '(${_hindiUnitNames[unit] ?? unit})',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _areaOutputUnit = newValue;
                                    _calculateAreaConversion();
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDimensionCalculatorCard() {
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Dimension-Based Area Calculation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Calculate area by entering length and width dimensions',
                  child: Icon(
                    Icons.help_outline,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Calculate area from length and width dimensions',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            
            // Visual representation of length x width
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.green.shade700,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.arrow_left,
                              color: Colors.black54,
                            ),
                            Text(
                              'Width',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_right,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            RotatedBox(
                              quarterTurns: 3,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.arrow_left,
                                    color: Colors.black54,
                                    size: 14,
                                  ),
                                  Text(
                                    'Length',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_right,
                                    color: Colors.black54,
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Area = Length × Width',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'क्षेत्रफल = लंबाई × चौड़ाई',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Length input
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'Length:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'लंबाई',
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Length value (70%)
                    Expanded(
                      flex: 70,
                      child: TextField(
                        controller: _lengthController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        ),
                        onChanged: (_) {
                          _calculateDimensionArea();
                          _generateConversionChart();
                          _generateComparisons();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Length unit (30%)
                    Expanded(
                      flex: 30,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: ButtonTheme(
                            alignedDropdown: true,
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _lengthUnit,
                              items: _lengthUnitOptions.map((String unit) {
                                return DropdownMenuItem<String>(
                                  value: unit,
                                  child: Text(
                                    unit,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _lengthUnit = newValue;
                                    _calculateDimensionArea();
                                    _generateComparisons();
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Width input
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'Width:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'चौड़ाई',
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Width value (70%)
                    Expanded(
                      flex: 70,
                      child: TextField(
                        controller: _widthController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        ),
                        onChanged: (_) {
                          _calculateDimensionArea();
                          _generateConversionChart();
                          _generateComparisons();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Width unit (30%)
                    Expanded(
                      flex: 30,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: ButtonTheme(
                            alignedDropdown: true,
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _widthUnit,
                              items: _lengthUnitOptions.map((String unit) {
                                return DropdownMenuItem<String>(
                                  value: unit,
                                  child: Text(
                                    unit,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _widthUnit = newValue;
                                    _calculateDimensionArea();
                                    _generateComparisons();
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Result unit
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'Result Unit:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'परिणाम इकाई',
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: ButtonTheme(
                            alignedDropdown: true,
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _resultUnit,
                              items: _areaUnitOptions.map((String unit) {
                                return DropdownMenuItem<String>(
                                  value: unit,
                                  child: Row(
                                    children: [
                                      Text(unit),
                                      const SizedBox(width: 4),
                                      Text(
                                        '(${_hindiUnitNames[unit] ?? unit})',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _resultUnit = newValue;
                                    _calculateDimensionArea();
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Reset Button for dimensions
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _resetCalculator,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset Values'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPriceCalculator() {
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Price Calculator',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Calculate the total price based on area and per-unit price',
                  child: Icon(
                    Icons.help_outline,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Calculate total cost based on per-unit price',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            
            // Price per unit input
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'Price Per Unit:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'प्रति इकाई मूल्य',
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Price value (70%)
                    Expanded(
                      flex: 70,
                      child: TextField(
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixText: '₹ ',
                          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        ),
                        onChanged: (value) {
                          double newPrice = double.tryParse(value) ?? _pricePerUnit;
                          setState(() {
                            _pricePerUnit = newPrice;
                            if (_tabController.index == 0) {
                              _calculateAreaConversion();
                            } else {
                              _calculateDimensionArea();
                            }
                          });
                        },
                        controller: TextEditingController(text: _pricePerUnit.toString()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Price unit (30%)
                    Expanded(
                      flex: 30,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: ButtonTheme(
                            alignedDropdown: true,
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _priceUnit,
                              items: _areaUnitOptions.map((String unit) {
                                return DropdownMenuItem<String>(
                                  value: unit,
                                  child: Text(
                                    unit,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _priceUnit = newValue;
                                    if (_tabController.index == 0) {
                                      _calculateAreaConversion();
                                    } else {
                                      _calculateDimensionArea();
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Total price result
            Container(
      width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Price:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '₹${_formatNumber(_totalPrice)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'कुल मूल्य: ₹${_formatNumber(_totalPrice)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
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
  
  Widget _buildAreaComparison() {
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Area Comparison',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Visual comparison of your area with common reference areas',
                  child: Icon(
                    Icons.help_outline,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'क्षेत्र तुलना',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _generateComparisons,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    foregroundColor: Colors.green.shade700,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Comparison visualizations
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _comparisons.length,
              itemBuilder: (context, index) {
                final comparison = _comparisons[index];
                final double ratio = comparison['ratio'] as double;
                final String comparisonText = ratio < 1 
                    ? '${_formatNumber(1/ratio)} times smaller than' 
                    : '${_formatNumber(ratio)} times larger than';
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Comparison description
                      Row(
                        children: [
                          Icon(
                            comparison['icon'] as IconData,
                            color: comparison['color'] as Color,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${comparison['name']} (${comparison['hindi_name']})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Your area is $comparisonText a ${comparison['name']}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Visual comparison bar
                      Container(
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade200,
                        ),
                        child: Row(
                          children: [
                            Flexible(
                              flex: min(10000, max(1, (ratio * 100).toInt())),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: comparison['color'] as Color,
                                ),
                                child: ratio > 0.25 ? Center(
                                  child: Text(
                                    'Your Area',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ) : const SizedBox(),
                              ),
                            ),
                            if (ratio < 1) Flexible(
                              flex: min(10000, max(1, ((1 - ratio) * 100).toInt())),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topRight: const Radius.circular(12),
                                    bottomRight: const Radius.circular(12),
                                  ),
                                  color: Colors.grey.shade200,
                                ),
                                child: ratio < 0.75 ? Center(
                                  child: Text(
                                    '${comparison['name']}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ) : const SizedBox(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionChart() {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _tabController.index == 0
                        ? '1 $_areaInputUnit equals'
                        : '1 $_resultUnit equals',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Conversion rates between different units',
                      child: Icon(
                        Icons.help_outline,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _tabController.index == 0
                    ? '1 ${_hindiUnitNames[_areaInputUnit] ?? _areaInputUnit} बराबर है'
                    : '1 ${_hindiUnitNames[_resultUnit] ?? _resultUnit} बराबर है',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
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
                  flex: 3,
                  child: Text(
                    'Unit (English / Hindi)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Value',
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
          // Chart rows - limit to 6 rows
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: min(6, _conversionChart.length),
            itemBuilder: (context, index) {
              final conversion = _conversionChart[index];
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
                      flex: 3,
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade800,
                          ),
                          children: [
                            TextSpan(
                              text: conversion['unit'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextSpan(
                              text: ' (${conversion['hindi_unit']})',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _formatNumber(conversion['value']),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Show more button if there are more units
          if (_conversionChart.length > 6)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Complete Conversion Chart'),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _conversionChart.length,
                        itemBuilder: (context, index) {
                          final conversion = _conversionChart[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    '${conversion['unit']} (${conversion['hindi_unit']})',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    _formatNumber(conversion['value']),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Show All Units'),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionalNote() {
    return Card(
      elevation: 2,
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
                Icon(
                  Icons.info_outline,
                  color: Colors.amber.shade700,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Regional Variations',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Units like Bigha, Biswa, Marla, and Kanal may vary significantly in different regions of India. This calculator uses standard North Indian measurements. Please verify the exact conversion rates applicable to your specific region.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'क्षेत्रीय विविधताएं: बीघा, बिस्वा, मरला और कनाल जैसी इकाइयाँ भारत के विभिन्न क्षेत्रों में अलग-अलग हो सकती हैं। यह कैलकुलेटर मानक उत्तर भारतीय माप का उपयोग करता है। कृपया अपने विशिष्ट क्षेत्र के लिए लागू सटीक रूपांतरण दरों की पुष्टि करें।',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Help & Information'),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHelpSection('Area-based Calculator', 
                            'Enter any land area and convert it to different units.'),
                          _buildHelpSection('Dimension-based Calculator', 
                            'Calculate area by entering length and width values.'),
                          _buildHelpSection('Price Calculator', 
                            'Calculate total price based on per-unit price.'),
                          _buildHelpSection('Area Comparisons', 
                            'Visualize your land size compared to common references.'),
                          _buildHelpSection('Units Dictionary', [
                            'Bigha (बीघा): Varies by region, standard ~1618 sq.m.',
                            'Biswa (बिस्वा): 1/20th of a Bigha, ~125 sq.m.',
                            'Marla (मरला): Common in North India, ~25 sq.m.',
                            'Kanal (कनाल): Common in Himachal/Punjab, ~505 sq.m.',
                          ].join('\n')),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              icon: Icon(
                Icons.help,
                color: Colors.green.shade700,
              ),
              label: const Text('Help & Information'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHelpSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(fontSize: 14),
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
        label: const Text('GENERATE CONVERSION REPORT'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
} 