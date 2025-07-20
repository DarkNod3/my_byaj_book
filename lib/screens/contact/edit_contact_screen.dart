import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:my_byaj_book/providers/transaction_provider.dart';
import 'package:my_byaj_book/providers/theme_provider.dart';
import 'package:my_byaj_book/widgets/dialogs/confirm_dialog.dart';
import 'package:my_byaj_book/screens/contact/contact_detail_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:my_byaj_book/utils/image_picker_helper.dart';

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
  bool _isWithInterest = false;
  final _interestRateController = TextEditingController();
  String _selectedType = 'borrower';
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ');
  File? _profileImage;
  bool _isDeleteLoading = false;
  
  // Add interest rate period selector (monthly or yearly)
  String _interestPeriod = 'yearly'; // 'monthly' or 'yearly'

  late TransactionProvider _transactionProvider;
  String get _contactId => widget.contact['phone'] ?? '';

  // Category list has been removed

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing contact data
    _nameController.text = widget.contact['name'] ?? '';
    _phoneController.text = widget.contact['phone'] ?? '';
    
    // Check if this is a with-interest contact
    _isWithInterest = widget.contact['type'] != null;
    
    if (_isWithInterest) {
      _selectedType = widget.contact['type'] ?? 'borrower';
      _interestRateController.text = widget.contact['interestRate']?.toString() ?? '0.0';
      _interestPeriod = widget.contact['interestPeriod'] ?? 'yearly';
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

  // Updated method to use ImagePickerHelper
  void _showProfileImageOptions() async {
    final imagePickerHelper = ImagePickerHelper();
    final File? result = await imagePickerHelper.showImageSourceDialog(
      context,
      currentImage: _profileImage,
    );
    
    // If result is null, user might have pressed "Remove"
    if (result != null) {
      setState(() {
        _profileImage = result;
      });
    } else if (result == null && mounted) {
      // This could be either "Remove" was pressed or selection was canceled
      // To differentiate, we need to check if the dialog returned vs user canceled
      // Since we can't easily differentiate, we'll handle this in the UI where 
      // "Remove" button explicitly sets _profileImage to null
    }
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

    // Prepare updated contact data with safe handling of null values
    final updatedContact = {
      ...widget.contact,
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      // Category feature has been removed
      // Handle possible null profileImagePath
      'profileImagePath': _profileImage?.path,
    };

    // Add interest-related fields if this is a with-interest contact
    if (_isWithInterest) {
      updatedContact['type'] = _selectedType;
      updatedContact['interestRate'] = double.tryParse(_interestRateController.text) ?? 0.0;
      updatedContact['interestPeriod'] = _interestPeriod;
    } else {
      // Remove interest-related fields if this is not a with-interest contact
      updatedContact.remove('type');
      updatedContact.remove('interestRate');
      updatedContact.remove('interestPeriod');
    }

    // Ensure all string values are non-null
    updatedContact.forEach((key, value) {
      // Replace null string values with empty strings
      if (value == null && (key == 'name' || key == 'phone' || 
          key == 'type' || key == 'interestPeriod')) {
        updatedContact[key] = '';
      }
    });

    // Update the contact
    final success = await _transactionProvider.updateContact(updatedContact);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact updated successfully')),
      );
      
      // Return true to the previous screen to indicate successful update
      Navigator.pop(context, true);
      
      // If this is a new contact, automatically navigate to the transaction entry dialog
      if (widget.contact['isNewContact'] == true) {
        // Short delay to allow the previous screen to process the result
        Future.delayed(const Duration(milliseconds: 300), () {
          // Find the ContactDetailScreen and show the transaction entry dialog
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ContactDetailScreen(
                contact: updatedContact,
                showTransactionDialogOnLoad: true,
              ),
            ),
          );
        });
      }
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
      // Removed debug print
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
    final hasTransactions = _transactionProvider.getTransactionsForContact(_contactId).isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Contact'),
        actions: [
          // Add delete button to app bar
          IconButton(
            icon: _isDeleteLoading ? 
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ) :
              const Icon(Icons.delete),
            onPressed: _isDeleteLoading ? null : _confirmDeleteContact,
            tooltip: 'Delete Contact',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Profile Image
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50, // Smaller radius to save space
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: _profileImage != null 
                                ? FileImage(_profileImage!) 
                                : null,
                            child: _profileImage == null
                                ? Text(
                                    _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : '',
                                    style: TextStyle(
                                      fontSize: 50,
                                      color: Colors.grey.shade400,
                                    ),
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
                                radius: 18,
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Balance information removed per request

                    // Name Field
                    const Text(
                      'Name',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter contact name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Phone Field
                    const Text(
                      'Phone Number',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        hintText: 'Enter phone number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
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
                    const SizedBox(height: 12),

                    // Category has been removed
                    const SizedBox(height: 16),

                    // With Interest Toggle
                    Row(
                      children: [
                        const Text(
                          'With Interest Account',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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
                            fontSize: 11,
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
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Interest Rate and Type (Only if with interest)
                    if (_isWithInterest) ...[
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Interest Rate',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: _interestRateController,
                                  decoration: InputDecoration(
                                    hintText: 'Enter rate',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    suffixText: '%',
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (value) {
                                    if (_isWithInterest) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a rate';
                                      }
                                      if (double.tryParse(value) == null) {
                                        return 'Enter a valid number';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Per Period',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _interestPeriod = 'monthly';
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            decoration: BoxDecoration(
                                              color: _interestPeriod == 'monthly' 
                                                ? Colors.amber.withOpacity(0.2) 
                                                : Colors.transparent,
                                              borderRadius: const BorderRadius.horizontal(
                                                left: Radius.circular(7),
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              'Monthly',
                                              style: TextStyle(
                                                fontWeight: _interestPeriod == 'monthly' 
                                                  ? FontWeight.bold 
                                                  : FontWeight.normal,
                                                color: _interestPeriod == 'monthly'
                                                  ? Colors.amber.shade900
                                                  : Colors.grey.shade700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 30,
                                        color: Colors.grey.shade400,
                                      ),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _interestPeriod = 'yearly';
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            decoration: BoxDecoration(
                                              color: _interestPeriod == 'yearly' 
                                                ? Colors.amber.withOpacity(0.2) 
                                                : Colors.transparent,
                                              borderRadius: const BorderRadius.horizontal(
                                                right: Radius.circular(7),
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              'Yearly',
                                              style: TextStyle(
                                                fontWeight: _interestPeriod == 'yearly' 
                                                  ? FontWeight.bold 
                                                  : FontWeight.normal,
                                                color: _interestPeriod == 'yearly'
                                                  ? Colors.amber.shade900
                                                  : Colors.grey.shade700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      const Text(
                        'Account Type',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          // Borrower Option
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: _selectedType == 'borrower' 
                                ? Colors.red.withOpacity(0.08)
                                : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedType == 'borrower'
                                  ? Colors.red
                                  : Colors.grey.shade300,
                                width: _selectedType == 'borrower' ? 2 : 1,
                              ),
                              boxShadow: _selectedType == 'borrower' 
                                ? [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                            ),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedType = 'borrower';
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.account_balance_wallet,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Expanded(
                                                    child: Text(
                                                      'Jisne Paise Liye Hai',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  Column(
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
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w500,
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              const Text(
                                                'वह आपका पैसा लेकर देनदार है',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              const Text(
                                                'This contact owes you money',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          // Lender Option
                          Container(
                            decoration: BoxDecoration(
                              color: _selectedType == 'lender'
                                ? Colors.green.withOpacity(0.08)
                                : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedType == 'lender'
                                  ? Colors.green
                                  : Colors.grey.shade300,
                                width: _selectedType == 'lender' ? 2 : 1,
                              ),
                              boxShadow: _selectedType == 'lender'
                                ? [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                            ),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedType = 'lender';
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.account_balance,
                                            color: Colors.green,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Expanded(
                                                    child: Text(
                                                      'Jisne Paise Diye Hai',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  Column(
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
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w500,
                                                          color: Colors.green,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              const Text(
                                                'आपने इनसे पैसे उधार लिए हैं',
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              const Text(
                                                'You owe money to this contact',
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          
          // Save Button bottom bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _updateContact,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 