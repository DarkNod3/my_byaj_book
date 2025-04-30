import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:my_byaj_book/providers/transaction_provider.dart';
import 'package:my_byaj_book/providers/theme_provider.dart';
import 'package:my_byaj_book/widgets/dialogs/confirm_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditContactScreen extends StatefulWidget {
  final Map<String, dynamic> contact;
  final TransactionProvider? transactionProvider;

  const EditContactScreen({
    Key? key, 
    required this.contact,
    this.transactionProvider,
  }) : super(key: key);

  @override
  _EditContactScreenState createState() => _EditContactScreenState();
}

class _EditContactScreenState extends State<EditContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedCategory = 'Personal';
  bool _isWithInterest = false;
  final _interestRateController = TextEditingController();
  String _selectedType = 'borrower';
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  File? _profileImage;
  bool _isDeleteLoading = false;

  late TransactionProvider _transactionProvider;
  String get _contactId => widget.contact['phone'] ?? '';

  final List<String> _categories = [
    'Personal',
    'Business',
    'Family',
    'Friend',
    'Client',
    'Supplier',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing contact data
    _nameController.text = widget.contact['name'] ?? '';
    _phoneController.text = widget.contact['phone'] ?? '';
    _selectedCategory = widget.contact['category'] ?? 'Personal';
    
    // Check if this is a with-interest contact
    _isWithInterest = widget.contact['type'] != null;
    
    if (_isWithInterest) {
      _selectedType = widget.contact['type'] ?? 'borrower';
      _interestRateController.text = widget.contact['interestRate']?.toString() ?? '0.0';
    }

    // Initialize profile image if it exists
    if (widget.contact['profileImagePath'] != null) {
      _profileImage = File(widget.contact['profileImagePath']);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Use the provided transaction provider if available, otherwise get from context
    _transactionProvider = widget.transactionProvider ?? Provider.of<TransactionProvider>(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _interestRateController.dispose();
    super.dispose();
  }

  void _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 500,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _showProfileImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Profile Picture',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  context,
                  Icons.camera_alt,
                  'Camera',
                  () => _pickImage(ImageSource.camera),
                ),
                _buildImageSourceOption(
                  context,
                  Icons.photo_library,
                  'Gallery',
                  () => _pickImage(ImageSource.gallery),
                ),
                if (_profileImage != null)
                  _buildImageSourceOption(
                    context,
                    Icons.delete,
                    'Remove',
                    () {
                      setState(() {
                        _profileImage = null;
                      });
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: themeProvider.primaryColor.withOpacity(0.1),
            child: Icon(icon, size: 30, color: themeProvider.primaryColor),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: themeProvider.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateContact() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Prepare updated contact data
    final updatedContact = {
      ...widget.contact,
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'category': _selectedCategory,
      'profileImagePath': _profileImage?.path,
    };

    // Add interest-related fields if this is a with-interest contact
    if (_isWithInterest) {
      updatedContact['type'] = _selectedType;
      updatedContact['interestRate'] = double.tryParse(_interestRateController.text) ?? 0.0;
    } else {
      // Remove interest-related fields if this is not a with-interest contact
      updatedContact.remove('type');
      updatedContact.remove('interestRate');
    }

    // Update the contact
    final success = await _transactionProvider.updateContact(updatedContact);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact updated successfully')),
      );
      Navigator.pop(context, true); // Return true to indicate successful update
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update contact')),
      );
    }
  }

  Future<void> _deleteContact() async {
    setState(() {
      _isDeleteLoading = true;
    });

    try {
      // Make sure contact exists in the contacts list
      final contactExists = _transactionProvider.getContactById(_contactId) != null;
      
      if (!contactExists) {
        // First add the contact to ensure it exists
        await _transactionProvider.addContact(widget.contact);
      }
      
      // Delete the contact and all associated transactions
      final success = await _transactionProvider.deleteContact(_contactId);

      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.contact['name']} deleted')),
        );
        
        // Navigate all the way back to home screen
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }
    } catch (e) {
      debugPrint('Error deleting contact: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isDeleteLoading = false;
        });
      }
    }
    
    // Show error message if we reach here
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete contact')),
      );
    }
  }

  void _confirmDeleteContact() {
    showDialog(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Delete Contact',
        content: 'Are you sure you want to delete ${widget.contact['name']}? This will delete all transaction history.',
        confirmText: 'Delete',
        confirmColor: Colors.red,
        onConfirm: _deleteContact,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final balance = _transactionProvider.calculateBalance(_contactId);
    final hasTransactions = _transactionProvider.getTransactionsForContact(_contactId).isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Contact'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _updateContact,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _profileImage != null 
                            ? FileImage(_profileImage!) 
                            : null,
                        child: _profileImage == null
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey.shade400,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showProfileImageOptions,
                          child: CircleAvatar(
                            backgroundColor: themeProvider.primaryColor,
                            radius: 20,
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Contact Summary
                if (hasTransactions) 
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Balance',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currencyFormat.format(balance.abs()),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: balance >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                          Text(
                            balance >= 0 ? 'You will get' : 'You will give',
                            style: TextStyle(
                              fontSize: 12,
                              color: balance >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Name Field
                const Text(
                  'Name',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter contact name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone Field
                const Text(
                  'Phone Number',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    hintText: 'Enter phone number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                const Text(
                  'Category',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),

                // With Interest Toggle
                Row(
                  children: [
                    const Text(
                      'With Interest Account',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: _isWithInterest,
                      onChanged: hasTransactions && !_isWithInterest
                          ? null // Disable converting to interest if there are transactions and it's not already interest
                          : (value) {
                              setState(() {
                                _isWithInterest = value;
                                
                                // If switching to with-interest, set default values
                                if (value && _interestRateController.text.isEmpty) {
                                  _interestRateController.text = '12.0'; // Default interest rate
                                }
                              });
                            },
                      activeColor: themeProvider.primaryColor,
                    ),
                  ],
                ),
                if (hasTransactions && !_isWithInterest)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Cannot convert to interest account after transactions',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (_isWithInterest)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Specify if this contact is a borrower (owes you money) or lender (you owe them)',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Interest Rate and Type (Only if with interest)
                if (_isWithInterest) ...[
                  const Text(
                    'Interest Rate (%)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _interestRateController,
                    decoration: InputDecoration(
                      hintText: 'Enter interest rate',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      suffixText: '% p.a.',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (_isWithInterest) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an interest rate';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Account Type',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          elevation: _selectedType == 'borrower' ? 4 : 0,
                          color: _selectedType == 'borrower' 
                              ? Colors.red.withOpacity(0.1) 
                              : Colors.grey.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: _selectedType == 'borrower' 
                                  ? Colors.red 
                                  : Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedType = 'borrower';
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Radio<String>(
                                        value: 'borrower',
                                        groupValue: _selectedType,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedType = value!;
                                          });
                                        },
                                        activeColor: Colors.red,
                                      ),
                                      const Text(
                                        'Borrower',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.only(left: 32),
                                    child: Text(
                                      'This contact owes you money',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Card(
                          elevation: _selectedType == 'lender' ? 4 : 0,
                          color: _selectedType == 'lender' 
                              ? Colors.green.withOpacity(0.1) 
                              : Colors.grey.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: _selectedType == 'lender' 
                                  ? Colors.green 
                                  : Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedType = 'lender';
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Radio<String>(
                                        value: 'lender',
                                        groupValue: _selectedType,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedType = value!;
                                          });
                                        },
                                        activeColor: Colors.green,
                                      ),
                                      const Text(
                                        'Lender',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.only(left: 32),
                                    child: Text(
                                      'You owe money to this contact',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),

                // Delete Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isDeleteLoading ? null : _confirmDeleteContact,
                    icon: _isDeleteLoading 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.delete),
                    label: Text(_isDeleteLoading ? 'Deleting...' : 'Delete Contact'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 