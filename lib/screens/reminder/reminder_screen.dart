import 'package:flutter/material.dart';
import 'package:my_byaj_book/constants/app_theme.dart';
import 'package:my_byaj_book/widgets/header/app_header.dart';
import 'package:my_byaj_book/providers/transaction_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:my_byaj_book/screens/card/card_screen.dart';
import 'package:my_byaj_book/providers/card_provider.dart';
import 'package:my_byaj_book/services/notification_service.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});
  
  static const routeName = '/reminders';

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    // Get due payments from transaction provider
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final upcomingPayments = transactionProvider.getUpcomingPayments();
    
    // Filter based on completion status
    final filteredReminders = _showAll 
      ? upcomingPayments 
      : upcomingPayments.where((reminder) => !reminder['isCompleted']).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          AppHeader(
            title: 'Reminders & Due Payments',
            showBackButton: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.add_alert, color: Colors.white),
                onPressed: () {
                  _showAddReminderDialog(context);
                },
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Payments',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Row(
                  children: [
                    Text(
                      'Show completed',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                    Switch(
                      value: _showAll,
                      onChanged: (value) {
                        setState(() {
                          _showAll = value;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildCategoriesRow(),
          Expanded(
            child: _buildReminderContent(filteredReminders),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddReminderDialog(context);
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildCategoriesRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            _buildCategoryChip('All', Icons.all_inclusive, Colors.purple),
            _buildCategoryChip('Contacts', Icons.person, Colors.blue),
            _buildCategoryChip('Loans', Icons.account_balance, Colors.green),
            _buildCategoryChip('Cards', Icons.credit_card, Colors.orange),
            _buildCategoryChip('Bills', Icons.receipt, Colors.red),
            _buildCategoryChip('EMI', Icons.calculate, Colors.teal),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoryChip(String label, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        avatar: Icon(icon, color: color, size: 16),
        label: Text(label),
        backgroundColor: Colors.grey.shade100,
        labelStyle: TextStyle(
          color: Colors.grey.shade800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildReminderContent(List<Map<String, dynamic>> reminders) {
    if (reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No upcoming payments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You don\'t have any payments due soon',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _showAddReminderDialog(context);
              },
              icon: const Icon(Icons.add_alert, size: 18),
              label: const Text('Add Reminder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: reminders.length,
      padding: const EdgeInsets.only(bottom: 80), // Padding for FAB
      itemBuilder: (context, index) {
        final reminder = reminders[index];
        return _buildReminderItem(reminder);
      },
    );
  }

  Widget _buildReminderItem(Map<String, dynamic> reminder) {
    final daysLeft = reminder['daysLeft'] as int;
    final dueDate = reminder['dueDate'] as DateTime;
    final formattedDate = DateFormat('dd MMM yyyy').format(dueDate);
    final amount = reminder['amount'] as double;
    final formattedAmount = '₹${amount.toStringAsFixed(2)}';
    
    Color statusColor = Colors.green;
    if (reminder['isCompleted']) {
      statusColor = Colors.grey;
    } else if (daysLeft <= 1) {
      statusColor = Colors.red;
    } else if (daysLeft <= 3) {
      statusColor = Colors.orange;
    }
    
    // Determine icon and background color based on payment type
    IconData typeIcon = Icons.person;
    Color typeColor = Colors.blue;
    
    final type = reminder['type'] as String;
    if (type.contains('loan')) {
      typeIcon = Icons.account_balance;
      typeColor = Colors.green;
    } else if (type.contains('card')) {
      typeIcon = Icons.credit_card;
      typeColor = Colors.orange;
    } else if (type.contains('bill')) {
      typeIcon = Icons.receipt;
      typeColor = Colors.red;
    } else if (type.contains('emi')) {
      typeIcon = Icons.calculate;
      typeColor = Colors.teal;
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shadowColor: AppTheme.primaryColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () {
          // Handle navigation based on reminder type
          if (type.contains('card') && reminder.containsKey('cardIndex')) {
            final cardIndex = reminder['cardIndex'] as int;
            
            // Navigate to card screen with the correct card selected
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  final cardProvider = Provider.of<CardProvider>(context, listen: false);
                  cardProvider.setSelectedCardIndex(cardIndex);
                  return const CardScreen(showAppBar: true);
                },
              ),
            );
          }
          // Handle other reminder types if needed
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      typeIcon,
                      color: typeColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      reminder['title'],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  Text(
                    formattedAmount,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Due: $formattedDate',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      reminder['isCompleted']
                          ? 'Completed'
                          : daysLeft <= 0
                              ? 'Due Today'
                              : '$daysLeft days left',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Special section for credit card reminders
              if (type.contains('card'))
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Credit Card Payment',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        if (reminder.containsKey('cardIndex')) {
                          final cardIndex = reminder['cardIndex'] as int;
                          
                          // Navigate to card screen with the correct card selected
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                final cardProvider = Provider.of<CardProvider>(context, listen: false);
                                cardProvider.setSelectedCardIndex(cardIndex);
                                return const CardScreen(showAppBar: true);
                              },
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.credit_card_outlined, size: 14),
                      label: const Text('Go to Card', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: typeColor,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              
              // Action buttons for all reminders
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!reminder['isCompleted'])
                    OutlinedButton.icon(
                      onPressed: () {
                        final provider = Provider.of<TransactionProvider>(context, listen: false);
                        
                        // Check if this is a manual reminder
                        if (reminder['manuallyCreated'] == true) {
                          // Find index of this reminder in the provider's list
                          final index = provider.manualReminders.indexWhere((r) => 
                            r['title'] == reminder['title'] && 
                            r['dueDate'] == reminder['dueDate']);
                            
                          if (index != -1) {
                            provider.updateManualReminderStatus(index, true);
                          }
                        } else {
                          // For non-manual reminders, just update locally
                          setState(() {
                            reminder['isCompleted'] = true;
                          });
                        }
                        
                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${reminder['title']} marked as paid'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Mark as Paid'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: BorderSide(color: AppTheme.primaryColor),
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () {
                        final provider = Provider.of<TransactionProvider>(context, listen: false);
                        
                        // Check if this is a manual reminder
                        if (reminder['manuallyCreated'] == true) {
                          // Find index of this reminder
                          final index = provider.manualReminders.indexWhere((r) => 
                            r['title'] == reminder['title'] && 
                            r['dueDate'] == reminder['dueDate']);
                            
                          if (index != -1) {
                            provider.updateManualReminderStatus(index, false);
                          }
                        } else {
                          // For non-manual reminders, just update locally
                          setState(() {
                            reminder['isCompleted'] = false;
                          });
                        }
                      },
                      icon: const Icon(Icons.undo, size: 16),
                      label: const Text('Unmark'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: const BorderSide(color: Colors.grey),
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    color: AppTheme.primaryColor,
                    onPressed: () {
                      _showPaymentDetails(context, reminder);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showPaymentDetails(BuildContext context, Map<String, dynamic> payment) {
    final dueDate = payment['dueDate'] as DateTime;
    final formattedDate = DateFormat('dd MMM yyyy').format(dueDate);
    final isManualReminder = payment['manuallyCreated'] == true;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                payment['title'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Amount', '₹${(payment['amount'] as double).toStringAsFixed(2)}'),
              _buildDetailRow('Due Date', formattedDate),
              _buildDetailRow('Status', payment['isCompleted'] ? 'Paid' : 'Pending'),
              _buildDetailRow('Type', payment['type'].toString().split('_')[0].toUpperCase()),
              if (isManualReminder)
                _buildDetailRow('Created By', 'You (Manual Reminder)'),
              if (payment['contactId'] != null)
                _buildDetailRow('Contact ID', payment['contactId']),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isManualReminder)
                    TextButton.icon(
                      onPressed: () {
                        // Confirm deletion
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Reminder'),
                            content: const Text('Are you sure you want to delete this reminder?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context); // Close confirmation dialog
                                  Navigator.pop(context); // Close details dialog
                                  
                                  // Find and delete the reminder
                                  final provider = Provider.of<TransactionProvider>(context, listen: false);
                                  final index = provider.manualReminders.indexWhere((r) => 
                                    r['title'] == payment['title'] && 
                                    r['dueDate'] == payment['dueDate']);
                                    
                                  if (index != -1) {
                                    provider.deleteManualReminder(index);
                                    
                                    // Show success message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Reminder deleted successfully'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                },
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                      label: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Handle payment and mark as complete
                      final provider = Provider.of<TransactionProvider>(context, listen: false);
                      
                      if (isManualReminder) {
                        // Find index of this reminder
                        final index = provider.manualReminders.indexWhere((r) => 
                          r['title'] == payment['title'] && 
                          r['dueDate'] == payment['dueDate']);
                          
                        if (index != -1) {
                          provider.updateManualReminderStatus(index, true);
                        }
                      } else {
                        // For non-manual reminders
                        setState(() {
                          payment['isCompleted'] = true;
                        });
                      }
                      
                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${payment['title']} marked as paid'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: const Text('Pay Now'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddReminderDialog(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    String selectedCategory = 'Contacts';
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Payment Reminder'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Reminder Title',
                        hintText: 'e.g. Payment to John',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount (₹)',
                        hintText: 'e.g. 500',
                        border: OutlineInputBorder(),
                        prefixText: '₹ ',
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Due Date:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                            const Icon(Icons.calendar_today, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Category:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildCategorySelectionChip('Contacts', Icons.person, Colors.blue, selectedCategory, (selected) {
                          setState(() {
                            selectedCategory = 'Contacts';
                          });
                        }),
                        _buildCategorySelectionChip('Loans', Icons.account_balance, Colors.green, selectedCategory, (selected) {
                          setState(() {
                            selectedCategory = 'Loans';
                          });
                        }),
                        _buildCategorySelectionChip('Cards', Icons.credit_card, Colors.orange, selectedCategory, (selected) {
                          setState(() {
                            selectedCategory = 'Cards';
                          });
                        }),
                        _buildCategorySelectionChip('Bills', Icons.receipt, Colors.red, selectedCategory, (selected) {
                          setState(() {
                            selectedCategory = 'Bills';
                          });
                        }),
                        _buildCategorySelectionChip('EMI', Icons.calculate, Colors.teal, selectedCategory, (selected) {
                          setState(() {
                            selectedCategory = 'EMI';
                          });
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Validate inputs
                    if (titleController.text.isEmpty || amountController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields')),
                      );
                      return;
                    }
                    
                    // Parse amount
                    double? amount;
                    try {
                      amount = double.parse(amountController.text);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid amount')),
                      );
                      return;
                    }
                    
                    // Create reminder
                    final reminder = {
                      'title': titleController.text,
                      'amount': amount,
                      'dueDate': selectedDate,
                      'daysLeft': selectedDate.difference(DateTime.now()).inDays,
                      'type': '${selectedCategory.toLowerCase()}_manual',
                      'isCompleted': false,
                      'manuallyCreated': true,
                    };
                    
                    // Add to provider
                    final provider = Provider.of<TransactionProvider>(context, listen: false);
                    provider.addManualReminder(reminder);
                    
                    // Schedule notification for the reminder
                    NotificationService.instance.scheduleManualReminders(provider);
                    
                    // Close dialog and show success message
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reminder created successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          }
        );
      },
    );
  }
  
  Widget _buildCategorySelectionChip(String label, IconData icon, Color color, String selectedCategory, Function(bool) onSelected) {
    final isSelected = selectedCategory == label;
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : color),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: Colors.grey.shade200,
      selectedColor: color,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }
} 