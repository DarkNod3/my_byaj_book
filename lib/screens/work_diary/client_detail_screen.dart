import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:open_file/open_file.dart';

import '../../models/work_diary/client.dart';
import '../../models/work_diary/work_entry.dart';
import '../../constants/colors.dart';

class ClientDetailScreen extends StatefulWidget {
  final Client client;
  final Function(Client) updateClient;
  final Function(String) deleteClient;

  const ClientDetailScreen({
    Key? key,
    required this.client,
    required this.updateClient,
    required this.deleteClient,
  }) : super(key: key);

  @override
  _ClientDetailScreenState createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  late Client _client;
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final dateFormat = DateFormat('dd MMM yyyy');
  final dateTimeFormat = DateFormat('dd MMM yyyy');
  final timeFormat = DateFormat('hh:mm a');

  @override
  void initState() {
    super.initState();
    _client = widget.client;
    
    // Ensure entries are sorted by most recent first
    if (_client.workEntries.isNotEmpty) {
      final sortedEntries = List<WorkEntry>.from(_client.workEntries)
        ..sort((a, b) => b.date.compareTo(a.date));
      _client = _client.copyWith(workEntries: sortedEntries);
    }
  }

  void _editClientInfo() async {
    final TextEditingController nameController = TextEditingController(text: _client.name);
    final TextEditingController phoneController = TextEditingController(text: _client.phoneNumber);
    final TextEditingController hourlyRateController = TextEditingController(
        text: _client.hourlyRate > 0 ? _client.hourlyRate.toString() : '');
    final TextEditingController halfDayRateController = TextEditingController(
        text: _client.halfDayRate > 0 ? _client.halfDayRate.toString() : '');
    final TextEditingController fullDayRateController = TextEditingController(
        text: _client.fullDayRate > 0 ? _client.fullDayRate.toString() : '');

    final result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Client'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Client Name *'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              const Text('Rate Information', style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: hourlyRateController,
                decoration: const InputDecoration(labelText: 'Hourly Rate (₹)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: halfDayRateController,
                decoration: const InputDecoration(labelText: 'Half Day Rate (₹)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: fullDayRateController,
                decoration: const InputDecoration(labelText: 'Full Day Rate (₹)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Client name is required')),
                );
                return;
              }
              
              Navigator.of(context).pop(true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      final updatedClient = _client.copyWith(
        name: nameController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        hourlyRate: double.tryParse(hourlyRateController.text) ?? 0.0,
        halfDayRate: double.tryParse(halfDayRateController.text) ?? 0.0,
        fullDayRate: double.tryParse(fullDayRateController.text) ?? 0.0,
      );

      setState(() {
        _client = updatedClient;
      });

      widget.updateClient(updatedClient);
    }
  }

  void _addWorkEntry() async {
    DateTime selectedDate = DateTime.now();
    String selectedDurationType = 'Full Day';
    final TextEditingController hoursController = TextEditingController(text: '1');
    final TextEditingController amountController = TextEditingController(
      text: _client.fullDayRate > 0 ? _client.fullDayRate.toString() : '',
    );
    final TextEditingController descriptionController = TextEditingController();

    void updateAmount() {
      double amount = 0.0;
      if (selectedDurationType == 'Hourly') {
        final hours = double.tryParse(hoursController.text) ?? 0;
        amount = _client.hourlyRate * hours;
      } else if (selectedDurationType == 'Half Day') {
        amount = _client.halfDayRate;
      } else if (selectedDurationType == 'Full Day') {
        amount = _client.fullDayRate;
      }
      amountController.text = amount.toString();
    }

    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar at top
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Header
                    const Text(
                      'Add Work Entry',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Date selector
                    GestureDetector(
                      onTap: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Date: ${dateFormat.format(selectedDate)}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Amount and Duration Type in a single row
                    Row(
                      children: [
                        // Amount field (first)
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: amountController,
                            decoration: InputDecoration(
                              labelText: 'Amount (₹)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.currency_rupee),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Duration Type (second)
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Type',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: selectedDurationType,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    hint: const Text('Type'),
                                    icon: const Icon(Icons.arrow_drop_down),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          selectedDurationType = newValue;
                                          updateAmount();
                                        });
                                      }
                                    },
                                    items: ['Hourly', 'Half Day', 'Full Day']
                                        .map<DropdownMenuItem<String>>((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Hours field (if hourly)
                    if (selectedDurationType == 'Hourly')
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: TextField(
                          controller: hoursController,
                          decoration: InputDecoration(
                            labelText: 'Hours',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.timelapse),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => updateAmount(),
                        ),
                      ),
                    const SizedBox(height: 16),
                    
                    // Description field
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        hintText: 'What was the work for?',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    
                    // Error message container
                    StatefulBuilder(
                      builder: (context, setErrorState) {
                        // Validate entry and show error message if needed
                        String errorMessage = '';
                        
                        // Get entries for the selected date
                        final sameDate = DateFormat('yyyy-MM-dd').format(selectedDate);
                        
                        // Count full day entries for the selected date
                        final fullDayEntries = _client.workEntries.where((entry) => 
                          entry.durationType == 'Full Day' && 
                          DateFormat('yyyy-MM-dd').format(entry.date) == sameDate
                        ).length;
                        
                        // Count half day entries for the selected date
                        final halfDayEntries = _client.workEntries.where((entry) => 
                          entry.durationType == 'Half Day' && 
                          DateFormat('yyyy-MM-dd').format(entry.date) == sameDate
                        ).length;
                        
                        // Sum total hours for the selected date
                        final totalHours = _client.workEntries
                          .where((entry) => DateFormat('yyyy-MM-dd').format(entry.date) == sameDate && entry.durationType == 'Hourly')
                          .fold(0.0, (sum, entry) => sum + (entry.hours ?? 0));
                        
                        // Add potential new entry hours
                        double potentialNewHours = 0;
                        if (selectedDurationType == 'Hourly') {
                          potentialNewHours = double.tryParse(hoursController.text) ?? 0;
                        }
                        
                        // Check validation rules
                        if (selectedDurationType == 'Full Day' && fullDayEntries > 0) {
                          errorMessage = 'Only 1 full day entry allowed per day';
                        } else if (selectedDurationType == 'Half Day' && halfDayEntries >= 2) {
                          errorMessage = 'Maximum 2 half day entries allowed per day';
                        } else if (selectedDurationType == 'Hourly' && (totalHours + potentialNewHours) > 10) {
                          errorMessage = 'Maximum 10 hours allowed per day (${10 - totalHours} hours left)';
                        }
                        
                        return errorMessage.isNotEmpty 
                          ? Container(
                              padding: const EdgeInsets.all(8),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      errorMessage,
                                      style: TextStyle(color: Colors.red.shade800),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink();
                      },
                    ),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final amount = double.tryParse(amountController.text) ?? 0.0;
                              if (amount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Amount must be greater than zero')),
                                );
                                return;
                              }
                              
                              // Get the selected date in YYYY-MM-DD format for comparison
                              final sameDate = DateFormat('yyyy-MM-dd').format(selectedDate);
                              
                              // Validate against business rules
                              String? validationError;
                              
                              // Rule 1: Only 1 full day entry per day
                              if (selectedDurationType == 'Full Day') {
                                final existingFullDayEntries = _client.workEntries.where((entry) => 
                                  entry.durationType == 'Full Day' && 
                                  DateFormat('yyyy-MM-dd').format(entry.date) == sameDate
                                ).toList();
                                
                                if (existingFullDayEntries.isNotEmpty) {
                                  validationError = 'Only 1 full day entry allowed per day';
                                }
                              }
                              
                              // Rule 2: Maximum 2 half day entries per day
                              else if (selectedDurationType == 'Half Day') {
                                final existingHalfDayEntries = _client.workEntries.where((entry) => 
                                  entry.durationType == 'Half Day' && 
                                  DateFormat('yyyy-MM-dd').format(entry.date) == sameDate
                                ).toList();
                                
                                if (existingHalfDayEntries.length >= 2) {
                                  validationError = 'Maximum 2 half day entries allowed per day';
                                }
                              }
                              
                              // Rule 3: Maximum 10 hours per day
                              else if (selectedDurationType == 'Hourly') {
                                final hours = double.tryParse(hoursController.text) ?? 0.0;
                                final existingHours = _client.workEntries
                                  .where((entry) => 
                                    entry.durationType == 'Hourly' && 
                                    DateFormat('yyyy-MM-dd').format(entry.date) == sameDate
                                  )
                                  .fold(0.0, (sum, entry) => sum + (entry.hours ?? 0));
                                
                                if (existingHours + hours > 10) {
                                  final hoursLeft = 10 - existingHours;
                                  validationError = 'Maximum 10 hours allowed per day (${hoursLeft.toStringAsFixed(1)} hours left)';
                                }
                              }
                              
                              // Display validation error if any
                              if (validationError != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(validationError),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              
                              Navigator.of(context).pop({
                                'date': selectedDate,
                                'durationType': selectedDurationType,
                                'hours': selectedDurationType == 'Hourly'
                                    ? double.tryParse(hoursController.text) ?? 1.0
                                    : null,
                                'amount': amount,
                                'description': descriptionController.text.trim(),
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Add'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      final newEntry = WorkEntry(
        id: const Uuid().v4(),
        date: result['date'],
        durationType: result['durationType'],
        hours: result['hours'],
        amount: result['amount'],
        description: result['description'],
      );

      final updatedEntries = List<WorkEntry>.from(_client.workEntries)..add(newEntry);
      final updatedClient = _client.copyWith(workEntries: updatedEntries);

      setState(() {
        _client = updatedClient;
      });

      widget.updateClient(updatedClient);
    }
  }

  void _deleteWorkEntry(String entryId) {
    // For the swipe action, the confirmation is handled by the Dismissible widget
    // For the long press, we need to show the confirmation dialog
    final updatedEntries = List<WorkEntry>.from(_client.workEntries)
      ..removeWhere((entry) => entry.id == entryId);
    final updatedClient = _client.copyWith(workEntries: updatedEntries);

    setState(() {
      _client = updatedClient;
    });

    widget.updateClient(updatedClient);
    
    // Show a snackbar to confirm deletion
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Work entry deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Restore the deleted entry
            setState(() {
              _client = widget.client;
            });
            widget.updateClient(widget.client);
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // New method for confirming deletion via long press
  void _confirmAndDeleteWorkEntry(String entryId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this work entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteWorkEntry(entryId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteClient() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Client'),
        content: Text(
          'Are you sure you want to delete ${_client.name} and all their work entries? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        widget.deleteClient(_client.id);
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _generateClientPDF(Client client) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating PDF report...'),
            ],
          ),
        ),
      );

      // Get directory for storing PDFs
      final directory = await getExternalStorageDirectory();
      final String formattedDate = DateFormat('dd-MM-yyyy_HH-mm').format(DateTime.now());
      final fileName = 'client_report_${client.name.replaceAll(' ', '_')}_$formattedDate.pdf';
      final filePath = '${directory!.path}/$fileName';
      
      // Format currency without rupee symbol for PDF
      String formatCurrencyForPdf(double amount) {
        return NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0).format(amount);
      }

      // Generate PDF
      final pdf = pw.Document();
      
      // Add client summary page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  color: PdfColors.blue700,
                  child: pw.Row(
                    children: [
                      pw.Container(
                        width: 50,
                        height: 50,
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.white,
                          shape: pw.BoxShape.circle,
                        ),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          client.initials,
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue700,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 16),
                      pw.Text(
                        client.name,
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Work Statistics
                pw.Text(
                  'Work Statistics',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Hours: ${client.hoursCount}'),
                    pw.Text('Half Days: ${client.halfDaysCount}'),
                    pw.Text('Full Days: ${client.fullDaysCount}'),
                  ],
                ),
                
                pw.SizedBox(height: 20),
                
                // Calculate work entries (positive amounts)
                pw.Text(
                  'Payment Summary',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),

                // Calculate work and payment amounts
                pw.Builder(
                  builder: (context) {
                    final workAmount = client.workEntries
                        .where((entry) => 
                          !entry.description.toLowerCase().contains('received') && 
                          !entry.description.toLowerCase().contains('payment'))
                        .fold(0.0, (sum, entry) => sum + entry.amount);
                    
                    final amountReceived = client.workEntries
                        .where((entry) => 
                          entry.description.toLowerCase().contains('received') || 
                          entry.description.toLowerCase().contains('payment'))
                        .fold(0.0, (sum, entry) => sum + entry.amount);
                    
                    final amountDue = workAmount - amountReceived;
                    
                    return pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Total Amount:'),
                            pw.Text(formatCurrencyForPdf(workAmount)),
                          ],
                        ),
                        pw.SizedBox(height: 5),
                        
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Amount Received:'),
                            pw.Text(formatCurrencyForPdf(amountReceived)),
                          ],
                        ),
                        pw.SizedBox(height: 5),
                        
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Amount Due:'),
                            pw.Text(formatCurrencyForPdf(amountDue)),
                          ],
                        ),
                      ],
                    );
                  }
                ),
                
                pw.SizedBox(height: 30),
                
                // Work History
                pw.Text(
                  'Work History',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                
                // Table header
                pw.Container(
                  color: PdfColors.grey200,
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Row(
                    children: [
                      pw.Expanded(flex: 2, child: pw.Text('Date')),
                      pw.Expanded(flex: 1, child: pw.Text('Time')),
                      pw.Expanded(flex: 1, child: pw.Text('Type')),
                      pw.Expanded(flex: 3, child: pw.Text('Description')),
                      pw.Expanded(flex: 2, child: pw.Text('Amount')),
                    ],
                  ),
                ),
                
                // Sort entries by date (newest first) before displaying
                ...((){
                  final sortedEntries = List<WorkEntry>.from(client.workEntries);
                  sortedEntries.sort((a, b) => b.date.compareTo(a.date)); // Sort newest first
                  return sortedEntries;
                })().map((entry) {
                  final isPayment = entry.description.toLowerCase().contains('received') || 
                                   entry.description.toLowerCase().contains('payment');
                  
                  return pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.grey300),
                      ),
                    ),
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 2, 
                          child: pw.Text(DateFormat('MM/dd/yyyy').format(entry.date))
                        ),
                        pw.Expanded(
                          flex: 1, 
                          child: pw.Text(DateFormat('hh:mm a').format(entry.date))
                        ),
                        pw.Expanded(
                          flex: 1, 
                          child: pw.Text(entry.durationType)
                        ),
                        pw.Expanded(
                          flex: 3, 
                          child: pw.Text(
                            entry.description,
                            maxLines: 1,
                            overflow: pw.TextOverflow.clip,
                          )
                        ),
                        pw.Expanded(
                          flex: 2, 
                          child: pw.Text(
                            formatCurrencyForPdf(entry.amount),
                            style: pw.TextStyle(
                              color: isPayment ? PdfColors.green : PdfColors.black,
                            ),
                          )
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            );
          },
        ),
      );
      
      // Save the PDF file
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      
      // Close the loading dialog
      Navigator.of(context).pop();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF report generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Open the PDF file automatically
      await OpenFile.open(filePath);
      
    } catch (e) {
      // Close the loading dialog
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method to add a payment entry
  void _addPaymentEntry(double amountDue) async {
    DateTime selectedDate = DateTime.now();
    final TextEditingController amountController = TextEditingController(
      text: amountDue > 0 ? amountDue.toString() : '',
    );
    final TextEditingController notesController = TextEditingController(
      text: 'Payment received'
    );

    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar at top
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Header
                    const Text(
                      'Add Payment',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Date selector
                    GestureDetector(
                      onTap: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Date: ${DateFormat('dd MMM yyyy').format(selectedDate)}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Amount input
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Payment Amount (₹)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    
                    // Notes input
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                        helperText: 'Limited to 40 characters',
                        helperStyle: TextStyle(fontSize: 12),
                      ),
                      maxLines: 1,
                      maxLength: 40,
                    ),
                    const SizedBox(height: 24),
                    
                    // Add button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final paymentAmount = double.tryParse(amountController.text);
                          if (paymentAmount == null || paymentAmount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid amount')),
                            );
                            return;
                          }
                          
                          // Limit description length to prevent overflow
                          String description = notesController.text.trim();
                          if (description.isEmpty) {
                            description = "Payment received";
                          } else if (!description.toLowerCase().contains("payment") && 
                                     !description.toLowerCase().contains("received")) {
                            description = "Payment: $description";
                          }
                          
                          if (description.length > 40) {
                            description = "${description.substring(0, 37)}...";
                          }
                          
                          Navigator.pop(context, {
                            'amount': paymentAmount,
                            'date': selectedDate,
                            'description': description,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'ADD PAYMENT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      final double amount = result['amount'];
      final DateTime date = result['date'];
      final String description = result['description'];
      
      final newEntry = WorkEntry(
        id: const Uuid().v4(),
        date: date,
        durationType: 'Payment',
        hours: null,
        amount: amount,
        description: description,
      );

      setState(() {
        final updatedEntries = List<WorkEntry>.from(_client.workEntries)..add(newEntry);
        updatedEntries.sort((a, b) => b.date.compareTo(a.date)); // Sort by date, newest first
        _client = _client.copyWith(workEntries: updatedEntries);
      });

      widget.updateClient(_client);
      
      // Calculate remaining balance
      final totalWork = _client.workEntries
          .where((entry) => 
            !entry.description.toLowerCase().contains('received') && 
            !entry.description.toLowerCase().contains('payment'))
          .fold(0.0, (sum, entry) => sum + entry.amount);
      
      final totalPayments = _client.workEntries
          .where((entry) => 
            entry.description.toLowerCase().contains('received') || 
            entry.description.toLowerCase().contains('payment'))
          .fold(0.0, (sum, entry) => sum + entry.amount);
      
      final remainingBalance = totalWork - totalPayments;
      
      // Show feedback message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment of ${currencyFormat.format(amount)} added.${remainingBalance > 0 ? ' Remaining: ${currencyFormat.format(remainingBalance)}' : ' All payments settled!'}'
          ),
          backgroundColor: remainingBalance > 0 ? Colors.orange : Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final workEntries = List<WorkEntry>.from(_client.workEntries)
      ..sort((a, b) => b.date.compareTo(a.date));

    final totalEarnings = _client.totalEarnings;
    
    // Group entries by month and year
    final groupedEntries = <String, List<WorkEntry>>{};
    for (var entry in workEntries) {
      final key = DateFormat('MMMM yyyy').format(entry.date);
      if (!groupedEntries.containsKey(key)) {
        groupedEntries[key] = [];
      }
      groupedEntries[key]!.add(entry);
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_client.name),
          backgroundColor: Colors.blue,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editClientInfo,
              tooltip: 'Edit Client',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDeleteClient,
              tooltip: 'Delete Client',
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Client Summary Card
              Card(
                margin: const EdgeInsets.all(16),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    
                    // Main Content Section
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          
                          // Work Stats Section with PDF button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Work Statistics',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.picture_as_pdf, color: Colors.blue),
                                tooltip: 'Download PDF Report',
                                iconSize: 20,
                                constraints: const BoxConstraints.tightFor(width: 30, height: 30),
                                padding: EdgeInsets.zero,
                                onPressed: () => _generateClientPDF(_client),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Counts of different work types
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildWorkStatItem(
                                icon: Icons.access_time,
                                label: 'Hours',
                                count: _client.hoursCount,
                                color: Colors.indigo,
                              ),
                              _buildWorkStatItem(
                                icon: Icons.more_time,
                                label: 'Half Days',
                                count: _client.halfDaysCount,
                                color: Colors.amber.shade700,
                              ),
                              _buildWorkStatItem(
                                icon: Icons.today,
                                label: 'Full Days',
                                count: _client.fullDaysCount,
                                color: Colors.green,
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          
                          // Payment Summary Section
                          Text(
                            'Payment Summary',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Calculate payments received
                          Builder(builder: (context) {
                            final double totalAmount = totalEarnings;
                            
                            // Calculate work entries (positive amounts)
                            final double workAmount = _client.workEntries
                                .where((entry) => 
                                  !entry.description.toLowerCase().contains('received') && 
                                  !entry.description.toLowerCase().contains('payment'))
                                .fold(0.0, (sum, entry) => sum + entry.amount);
                            
                            // Calculate payment entries (positive amounts)
                            final double amountReceived = _client.workEntries
                                .where((entry) => 
                                  entry.description.toLowerCase().contains('received') || 
                                  entry.description.toLowerCase().contains('payment'))
                                .fold(0.0, (sum, entry) => sum + entry.amount);
                            
                            final double amountDue = workAmount - amountReceived;
                            final double paymentPercentage = workAmount > 0 ? (amountReceived / workAmount) * 100 : 0;
                            
                            return Column(
                              children: [
                                // Total Amount
                                _buildPaymentRow(
                                  label: 'Total Amount:',
                                  amount: workAmount,
                                  isTotal: true,
                                ),
                                const SizedBox(height: 8),
                                
                                // Amount Received
                                _buildPaymentRow(
                                  label: 'Amount Received:',
                                  amount: amountReceived,
                                  textColor: Colors.green,
                                ),
                                const SizedBox(height: 8),
                                
                                // Amount Due
                                _buildPaymentRow(
                                  label: 'Amount Due:',
                                  amount: amountDue,
                                  textColor: Colors.red,
                                  isLast: true,
                                ),
                                
                                // Add Payment Button
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _addPaymentEntry(amountDue),
                                    icon: const Icon(Icons.payments),
                                    label: const Text('ADD PAYMENT'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                ),
                                
                                // Progress Bar
                                if (workAmount > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Payment Progress',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: LinearProgressIndicator(
                                            value: workAmount > 0 ? amountReceived / workAmount : 0,
                                            minHeight: 10,
                                            backgroundColor: Colors.grey[300],
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              amountReceived >= workAmount ? Colors.green : Colors.blue,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              '0%',
                                              style: TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                            Text(
                                              '${paymentPercentage.toStringAsFixed(1)}%',
                                              style: const TextStyle(
                                                fontSize: 12, 
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                              ),
                                            ),
                                            const Text(
                                              '100%',
                                              style: TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Work History Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    const Text(
                      'Work History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${workEntries.length} entries)',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Work History Content
              workEntries.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      'No work entries yet.\nTap + to add work entries.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: groupedEntries.length,
                    padding: const EdgeInsets.only(bottom: 80),
                    itemBuilder: (context, index) {
                      final monthYear = groupedEntries.keys.elementAt(index);
                      final entries = groupedEntries[monthYear]!;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              monthYear,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          ...entries.map((entry) => _buildWorkEntryTile(entry)),
                        ],
                      );
                    },
                  ),
              
              // Add bottom padding to make room for the FAB
              const SizedBox(height: 80),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addWorkEntry,
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add),
          label: const Text('Add Entry'),
          tooltip: 'Add Work Entry',
        ),
      ),
    );
  }

  Widget _buildWorkStatItem({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(icon, color: color, size: 24),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPaymentRow({
    required String label,
    required double amount,
    Color? textColor,
    bool isTotal = false,
    bool isLast = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: Colors.grey[800],
          ),
        ),
        Text(
          currencyFormat.format(amount),
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: FontWeight.bold,
            color: textColor ?? (isTotal ? AppColors.primary : Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkEntryTile(WorkEntry entry) {
    IconData getTypeIcon() {
      switch (entry.durationType) {
        case 'Hourly':
          return Icons.access_time;
        case 'Half Day':
          return Icons.more_time;
        case 'Full Day':
          return Icons.today;
        default:
          return Icons.work;
      }
    }

    // Determine if this is a payment entry
    bool isPayment = entry.durationType == 'Payment' || 
                     entry.description.toLowerCase().contains('payment') ||
                     entry.description.toLowerCase().contains('received');

    Widget entryCard = Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      shadowColor: Colors.black38,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: isPayment 
                      ? Colors.green.withOpacity(0.2) 
                      : AppColors.primary.withOpacity(0.2),
                  child: Icon(
                    isPayment ? Icons.payments : getTypeIcon(), 
                    color: isPayment ? Colors.green : AppColors.primary
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date and time on the same row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateFormat.format(entry.date),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            timeFormat.format(entry.date),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      
                      // Description below date/time
                      if (entry.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            entry.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[800],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      
                      const SizedBox(height: 8),
                      
                      // Amount and work/payment indicator at bottom
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPayment 
                                  ? Colors.green.withOpacity(0.15) 
                                  : AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isPayment ? 'Payment' : entry.durationType,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isPayment ? Colors.green : AppColors.primary,
                              ),
                            ),
                          ),
                          Text(
                            currencyFormat.format(entry.amount),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isPayment ? Colors.green : AppColors.primary,
                              fontSize: 16,
                            ),
                          ),
                        ],
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Dismissible(
        key: Key(entry.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20.0),
          color: Colors.red,
          child: const Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
        confirmDismiss: (direction) async {
          return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Entry'),
              content: const Text('Are you sure you want to delete this work entry?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        },
        onDismissed: (direction) {
          _deleteWorkEntry(entry.id);
        },
        child: entryCard,
      ),
    );
  }
} 