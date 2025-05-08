import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:my_byaj_book/services/pdf_template_service.dart';

/// Legacy PDF service - now refactored to use the standardized PdfTemplateService
class PDFService {
  static final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '');
  static final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
  
  /// Generates a PDF report for a contact with their transaction history
  static Future<void> generateContactReport(
    String filePath,
    String contactName,
    String contactPhone,
    List<Map<String, dynamic>> transactions,
    double balance,
    double interestRate,
    String relationshipType,
  ) async {
    // Prepare summary items
    final isPositive = balance >= 0;
    final List<Map<String, dynamic>> summaryItems = [
      {'label': 'Name', 'value': contactName},
      {'label': 'Phone', 'value': contactPhone},
      {
        'label': isPositive ? 'YOU WILL GET' : 'YOU WILL GIVE',
        'value': 'Rs. ${PdfTemplateService.formatCurrency(balance.abs())}',
        'highlight': true,
        'isPositive': isPositive,
      },
    ];
    
    // Add interest information if applicable
    if (interestRate > 0 && relationshipType.isNotEmpty) {
      summaryItems.addAll([
        {'label': 'Interest Rate', 'value': '$interestRate% p.a.'},
        {'label': 'Relationship Type', 'value': relationshipType.isEmpty ? 'N/A' : 
          relationshipType[0].toUpperCase() + relationshipType.substring(1)},
      ]);
    }
    
    // Prepare transaction table data
    final List<String> tableColumns = ['Date', 'Note', 'Amount', 'Type'];
    final List<List<String>> tableRows = [];
    
    for (var transaction in transactions) {
      final date = transaction['date'] != null
          ? DateFormat('dd MMM yyyy').format(DateTime.parse(transaction['date']))
          : 'N/A';
      final note = transaction['note'] ?? '';
      final amount = 'Rs. ${PdfTemplateService.formatCurrency(transaction['amount'])}';
      final type = transaction['type'] == 'credit' ? 'Received' : 'Given';
      
      tableRows.add([date, note, amount, type]);
    }
    
    // Create PDF content
    final content = [
      // Balance Summary
      PdfTemplateService.buildSummaryCard(
        title: 'Balance Summary',
        items: summaryItems,
      ),
      pw.SizedBox(height: 20),
      
      // Transaction table
      PdfTemplateService.buildDataTable(
        title: 'Transaction History',
        columns: tableColumns,
        rows: tableRows,
        columnWidths: [
          const pw.FlexColumnWidth(2),  // Date
          const pw.FlexColumnWidth(3),  // Note
          const pw.FlexColumnWidth(1.5),  // Amount
          const pw.FlexColumnWidth(1.5),  // Type
        ],
      ),
    ];
    
    // Generate the PDF document
    final pdf = await PdfTemplateService.createDocument(
      title: contactName,
      subtitle: 'Transaction Report',
      content: content,
    );
    
    // Save the PDF
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
  }
} 