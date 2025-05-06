import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';

/// A standardized service for generating PDF documents throughout the app
/// with consistent styling, fonts, and layouts.
class PdfTemplateService {
  // Common formatters
  static final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '');
  static final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final shortDateFormat = DateFormat('dd MMM yyyy');
  
  // Standard colors
  static final primaryColor = PdfColors.teal700;
  static final accentColor = PdfColors.teal400;
  static final successColor = PdfColors.green700;
  static final dangerColor = PdfColors.red700;
  static final neutralColor = PdfColors.grey800;
  static final neutralLightColor = PdfColors.grey400;
  static final lightBackgroundColor = PdfColors.grey100;
  static final separatorColor = PdfColors.grey300;
  static final tableHeaderColor = PdfColors.teal100;
  static final tableAlternateColor = PdfColors.grey100;
  
  // Common border styles
  static final defaultBorder = pw.Border.all(color: separatorColor);
  static final roundedBorder = pw.BorderRadius.all(pw.Radius.circular(8));
  
  // Font initialization - make sure to call this before using custom fonts
  static Future<void> initFonts() async {
    // No custom fonts now, using default fonts
  }
  
  /// Creates a standard PDF document with the provided content
  static Future<pw.Document> createDocument({
    required String title,
    required String subtitle,
    required List<pw.Widget> content,
    Map<String, dynamic>? metadata,
    bool showPageNumbers = true,
  }) async {
    final pdf = pw.Document(
      title: title,
      author: 'My Byaj Book',
      creator: 'My Byaj Book App',
      subject: subtitle,
      keywords: 'My Byaj Book, $title, $subtitle',
    );
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => buildHeader(title: title, subtitle: subtitle, metadata: metadata),
        footer: (context) => buildFooter(context, showPageNumbers: showPageNumbers),
        build: (context) => content,
      )
    );
    
    return pdf;
  }
  
  /// Builds a standard header for PDF documents
  static pw.Widget buildHeader({
    required String title,
    required String subtitle,
    Map<String, dynamic>? metadata,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 16),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 1, color: separatorColor)),
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
                  color: primaryColor,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                subtitle,
                style: pw.TextStyle(
                  fontSize: 14,
                  color: neutralColor,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Generated on',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: neutralColor,
                ),
              ),
              pw.Text(
                dateFormat.format(DateTime.now()),
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
  }
  
  /// Builds a standard footer for PDF documents
  static pw.Widget buildFooter(pw.Context context, {bool showPageNumbers = true}) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated using My Byaj Book App',
            style: pw.TextStyle(
              fontSize: 10,
              color: neutralLightColor,
            ),
          ),
          if (showPageNumbers)
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(
                fontSize: 10,
                color: neutralLightColor,
              ),
            ),
        ],
      ),
    );
  }
  
  /// Builds a standard summary card for PDF documents
  static pw.Widget buildSummaryCard({
    required String title,
    required List<Map<String, dynamic>> items,
    bool hasBorder = true,
    PdfColor? backgroundColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: backgroundColor ?? lightBackgroundColor,
        border: hasBorder ? defaultBorder : null,
        borderRadius: roundedBorder,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: 12),
          ...items.map((item) {
            final isHighlighted = item['highlight'] == true;
            final isPositive = item['isPositive'] == true;
            final hasCustomColor = item['customColor'] != null;
            
            PdfColor textColor = neutralColor;
            if (isHighlighted) {
              textColor = isPositive ? successColor : dangerColor;
            } else if (hasCustomColor) {
              textColor = item['customColor'];
            }
            
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    item['label'],
                    style: pw.TextStyle(
                      fontSize: isHighlighted ? 14 : 12,
                      fontWeight: isHighlighted ? pw.FontWeight.bold : pw.FontWeight.normal,
                      color: textColor,
                    ),
                  ),
                  pw.Text(
                    item['value'].toString(),
                    style: pw.TextStyle(
                      fontSize: isHighlighted ? 14 : 12,
                      fontWeight: isHighlighted ? pw.FontWeight.bold : pw.FontWeight.normal,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  
  /// Builds a standard data table for PDF documents
  static pw.Widget buildDataTable({
    required String title,
    required List<String> columns,
    required List<List<String>> rows,
    List<pw.FlexColumnWidth>? columnWidths,
    bool showBorder = true,
    bool alternateRowColors = true,
    bool showTitleInTable = true,
  }) {
    if (rows.isEmpty) {
      return pw.Container(
        alignment: pw.Alignment.center,
        padding: const pw.EdgeInsets.symmetric(vertical: 30),
        child: pw.Text(
          'No data available',
          style: pw.TextStyle(
            fontSize: 14,
            color: neutralLightColor,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      );
    }
    
    // If column widths not specified, create equal widths
    final effectiveColumnWidths = columnWidths ??
        columns.map((_) => const pw.FlexColumnWidth(1)).toList();
        
    final Map<int, pw.TableColumnWidth> columnWidthMap = {};
    for (int i = 0; i < effectiveColumnWidths.length; i++) {
      columnWidthMap[i] = effectiveColumnWidths[i];
    }
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (!showTitleInTable) ...[
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
        ],
        pw.Table(
          border: showBorder ? pw.TableBorder.all(color: separatorColor, width: 0.5) : null,
          columnWidths: columnWidthMap,
          children: [
            // Header row
            pw.TableRow(
              decoration: pw.BoxDecoration(color: tableHeaderColor),
              children: columns.map((column) => pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  column,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              )).toList(),
            ),
            
            // Data rows
            ...rows.asMap().entries.map((entry) {
              final index = entry.key;
              final row = entry.value;
              
              return pw.TableRow(
                decoration: alternateRowColors && index % 2 == 1
                    ? pw.BoxDecoration(color: tableAlternateColor)
                    : null,
                children: row.map((cell) => pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    cell,
                    textAlign: pw.TextAlign.center,
                  ),
                )).toList(),
              );
            }).toList(),
          ],
        ),
      ],
    );
  }
  
  /// Save and open a PDF document
  static Future<void> saveAndOpenPdf(pw.Document pdf, String fileName) async {
    try {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      
      final result = await OpenFile.open(file.path);
      
      if (result.type != 'done') {
        throw Exception('Could not open the file: ${result.message}');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  /// Formats currency for PDF display (without the rupee symbol)
  static String formatCurrency(double amount) {
    // Format without currency symbol
    return 'Rs. ' + amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]},'
    );
  }
} 