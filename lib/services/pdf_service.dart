import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class PDFService {
  static final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
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
    final pdf = pw.Document();
    
    // Add pages to the PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(contactName, contactPhone, balance, interestRate, relationshipType),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildSummary(balance, interestRate, relationshipType),
          pw.SizedBox(height: 20),
          _buildTransactionTable(transactions),
        ],
      )
    );
    
    // Save the PDF
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
  }
  
  static pw.Widget _buildHeader(
    String contactName,
    String contactPhone,
    double balance,
    double interestRate,
    String relationshipType,
  ) {
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
                'Transaction Report',
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
                dateFormat.format(DateTime.now()),
                style: const pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildFooter(pw.Context context) {
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
  }
  
  static pw.Widget _buildSummary(
    double balance,
    double interestRate,
    String relationshipType,
  ) {
    final isPositive = balance >= 0;
    final balanceText = currencyFormat.format(balance.abs());
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Balance Summary',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                isPositive ? 'YOU WILL GET' : 'YOU WILL GIVE',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: isPositive ? PdfColors.green700 : PdfColors.red700,
                ),
              ),
              pw.Text(
                balanceText,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: isPositive ? PdfColors.green700 : PdfColors.red700,
                ),
              ),
            ],
          ),
          
          // Only show interest info if relevant
          if (interestRate > 0 && relationshipType.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Interest Rate:',
                  style: const pw.TextStyle(
                    fontSize: 12,
                  ),
                ),
                pw.Text(
                  '$interestRate% p.a.',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Relationship Type:',
                  style: const pw.TextStyle(
                    fontSize: 12,
                  ),
                ),
                pw.Text(
                  relationshipType.isEmpty ? 'N/A' : 
                  relationshipType[0].toUpperCase() + relationshipType.substring(1),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  static pw.Widget _buildTransactionTable(List<Map<String, dynamic>> transactions) {
    // If no transactions, show message
    if (transactions.isEmpty) {
      return pw.Container(
        alignment: pw.Alignment.center,
        padding: const pw.EdgeInsets.symmetric(vertical: 30),
        child: pw.Text(
          'No transactions found',
          style: const pw.TextStyle(
            fontSize: 14,
            color: PdfColors.grey600,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      );
    }
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Transaction History',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),  // Date
            1: const pw.FlexColumnWidth(3),  // Note
            2: const pw.FlexColumnWidth(1.5),  // Amount
            3: const pw.FlexColumnWidth(1.5),  // Type
          },
          children: [
            // Table header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Date', isHeader: true),
                _buildTableCell('Note', isHeader: true),
                _buildTableCell('Amount', isHeader: true),
                _buildTableCell('Type', isHeader: true),
              ],
            ),
            
            // Table data
            ...transactions.asMap().entries.map((entry) {
              final tx = entry.value;
              final isGave = tx['type'] == 'gave';
              
              return pw.TableRow(
                children: [
                  _buildTableCell(dateFormat.format(tx['date'])),
                  _buildTableCell(tx['note'] ?? ''),
                  _buildTableCell(
                    currencyFormat.format(tx['amount']),
                    textColor: isGave ? PdfColors.red700 : PdfColors.green700,
                    textAlign: pw.TextAlign.right,
                  ),
                  _buildTableCell(
                    isGave ? 'YOU GAVE' : 'YOU GOT',
                    textColor: isGave ? PdfColors.red700 : PdfColors.green700,
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }
  
  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    PdfColor? textColor,
    pw.TextAlign textAlign = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : null,
          color: textColor,
        ),
        textAlign: textAlign,
      ),
    );
  }
} 