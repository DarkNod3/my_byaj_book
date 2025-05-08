import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/bill_note.dart';
import '../../providers/bill_note_provider.dart';
import '../../constants/app_theme.dart';
import 'bill_note_detail_screen.dart';

class BillDiaryScreen extends StatefulWidget {
  static const routeName = '/bill-diary';

  final bool showAppBar;
  
  const BillDiaryScreen({
    Key? key,
    this.showAppBar = true
  }) : super(key: key);

  @override
  State<BillDiaryScreen> createState() => _BillDiaryScreenState();
}

class _BillDiaryScreenState extends State<BillDiaryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  BillCategory _selectedCategory = BillCategory.all;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load notes when screen initializes
    Future.microtask(() {
      Provider.of<BillNoteProvider>(context, listen: false).loadNotes();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddNoteDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NewNoteBottomSheet(),
    );
  }
  
  void _navigateToDetailScreen(BuildContext context, {BillNote? note}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BillNoteDetailScreen(note: note),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar ? AppBar(
        title: const Text('Bill Diary'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Notes'),
            Tab(text: 'Reminders'),
          ],
        ),
      ) : null,
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotesList(),
                _buildRemindersList(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNoteDialog,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildCategoryChip(BillCategory.all),
          ...BillCategory.values
              .where((c) => c != BillCategory.all)
              .map((category) => _buildCategoryChip(category))
              .toList(),
        ],
      ),
    );
  }
  
  Widget _buildCategoryChip(BillCategory category) {
    final isSelected = _selectedCategory == category;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(category.name.capitalize()),
        avatar: Icon(category.icon, size: 18),
        backgroundColor: Colors.white,
        selectedColor: category.color.withOpacity(0.2),
        checkmarkColor: category.color,
        labelStyle: TextStyle(
          color: isSelected ? category.color : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
        },
      ),
    );
  }
  
  Widget _buildNotesList() {
    return Consumer<BillNoteProvider>(
      builder: (ctx, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final notes = _selectedCategory == BillCategory.all
            ? provider.notes
            : provider.getNotesByCategory(_selectedCategory);
            
        if (notes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.note_alt_outlined, 
                  size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text('No notes found',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                const SizedBox(height: 8),
                Text(_selectedCategory == BillCategory.all 
                  ? 'Add your first note'
                  : 'Try selecting a different category',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notes.length,
          itemBuilder: (ctx, index) {
            return _buildNoteCard(notes[index]);
          },
        );
      },
    );
  }
  
  Widget _buildRemindersList() {
    return Consumer<BillNoteProvider>(
      builder: (ctx, provider, child) {
        final upcomingReminders = provider.upcomingReminders;
        
        if (upcomingReminders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none_outlined, 
                  size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text('No upcoming reminders',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                const SizedBox(height: 8),
                Text('Add reminders to your notes',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: upcomingReminders.length,
          itemBuilder: (ctx, index) {
            return _buildNoteCard(upcomingReminders[index]);
          },
        );
      },
    );
  }
  
  Widget _buildNoteCard(BillNote note) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy');
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: note.category.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToDetailScreen(context, note: note),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: note.category.color.withOpacity(0.2),
                    foregroundColor: note.category.color,
                    radius: 20,
                    child: Icon(note.category.icon),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            decoration: note.isCompleted 
                                ? TextDecoration.lineThrough 
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          note.content.isEmpty ? "No details provided" : note.content,
                          style: TextStyle(
                            color: note.content.isEmpty ? Colors.grey.shade500 : Colors.grey.shade700,
                            fontStyle: note.content.isEmpty ? FontStyle.italic : FontStyle.normal,
                            decoration: note.isCompleted 
                                ? TextDecoration.lineThrough 
                                : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Created: ${dateFormat.format(note.createdDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (note.amount != null)
                    Chip(
                      backgroundColor: AppTheme.secondaryColor.withOpacity(0.1),
                      label: Text(
                        '₹${note.amount!.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
              if (note.reminderDate != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_active_outlined,
                        size: 16,
                        color: Colors.amber.shade800,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Reminder: ${dateFormat.format(note.reminderDate!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NewNoteBottomSheet extends StatefulWidget {
  @override
  _NewNoteBottomSheetState createState() => _NewNoteBottomSheetState();
}

class _NewNoteBottomSheetState extends State<_NewNoteBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _amountController = TextEditingController();
  BillCategory _category = BillCategory.others;
  DateTime? _reminderDate;
  bool _isLoading = false;
  
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _amountController.dispose();
    super.dispose();
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _reminderDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _reminderDate = picked;
      });
    }
  }
  
  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      double? amount;
      if (_amountController.text.isNotEmpty) {
        amount = double.tryParse(_amountController.text);
      }
      
      await Provider.of<BillNoteProvider>(context, listen: false).addNote(
        _titleController.text.trim(),
        _contentController.text.trim().isEmpty ? "" : _contentController.text.trim(),
        _category,
        reminderDate: _reminderDate,
        amount: amount,
      );
      
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving note: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(
                child: Text(
                  'Add New Note',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content (Optional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (Optional)',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: BillCategory.values
                    .where((c) => c != BillCategory.all)
                    .map((category) {
                  return ChoiceChip(
                    label: Text(category.name.capitalize()),
                    selected: _category == category,
                    avatar: Icon(
                      category.icon,
                      size: 18,
                      color: _category == category 
                          ? Colors.white 
                          : category.color,
                    ),
                    selectedColor: category.color,
                    labelStyle: TextStyle(
                      color: _category == category 
                          ? Colors.white 
                          : Colors.black87,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _category = category;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Set Reminder (Optional)'),
                subtitle: _reminderDate == null 
                    ? const Text('No reminder set') 
                    : Text(
                        'Reminder on ${DateFormat('dd MMM yyyy').format(_reminderDate!)}',
                        style: const TextStyle(color: AppTheme.primaryColor),
                      ),
                trailing: IconButton(
                  icon: Icon(
                    _reminderDate == null 
                        ? Icons.notifications_outlined 
                        : Icons.notifications_active,
                    color: _reminderDate == null 
                        ? Colors.grey 
                        : AppTheme.primaryColor,
                  ),
                  onPressed: () => _selectDate(context),
                ),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isLoading ? null : _saveNote,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Note',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 