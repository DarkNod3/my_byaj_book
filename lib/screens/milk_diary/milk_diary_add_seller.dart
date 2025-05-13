import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/milk_diary/milk_seller.dart';

class MilkDiaryAddSeller extends StatefulWidget {
  final MilkSeller? seller;

  const MilkDiaryAddSeller({Key? key, this.seller}) : super(key: key);
  
  // Static method to show bottom sheet
  static Future<MilkSeller?> showAddSellerBottomSheet(
    BuildContext context, {
    MilkSeller? seller,
  }) async {
    return await showModalBottomSheet<MilkSeller>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MilkDiaryAddSeller(seller: seller),
    );
  }

  @override
  State<MilkDiaryAddSeller> createState() => _MilkDiaryAddSellerState();
}

class _MilkDiaryAddSellerState extends State<MilkDiaryAddSeller> {
  final _formKey = GlobalKey<FormState>();
  
  // Text controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _defaultRateController = TextEditingController();
  final _fatRateController = TextEditingController();
  final _baseFatController = TextEditingController();
  final _defaultQuantityController = TextEditingController();
  
  PriceSystem _priceSystem = PriceSystem.defaultRate;
  String _defaultUnit = 'Liter (L)';
  
  @override
  void initState() {
    super.initState();
    
    // Initialize with existing seller data if available
    if (widget.seller != null) {
      _nameController.text = widget.seller!.name;
      _phoneController.text = widget.seller?.mobile ?? '';
      _addressController.text = widget.seller?.address ?? '';
      _defaultRateController.text = widget.seller!.defaultRate.toString();
      _defaultQuantityController.text = widget.seller!.defaultQuantity.toString();
      _priceSystem = widget.seller!.priceSystem;
      
      // Initialize fat-based pricing fields if available
      if (widget.seller!.fatRates != null && widget.seller!.fatRates!.isNotEmpty) {
        // Assuming the first entry is for 100 fat
        final entry = widget.seller!.fatRates!.entries.first;
        _fatRateController.text = entry.value.toString();
        _baseFatController.text = entry.key.toString();
      } else {
        _fatRateController.text = '85.0';
        _baseFatController.text = '100.0';
      }
    } else {
      // Default values for new seller
      _defaultRateController.text = '';
      _defaultQuantityController.text = '1.0';
      _fatRateController.text = '85.0';
      _baseFatController.text = '100.0';
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _defaultRateController.dispose();
    _fatRateController.dispose();
    _baseFatController.dispose();
    _defaultQuantityController.dispose();
    super.dispose();
  }

  void _saveSeller() {
    if (_formKey.currentState!.validate()) {
      // Create fat rates map if fat-based pricing is selected
      Map<double, double>? fatRates;
      if (_priceSystem == PriceSystem.fatBased) {
        fatRates = {
          double.parse(_baseFatController.text): double.parse(_fatRateController.text)
        };
      }
      
      // Get default quantity
      double defaultQuantity = 1.0;
      try {
        defaultQuantity = double.parse(_defaultQuantityController.text);
      } catch (e) {
        // Use default if parsing fails
      }
      
      // Create seller object
      final seller = MilkSeller(
        id: widget.seller?.id ?? const Uuid().v4(),
        name: _nameController.text,
        mobile: _phoneController.text.isEmpty ? null : _phoneController.text,
        address: _addressController.text.isEmpty ? null : _addressController.text,
        defaultRate: _priceSystem == PriceSystem.defaultRate 
            ? double.parse(_defaultRateController.text)
            : 0.0,
        defaultQuantity: defaultQuantity,
        isActive: true,
        priceSystem: _priceSystem,
        fatRates: fatRates,
      );
      
      Navigator.of(context).pop(seller);
    }
  }

  // Text style for field labels
  final _labelStyle = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );
  
  // Text style for hints and helper text
  final _hintStyle = TextStyle(
    fontSize: 12,
    color: Colors.grey.shade600,
  );

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      // Use Flexible content height to prevent overflow
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        maxWidth: screenWidth,
      ),
      width: screenWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with drag handle
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              widget.seller == null ? 'Add New Seller' : 'Edit Seller',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name field
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Name',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter seller name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10.0),
                      
                      // Phone field
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      
                      // Address field
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          hintText: 'Address (Optional)',
                          prefixIcon: Icon(Icons.home),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                        ),
                      ),
                      const SizedBox(height: 14.0),
                      
                      // Price System label
                      Text(
                        'Price System',
                        style: _labelStyle,
                      ),
                      const SizedBox(height: 8.0),
                      
                      // Price System Radio Buttons
                      Row(
                        children: [
                          // Default Rate radio
                          Radio<PriceSystem>(
                            value: PriceSystem.defaultRate,
                            groupValue: _priceSystem,
                            onChanged: (value) {
                              setState(() {
                                _priceSystem = value!;
                              });
                            },
                            activeColor: Colors.blue,
                            visualDensity: VisualDensity.compact,
                          ),
                          const Text('Default Rate'),
                          
                          const SizedBox(width: 20),
                          
                          // Fat Based radio
                          Radio<PriceSystem>(
                            value: PriceSystem.fatBased,
                            groupValue: _priceSystem,
                            onChanged: (value) {
                              setState(() {
                                _priceSystem = value!;
                              });
                            },
                            activeColor: Colors.blue,
                            visualDensity: VisualDensity.compact,
                          ),
                          const Text('Fat Based'),
                        ],
                      ),
                      const SizedBox(height: 10.0),
                      
                      // Default Rate fields - only show if default rate system selected
                      if (_priceSystem == PriceSystem.defaultRate)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Default Rate field with Unit
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Rate input
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: _defaultRateController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      hintText: 'Price per unit',
                                      prefixIcon: Icon(Icons.currency_rupee),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(12)),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                                    ),
                                    validator: (value) {
                                      if (_priceSystem == PriceSystem.defaultRate) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter rate';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'Please enter a valid number';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                
                                // Unit selector
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _defaultUnit,
                                        isExpanded: true,
                                        icon: const Icon(Icons.arrow_drop_down),
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                        items: ['Liter (L)', 'Kilogram (kg)'].map((unit) {
                                          return DropdownMenuItem<String>(
                                            value: unit,
                                            child: Text(
                                              unit,
                                              style: const TextStyle(fontSize: 14),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _defaultUnit = value!;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            // Helper text
                            const SizedBox(height: 8.0),
                            Text(
                              'This rate will be used for all entries for this seller.',
                              style: _hintStyle,
                            ),
                            
                            // Default Quantity field
                            const SizedBox(height: 16.0),
                            Text(
                              'Default Quantity',
                              style: _labelStyle,
                            ),
                            const SizedBox(height: 8.0),
                            TextFormField(
                              controller: _defaultQuantityController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: 'Default milk quantity',
                                prefixIcon: const Icon(Icons.water_drop_outlined),
                                suffixText: _defaultUnit == 'Liter (L)' ? 'L' : 'kg',
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(12)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter default quantity';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'This quantity will be pre-filled when adding new entries for this seller.',
                              style: _hintStyle,
                            ),
                          ],
                        ),
                      
                      // Fat Based Rate fields - only show if fat based system selected
                      if (_priceSystem == PriceSystem.fatBased)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Label
                            Text(
                              'Fat Based Price',
                              style: _labelStyle,
                            ),
                            const SizedBox(height: 8.0),
                            
                            // Fat rate inputs in row
                            Row(
                              children: [
                                // Base fat percentage
                                Expanded(
                                  child: TextFormField(
                                    controller: _baseFatController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      hintText: 'Fat %',
                                      suffixText: '%',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(12)),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                                    ),
                                    validator: (value) {
                                      if (_priceSystem == PriceSystem.fatBased) {
                                        if (value == null || value.isEmpty) {
                                          return 'Enter fat %';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'Invalid number';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10.0),
                                
                                // Rate for this fat
                                Expanded(
                                  child: TextFormField(
                                    controller: _fatRateController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      hintText: 'Rate (₹)',
                                      prefixIcon: Icon(Icons.currency_rupee),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(12)),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                                    ),
                                    validator: (value) {
                                      if (_priceSystem == PriceSystem.fatBased) {
                                        if (value == null || value.isEmpty) {
                                          return 'Enter rate';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'Invalid number';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 8.0),
                            
                            // Helper text
                            Text(
                              'Rate will be calculated based on fat percentage for each entry.',
                              style: _hintStyle,
                            ),
                          ],
                        ),

                      const SizedBox(height: 24.0),
                      
                      // Save and Cancel buttons
                      Row(
                        children: [
                          // Cancel button
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          
                          // Save button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saveSeller,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                              child: Text(widget.seller == null ? 'Add Seller' : 'Save Changes'),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 