import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';

/// A standardized service for generating PDF documents throughout the app
/// with consistent styling, fonts, and layouts.
class PdfTemplateService {
  // Common formatters
  static final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '');
  static final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final shortDateFormat = DateFormat('dd MMM yyyy');
  
  // Standard colors
  static const primaryColor = PdfColors.teal700;
  static const accentColor = PdfColors.teal400;
  static const successColor = PdfColors.green700;
  static const dangerColor = PdfColors.red700;
  static const neutralColor = PdfColors.grey800;
  static const neutralLightColor = PdfColors.grey400;
  static const lightBackgroundColor = PdfColors.grey100;
  static const separatorColor = PdfColors.grey300;
  static const tableHeaderColor = PdfColors.teal100;
  static const tableAlternateColor = PdfColors.grey100;
  
  // Common border styles
  static final defaultBorder = pw.Border.all(color: separatorColor);
  static const roundedBorder = pw.BorderRadius.all(pw.Radius.circular(8));
  
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
    // Using compute to run in background
    return compute(_createPdfDocument, {
      'title': title,
      'subtitle': subtitle,
      'keywords': metadata?['keywords'] ?? '',
    }).then((pdf) async {
      // We can't return the document with content directly since pw.Widget isn't serializable
      // Add all content to a single page rather than creating multiple pages
      pdf.addPage(
        pw.Page(
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Add the header
                buildHeader(
                  title: title,
                  subtitle: subtitle,
                  metadata: metadata,
                ),
                pw.SizedBox(height: 20),
                
                // Main content - all widgets in a single column
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: content,
                ),
                
                // Add the footer
                buildFooter(context, showPageNumbers: showPageNumbers),
              ],
            );
          },
        ),
      );
      return pdf;
    });
  }
  
  /// Builds a standard header for PDF documents
  static pw.Widget buildHeader({
    required String title,
    required String subtitle,
    Map<String, dynamic>? metadata,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 1, color: separatorColor)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              // Simple logo placeholder
              pw.Container(
                width: 40,
                height: 40,
                decoration: const pw.BoxDecoration(
                  color: primaryColor,
                  shape: pw.BoxShape.circle,
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'MB',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
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
                    title,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: neutralColor,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    subtitle,
                    style: const pw.TextStyle(
                      fontSize: 14,
                      color: neutralColor,
                    ),
                  ),
                ],
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
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'OFFICIAL REPORT',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
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
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(width: 0.5, color: separatorColor)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'My Byaj Book - Personal Finance Manager',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Generated using My Byaj Book App • mybyajbook.com',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: neutralLightColor,
                ),
              ),
            ],
          ),
          if (showPageNumbers)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: pw.BoxDecoration(
                color: lightBackgroundColor,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: neutralColor,
                ),
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
              decoration: const pw.BoxDecoration(color: tableHeaderColor),
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
                    ? const pw.BoxDecoration(color: tableAlternateColor)
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
  
  /// Builds a traditional ledger style table for PDF documents
  static pw.Widget buildLedgerTable({
    required String title,
    required List<String> columns,
    required List<List<String>> rows,
    Map<int, pw.TableColumnWidth>? columnWidths,
    bool alternateRowColor = true,
    bool showBorder = true,
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
    final Map<int, pw.TableColumnWidth> effectiveColumnWidths = columnWidths ?? {};
    if (effectiveColumnWidths.isEmpty) {
      for (int i = 0; i < columns.length; i++) {
        effectiveColumnWidths[i] = const pw.FlexColumnWidth(1);
      }
    }
    
    return pw.Column(
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
        pw.Container(
          decoration: pw.BoxDecoration(
            border: showBorder ? pw.Border.all(color: separatorColor) : null,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Table(
            border: showBorder ? pw.TableBorder.all(color: separatorColor, width: 0.5) : null,
            columnWidths: effectiveColumnWidths,
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: tableHeaderColor),
                children: columns.asMap().entries.map((entry) {
                  final index = entry.key;
                  final column = entry.value;
                  
                  // Use different alignment based on column type
                  pw.TextAlign alignment = pw.TextAlign.left;
                  if (index >= 2 && index <= 4) { // Debit, Credit, Balance columns - right aligned
                    alignment = pw.TextAlign.right;
                  } else if (index == 0) { // Date column - center aligned
                    alignment = pw.TextAlign.center;
                  }
                  
                  return pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      column,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      textAlign: alignment,
                    ),
                  );
                }).toList(),
              ),
              
              // Data rows
              ...rows.asMap().entries.map((entry) {
                final index = entry.key;
                final row = entry.value;
                
                return pw.TableRow(
                  decoration: alternateRowColor && index % 2 == 1
                      ? const pw.BoxDecoration(color: tableAlternateColor)
                      : const pw.BoxDecoration(color: PdfColors.white),
                  children: row.asMap().entries.map((cellEntry) {
                    final cellIndex = cellEntry.key;
                    final cell = cellEntry.value;
                    
                    // Use different alignment based on column type
                    pw.TextAlign alignment = pw.TextAlign.left;
                    if (cellIndex >= 2 && cellIndex <= 4) { // Debit, Credit, Balance columns - right aligned
                      alignment = pw.TextAlign.right;
                    } else if (cellIndex == 0) { // Date column - center aligned
                      alignment = pw.TextAlign.center;
                    }
                    
                    // Determine font weight and color for balance column
                    pw.FontWeight fontWeight = pw.FontWeight.normal;
                    PdfColor textColor = PdfColors.black;
                    
                    if (cellIndex == 4) { // Balance column
                      fontWeight = pw.FontWeight.bold;
                      if (cell.contains('(')) {
                        textColor = dangerColor; // Negative balance in parentheses
                      } else {
                        textColor = successColor; // Positive balance
                      }
                    }
                    
                    return pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        cell,
                        textAlign: alignment,
                        style: pw.TextStyle(
                          fontWeight: fontWeight,
                          color: textColor,
                        ),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
              
              // Total row at the bottom
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: tableHeaderColor),
                children: List.generate(columns.length, (index) {
                  String content = '';
                  pw.TextAlign alignment = pw.TextAlign.left;
                  
                  if (index == 1) {
                    content = 'CLOSING BALANCE';
                    alignment = pw.TextAlign.right;
                  } else if (index == 4 && rows.isNotEmpty) {
                    // Get the final balance from the last row
                    content = rows.last[4]; // Balance from last row
                    alignment = pw.TextAlign.right;
                  }
                  
                  return pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      content,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: index == 4 ? primaryColor : PdfColors.black,
                      ),
                      textAlign: alignment,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Save and open a PDF document
  static Future<void> saveAndOpenPdf(pw.Document pdf, String fileName) async {
    try {
      // Save the PDF using compute for background processing
      final bytes = await pdf.save();
      final savePath = await _getAndPrepareSavePath(fileName);
      
      // Save to file system
      await compute(_saveBytesToFile, {
        'bytes': bytes,
        'path': savePath,
      });
      
      // Try to open the PDF
      final result = await OpenFile.open(savePath);
      
      if (result.type != ResultType.done) {
        // Log if open failed
        // print('Could not open PDF automatically: ${result.message}');
      }
    } catch (e) {
      // print('Error saving or opening PDF: $e');
      rethrow;
    }
  }
  
  /// Formats currency for PDF display (without the rupee symbol)
  static String formatCurrency(double amount) {
    // Format without currency symbol
    return amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]},'
    );
  }
  
  // Helper function to create PDF document in isolate
  static pw.Document _createPdfDocument(Map<String, dynamic> params) {
    final title = params['title'];
    final subtitle = params['subtitle'];
    final keywords = params['keywords'];
    
    return pw.Document(
      title: title,
      author: 'My Byaj Book',
      keywords: keywords,
      creator: 'My Byaj Book App',
      subject: subtitle,
      producer: 'My Byaj Book PDF Service',
    );
  }
  
  // Helper to save bytes to file in background
  static void _saveBytesToFile(Map<String, dynamic> params) {
    final bytes = params['bytes'] as List<int>;
    final path = params['path'] as String;
    final file = File(path);
    file.writeAsBytesSync(bytes);
  }
  
  // Helper to get the save path
  static Future<String> _getAndPrepareSavePath(String fileName) async {
    Directory? directory;
    
    try {
      // Try to get the documents directory first
      directory = await getApplicationDocumentsDirectory();
    } catch (e) {
      // Fallback to temporary directory if documents is not available
      directory = await getTemporaryDirectory();
    }
    
    // Check if file already exists and create unique name if needed
    String baseName = fileName;
    String path = '${directory.path}/$fileName';
    int counter = 1;
    
    // If file already exists, add counter to filename until unique
    while (await File(path).exists()) {
      // Extract extension (usually .pdf)
      final lastDot = baseName.lastIndexOf('.');
      final String nameWithoutExt = lastDot != -1 ? baseName.substring(0, lastDot) : baseName;
      final String extension = lastDot != -1 ? baseName.substring(lastDot) : '';
      
      // Create new filename with counter
      fileName = '${nameWithoutExt}_$counter$extension';
      path = '${directory.path}/$fileName';
      counter++;
      
      // print('PDF with same name exists, trying new filename: $fileName');
    }
    
    return path;
  }
} 