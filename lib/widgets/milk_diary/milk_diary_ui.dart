import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A reusable Milk Diary UI widget that provides a consistent interface
/// with no duplicate headers and properly aligned text.
class MilkDiaryUI extends StatefulWidget {
  final Widget dailyEntriesTab;
  final Widget monthlySummaryTab;
  final VoidCallback onAddEntry;
  
  const MilkDiaryUI({
    Key? key,
    required this.dailyEntriesTab,
    required this.monthlySummaryTab,
    required this.onAddEntry,
  }) : super(key: key);

  @override
  State<MilkDiaryUI> createState() => _MilkDiaryUIState();
}

class _MilkDiaryUIState extends State<MilkDiaryUI> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No appBar defined here - rely on the parent to provide one
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: Colors.deepPurple,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'Daily Entries'),
                Tab(text: 'Monthly Summary'),
              ],
            ),
          ),
          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                widget.dailyEntriesTab,
                widget.monthlySummaryTab,
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onAddEntry,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// A UI component for showing the date selector in the Milk Diary
class DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  
  const DateSelector({
    Key? key,
    required this.selectedDate,
    required this.onDateChanged,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Date: ${DateFormat('MMMM d, yyyy').format(selectedDate)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );
              if (picked != null && picked != selectedDate) {
                onDateChanged(picked);
              }
            },
            icon: const Icon(Icons.calendar_today),
            label: const Text('Change'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}

/// A widget to ensure text is always horizontal and never rotated
class HorizontalText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  
  const HorizontalText({
    Key? key,
    required this.text,
    this.style,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      textDirection: TextDirection.ltr,
    );
  }
} 