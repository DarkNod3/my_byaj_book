import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/milk_diary/daily_entry.dart';
import '../../models/milk_diary/milk_seller.dart';
import '../../providers/milk_diary/daily_entry_provider.dart';
import '../../providers/milk_diary/milk_seller_provider.dart';
import '../../constants/app_theme.dart';
import 'package:uuid/uuid.dart';
import 'milk_seller_dialog.dart';
import 'milk_diary_screen.dart';

class AddEntryScreen extends StatefulWidget {
  final DailyEntry? entry;
  
  const AddEntryScreen({Key? key, this.entry}) : super(key: key);

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  late DateTime _selectedDate;
  late EntryShift _selectedShift;
  String? _selectedSellerId;
  String _selectedUnit = 'Liter (L)';
  
  final _quantityController = TextEditingController();
  final _rateController = TextEditingController();
  final _remarksController = TextEditingController();
  
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
      _rateController.text = widget.entry!.rate.toString();
    } else {
      // Initialize with default values
      _selectedDate = DateTime.now();
      _selectedShift = _getDefaultShift();
      _quantityController.text = '';
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
    _rateController.dispose();
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
      } else if (_selectedUnit == 'Kilogram (Kg)') {
        if (amount.endsWith('g')) {
          // Convert g to kg
          final g = int.parse(amount.replaceAll('g', ''));
          _quantityController.text = (g / 1000).toString();
        } else {
          _quantityController.text = amount.replaceAll('kg', '');
        }
      }
    });
  }

  // Get rate for selected seller
  double _getSellerRate() {
    if (_selectedSellerId == null) return 0.0;
    
    final sellerProvider = Provider.of<MilkSellerProvider>(context, listen: false);
    final seller = sellerProvider.getSellerById(_selectedSellerId!);
    
    if (seller != null) {
      return seller.defaultRate;
    }
    
    return 0.0;
  }
  
  void _updateRateFromSeller() {
    if (_selectedSellerId != null) {
      final sellerProvider = Provider.of<MilkSellerProvider>(context, listen: false);
      final seller = sellerProvider.getSellerById(_selectedSellerId!);
      
      if (seller != null) {
        setState(() {
          _rateController.text = seller.defaultRate.toString();
        });
      }
    }
  }

  Future<void> _saveEntry() async {
    // Validate inputs
    if (_selectedSellerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a seller')),
      );
      return;
    }
    
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
    
    try {
      final quantity = double.parse(_quantityController.text);
      final rate = double.parse(_rateController.text);
      final amount = quantity * rate;
      
      final entry = DailyEntry(
        id: widget.entry?.id ?? const Uuid().v4(),
        sellerId: _selectedSellerId!,
        date: _selectedDate,
        shift: _selectedShift,
        quantity: quantity,
        rate: rate,
        amount: amount,
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

  @override
  Widget build(BuildContext context) {
    // Get the bottom padding for safe area
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      width: screenWidth,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: bottomPadding + 8,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add a drag indicator at the top
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Milk Entry',
                  style: TextStyle(
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
            const SizedBox(height: 16),
            _buildDateSelector(),
            const SizedBox(height: 16),
            _buildSellerDropdown(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Time'),
                      const SizedBox(height: 4),
                      _buildShiftSelector(),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Unit'),
                      const SizedBox(height: 4),
                      _buildUnitSelector(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _selectedUnit == 'Liter (L)' 
                  ? [
                      _buildQuantityButton('250ml'),
                      const SizedBox(width: 8),
                      _buildQuantityButton('500ml'),
                      const SizedBox(width: 8),
                      _buildQuantityButton('1L'),
                      const SizedBox(width: 8),
                      _buildQuantityButton('2L'),
                      const SizedBox(width: 8),
                      _buildQuantityButton('5L'),
                    ]
                  : [
                      _buildQuantityButton('250g'),
                      const SizedBox(width: 8),
                      _buildQuantityButton('500g'),
                      const SizedBox(width: 8),
                      _buildQuantityButton('1kg'),
                      const SizedBox(width: 8),
                      _buildQuantityButton('2kg'),
                      const SizedBox(width: 8),
                      _buildQuantityButton('5kg'),
                    ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: 'Quantity (${_selectedUnit == 'Liter (L)' ? 'L' : 'Kg'})',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _rateController,
                    decoration: const InputDecoration(
                      labelText: 'Rate (₹)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _remarksController,
              decoration: const InputDecoration(
                labelText: 'Remarks (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saveEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save Entry'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDateSelector() {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: _selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 7)),
          );
          if (picked != null && picked != _selectedDate) {
            setState(() {
              _selectedDate = picked;
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.blue),
                  const SizedBox(width: 16),
                  Text(
                    DateFormat('dd MMM yyyy').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 7)),
                  );
                  if (picked != null && picked != _selectedDate) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSellerDropdown() {
    return Consumer<MilkSellerProvider>(
      builder: (context, sellerProvider, child) {
        final sellers = sellerProvider.sellers;
        
        return Row(
          children: [
            Expanded(
              flex: 3,
              child: Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSellerId,
                      isExpanded: true,
                      hint: const Row(
                        children: [
                          Icon(Icons.person, color: Colors.black),
                          SizedBox(width: 16),
                          Text('Select Seller'),
                        ],
                      ),
                      icon: const Icon(Icons.arrow_drop_down),
                      items: sellers.map((seller) {
                        return DropdownMenuItem<String>(
                          value: seller.id,
                          child: Row(
                            children: [
                              const Icon(Icons.person),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  seller.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedSellerId = newValue;
                          _updateRateFromSeller();
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: InkWell(
                onTap: () => _showAddSellerDialog(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: const Icon(
                    Icons.person_add,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildShiftSelector() {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<EntryShift>(
            value: _selectedShift,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down),
            items: [
              DropdownMenuItem<EntryShift>(
                value: EntryShift.morning,
                child: const Row(
                  children: [
                    Icon(Icons.wb_sunny, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Morning'),
                  ],
                ),
              ),
              DropdownMenuItem<EntryShift>(
                value: EntryShift.evening,
                child: const Row(
                  children: [
                    Icon(Icons.nightlight_round, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text('Evening'),
                  ],
                ),
              ),
            ],
            onChanged: (EntryShift? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedShift = newValue;
                });
              }
            },
          ),
        ),
      ),
    );
  }
  
  Widget _buildUnitSelector() {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedUnit,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down),
            items: const [
              DropdownMenuItem<String>(
                value: 'Liter (L)',
                child: Text('Liter (L)'),
              ),
              DropdownMenuItem<String>(
                value: 'Kilogram (Kg)',
                child: Text('Kilogram (Kg)'),
              ),
            ],
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedUnit = newValue;
                  // Clear quantity when unit changes
                  _quantityController.clear();
                });
              }
            },
          ),
        ),
      ),
    );
  }
  
  Widget _buildQuantityButton(String amount) {
    return ElevatedButton(
      onPressed: () => _selectQuantity(amount),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade50,
        foregroundColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: Text(amount),
    );
  }
  
  void _showAddSellerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final rateController = TextEditingController();
    final fatRateController = TextEditingController(text: '85.0');
    final baseFatController = TextEditingController(text: '100.0');
    bool isFatBased = false;
    String unit = 'Liter (L)';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'Add Milk Seller',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.home),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Price System',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Radio<bool>(
                          value: false,
                          groupValue: isFatBased,
                          onChanged: (value) {
                            setState(() {
                              isFatBased = value!;
                            });
                          },
                        ),
                        const Text('Default Rate'),
                        const SizedBox(width: 16),
                        Radio<bool>(
                          value: true,
                          groupValue: isFatBased,
                          onChanged: (value) {
                            setState(() {
                              isFatBased = value!;
                            });
                          },
                        ),
                        const Text('Fat Based'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Default Unit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      value: unit,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Liter (L)',
                          child: Text('Liter (L)'),
                        ),
                        DropdownMenuItem(
                          value: 'Kilogram (Kg)',
                          child: Text('Kilogram (Kg)'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          unit = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (!isFatBased) 
                      TextField(
                        controller: rateController,
                        decoration: const InputDecoration(
                          labelText: 'Default Rate',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.currency_rupee),
                        ),
                        keyboardType: TextInputType.number,
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: fatRateController,
                            decoration: const InputDecoration(
                              labelText: 'Rate per Fat',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.currency_rupee),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: baseFatController,
                            decoration: const InputDecoration(
                              labelText: 'Base Fat %',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.percent),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter seller name')),
                            );
                            return;
                          }
                          
                          final sellerProvider = Provider.of<MilkSellerProvider>(context, listen: false);
                          
                          // Get the appropriate rate depending on the selected option
                          double defaultRate = 0.0;
                          if (!isFatBased) {
                            defaultRate = double.tryParse(rateController.text) ?? 0.0;
                          }
                          
                          final seller = MilkSeller(
                            id: const Uuid().v4(),
                            name: nameController.text.trim(),
                            mobile: phoneController.text.trim(),
                            address: addressController.text.trim(),
                            defaultRate: defaultRate,
                            isActive: true,
                          );
                          
                          sellerProvider.addSeller(seller).then((_) {
                            Navigator.of(context).pop();
                            
                            // Update the selected seller in the parent screen
                            this.setState(() {
                              _selectedSellerId = seller.id;
                              _updateRateFromSeller();
                            });
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Seller ${seller.name} added successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }).catchError((error) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error adding seller: $error'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Add Seller'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} 