import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/bill_note.dart';
import '../../providers/bill_note_provider.dart';
import '../../constants/app_theme.dart';
import '../../widgets/dialogs/confirm_dialog.dart';

class BillNoteDetailScreen extends StatefulWidget {
  final BillNote? note;

  const BillNoteDetailScreen({Key? key, this.note}) : super(key: key);

  @override
  State<BillNoteDetailScreen> createState() => _BillNoteDetailScreenState();
}

class _BillNoteDetailScreenState extends State<BillNoteDetailScreen> {
  late BillNote _note;
  bool _isEditing = false;
  bool _isLoading = false;
  
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _amountController;
  late BillCategory _selectedCategory;
  DateTime? _reminderDate;
  
  @override
  void initState() {
    super.initState();
    
    // Get the note from the provider if only an ID was passed
    if (widget.note == null) {
      Navigator.of(context).pop();
      return;
    }
    
    _note = widget.note!;
    _initFormControllers();
  }
  
  void _initFormControllers() {
    _titleController = TextEditingController(text: _note.title);
    _contentController = TextEditingController(text: _note.content);
    _amountController = TextEditingController(
      text: _note.amount?.toString() ?? '',
    );
    _selectedCategory = _note.category;
    _reminderDate = _note.reminderDate;
  }
  
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
  
  Future<void> _toggleEditMode() async {
    if (_isEditing) {
      // Save the changes
      if (_formKey.currentState!.validate()) {
        _saveChanges();
      }
    } else {
      // Enter edit mode
      setState(() {
        _isEditing = true;
      });
    }
  }
  
  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      double? amount;
      if (_amountController.text.isNotEmpty) {
        amount = double.tryParse(_amountController.text);
      }
      
      final updatedNote = _note.copyWith(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        category: _selectedCategory,
        reminderDate: _reminderDate,
        amount: amount,
      );
      
      await Provider.of<BillNoteProvider>(context, listen: false)
          .updateNote(updatedNote);
      
      setState(() {
        _note = updatedNote;
        _isEditing = false;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating note: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _toggleCompleteStatus() async {
    try {
      final provider = Provider.of<BillNoteProvider>(context, listen: false);
      await provider.toggleNoteStatus(_note.id);
      
      final updatedNote = _note.copyWith(isCompleted: !_note.isCompleted);
      setState(() {
        _note = updatedNote;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_note.isCompleted 
            ? 'Note marked as completed' 
            : 'Note marked as pending'
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }
  
  Future<void> _deleteNote() async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Delete Note',
        content: 'Are you sure you want to delete this note?',
        confirmText: 'Delete',
        confirmColor: Colors.red,
      ),
    );
    
    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        await Provider.of<BillNoteProvider>(context, listen: false)
            .deleteNote(_note.id);
        
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note deleted successfully')),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting note: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Note' : 'Note Details'),
        actions: [
          if (!_isEditing) 
            IconButton(
              icon: Icon(
                _note.isCompleted 
                    ? Icons.check_circle
                    : Icons.check_circle_outline,
                color: Colors.white,
              ),
              onPressed: _toggleCompleteStatus,
              tooltip: _note.isCompleted 
                  ? 'Mark as Pending' 
                  : 'Mark as Completed',
            ),
          IconButton(
            icon: Icon(
              _isEditing ? Icons.save : Icons.edit,
              color: Colors.white,
            ),
            onPressed: _toggleEditMode,
          ),
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _deleteNote,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isEditing
              ? _buildEditForm()
              : _buildNoteDetails(),
    );
  }
  
  Widget _buildNoteDetails() {
    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('hh:mm a');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: _note.category.color.withOpacity(0.2),
                foregroundColor: _note.category.color,
                radius: 24,
                child: Icon(_note.category.icon, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _note.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        decoration: _note.isCompleted 
                            ? TextDecoration.lineThrough 
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.category,
                          size: 16,
                          color: _note.category.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _note.category.name.capitalize(),
                          style: TextStyle(
                            color: _note.category.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (_note.amount != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.secondaryColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.currency_rupee, 
                    color: AppTheme.secondaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '₹${_note.amount!.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          Text(
            'Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              _note.content,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.grey.shade800,
                decoration: _note.isCompleted 
                    ? TextDecoration.lineThrough 
                    : null,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          Text(
            'Date & Time',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  'Created on',
                  '${dateFormat.format(_note.createdDate)} at ${timeFormat.format(_note.createdDate)}',
                  Icons.event_available,
                ),
                if (_note.reminderDate != null) ...[
                  const Divider(height: 24),
                  _buildInfoRow(
                    'Reminder set for',
                    dateFormat.format(_note.reminderDate!),
                    Icons.notifications_active,
                    iconColor: Colors.amber.shade700,
                  ),
                ],
                if (_note.isCompleted) ...[
                  const Divider(height: 24),
                  _buildInfoRow(
                    'Completed',
                    'This note is marked as completed',
                    Icons.check_circle,
                    iconColor: Colors.green,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, IconData icon, {Color? iconColor}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: iconColor ?? Colors.grey.shade700,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                labelText: 'Content',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter content';
                }
                return null;
              },
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
                  selected: _selectedCategory == category,
                  avatar: Icon(
                    category.icon,
                    size: 18,
                    color: _selectedCategory == category 
                        ? Colors.white 
                        : category.color,
                  ),
                  selectedColor: category.color,
                  labelStyle: TextStyle(
                    color: _selectedCategory == category 
                        ? Colors.white 
                        : Colors.black87,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCategory = category;
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
                      style: TextStyle(color: AppTheme.primaryColor),
                    ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_reminderDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _reminderDate = null;
                        });
                      },
                    ),
                  IconButton(
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
                ],
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
                onPressed: _saveChanges,
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 