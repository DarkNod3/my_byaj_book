import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/milk_diary/daily_entry.dart';
import '../../models/milk_diary/milk_seller.dart';
import '../../providers/milk_diary/daily_entry_provider.dart';
import '../../providers/milk_diary/milk_seller_provider.dart';
import '../../constants/app_theme.dart';
import 'package:uuid/uuid.dart';

class AddEntryBottomSheet extends StatefulWidget {
  final DailyEntry? entry;
  final String sellerId;
  final DateTime? initialDate;
  
  const AddEntryBottomSheet({
    Key? key, 
    this.entry, 
    required this.sellerId, 
    this.initialDate
  }) : super(key: key);

  // Show bottom sheet method
  static Future<void> show(
    BuildContext context, {
    DailyEntry? entry,
    required String sellerId,
    DateTime? initialDate,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEntryBottomSheet(
        entry: entry,
        sellerId: sellerId,
        initialDate: initialDate,
      ),
    );
  }

  @override
  State<AddEntryBottomSheet> createState() => _AddEntryBottomSheetState();
}

class _AddEntryBottomSheetState extends State<AddEntryBottomSheet> {
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
      _rateController.text = '';
      _fatController.text = '';
      _snfController.text = '';
    }
    
    // Check if seller uses fat-based pricing
    _updateSellerPriceSystem();
    _updateRateFromSeller();
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
          _quantityController.text = (ml / 1000).toString();
        } else {
          _quantityController.text = amount.replaceAll('L', '');
        }
      } else if (_selectedUnit == 'Kilogram (kg)') {
        if (amount.endsWith('g')) {
          // Convert g to kg
          final g = int.parse(amount.replaceAll('g', ''));
          _quantityController.text = (g / 1000).toString();
        } else {
          _quantityController.text = amount.replaceAll('kg', '').replaceAll('L', '');
        }
      }
    });
  }

  // Get rate for selected seller
  double _getSellerRate() {
    final sellerProvider = Provider.of<MilkSellerProvider>(context, listen: false);
    final seller = sellerProvider.getSellerById(widget.sellerId);
    
    if (seller != null) {
      return seller.defaultRate;
    }
    
    return 0.0;
  }
  
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
      });
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Calculate rate based on fat percentage
  void _calculateRateFromFat() {
    if (_isFatBased && _fatController.text.isNotEmpty) {
      try {
        final sellerProvider = Provider.of<MilkSellerProvider>(context, listen: false);
        final seller = sellerProvider.getSellerById(widget.sellerId);
        
        if (seller != null && seller.fatRates != null) {
          final fat = double.parse(_fatController.text);
          
          // Find the closest fat rate
          double? closestRate;
          double? closestFat;
          
          for (final entry in seller.fatRates!.entries) {
            if (closestFat == null || (fat - entry.key).abs() < (fat - closestFat).abs()) {
              closestFat = entry.key;
              closestRate = entry.value;
            }
          }
          
          if (closestRate != null) {
            setState(() {
              _rateController.text = closestRate.toString();
            });
          }
        }
      } catch (e) {
        // Ignore parsing errors
      }
    }
  }

  // Add this function to update quantity hint based on unit
  void _updateQuantityHint() {
    // If needed, create separate quick quantity buttons for kg
    if (_selectedUnit == 'Kilogram (kg)') {
      // Convert any existing quantity to kg if needed
      if (_quantityController.text.isNotEmpty) {
        try {
          final quantity = double.parse(_quantityController.text);
          // No conversion needed as both are base units, just update the display
        } catch (e) {
          // Handle parsing error
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get seller name for display
    final sellerProvider = Provider.of<MilkSellerProvider>(context, listen: false);
    final seller = sellerProvider.getSellerById(widget.sellerId);
    final sellerName = seller?.name ?? 'Seller';
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with drag handle
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            width: double.infinity,
            alignment: Alignment.center,
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          
          // Title and close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Entry for $sellerName',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          
          // Divider
          const Divider(),
          
          // Main content - scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date picker with edit button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('dd MMM yyyy').format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _selectDate(context),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit'),
                          style: TextButton.styleFrom(foregroundColor: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Time and Unit in a row
                  Row(
                    children: [
                      // Time dropdown (Morning/Evening)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Time', style: TextStyle(fontSize: 14)),
                            const SizedBox(height: 4),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<EntryShift>(
                                  value: _selectedShift,
                                  isExpanded: true,
                                  icon: const Icon(Icons.arrow_drop_down),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  items: [
                                    DropdownMenuItem(
                                      value: EntryShift.morning,
                                      child: Row(
                                        children: [
                                          const Icon(Icons.wb_sunny, color: Colors.orange, size: 18),
                                          const SizedBox(width: 8),
                                          const Text('Morning'),
                                        ],
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: EntryShift.evening,
                                      child: Row(
                                        children: [
                                          const Icon(Icons.nightlight, size: 18),
                                          const SizedBox(width: 8),
                                          const Text('Evening'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedShift = value;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Unit dropdown
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Unit', style: TextStyle(fontSize: 14)),
                            const SizedBox(height: 4),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedUnit,
                                  isExpanded: true,
                                  icon: const Icon(Icons.arrow_drop_down),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Liter (L)',
                                      child: Text('Liter (L)'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Kilogram (kg)',
                                      child: Text('Kilogram (kg)'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedUnit = value;
                                        // Update quick buttons when unit changes
                                        _updateQuantityHint();
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Quick quantity buttons
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickQuantityButton('250ml'),
                        const SizedBox(width: 8),
                        _buildQuickQuantityButton('500ml'),
                        const SizedBox(width: 8),
                        _buildQuickQuantityButton('1L'),
                        const SizedBox(width: 8),
                        _buildQuickQuantityButton('2L'),
                        const SizedBox(width: 8),
                        _buildQuickQuantityButton('5L'),
                        const SizedBox(width: 8),
                        _buildQuickQuantityButton('10L'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Quantity and Rate in a row
                  Row(
                    children: [
                      // Quantity input
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _quantityController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: 'Quantity (L)',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Rate input
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _rateController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: 'Rate (₹)',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                              prefixText: _rateController.text.isNotEmpty ? '₹ ' : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Remarks field
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _remarksController,
                      decoration: InputDecoration(
                        hintText: 'Remarks (Optional)',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: const Icon(Icons.description, size: 20),
                      ),
                      maxLines: 3,
                      minLines: 1,
                    ),
                  ),
                  
                  // Reduce the space between remarks and end of form
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          
          // Save button at bottom (outside scrollable area)
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              left: 16, 
              right: 16, 
              bottom: 16 + MediaQuery.of(context).viewInsets.bottom
            ),
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _saveEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Entry',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickQuantityButton(String amount) {
    // Display appropriate unit based on selected unit
    String displayAmount = amount;
    if (_selectedUnit == 'Kilogram (kg)' && amount.endsWith('L')) {
      displayAmount = amount.replaceAll('L', 'kg');
    } else if (_selectedUnit == 'Kilogram (kg)' && amount.endsWith('ml')) {
      displayAmount = amount.replaceAll('ml', 'g');
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _selectQuantity(amount),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            displayAmount,
            style: TextStyle(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
} 