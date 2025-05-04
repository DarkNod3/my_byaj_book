import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/milk_diary/milk_seller.dart';
import '../../providers/milk_diary/milk_seller_provider.dart';

class MilkSellerBottomSheet extends StatefulWidget {
  final MilkSeller? seller;

  const MilkSellerBottomSheet({Key? key, this.seller}) : super(key: key);

  @override
  _MilkSellerBottomSheetState createState() => _MilkSellerBottomSheetState();
}

class _MilkSellerBottomSheetState extends State<MilkSellerBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  
  // Text controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _defaultRateController = TextEditingController();
  final _fatRateController = TextEditingController();
  final _baseFatController = TextEditingController();
  
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
      
      // Create seller object
      final seller = MilkSeller(
        id: widget.seller?.id ?? const Uuid().v4(),
        name: _nameController.text,
        mobile: _phoneController.text.isEmpty ? null : _phoneController.text,
        address: _addressController.text.isEmpty ? null : _addressController.text,
        defaultRate: _priceSystem == PriceSystem.defaultRate 
            ? double.parse(_defaultRateController.text)
            : 0.0,
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
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              'Add Milk Seller',
              textAlign: TextAlign.center,
              style: TextStyle(
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
                      
                      // Combine Default Rate and Default Unit in one row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Default Unit dropdown
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Default Unit', style: _labelStyle),
                                const SizedBox(height: 4),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _defaultUnit,
                                      isExpanded: true,
                                      icon: const Icon(Icons.arrow_drop_down),
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                                        setState(() {
                                          _defaultUnit = value!;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // Conditional Default Rate field
                          if (_priceSystem == PriceSystem.defaultRate)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Default Rate', style: _labelStyle),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _defaultRateController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
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
                                          return 'Invalid number';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10.0),
                      
                      // Fat-based pricing fields in compact layout
                      if (_priceSystem == PriceSystem.fatBased)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Rate per fat and Base fat in a row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Rate per 100 Fat field
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Rate per 100 Fat', style: _labelStyle),
                                      const SizedBox(height: 4),
                                      TextFormField(
                                        controller: _fatRateController,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          prefixIcon: Icon(Icons.currency_rupee),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(12)),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                                        ),
                                        validator: (value) {
                                          if (_priceSystem == PriceSystem.fatBased) {
                                            if (value == null || value.isEmpty) {
                                              return 'Enter rate per 100 fat';
                                            }
                                            if (double.tryParse(value) == null) {
                                              return 'Invalid number';
                                            }
                                          }
                                          return null;
                                        },
                                      ),
                                      Text(
                                        'Ex: ₹${_fatRateController.text} for 100 fat',
                                        style: _hintStyle,
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(width: 12),
                                
                                // Base Fat Value field
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Base Fat Value', style: _labelStyle),
                                      const SizedBox(height: 4),
                                      TextFormField(
                                        controller: _baseFatController,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(12)),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                                        ),
                                        validator: (value) {
                                          if (_priceSystem == PriceSystem.fatBased) {
                                            if (value == null || value.isEmpty) {
                                              return 'Enter base fat value';
                                            }
                                            if (double.tryParse(value) == null) {
                                              return 'Invalid number';
                                            }
                                          }
                                          return null;
                                        },
                                      ),
                                      Text(
                                        'Usually 100',
                                        style: _hintStyle,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      
                      const SizedBox(height: 20.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Bottom buttons section (stays in place)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Add Seller button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saveSeller,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Add Seller',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                
                // Cancel button
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 