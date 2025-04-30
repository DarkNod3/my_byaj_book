import 'package:flutter/material.dart';
import 'package:my_byaj_book/constants/app_theme.dart';
import 'package:my_byaj_book/widgets/header/app_header.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  bool _showAll = false;

  // Sample data - in a real app, this would come from a provider or service
  final List<Map<String, dynamic>> _reminders = [
    {
      'title': 'Home Loan EMI Payment',
      'amount': '₹12,500',
      'dueDate': '28 April 2025',
      'daysLeft': 2,
      'isCompleted': false,
    },
    {
      'title': 'Car Loan EMI',
      'amount': '₹8,200',
      'dueDate': '30 April 2025',
      'daysLeft': 4,
      'isCompleted': false,
    },
    {
      'title': 'Credit Card Bill',
      'amount': '₹5,600',
      'dueDate': '5 May 2025',
      'daysLeft': 9,
      'isCompleted': false,
    },
    {
      'title': 'Personal Loan EMI',
      'amount': '₹3,800',
      'dueDate': '10 May 2025',
      'daysLeft': 14,
      'isCompleted': false,
    },
    {
      'title': 'Education Loan EMI',
      'amount': '₹7,200',
      'dueDate': '15 May 2025',
      'daysLeft': 19,
      'isCompleted': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredReminders = _showAll 
      ? _reminders 
      : _reminders.where((reminder) => !reminder['isCompleted']).toList();

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Reminders',
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
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Reminders',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Row(
                  children: [
                    const Text('Show completed'),
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
          Expanded(
            child: filteredReminders.isEmpty
                ? const Center(
                    child: Text(
                      'No reminders to show',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredReminders.length,
                    itemBuilder: (context, index) {
                      final reminder = filteredReminders[index];
                      return _buildReminderItem(reminder);
                    },
                  ),
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

  Widget _buildReminderItem(Map<String, dynamic> reminder) {
    final daysLeft = reminder['daysLeft'];
    Color statusColor = Colors.green;
    
    if (reminder['isCompleted']) {
      statusColor = Colors.grey;
    } else if (daysLeft <= 3) {
      statusColor = Colors.red;
    } else if (daysLeft <= 7) {
      statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    reminder['title'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  reminder['amount'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 4),
                    Text('Due: ${reminder['dueDate']}'),
                  ],
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
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!reminder['isCompleted'])
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        reminder['isCompleted'] = true;
                      });
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Mark as Done'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: BorderSide(color: AppTheme.primaryColor),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        reminder['isCompleted'] = false;
                      });
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
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                  onPressed: () {
                    setState(() {
                      _reminders.remove(reminder);
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddReminderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Reminder'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'Enter reminder title',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Amount',
                hintText: 'Enter amount',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Due Date',
                hintText: 'Select due date',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reminder added successfully'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Add Reminder'),
          ),
        ],
      ),
    );
  }
} 