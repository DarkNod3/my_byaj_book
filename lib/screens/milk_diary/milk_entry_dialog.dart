import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/milk_diary/milk_entry.dart';
import '../../models/milk_diary/milk_seller.dart';
import '../../providers/milk_diary/milk_entry_provider.dart';
import '../../providers/milk_diary/milk_seller_provider.dart';
import '../../constants/app_theme.dart';

class MilkEntryDialog extends StatefulWidget {
  final MilkEntry? entry;
  final String? sellerId;
  final DateTime? initialDate;
  final EntryShift? initialShift;

  const MilkEntryDialog({
    Key? key,
    this.entry,
    this.sellerId,
    this.initialDate,
    this.initialShift,
  }) : super(key: key);

  @override
  _MilkEntryDialogState createState() => _MilkEntryDialogState();
}

class _MilkEntryDialogState extends State<MilkEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _sellerId;
  late DateTime _date;
  late EntryShift _shift;
  late double _quantity;
  late double _fat;
  late double _rate;
  late double _amount;
  
  final _quantityController = TextEditingController();
  final _fatController = TextEditingController();
  final _rateController = TextEditingController();
  final _amountController = TextEditingController();
  
  List<MilkSeller> _sellers = [];
  MilkSeller? _selectedSeller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.entry != null;
    
    // Default values
    _sellerId = widget.entry?.sellerId ?? widget.sellerId;
    _date = widget.entry?.date ?? widget.initialDate ?? DateTime.now();
    _shift = widget.entry?.shift ?? widget.initialShift ?? EntryShift.morning;
    _quantity = widget.entry?.quantity ?? 0.0;
    _fat = widget.entry?.fat ?? 0.0;
    _rate = widget.entry?.rate ?? 0.0;
    _amount = widget.entry?.amount ?? 0.0;
    
    _quantityController.text = _quantity > 0 ? _quantity.toString() : '';
    _fatController.text = _fat > 0 ? _fat.toString() : '';
    _rateController.text = _rate > 0 ? _rate.toString() : '';
    _amountController.text = _amount > 0 ? _amount.toString() : '';
    
    // Add listeners to update amount
    _quantityController.addListener(_calculateAmount);
    _rateController.addListener(_calculateAmount);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSellers();
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _fatController.dispose();
    _rateController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _loadSellers() {
    final sellerProvider = Provider.of<MilkSellerProvider>(context, listen: false);
    setState(() {
      _sellers = sellerProvider.sellers.where((seller) => seller.isActive).toList();
      
      if (_sellerId != null) {
        _selectedSeller = _sellers.firstWhere(
          (seller) => seller.id == _sellerId,
          orElse: () => _sellers.isNotEmpty ? _sellers.first : MilkSeller(
            name: 'Unknown',
            defaultRate: 0.0,
            priceSystem: PriceSystem.defaultRate,
          ),
        );
        
        _sellerId = _selectedSeller!.id;
        _updateRateFromSeller();
      } else if (_sellers.isNotEmpty) {
        _selectedSeller = _sellers.first;
        _sellerId = _selectedSeller!.id;
        _updateRateFromSeller();
      }
    });
  }

  void _updateRateFromSeller() {
    if (_selectedSeller != null && !_isEditing) {
      if (_selectedSeller!.priceSystem == PriceSystem.defaultRate) {
        setState(() {
          _rate = _selectedSeller!.defaultRate;
          _rateController.text = _rate.toString();
        });
      } else if (_selectedSeller!.priceSystem == PriceSystem.fatBased && _fat > 0) {
        _updateRateBasedOnFat();
      }
    }
  }

  void _updateRateBasedOnFat() {
    if (_selectedSeller?.priceSystem == PriceSystem.fatBased && 
        _selectedSeller?.baseFat != null && 
        _selectedSeller?.fatRate != null) {
      double newRate = _selectedSeller!.calculateRate(_fat);
      setState(() {
        _rate = newRate;
        _rateController.text = _rate.toString();
      });
      _calculateAmount();
    }
  }

  void _calculateAmount() {
    if (_quantityController.text.isNotEmpty && _rateController.text.isNotEmpty) {
      try {
        double quantity = double.parse(_quantityController.text);
        double rate = double.parse(_rateController.text);
        double amount = quantity * rate;
        
        setState(() {
          _amount = amount;
          _amountController.text = amount.toStringAsFixed(2);
        });
      } catch (e) {
        // Handle parsing error
      }
    }
  }

  void _saveEntry() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final entryProvider = Provider.of<MilkEntryProvider>(context, listen: false);
      
      if (_isEditing) {
        // Update existing entry
        final updatedEntry = widget.entry!.copyWith(
          sellerId: _sellerId!,
          date: _date,
          shift: _shift,
          quantity: _quantity,
          fat: _fat,
          rate: _rate,
          amount: _amount,
        );
        
        entryProvider.updateEntry(updatedEntry);
      } else {
        // Create new entry
        final newEntry = MilkEntry(
          sellerId: _sellerId!,
          date: _date,
          shift: _shift,
          quantity: _quantity,
          fat: _fat,
          rate: _rate,
          amount: _amount,
        );
        
        entryProvider.addEntry(newEntry);
      }
      
      Navigator.of(context).pop();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  _isEditing ? 'Edit Milk Entry' : 'Add Milk Entry',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Seller dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Seller',
                  border: OutlineInputBorder(),
                ),
                value: _sellerId,
                items: _sellers.map((seller) {
                  return DropdownMenuItem<String>(
                    value: seller.id,
                    child: Text(seller.name),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a seller';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _sellerId = value;
                    _selectedSeller = _sellers.firstWhere((seller) => seller.id == value);
                    _updateRateFromSeller();
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Date and Shift
              Row(
                children: [
                  // Date Picker
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          DateFormat('dd-MM-yyyy').format(_date),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Shift Selection
                  Expanded(
                    child: DropdownButtonFormField<EntryShift>(
                      decoration: const InputDecoration(
                        labelText: 'Shift',
                        border: OutlineInputBorder(),
                      ),
                      value: _shift,
                      items: EntryShift.values.map((shift) {
                        return DropdownMenuItem<EntryShift>(
                          value: shift,
                          child: Text(shift == EntryShift.morning ? 'Morning' : 'Evening'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _shift = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Quantity and Fat
              Row(
                children: [
                  // Quantity field
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity (L)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _quantity = double.parse(value!);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Fat field
                  Expanded(
                    child: TextFormField(
                      controller: _fatController,
                      decoration: const InputDecoration(
                        labelText: 'Fat %',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (_selectedSeller?.priceSystem == PriceSystem.fatBased) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _fat = value != null && value.isNotEmpty ? double.parse(value) : 0.0;
                      },
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          try {
                            _fat = double.parse(value);
                            if (_selectedSeller?.priceSystem == PriceSystem.fatBased) {
                              _updateRateBasedOnFat();
                            }
                          } catch (e) {
                            // Handle parsing error
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Rate and Amount
              Row(
                children: [
                  // Rate field
                  Expanded(
                    child: TextFormField(
                      controller: _rateController,
                      decoration: const InputDecoration(
                        labelText: 'Rate (₹)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _rate = double.parse(value!);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Amount field (calculated)
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount (₹)',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onSaved: (value) {
                        _amount = double.parse(value!);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _saveEntry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: Text(_isEditing ? 'Update' : 'Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 