import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/milk_diary/daily_entry.dart';
import '../../models/milk_diary/milk_seller.dart';
import '../../providers/milk_diary/daily_entry_provider.dart';
import '../../providers/milk_diary/milk_seller_provider.dart';
import 'package:uuid/uuid.dart';

class MilkDiaryAddEntry extends StatefulWidget {
  final DailyEntry? entry;
  final String sellerId;
  final DateTime? initialDate;
  
  const MilkDiaryAddEntry({
    Key? key, 
    this.entry, 
    required this.sellerId, 
    this.initialDate
  }) : super(key: key);

  // Static method to show bottom sheet
  static Future<void> showAddEntryBottomSheet(
    BuildContext context, {
    DailyEntry? entry,
    required String sellerId,
    DateTime? initialDate,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MilkDiaryAddEntry(
        entry: entry,
        sellerId: sellerId,
        initialDate: initialDate,
      ),
    );
  }

  @override
  State<MilkDiaryAddEntry> createState() => _MilkDiaryAddEntryState();
}

class _MilkDiaryAddEntryState extends State<MilkDiaryAddEntry> {
  late DateTime _selectedDate;
  late EntryShift _selectedShift;
  String _selectedUnit = 'Liter (L)';
  MilkType _selectedMilkType = MilkType.cow;
  
  final _quantityController = TextEditingController();
  final _rateController = TextEditingController();
  final _fatController = TextEditingController();
  final _snfController = TextEditingController();
  final _remarksController = TextEditingController();
  
  bool _isEditMode = false;
  bool _isFatBased = false;
  String? _errorMessage;
  
  // Lists for preset quantities based on unit
  final List<String> _literPresets = ['250ml', '500ml', '1L', '2L', '5L'];
  final List<String> _kgPresets = ['250g', '500g', '1kg', '2kg', '5kg'];
  
  @override
  void initState() {
    super.initState();
    
    _isEditMode = widget.entry != null;
    
    if (_isEditMode) {
      // Initialize with existing entry data
      _selectedDate = widget.entry!.date;
      _selectedShift = widget.entry!.shift;
      _quantityController.text = widget.entry!.quantity.toString();
      _rateController.text = widget.entry!.rate.toString();
      _selectedMilkType = widget.entry!.milkType;
      
      // Set the unit based on the existing entry
      if (widget.entry!.unit == 'kg') {
        _selectedUnit = 'Kilogram (kg)';
      } else {
        _selectedUnit = 'Liter (L)';
      }
      
      if (widget.entry!.fat != null) {
        _fatController.text = widget.entry!.fat.toString();
      }
      if (widget.entry!.snf != null) {
        _snfController.text = widget.entry!.snf.toString();
      }
      if (widget.entry!.remarks != null) {
        _remarksController.text = widget.entry!.remarks!;
      }
    } else {
      // Initialize with default values or provided initial values
      _selectedDate = widget.initialDate ?? DateTime.now();
      _selectedShift = _getDefaultShift();
      _quantityController.text = '';
      
      // Always set the rate from seller's default rate for new entries
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateRateFromSeller();
        // Check for duplicate entries when form loads
        _checkDuplicateEntry();
      });
    }
    
    // Check if seller uses fat-based pricing
    _updateSellerPriceSystem();
  }
  
  EntryShift _getDefaultShift() {
    final currentHour = DateTime.now().hour;
    // Morning: before 12pm, Evening: after 12pm
    return currentHour < 12 ? EntryShift.morning : EntryShift.evening;
  }
  
  void _updateSellerPriceSystem() {
    final sellerProvider = Provider.of<MilkSellerProvider>(context, listen: false);
    final seller = sellerProvider.getSellerById(widget.sellerId);
    
    if (seller != null) {
      setState(() {
        _isFatBased = seller.priceSystem == PriceSystem.fatBased;
      });
    }
  }
  
  @override
  void dispose() {
    _quantityController.dispose();
    _rateController.dispose();
    _fatController.dispose();
    _snfController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _selectQuantity(String amount) {
    setState(() {
      if (_selectedUnit == 'Liter (L)') {
        if (amount.endsWith('ml')) {
          // Convert ml to L
          final ml = int.parse(amount.replaceAll('ml', ''));
          _quantityController.text = (ml / 1000).toStringAsFixed(3);
        } else {
          _quantityController.text = amount.replaceAll('L', '');
        }
      } else if (_selectedUnit == 'Kilogram (kg)') {
        if (amount.endsWith('g')) {
          // Convert g to kg
          final g = int.parse(amount.replaceAll('g', ''));
          _quantityController.text = (g / 1000).toStringAsFixed(3);
        } else {
          _quantityController.text = amount.replaceAll('kg', '');
        }
      }
    });
  }

  // Convert quantity between units if needed
  void _convertQuantity(String fromUnit, String toUnit) {
    if (_quantityController.text.isEmpty) return;
    
    try {
      final quantity = double.parse(_quantityController.text);
      // In most milk applications, 1L ≈ 1.03kg, but for simplicity we can use 1:1
      // If a more accurate conversion is needed, we could implement it here
      
      // For now, we'll keep the same numeric value and just update the unit
      _quantityController.text = quantity.toStringAsFixed(3);
    } catch (e) {
      // Invalid number, ignore
    }
  }

  // Get current quantity presets based on selected unit
  List<String> get _currentPresets => _selectedUnit == 'Liter (L)' ? _literPresets : _kgPresets;

  // Get rate for selected seller
  // Unused method - commented out per analyzer warning
  /*
  double _getSellerRate() {
    final sellerProvider = Provider.of<MilkSellerProvider>(context, listen: false);
    final seller = sellerProvider.getSellerById(widget.sellerId);
    
    if (seller != null) {
      return seller.defaultRate;
    }
    
    return 0.0;
  }
  */
  
  void _updateRateFromSeller() {
    final sellerProvider = Provider.of<MilkSellerProvider>(context, listen: false);
    final seller = sellerProvider.getSellerById(widget.sellerId);
    
    if (seller != null) {
      setState(() {
        _rateController.text = seller.defaultRate.toString();
      });
    }
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Check for duplicate entries when date changes
        _checkDuplicateEntry();
      });
    }
  }
  
  // Method to check if an entry already exists for this date, shift and seller
  void _checkDuplicateEntry() {
    // Skip check if in edit mode (updating existing entry)
    if (_isEditMode) return;
    
    final entryProvider = Provider.of<DailyEntryProvider>(context, listen: false);
    final entries = entryProvider.entries;
    
    // Check if an entry with same date, shift and seller already exists
    final duplicateEntry = entries.any((e) => 
      e.sellerId == widget.sellerId &&
      e.date.year == _selectedDate.year &&
      e.date.month == _selectedDate.month &&
      e.date.day == _selectedDate.day &&
      e.shift == _selectedShift
    );
    
    setState(() {
      _errorMessage = duplicateEntry 
        ? 'An entry already exists for ${_selectedShift == EntryShift.morning ? "Morning" : "Evening"} on ${DateFormat('dd MMM yyyy').format(_selectedDate)}' 
        : null;
    });
  }

  Future<void> _saveEntry() async {
    // Validate inputs
    if (_quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter quantity')),
      );
      return;
    }
    
    if (_rateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter rate')),
      );
      return;
    }
    
    if (_isFatBased && _fatController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter fat percentage')),
      );
      return;
    }
    
    // Check for duplicate entries again before saving
    _checkDuplicateEntry();
    if (_errorMessage != null && !_isEditMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      final quantity = double.parse(_quantityController.text);
      final rate = double.parse(_rateController.text);
      final amount = quantity * rate;
      
      // Parse fat and SNF if available
      double? fat;
      double? snf;
      if (_fatController.text.isNotEmpty) {
        fat = double.parse(_fatController.text);
      }
      if (_snfController.text.isNotEmpty) {
        snf = double.parse(_snfController.text);
      }
      
      // Get unit type for storage
      final unitType = _selectedUnit == 'Kilogram (kg)' ? 'kg' : 'L';
      
      final entry = DailyEntry(
        id: widget.entry?.id ?? const Uuid().v4(),
        sellerId: widget.sellerId,
        date: _selectedDate,
        shift: _selectedShift,
        quantity: quantity,
        fat: fat,
        snf: snf,
        rate: rate,
        amount: amount,
        remarks: _remarksController.text.isNotEmpty ? _remarksController.text : null,
        milkType: _selectedMilkType,
        unit: unitType, // Store the unit type
      );
      
      final entryProvider = Provider.of<DailyEntryProvider>(context, listen: false);
      
      if (_isEditMode) {
        await entryProvider.updateEntry(entry);
      } else {
        await entryProvider.addEntry(entry);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Entry ${_isEditMode ? 'updated' : 'added'} successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sellerProvider = Provider.of<MilkSellerProvider>(context, listen: false);
    final seller = sellerProvider.getSellerById(widget.sellerId);
    
    if (seller == null) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Error: Seller not found'),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16.0,
        right: 16.0,
        top: 16.0,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with drag handle
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditMode ? 'Edit Entry' : 'Add New Entry',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            
            // Seller info
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue[700],
                    child: Text(seller.name[0].toUpperCase()),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        seller.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Default Rate: ₹${seller.defaultRate}/L',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Date and Shift selector
            Row(
              children: [
                // Date picker
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('dd MMM yyyy').format(_selectedDate),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Shift selector
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<EntryShift>(
                        value: _selectedShift,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down),
                        onChanged: (EntryShift? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedShift = newValue;
                              // Check for duplicate entries when shift changes
                              _checkDuplicateEntry();
                            });
                          }
                        },
                        items: EntryShift.values.map<DropdownMenuItem<EntryShift>>((EntryShift shift) {
                          return DropdownMenuItem<EntryShift>(
                            value: shift,
                            child: Text(
                              shift == EntryShift.morning ? 'Morning' : 'Evening',
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Error message if duplicate entry
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Quantity and Unit
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quantity input
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Unit selector
                Expanded(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedUnit,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down),
                        onChanged: (String? newValue) {
                          if (newValue != null && newValue != _selectedUnit) {
                            // Store the old unit to handle conversion
                            final oldUnit = _selectedUnit;
                            
                            setState(() {
                              _selectedUnit = newValue;
                              // Convert existing quantity if needed
                              _convertQuantity(oldUnit, newValue);
                            });
                          }
                        },
                        items: ['Liter (L)', 'Kilogram (kg)'].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Quick quantity selectors
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _currentPresets.map((amount) => ElevatedButton(
                onPressed: () => _selectQuantity(amount),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[50],
                  foregroundColor: Colors.blue[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                ),
                child: Text(amount),
              )).toList(),
            ),
            const SizedBox(height: 16),
            
            // Rate input
            TextField(
              controller: _rateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Rate (₹ per ${_selectedUnit == 'Liter (L)' ? 'L' : 'kg'})',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                prefixIcon: const Icon(Icons.currency_rupee),
              ),
            ),
            const SizedBox(height: 16),
            
            // Fat and SNF section
            if (_isFatBased || _fatController.text.isNotEmpty || _snfController.text.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quality Parameters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Fat and SNF inputs in a row
                  Row(
                    children: [
                      // Fat input
                      Expanded(
                        child: TextField(
                          controller: _fatController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Fat %',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            suffixText: '%',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // SNF input
                      Expanded(
                        child: TextField(
                          controller: _snfController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'SNF %',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            suffixText: '%',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            
            // Remarks
            TextField(
              controller: _remarksController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Remarks (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),
            
            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(_isEditMode ? 'Update Entry' : 'Add Entry'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
} 