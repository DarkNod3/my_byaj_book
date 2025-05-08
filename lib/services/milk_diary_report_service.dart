import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import '../models/milk_diary/daily_entry.dart';
import '../models/milk_diary/milk_seller.dart';
import '../models/milk_diary/milk_payment.dart';
import '../providers/milk_diary/milk_seller_provider.dart';
import '../providers/milk_diary/daily_entry_provider.dart';

class MilkDiaryReportService {
  final DailyEntryProvider entryProvider;
  final MilkSellerProvider sellerProvider;

  MilkDiaryReportService({
    required this.entryProvider,
    required this.sellerProvider,
  });

  Future<String> generateDailyReport(DateTime date) async {
    final pdf = pw.Document();
    final entries = entryProvider.getEntriesForDate(date);
    
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
          _buildHeader(date),
          _buildSummary(entries),
          ...entriesBySeller.entries.map(
            (entry) => _buildSellerEntries(entry.key, entry.value)
          ),
        ],
      )
    );
    
    // Save the PDF file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/milk_report_${DateFormat('yyyyMMdd').format(date)}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    // Return the file path instead of opening it directly
    return file.path;
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
          _buildMonthlyHeader(month),
          _buildMonthlySummary(entries),
          ...entriesBySeller.entries.map(
            (entry) => _buildSellerMonthlyEntries(entry.key, entry.value)
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
    
    // Get ALL entries for this seller (complete history)
    final allEntries = entryProvider.entries.where(
      (entry) => entry.sellerId == seller.id
    ).toList();
    
    // Get ALL payments for this seller (complete history)
    final allPayments = sellerProvider.getPaymentsForSeller(seller.id);
    
    // Get current month entries for this seller for the recent activity section
    final entriesInDateRange = allEntries.where(
      (entry) => entry.date.isAfter(fromDate.subtract(const Duration(days: 1))) &&
                entry.date.isBefore(toDate.add(const Duration(days: 1)))
    ).toList();
    
    // Get current month payments for the recent activity section
    final paymentsInDateRange = allPayments.where(
      (payment) => payment.date.isAfter(fromDate.subtract(const Duration(days: 1))) &&
                  payment.date.isBefore(toDate.add(const Duration(days: 1)))
    ).toList();
    
    // Sort entries by date
    allEntries.sort((a, b) => b.date.compareTo(a.date)); // Most recent first
    entriesInDateRange.sort((a, b) => b.date.compareTo(a.date)); // Most recent first
    
    // Sort payments by date
    allPayments.sort((a, b) => b.date.compareTo(a.date)); // Most recent first
    paymentsInDateRange.sort((a, b) => b.date.compareTo(a.date)); // Most recent first
    
    // Calculate all-time totals
    final totalQuantity = allEntries.fold(0.0, (sum, entry) => sum + entry.quantity);
    final totalAmount = allEntries.fold(0.0, (sum, entry) => sum + entry.amount);
    final totalPaid = allPayments.fold(0.0, (sum, payment) => sum + payment.amount);
    final amountDue = totalAmount - totalPaid;
    
    // Calculate current month totals (for comparison)
    final currentMonthQuantity = entriesInDateRange.fold(0.0, (sum, entry) => sum + entry.quantity);
    final currentMonthAmount = entriesInDateRange.fold(0.0, (sum, entry) => sum + entry.amount);
    final currentMonthPaid = paymentsInDateRange.fold(0.0, (sum, payment) => sum + payment.amount);
    
    // Get first transaction date (all-time) for "Since" date
    DateTime? firstTransactionDate;
    if (allEntries.isNotEmpty) {
      // Find earliest entry date
      firstTransactionDate = allEntries
          .map((e) => e.date)
          .reduce((a, b) => a.isBefore(b) ? a : b);
    }
    
    try {
      // Create PDF content
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            // App Name at the top
            pw.Center(
              child: pw.Text(
                'My Byaj Book',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            
            // Seller Report Header
            _buildSellerReportHeader(seller, fromDate, toDate, firstTransactionDate),
            
            // All-time Summary section
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: const pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'All-Time Summary',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryPdfItem('Total Milk', '${totalQuantity.toStringAsFixed(2)} L'),
                      _buildSummaryPdfItem('Total Amount', '₹${totalAmount.toStringAsFixed(2)}'),
                      _buildSummaryPdfItem('Total Paid', '₹${totalPaid.toStringAsFixed(2)}'),
                      _buildSummaryPdfItem('Amount Due', '₹${amountDue.toStringAsFixed(2)}'),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 15),
            
            // Current Month Summary section
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: const pw.BoxDecoration(
                color: PdfColors.amber50,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Current Month Summary (${DateFormat('MMMM yyyy').format(fromDate)})',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryPdfItem('Month Milk', '${currentMonthQuantity.toStringAsFixed(2)} L'),
                      _buildSummaryPdfItem('Month Amount', '₹${currentMonthAmount.toStringAsFixed(2)}'),
                      _buildSummaryPdfItem('Month Paid', '₹${currentMonthPaid.toStringAsFixed(2)}'),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 15),
            
            // All-time Milk Entries Table
            pw.Text(
              'All Milk Entries',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            _buildSellerDetailTable(allEntries),
            pw.SizedBox(height: 20),
            
            // All-time Payment History Table
            pw.Text(
              'All Payment History',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            _buildPaymentHistoryTable(allPayments),
            
            // Footer with generation date
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 5),
            pw.Text(
              'Generated on: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      );
      
      // Save the PDF file
      final output = await getApplicationDocumentsDirectory(); // Use app documents directory instead of temp
      final fileName = 'milk_diary_${seller.name.replaceAll(' ', '_')}_complete_history_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      
      // Open the PDF file
      OpenFile.open(file.path);
    } catch (e) {
      rethrow; // Re-throw the exception to be handled by the calling code
    }
  }
  
  pw.Widget _buildHeader(DateTime date) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Milk Diary Daily Report',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Date: ${DateFormat('dd MMMM yyyy').format(date)}',
          style: const pw.TextStyle(
            fontSize: 14,
          ),
        ),
        pw.Divider(),
      ],
    );
  }
  
  pw.Widget _buildMonthlyHeader(DateTime month) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Milk Diary Monthly Report',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Month: ${DateFormat('MMMM yyyy').format(month)}',
          style: const pw.TextStyle(
            fontSize: 14,
          ),
        ),
        pw.Divider(),
      ],
    );
  }
  
  pw.Widget _buildSellerReportHeader(MilkSeller seller, DateTime fromDate, DateTime toDate, DateTime? firstTransactionDate) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Milk Seller Complete History Report',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Seller: ${seller.name}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    if (seller.mobile != null)
                      pw.Text(
                        'Mobile: ${seller.mobile}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                        ),
                      ),
                    if (seller.address != null)
                      pw.Text(
                        'Address: ${seller.address}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                        ),
                      ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Default Rate: ₹${seller.defaultRate}/L',
                      style: const pw.TextStyle(
                        fontSize: 10,
                      ),
                    ),
                    if (firstTransactionDate != null)
                      pw.Text(
                        'Since: ${DateFormat('dd MMM yyyy').format(firstTransactionDate)}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Current Month:',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    '${DateFormat('dd MMM yyyy').format(fromDate)} to ${DateFormat('dd MMM yyyy').format(toDate)}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Full History Included',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  pw.Widget _buildSummary(List<DailyEntry> entries) {
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
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildSummaryItem('Total Quantity', '$totalQuantity L'),
            _buildSummaryItem('Total Amount', '₹ ${totalAmount.toStringAsFixed(2)}'),
            _buildSummaryItem('Total Sellers', '$totalSellers'),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          children: [
            _buildSummaryItem('Morning', '$morningQty L'),
            pw.SizedBox(width: 40),
            _buildSummaryItem('Evening', '$eveningQty L'),
          ],
        ),
        pw.Divider(),
        pw.SizedBox(height: 10),
      ],
    );
  }
  
  pw.Widget _buildMonthlySummary(List<DailyEntry> entries) {
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
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildSummaryItem('Total Quantity', '$totalQuantity L'),
            _buildSummaryItem('Total Amount', '₹ ${totalAmount.toStringAsFixed(2)}'),
            _buildSummaryItem('Total Sellers', '$totalSellers'),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildSummaryItem('Avg. Daily Quantity', '${avgDailyQty.toStringAsFixed(2)} L'),
            _buildSummaryItem('Cow Milk', '$cowQty L'),
            _buildSummaryItem('Buffalo Milk', '$buffaloQty L'),
          ],
        ),
        pw.Divider(),
        pw.SizedBox(height: 10),
      ],
    );
  }
  
  pw.Widget _buildSellerSummary(List<DailyEntry> entries) {
    final totalQuantity = entries.fold(0.0, (sum, entry) => sum + entry.quantity);
    final totalAmount = entries.fold(0.0, (sum, entry) => sum + entry.amount);
    final avgRate = entries.isEmpty ? 0.0 : totalAmount / totalQuantity;
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Seller Summary',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildSummaryItem('Total Quantity', '$totalQuantity L'),
            _buildSummaryItem('Total Amount', '₹ ${totalAmount.toStringAsFixed(2)}'),
            _buildSummaryItem('Avg. Rate', '₹ ${avgRate.toStringAsFixed(2)}/L'),
          ],
        ),
        pw.SizedBox(height: 10),
      ],
    );
  }
  
  pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  pw.Widget _buildSellerEntries(String sellerId, List<DailyEntry> entries) {
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
                _buildTableCell('Shift', isHeader: true),
                _buildTableCell('Quantity (L)', isHeader: true),
                _buildTableCell('Rate (₹)', isHeader: true),
                _buildTableCell('Amount (₹)', isHeader: true),
              ],
            ),
            // Morning Row
            pw.TableRow(
              children: [
                _buildTableCell('Morning'),
                _buildTableCell(morningQty.toStringAsFixed(2)),
                _buildTableCell(
                  morningEntries.isNotEmpty 
                    ? (morningEntries.first.rate.toStringAsFixed(2)) 
                    : '-'
                ),
                _buildTableCell(
                  morningEntries.fold(0.0, (sum, e) => sum + e.amount).toStringAsFixed(2)
                ),
              ],
            ),
            // Evening Row
            pw.TableRow(
              children: [
                _buildTableCell('Evening'),
                _buildTableCell(eveningQty.toStringAsFixed(2)),
                _buildTableCell(
                  eveningEntries.isNotEmpty 
                    ? (eveningEntries.first.rate.toStringAsFixed(2)) 
                    : '-'
                ),
                _buildTableCell(
                  eveningEntries.fold(0.0, (sum, e) => sum + e.amount).toStringAsFixed(2)
                ),
              ],
            ),
            // Total Row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('Total', isBold: true),
                _buildTableCell(totalQuantity.toStringAsFixed(2), isBold: true),
                _buildTableCell(''),
                _buildTableCell(totalAmount.toStringAsFixed(2), isBold: true),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
      ],
    );
  }
  
  pw.Widget _buildSellerMonthlyEntries(String sellerId, List<DailyEntry> entries) {
    final seller = sellerProvider.getSellerById(sellerId);
    final sellerName = seller?.name ?? 'Unknown Seller';
    final totalQuantity = entries.fold(0.0, (sum, entry) => sum + entry.quantity);
    final totalAmount = entries.fold(0.0, (sum, entry) => sum + entry.amount);
    
    // Group by week
    Map<int, List<DailyEntry>> entriesByWeek = {};
    
    // Initialize weeks data
    for (int i = 1; i <= 5; i++) {
      entriesByWeek[i] = [];
    }
    
    // Group entries by week of month
    for (var entry in entries) {
      int weekOfMonth = ((entry.date.day - 1) ~/ 7) + 1; // Week 1 starts on day 1
      if (weekOfMonth > 5) weekOfMonth = 5; // Cap at 5 weeks
      entriesByWeek[weekOfMonth]!.add(entry);
    }
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          sellerName,
          style: pw.TextStyle(
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
                _buildTableCell('Week', isHeader: true),
                _buildTableCell('Period', isHeader: true),
                _buildTableCell('Quantity (L)', isHeader: true),
                _buildTableCell('Amount (₹)', isHeader: true),
              ],
            ),
            // Data Rows - Week wise
            ...entriesByWeek.entries.where((e) => e.value.isNotEmpty).map((e) {
              final weekNum = e.key;
              final weekEntries = e.value;
              final weekQty = weekEntries.fold(0.0, (sum, entry) => sum + entry.quantity);
              final weekAmount = weekEntries.fold(0.0, (sum, entry) => sum + entry.amount);
              
              // Get first and last day of entries in this week
              final firstDay = weekEntries.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);
              final lastDay = weekEntries.map((e) => e.date).reduce((a, b) => a.isAfter(b) ? a : b);
              
              return pw.TableRow(
                children: [
                  _buildTableCell('Week $weekNum'),
                  _buildTableCell(
                    '${DateFormat('dd/MM').format(firstDay)} - ${DateFormat('dd/MM').format(lastDay)}'
                  ),
                  _buildTableCell(weekQty.toStringAsFixed(2)),
                  _buildTableCell(weekAmount.toStringAsFixed(2)),
                ],
              );
            }),
            // Total Row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('Total', isBold: true),
                _buildTableCell(''),
                _buildTableCell(totalQuantity.toStringAsFixed(2), isBold: true),
                _buildTableCell(totalAmount.toStringAsFixed(2), isBold: true),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
      ],
    );
  }
  
  pw.Widget _buildSellerDetailTable(List<DailyEntry> entries) {
    // Check if entries list is empty
    if (entries.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 20),
        alignment: pw.Alignment.center,
        child: pw.Text(
          'No milk entries found',
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey600,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      );
    }
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Date', isHeader: true),
            _buildTableCell('Shift', isHeader: true),
            _buildTableCell('Qty (L)', isHeader: true),
            _buildTableCell('Rate (Rs.)', isHeader: true),
            _buildTableCell('Fat %', isHeader: true),
            _buildTableCell('Amount (Rs.)', isHeader: true),
          ],
        ),
        // Data Rows
        ...entries.map((entry) {
          return pw.TableRow(
            children: [
              _buildTableCell(DateFormat('dd/MM/yy').format(entry.date)),
              _buildTableCell(
                entry.shift == EntryShift.morning ? 'Morning' : 'Evening'
              ),
              _buildTableCell(entry.quantity.toStringAsFixed(2)),
              _buildTableCell(entry.rate.toStringAsFixed(2)),
              _buildTableCell(entry.fat != null ? entry.fat!.toStringAsFixed(1) : '-'),
              _buildTableCell(entry.amount.toStringAsFixed(2)),
            ],
          );
        }),
        // Total Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildTableCell('Total', isBold: true),
            _buildTableCell(''),
            _buildTableCell(
              entries.fold(0.0, (sum, e) => sum + e.quantity).toStringAsFixed(2),
              isBold: true
            ),
            _buildTableCell(''),
            _buildTableCell(''),
            _buildTableCell(
              entries.fold(0.0, (sum, e) => sum + e.amount).toStringAsFixed(2),
              isBold: true
            ),
          ],
        ),
      ],
    );
  }
  
  pw.Widget _buildTableCell(String text, {bool isHeader = false, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
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
  
  // Helper method to build summary item for PDF
  pw.Widget _buildSummaryPdfItem(String title, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          title,
          style: const pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  // Helper method to build payment history table
  pw.Widget _buildPaymentHistoryTable(List<MilkPayment> payments) {
    if (payments.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 20),
        alignment: pw.Alignment.center,
        child: pw.Text(
          'No payment records found',
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey600,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      );
    }
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.green100),
          children: [
            _buildTableCell('Date', isHeader: true),
            _buildTableCell('Amount (Rs.)', isHeader: true),
            _buildTableCell('Note', isHeader: true),
          ],
        ),
        // Data Rows
        ...payments.map((payment) {
          return pw.TableRow(
            children: [
              _buildTableCell(DateFormat('dd/MM/yyyy').format(payment.date)),
              _buildTableCell(payment.amount.toStringAsFixed(2)),
              _buildTableCell(payment.note ?? '-'),
            ],
          );
        }),
        // Total Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.green50),
          children: [
            _buildTableCell('Total', isBold: true),
            _buildTableCell(
              payments.fold(0.0, (sum, p) => sum + p.amount).toStringAsFixed(2),
              isBold: true
            ),
            _buildTableCell(''),
          ],
        ),
      ],
    );
  }
} 