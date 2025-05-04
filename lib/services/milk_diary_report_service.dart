import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import '../models/milk_diary/daily_entry.dart';
import '../models/milk_diary/milk_seller.dart';
import '../providers/milk_diary/milk_seller_provider.dart';
import '../providers/milk_diary/daily_entry_provider.dart';

class MilkDiaryReportService {
  final DailyEntryProvider entryProvider;
  final MilkSellerProvider sellerProvider;

  MilkDiaryReportService({
    required this.entryProvider,
    required this.sellerProvider,
  });

  Future<void> generateDailyReport(DateTime date) async {
    final pdf = pw.Document();
    final entries = entryProvider.getEntriesForDate(date);
    
    // Load font
    final font = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(font);
    
    // Group entries by seller
    Map<String, List<DailyEntry>> entriesBySeller = {};
    for (var entry in entries) {
      if (!entriesBySeller.containsKey(entry.sellerId)) {
        entriesBySeller[entry.sellerId] = [];
      }
      entriesBySeller[entry.sellerId]!.add(entry);
    }
    
    // Create PDF content
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildHeader(date, ttf),
          _buildSummary(entries, ttf),
          ...entriesBySeller.entries.map(
            (entry) => _buildSellerEntries(entry.key, entry.value, ttf)
          ),
        ],
      )
    );
    
    // Save the PDF file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/milk_report_${DateFormat('yyyyMMdd').format(date)}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    // Open the PDF file
    OpenFile.open(file.path);
  }
  
  Future<void> generateMonthlyReport(DateTime month) async {
    final pdf = pw.Document();
    
    // Calculate start and end of month
    final DateTime startDate = DateTime(month.year, month.month, 1);
    final DateTime endDate = DateTime(month.year, month.month + 1, 0);
    
    // Get all entries for the month
    final entries = entryProvider.entries.where(
      (entry) => entry.date.isAfter(startDate.subtract(const Duration(days: 1))) && 
                entry.date.isBefore(endDate.add(const Duration(days: 1)))
    ).toList();
    
    // Load font
    final font = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(font);
    
    // Group by seller
    Map<String, List<DailyEntry>> entriesBySeller = {};
    for (var entry in entries) {
      if (!entriesBySeller.containsKey(entry.sellerId)) {
        entriesBySeller[entry.sellerId] = [];
      }
      entriesBySeller[entry.sellerId]!.add(entry);
    }
    
    // Create PDF content
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildMonthlyHeader(month, ttf),
          _buildMonthlySummary(entries, ttf),
          ...entriesBySeller.entries.map(
            (entry) => _buildSellerMonthlyEntries(entry.key, entry.value, ttf)
          ),
        ],
      )
    );
    
    // Save the PDF file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/milk_monthly_report_${DateFormat('yyyyMM').format(month)}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    // Open the PDF file
    OpenFile.open(file.path);
  }
  
  Future<void> generateSellerReport(MilkSeller seller, DateTime fromDate, DateTime toDate) async {
    final pdf = pw.Document();
    
    // Get all entries for this seller in the date range
    final entries = entryProvider.entries.where(
      (entry) => entry.sellerId == seller.id && 
                entry.date.isAfter(fromDate.subtract(const Duration(days: 1))) &&
                entry.date.isBefore(toDate.add(const Duration(days: 1)))
    ).toList();
    
    // Sort entries by date
    entries.sort((a, b) => a.date.compareTo(b.date));
    
    // Load font
    final font = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(font);
    
    // Create PDF content
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildSellerReportHeader(seller, fromDate, toDate, ttf),
          _buildSellerSummary(entries, ttf),
          _buildSellerDetailTable(entries, ttf),
        ],
      )
    );
    
    // Save the PDF file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/seller_${seller.id}_${DateFormat('yyyyMMdd').format(fromDate)}_${DateFormat('yyyyMMdd').format(toDate)}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    // Open the PDF file
    OpenFile.open(file.path);
  }
  
  pw.Widget _buildHeader(DateTime date, pw.Font ttf) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Milk Diary Daily Report',
          style: pw.TextStyle(
            font: ttf,
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Date: ${DateFormat('dd MMMM yyyy').format(date)}',
          style: pw.TextStyle(
            font: ttf,
            fontSize: 14,
          ),
        ),
        pw.Divider(),
      ],
    );
  }
  
  pw.Widget _buildMonthlyHeader(DateTime month, pw.Font ttf) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Milk Diary Monthly Report',
          style: pw.TextStyle(
            font: ttf,
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Month: ${DateFormat('MMMM yyyy').format(month)}',
          style: pw.TextStyle(
            font: ttf,
            fontSize: 14,
          ),
        ),
        pw.Divider(),
      ],
    );
  }
  
  pw.Widget _buildSellerReportHeader(MilkSeller seller, DateTime fromDate, DateTime toDate, pw.Font ttf) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Seller Report: ${seller.name}',
          style: pw.TextStyle(
            font: ttf,
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Period: ${DateFormat('dd MMM yyyy').format(fromDate)} to ${DateFormat('dd MMM yyyy').format(toDate)}',
          style: pw.TextStyle(
            font: ttf,
            fontSize: 14,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Contact: ${seller.mobile ?? 'N/A'}',
          style: pw.TextStyle(
            font: ttf,
            fontSize: 12,
          ),
        ),
        pw.Divider(),
      ],
    );
  }
  
  pw.Widget _buildSummary(List<DailyEntry> entries, pw.Font ttf) {
    final totalQuantity = entries.fold(0.0, (sum, entry) => sum + entry.quantity);
    final totalAmount = entries.fold(0.0, (sum, entry) => sum + entry.amount);
    final morningEntries = entries.where((e) => e.shift == EntryShift.morning);
    final eveningEntries = entries.where((e) => e.shift == EntryShift.evening);
    final totalSellers = entries.map((e) => e.sellerId).toSet().length;
    
    final morningQty = morningEntries.fold(0.0, (sum, entry) => sum + entry.quantity);
    final eveningQty = eveningEntries.fold(0.0, (sum, entry) => sum + entry.quantity);
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Summary',
          style: pw.TextStyle(
            font: ttf,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildSummaryItem('Total Quantity', '$totalQuantity L', ttf),
            _buildSummaryItem('Total Amount', '₹ ${totalAmount.toStringAsFixed(2)}', ttf),
            _buildSummaryItem('Total Sellers', '$totalSellers', ttf),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          children: [
            _buildSummaryItem('Morning', '$morningQty L', ttf),
            pw.SizedBox(width: 40),
            _buildSummaryItem('Evening', '$eveningQty L', ttf),
          ],
        ),
        pw.Divider(),
        pw.SizedBox(height: 10),
      ],
    );
  }
  
  pw.Widget _buildMonthlySummary(List<DailyEntry> entries, pw.Font ttf) {
    final totalQuantity = entries.fold(0.0, (sum, entry) => sum + entry.quantity);
    final totalAmount = entries.fold(0.0, (sum, entry) => sum + entry.amount);
    final totalSellers = entries.map((e) => e.sellerId).toSet().length;
    final avgDailyQty = totalQuantity / entries.map((e) => DateFormat('yyyyMMdd').format(e.date)).toSet().length;
    
    // Group by cow/buffalo
    final cowMilk = entries.where((e) => e.milkType == MilkType.cow);
    final buffaloMilk = entries.where((e) => e.milkType == MilkType.buffalo);
    
    final cowQty = cowMilk.fold(0.0, (sum, entry) => sum + entry.quantity);
    final buffaloQty = buffaloMilk.fold(0.0, (sum, entry) => sum + entry.quantity);
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Monthly Summary',
          style: pw.TextStyle(
            font: ttf,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildSummaryItem('Total Quantity', '$totalQuantity L', ttf),
            _buildSummaryItem('Total Amount', '₹ ${totalAmount.toStringAsFixed(2)}', ttf),
            _buildSummaryItem('Total Sellers', '$totalSellers', ttf),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildSummaryItem('Avg. Daily Quantity', '${avgDailyQty.toStringAsFixed(2)} L', ttf),
            _buildSummaryItem('Cow Milk', '$cowQty L', ttf),
            _buildSummaryItem('Buffalo Milk', '$buffaloQty L', ttf),
          ],
        ),
        pw.Divider(),
        pw.SizedBox(height: 10),
      ],
    );
  }
  
  pw.Widget _buildSellerSummary(List<DailyEntry> entries, pw.Font ttf) {
    final totalQuantity = entries.fold(0.0, (sum, entry) => sum + entry.quantity);
    final totalAmount = entries.fold(0.0, (sum, entry) => sum + entry.amount);
    final avgRate = entries.isEmpty ? 0.0 : totalAmount / totalQuantity;
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Seller Summary',
          style: pw.TextStyle(
            font: ttf,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildSummaryItem('Total Quantity', '$totalQuantity L', ttf),
            _buildSummaryItem('Total Amount', '₹ ${totalAmount.toStringAsFixed(2)}', ttf),
            _buildSummaryItem('Avg. Rate', '₹ ${avgRate.toStringAsFixed(2)}/L', ttf),
          ],
        ),
        pw.SizedBox(height: 10),
      ],
    );
  }
  
  pw.Widget _buildSummaryItem(String label, String value, pw.Font ttf) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: ttf,
            fontSize: 10,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: ttf,
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  pw.Widget _buildSellerEntries(String sellerId, List<DailyEntry> entries, pw.Font ttf) {
    final seller = sellerProvider.getSellerById(sellerId);
    final sellerName = seller?.name ?? 'Unknown Seller';
    final totalQuantity = entries.fold(0.0, (sum, entry) => sum + entry.quantity);
    final totalAmount = entries.fold(0.0, (sum, entry) => sum + entry.amount);
    
    // Group by shift
    final morningEntries = entries.where((e) => e.shift == EntryShift.morning).toList();
    final eveningEntries = entries.where((e) => e.shift == EntryShift.evening).toList();
    
    final morningQty = morningEntries.fold(0.0, (sum, entry) => sum + entry.quantity);
    final eveningQty = eveningEntries.fold(0.0, (sum, entry) => sum + entry.quantity);
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          sellerName,
          style: pw.TextStyle(
            font: ttf,
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            // Header Row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Shift', ttf, isHeader: true),
                _buildTableCell('Quantity (L)', ttf, isHeader: true),
                _buildTableCell('Rate (₹)', ttf, isHeader: true),
                _buildTableCell('Amount (₹)', ttf, isHeader: true),
              ],
            ),
            // Morning Row
            pw.TableRow(
              children: [
                _buildTableCell('Morning', ttf),
                _buildTableCell(morningQty.toStringAsFixed(2), ttf),
                _buildTableCell(
                  morningEntries.isNotEmpty 
                    ? (morningEntries.first.rate.toStringAsFixed(2)) 
                    : '-', 
                  ttf
                ),
                _buildTableCell(
                  morningEntries.fold(0.0, (sum, e) => sum + e.amount).toStringAsFixed(2), 
                  ttf
                ),
              ],
            ),
            // Evening Row
            pw.TableRow(
              children: [
                _buildTableCell('Evening', ttf),
                _buildTableCell(eveningQty.toStringAsFixed(2), ttf),
                _buildTableCell(
                  eveningEntries.isNotEmpty 
                    ? (eveningEntries.first.rate.toStringAsFixed(2)) 
                    : '-', 
                  ttf
                ),
                _buildTableCell(
                  eveningEntries.fold(0.0, (sum, e) => sum + e.amount).toStringAsFixed(2), 
                  ttf
                ),
              ],
            ),
            // Total Row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('Total', ttf, isBold: true),
                _buildTableCell(totalQuantity.toStringAsFixed(2), ttf, isBold: true),
                _buildTableCell('', ttf),
                _buildTableCell(totalAmount.toStringAsFixed(2), ttf, isBold: true),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
      ],
    );
  }
  
  pw.Widget _buildSellerMonthlyEntries(String sellerId, List<DailyEntry> entries, pw.Font ttf) {
    final seller = sellerProvider.getSellerById(sellerId);
    final sellerName = seller?.name ?? 'Unknown Seller';
    final totalQuantity = entries.fold(0.0, (sum, entry) => sum + entry.quantity);
    final totalAmount = entries.fold(0.0, (sum, entry) => sum + entry.amount);
    
    // Group by week
    Map<int, List<DailyEntry>> entriesByWeek = {};
    for (var entry in entries) {
      // Get ISO week number
      final weekNumber = _getWeekNumber(entry.date);
      if (!entriesByWeek.containsKey(weekNumber)) {
        entriesByWeek[weekNumber] = [];
      }
      entriesByWeek[weekNumber]!.add(entry);
    }
    
    // Sort keys
    final sortedWeeks = entriesByWeek.keys.toList()..sort();
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          sellerName,
          style: pw.TextStyle(
            font: ttf,
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            // Header Row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Week', ttf, isHeader: true),
                _buildTableCell('Period', ttf, isHeader: true),
                _buildTableCell('Quantity (L)', ttf, isHeader: true),
                _buildTableCell('Amount (₹)', ttf, isHeader: true),
              ],
            ),
            // Data Rows for each week
            ...sortedWeeks.map((weekNum) {
              final weekEntries = entriesByWeek[weekNum]!;
              final weekQty = weekEntries.fold(0.0, (sum, e) => sum + e.quantity);
              final weekAmount = weekEntries.fold(0.0, (sum, e) => sum + e.amount);
              
              // Find first and last day of entries this week
              weekEntries.sort((a, b) => a.date.compareTo(b.date));
              final firstDay = weekEntries.first.date;
              final lastDay = weekEntries.last.date;
              
              return pw.TableRow(
                children: [
                  _buildTableCell('Week $weekNum', ttf),
                  _buildTableCell(
                    '${DateFormat('dd/MM').format(firstDay)} - ${DateFormat('dd/MM').format(lastDay)}', 
                    ttf
                  ),
                  _buildTableCell(weekQty.toStringAsFixed(2), ttf),
                  _buildTableCell(weekAmount.toStringAsFixed(2), ttf),
                ],
              );
            }),
            // Total Row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('Total', ttf, isBold: true),
                _buildTableCell('', ttf),
                _buildTableCell(totalQuantity.toStringAsFixed(2), ttf, isBold: true),
                _buildTableCell(totalAmount.toStringAsFixed(2), ttf, isBold: true),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 15),
      ],
    );
  }
  
  pw.Widget _buildSellerDetailTable(List<DailyEntry> entries, pw.Font ttf) {
    // Sort entries by date
    entries.sort((a, b) => a.date.compareTo(b.date));
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Detailed Entries',
          style: pw.TextStyle(
            font: ttf,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            // Header Row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Date', ttf, isHeader: true),
                _buildTableCell('Shift', ttf, isHeader: true),
                _buildTableCell('Qty (L)', ttf, isHeader: true),
                _buildTableCell('Rate (₹)', ttf, isHeader: true),
                _buildTableCell('Fat %', ttf, isHeader: true),
                _buildTableCell('Amount (₹)', ttf, isHeader: true),
              ],
            ),
            // Data Rows
            ...entries.map((entry) {
              return pw.TableRow(
                children: [
                  _buildTableCell(DateFormat('dd/MM/yy').format(entry.date), ttf),
                  _buildTableCell(
                    entry.shift == EntryShift.morning ? 'Morning' : 'Evening',
                    ttf
                  ),
                  _buildTableCell(entry.quantity.toStringAsFixed(2), ttf),
                  _buildTableCell(entry.rate.toStringAsFixed(2), ttf),
                  _buildTableCell(entry.fat != null ? entry.fat!.toStringAsFixed(1) : '-', ttf),
                  _buildTableCell(entry.amount.toStringAsFixed(2), ttf),
                ],
              );
            }),
            // Total Row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('Total', ttf, isBold: true),
                _buildTableCell('', ttf),
                _buildTableCell(
                  entries.fold(0.0, (sum, e) => sum + e.quantity).toStringAsFixed(2), 
                  ttf, 
                  isBold: true
                ),
                _buildTableCell('', ttf),
                _buildTableCell('', ttf),
                _buildTableCell(
                  entries.fold(0.0, (sum, e) => sum + e.amount).toStringAsFixed(2), 
                  ttf, 
                  isBold: true
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
  
  pw.Widget _buildTableCell(String text, pw.Font ttf, {bool isHeader = false, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: ttf,
          fontSize: 10,
          fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : null,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }
  
  // Helper to get ISO week number
  int _getWeekNumber(DateTime date) {
    // The algorithm is based on ISO-8601:
    // https://en.wikipedia.org/wiki/ISO_week_date
    int dayOfYear = int.parse(DateFormat('D').format(date));
    int woy = ((dayOfYear - date.weekday + 10) / 7).floor();
    if (woy < 1) {
      woy = _getWeeksInYear(date.year - 1);
    } else if (woy > _getWeeksInYear(date.year)) {
      woy = 1;
    }
    return woy;
  }
  
  // Helper to get the number of weeks in a year
  int _getWeeksInYear(int year) {
    final p1 = 365 * year + (year / 4).floor() - (year / 100).floor() + (year / 400).floor();
    final p2 = (p1 + 1) % 7;
    return p2 == 4 || (p2 == 3 && _isLeapYear(year)) ? 53 : 52;
  }
  
  // Helper to check if a year is a leap year
  bool _isLeapYear(int year) {
    return (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0));
  }
} 