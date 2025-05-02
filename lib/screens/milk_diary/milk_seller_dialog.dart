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
  late double _defaultRate;

  @override
  void initState() {
    super.initState();
    _name = widget.seller?.name ?? '';
    _phone = widget.seller?.mobile ?? '';
    _address = widget.seller?.address ?? '';
    _defaultRate = widget.seller?.defaultRate ?? 0.0;
  }

  void _saveSeller() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final provider = Provider.of<MilkSellerProvider>(context, listen: false);
      
      if (widget.seller == null) {
        // Create new seller
        final newSeller = MilkSeller(
          id: const Uuid().v4(),
          name: _name,
          mobile: _phone,
          address: _address.isEmpty ? null : _address,
          defaultRate: _defaultRate,
        );
        
        provider.addSeller(newSeller);
      } else {
        // Update existing seller
        final updatedSeller = widget.seller!.copyWith(
          name: _name,
          mobile: _phone,
          address: _address.isEmpty ? null : _address,
          defaultRate: _defaultRate,
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
              
              // Mobile field
              TextFormField(
                initialValue: _phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
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
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('CANCEL'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saveSeller,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: Text(widget.seller == null ? 'ADD' : 'SAVE'),
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