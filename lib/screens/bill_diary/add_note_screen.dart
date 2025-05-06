import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/bill_note.dart';
import '../../providers/bill_note_provider.dart';
import '../../constants/app_theme.dart';

class AddNoteScreen extends StatefulWidget {
  final BillNote? note; // Pass existing note for editing
  
  const AddNoteScreen({Key? key, this.note}) : super(key: key);

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _amountController = TextEditingController();
  
  BillCategory _selectedCategory = BillCategory.bills;
  DateTime? _reminderDate;
  bool _isEditing = false;
  
  @override
  void initState() {
    super.initState();
    _isEditing = widget.note != null;
    
    if (_isEditing) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _selectedCategory = widget.note!.category;
      _reminderDate = widget.note!.reminderDate;
      
      if (widget.note!.amount != null) {
        _amountController.text = widget.note!.amount!.toString();
      }
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Note' : 'Add New Note'),
        actions: [
          TextButton.icon(
            onPressed: _saveNote,
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: 'Content (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
              ),
              SizedBox(height: 16),
              Text(
                'Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in BillCategory.values)
                    _buildCategoryChip(category),
                ],
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
                  hintText: 'Enter amount if applicable',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 16),
              _buildReminderSection(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCategoryChip(BillCategory category) {
    final isSelected = _selectedCategory == category;
    
    return FilterChip(
      label: Text(category.name),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = category;
        });
      },
      avatar: Icon(
        category.icon,
        color: isSelected ? Colors.white : category.color,
        size: 16,
      ),
      backgroundColor: category.color.withOpacity(0.1),
      selectedColor: category.color,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : category.color,
        fontWeight: FontWeight.bold,
      ),
    );
  }
  
  Widget _buildReminderSection() {
    final dateText = _reminderDate != null
        ? DateFormat('dd MMM yyyy').format(_reminderDate!)
        : 'No reminder set';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reminder',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.alarm,
                  color: Colors.orangeAccent,
                ),
                SizedBox(width: 12),
                Text(
                  dateText,
                  style: TextStyle(
                    fontSize: 16,
                    color: _reminderDate != null 
                        ? Colors.black87 
                        : Colors.grey.shade600,
                  ),
                ),
                Spacer(),
                if (_reminderDate != null)
                  IconButton(
                    icon: Icon(Icons.close, size: 18),
                    onPressed: () {
                      setState(() {
                        _reminderDate = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Future<void> _selectDate() async {
    final now = DateTime.now();
    final initialDate = _reminderDate ?? now;
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    
    if (selectedDate != null) {
      setState(() {
        _reminderDate = selectedDate;
      });
    }
  }
  
  void _saveNote() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    double? amount;
    if (_amountController.text.isNotEmpty) {
      amount = double.tryParse(_amountController.text);
    }
    
    final provider = Provider.of<BillNoteProvider>(context, listen: false);
    
    if (_isEditing) {
      // Update existing note
      final updatedNote = widget.note!.copyWith(
        title: _titleController.text,
        content: _contentController.text.isEmpty ? "" : _contentController.text,
        category: _selectedCategory,
        reminderDate: _reminderDate,
        amount: amount,
      );
      
      provider.updateNote(updatedNote);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note updated successfully')),
      );
    } else {
      // Create new note
      final newNote = BillNote(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        content: _contentController.text.isEmpty ? "" : _contentController.text,
        category: _selectedCategory,
        createdDate: DateTime.now(),
        reminderDate: _reminderDate,
        amount: amount,
        isCompleted: false,
      );
      
      provider.addNote(newNote);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note added successfully')),
      );
    }
    
    Navigator.pop(context);
  }
} 