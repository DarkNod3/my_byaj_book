import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

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

  @override
  void initState() {
    super.initState();
    _client = widget.client;
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
        title: Text('Edit Client'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Client Name *'),
              ),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),
              Text('Rate Information', style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: hourlyRateController,
                decoration: InputDecoration(labelText: 'Hourly Rate (₹)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: halfDayRateController,
                decoration: InputDecoration(labelText: 'Half Day Rate (₹)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: fullDayRateController,
                decoration: InputDecoration(labelText: 'Full Day Rate (₹)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Client name is required')),
                );
                return;
              }
              
              Navigator.of(context).pop(true);
            },
            child: Text('Save'),
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
    String selectedDurationType = 'Hourly';
    final TextEditingController hoursController = TextEditingController(text: '1');
    final TextEditingController amountController = TextEditingController(
      text: _client.hourlyRate > 0 ? _client.hourlyRate.toString() : '',
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

    final result = await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Work Entry'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Date: ${dateFormat.format(selectedDate)}',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text('Duration Type', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: selectedDurationType,
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
                    SizedBox(height: 8),
                    if (selectedDurationType == 'Hourly')
                      TextField(
                        controller: hoursController,
                        decoration: InputDecoration(labelText: 'Hours'),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => updateAmount(),
                      ),
                    TextField(
                      controller: amountController,
                      decoration: InputDecoration(labelText: 'Amount (₹)'),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description (optional)',
                        hintText: 'What was the work for?',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final amount = double.tryParse(amountController.text) ?? 0.0;
                    if (amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Amount must be greater than zero')),
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
                  child: Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      final newEntry = WorkEntry(
        id: Uuid().v4(),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Entry'),
        content: Text('Are you sure you want to delete this work entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        final updatedEntries = List<WorkEntry>.from(_client.workEntries)
          ..removeWhere((entry) => entry.id == entryId);
        final updatedClient = _client.copyWith(workEntries: updatedEntries);

        setState(() {
          _client = updatedClient;
        });

        widget.updateClient(updatedClient);
      }
    });
  }

  void _confirmDeleteClient() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Client'),
        content: Text(
          'Are you sure you want to delete ${_client.name} and all their work entries? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
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
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: _editClientInfo,
              tooltip: 'Edit Client',
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _confirmDeleteClient,
              tooltip: 'Delete Client',
            ),
          ],
        ),
        body: Column(
          children: [
            Card(
              margin: EdgeInsets.all(16),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: _client.avatarColor,
                          radius: 30,
                          child: Text(
                            _client.initials,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _client.name,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_client.phoneNumber.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    children: [
                                      Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                                      SizedBox(width: 4),
                                      Text(
                                        _client.phoneNumber,
                                        style: TextStyle(color: Colors.grey[700]),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Divider(),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildRateInfo(
                          icon: Icons.access_time,
                          label: 'Hourly',
                          rate: _client.hourlyRate > 0
                              ? currencyFormat.format(_client.hourlyRate)
                              : 'Not Set',
                        ),
                        _buildRateInfo(
                          icon: Icons.more_time,
                          label: 'Half Day',
                          rate: _client.halfDayRate > 0
                              ? currencyFormat.format(_client.halfDayRate)
                              : 'Not Set',
                        ),
                        _buildRateInfo(
                          icon: Icons.today,
                          label: 'Full Day',
                          rate: _client.fullDayRate > 0
                              ? currencyFormat.format(_client.fullDayRate)
                              : 'Not Set',
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Divider(),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Earnings:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          currencyFormat.format(totalEarnings),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text(
                    'Work History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
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
            Expanded(
              child: workEntries.isEmpty
                  ? Center(
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
                      itemCount: groupedEntries.length,
                      padding: EdgeInsets.only(bottom: 80),
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
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addWorkEntry,
          backgroundColor: AppColors.primary,
          child: Icon(Icons.add),
          tooltip: 'Add Work Entry',
        ),
      ),
    );
  }

  Widget _buildRateInfo({
    required IconData icon,
    required String label,
    required String rate,
  }) {
    final isNotSet = rate == 'Not Set';
    
    return Column(
      children: [
        Icon(icon, color: isNotSet ? Colors.grey : AppColors.primary),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        ),
        SizedBox(height: 2),
        Text(
          rate,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isNotSet ? Colors.grey : Colors.black87,
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

    String getTypeText() {
      if (entry.durationType == 'Hourly' && entry.hours != null) {
        return '${entry.hours} hour${entry.hours == 1 ? '' : 's'}';
      }
      return entry.durationType;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Card(
        elevation: 1,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: Icon(getTypeIcon(), color: AppColors.primary),
          ),
          title: Row(
            children: [
              Text(
                dateFormat.format(entry.date),
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  getTypeText(),
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          subtitle: entry.description.isNotEmpty
              ? Text(
                  entry.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(entry.amount),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          onLongPress: () => _deleteWorkEntry(entry.id),
        ),
      ),
    );
  }
} 