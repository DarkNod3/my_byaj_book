import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/milk_diary/milk_seller.dart';
import '../../providers/milk_diary/milk_seller_provider.dart';
import '../../constants/app_theme.dart';

class MilkSellerDialog extends StatefulWidget {
  final MilkSeller? seller;

  const MilkSellerDialog({Key? key, this.seller}) : super(key: key);

  @override
  _MilkSellerDialogState createState() => _MilkSellerDialogState();
}

class _MilkSellerDialogState extends State<MilkSellerDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _phone;
  late String _address;
  late PriceSystem _priceSystem;
  late double _defaultRate;
  late double? _baseFat;
  late double? _fatRate;

  @override
  void initState() {
    super.initState();
    _name = widget.seller?.name ?? '';
    _phone = widget.seller?.phone ?? '';
    _address = widget.seller?.address ?? '';
    _priceSystem = widget.seller?.priceSystem ?? PriceSystem.defaultRate;
    _defaultRate = widget.seller?.defaultRate ?? 0.0;
    _baseFat = widget.seller?.baseFat;
    _fatRate = widget.seller?.fatRate;
  }

  void _saveSeller() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final provider = Provider.of<MilkSellerProvider>(context, listen: false);
      
      if (widget.seller == null) {
        // Create new seller
        final newSeller = MilkSeller(
          name: _name,
          phone: _phone,
          address: _address,
          priceSystem: _priceSystem,
          defaultRate: _defaultRate,
          baseFat: _baseFat,
          fatRate: _fatRate,
        );
        
        provider.addSeller(newSeller);
      } else {
        // Update existing seller
        final updatedSeller = widget.seller!.copyWith(
          name: _name,
          phone: _phone,
          address: _address,
          priceSystem: _priceSystem,
          defaultRate: _defaultRate,
          baseFat: _baseFat,
          fatRate: _fatRate,
        );
        
        provider.updateSeller(updatedSeller);
      }

      Navigator.of(context).pop();
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
                  widget.seller == null ? 'Add New Milk Seller' : 'Edit Milk Seller',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Name field
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter seller name';
                  }
                  return null;
                },
                onSaved: (value) {
                  _name = value!;
                },
              ),
              const SizedBox(height: 16),
              
              // Phone field
              TextFormField(
                initialValue: _phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                onSaved: (value) {
                  _phone = value ?? '';
                },
              ),
              const SizedBox(height: 16),
              
              // Address field
              TextFormField(
                initialValue: _address,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) {
                  _address = value ?? '';
                },
              ),
              const SizedBox(height: 16),
              
              // Price System dropdown
              DropdownButtonFormField<PriceSystem>(
                value: _priceSystem,
                decoration: const InputDecoration(
                  labelText: 'Price System',
                  border: OutlineInputBorder(),
                ),
                items: PriceSystem.values.map((system) {
                  return DropdownMenuItem<PriceSystem>(
                    value: system,
                    child: Text(system == PriceSystem.defaultRate ? 'Default Rate' : 'Fat-Based Rate'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _priceSystem = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Default Rate field
              TextFormField(
                initialValue: _defaultRate.toString(),
                decoration: const InputDecoration(
                  labelText: 'Default Rate (₹)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter default rate';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                onSaved: (value) {
                  _defaultRate = double.parse(value!);
                },
              ),
              const SizedBox(height: 16),
              
              // Fat-based pricing fields
              if (_priceSystem == PriceSystem.fatBased) ...[
                TextFormField(
                  initialValue: _baseFat?.toString() ?? '3.5',
                  decoration: const InputDecoration(
                    labelText: 'Base Fat %',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter base fat percentage';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _baseFat = double.parse(value!);
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  initialValue: _fatRate?.toString() ?? '10.0',
                  decoration: const InputDecoration(
                    labelText: 'Rate per Fat % (₹)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter rate per fat percentage';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _fatRate = double.parse(value!);
                  },
                ),
                const SizedBox(height: 16),
              ],
              
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
                    onPressed: _saveSeller,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: Text(widget.seller == null ? 'Add' : 'Update'),
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