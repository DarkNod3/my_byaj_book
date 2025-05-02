import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/milk_diary/daily_entry.dart';
import '../../models/milk_diary/milk_seller.dart';
import '../../providers/milk_diary/daily_entry_provider.dart';
import '../../providers/milk_diary/milk_seller_provider.dart';
import '../../constants/app_theme.dart';

class AddEntryScreen extends StatefulWidget {
  final DailyEntry? entry;
  
  const AddEntryScreen({Key? key, this.entry}) : super(key: key);

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late DateTime _selectedDate;
  late EntryShift _selectedShift;
  String? _selectedSellerId;
  
  final _quantityController = TextEditingController();
  final _fatController = TextEditingController();
  final _rateController = TextEditingController();
  
  bool _isEditMode = false;
  
  @override
  void initState() {
    super.initState();
    
    _isEditMode = widget.entry != null;
    
    if (_isEditMode) {
      // Initialize with existing entry data
      _selectedDate = widget.entry!.date;
      _selectedShift = widget.entry!.shift;
      _selectedSellerId = widget.entry!.sellerId;
      _quantityController.text = widget.entry!.quantity.toString();
      _fatController.text = widget.entry!.fat.toString();
      _rateController.text = widget.entry!.rate.toString();
    } else {
      // Initialize with default values
      _selectedDate = DateTime.now();
      _selectedShift = _getDefaultShift();
      _quantityController.text = '';
      _fatController.text = '';
      _rateController.text = '';
    }
  }
  
  EntryShift _getDefaultShift() {
    final currentHour = DateTime.now().hour;
    // Morning: before 12pm, Evening: after 12pm
    return currentHour < 12 ? EntryShift.morning : EntryShift.evening;
  }
  
  @override
  void dispose() {
    _quantityController.dispose();
    _fatController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Entry' : 'Add New Entry'),
      ),
      body: Consumer<MilkSellerProvider>(
        builder: (context, sellerProvider, child) {
          final sellers = sellerProvider.sellers;
          
          if (sellers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No sellers found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please add a seller first before adding entries',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/milk-sellers');
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Seller'),
                  ),
                ],
              ),
            );
          }
          
          // Set initial seller if not set and sellers exist
          if (_selectedSellerId == null && sellers.isNotEmpty) {
            _selectedSellerId = sellers.first.id;
          }
          
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDateSelector(),
                    const SizedBox(height: 24),
                    _buildShiftSelector(),
                    const SizedBox(height: 24),
                    _buildSellerDropdown(sellers),
                    const SizedBox(height: 24),
                    _buildQuantityField(),
                    const SizedBox(height: 16),
                    _buildFatField(),
                    const SizedBox(height: 16),
                    _buildRateField(),
                    const SizedBox(height: 16),
                    _buildAmountPreview(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildDateSelector() {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
        );
        if (picked != null && picked != _selectedDate) {
          setState(() {
            _selectedDate = picked;
          });
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          DateFormat('dd MMMM yyyy').format(_selectedDate),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
  
  Widget _buildShiftSelector() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Shift',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.schedule),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<EntryShift>(
          value: _selectedShift,
          isExpanded: true,
          items: EntryShift.values.map((shift) {
            return DropdownMenuItem<EntryShift>(
              value: shift,
              child: Text(shift == EntryShift.morning ? 'Morning' : 'Evening'),
            );
          }).toList(),
          onChanged: (EntryShift? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedShift = newValue;
              });
            }
          },
        ),
      ),
    );
  }
  
  Widget _buildSellerDropdown(List<MilkSeller> sellers) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Seller',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSellerId,
          isExpanded: true,
          items: sellers.map((seller) {
            return DropdownMenuItem<String>(
              value: seller.id,
              child: Text(seller.name),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedSellerId = newValue;
              
              // Auto-fill rate if available
              if (newValue != null) {
                final selectedSeller = sellers.firstWhere((s) => s.id == newValue);
                if (selectedSeller.defaultRate > 0 && _rateController.text.isEmpty) {
                  _rateController.text = selectedSeller.defaultRate.toString();
                  _updateCalculatedAmount();
                }
              }
            });
          },
        ),
      ),
    );
  }
  
  Widget _buildQuantityField() {
    return TextFormField(
      controller: _quantityController,
      decoration: const InputDecoration(
        labelText: 'Quantity (L)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.water_drop),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter quantity';
        }
        if (double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        if (double.parse(value) <= 0) {
          return 'Quantity must be greater than zero';
        }
        return null;
      },
      onChanged: (_) => _updateCalculatedAmount(),
    );
  }
  
  Widget _buildFatField() {
    return TextFormField(
      controller: _fatController,
      decoration: const InputDecoration(
        labelText: 'Fat %',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.opacity),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter fat percentage';
        }
        if (double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        if (double.parse(value) < 0 || double.parse(value) > 100) {
          return 'Fat must be between 0 and 100';
        }
        return null;
      },
    );
  }
  
  Widget _buildRateField() {
    return TextFormField(
      controller: _rateController,
      decoration: const InputDecoration(
        labelText: 'Rate (₹/L)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.currency_rupee),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter rate';
        }
        if (double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        if (double.parse(value) <= 0) {
          return 'Rate must be greater than zero';
        }
        return null;
      },
      onChanged: (_) => _updateCalculatedAmount(),
    );
  }
  
  Widget _buildAmountPreview() {
    final amount = _calculateAmount();
    
    return Card(
      elevation: 2,
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Amount:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  double _calculateAmount() {
    double quantity = 0;
    double rate = 0;
    
    if (_quantityController.text.isNotEmpty && double.tryParse(_quantityController.text) != null) {
      quantity = double.parse(_quantityController.text);
    }
    
    if (_rateController.text.isNotEmpty && double.tryParse(_rateController.text) != null) {
      rate = double.parse(_rateController.text);
    }
    
    return quantity * rate;
  }
  
  void _updateCalculatedAmount() {
    setState(() {});
  }
  
  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _saveEntry,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(
        _isEditMode ? 'Update Entry' : 'Save Entry',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
  
  void _saveEntry() {
    if (_formKey.currentState!.validate()) {
      if (_selectedSellerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a seller')),
        );
        return;
      }
      
      final entryProvider = Provider.of<DailyEntryProvider>(context, listen: false);
      
      final quantity = double.parse(_quantityController.text);
      final fat = double.parse(_fatController.text);
      final rate = double.parse(_rateController.text);
      final amount = quantity * rate;
      
      if (_isEditMode) {
        final updatedEntry = widget.entry!.copyWith(
          date: _selectedDate,
          shift: _selectedShift,
          sellerId: _selectedSellerId!,
          quantity: quantity,
          fat: fat,
          rate: rate,
          amount: amount,
        );
        
        entryProvider.updateEntry(updatedEntry);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry updated successfully')),
        );
      } else {
        final newEntry = DailyEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          date: _selectedDate,
          shift: _selectedShift,
          sellerId: _selectedSellerId!,
          quantity: quantity,
          fat: fat,
          rate: rate,
          amount: amount,
        );
        
        entryProvider.addEntry(newEntry);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry added successfully')),
        );
      }
      
      Navigator.pop(context);
    }
  }
} 