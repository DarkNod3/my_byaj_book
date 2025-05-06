import 'package:flutter/material.dart';
import 'package:pdf_template_service/pdf_template_service.dart';

class TaxCalculatorScreen extends StatefulWidget {
  // ... (existing code)
}

class _TaxCalculatorScreenState extends State<TaxCalculatorScreen> {
  // ... (existing code)

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

    // ... (rest of the existing code)
  }

  // ... (rest of the existing code)
} 