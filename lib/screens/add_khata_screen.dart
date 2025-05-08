import 'package:flutter/material.dart';
import '../models/khata.dart';
import '../models/contact.dart';
import '../services/database_service.dart';

class AddKhataScreen extends StatefulWidget {
  final KhataType khataType;
  
  const AddKhataScreen({Key? key, required this.khataType}) : super(key: key);

  @override
  State<AddKhataScreen> createState() => _AddKhataScreenState();
}

class _AddKhataScreenState extends State<AddKhataScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Contact details
  Contact? _selectedContact;
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  
  // Khata details
  final TextEditingController _interestRateController = TextEditingController(text: '0.0');
  final TextEditingController _noteController = TextEditingController();
  bool _isLender = true; // Default: I'm lending money (I'll get)
  InterestCalculationType _interestCalculationType = InterestCalculationType.simple;
  
  bool _isLoading = false;
  List<Contact> _contacts = [];
  
  @override
  void initState() {
    super.initState();
    _loadContacts();
  }
  
  @override
  void dispose() {
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _interestRateController.dispose();
    _noteController.dispose();
    super.dispose();
  }
  
  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
    });
    
    final contacts = await DatabaseService.instance.getContacts();
    
    setState(() {
      _contacts = contacts;
      _isLoading = false;
    });
  }
  
  Future<void> _saveKhata() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // If no contact is selected, create a new one
      if (_selectedContact == null) {
        final newContact = Contact(
          name: _contactNameController.text.trim(),
          phoneNumber: _contactPhoneController.text.trim(),
        );
        
        await DatabaseService.instance.addContact(newContact);
        _selectedContact = newContact;
      }
      
      // Create khata
      final khata = Khata(
        contactId: _selectedContact!.id!,
        contactName: _selectedContact!.name,
        type: widget.khataType,
        interestRate: double.tryParse(_interestRateController.text) ?? 0.0,
        note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
        currentBalance: 0.0,
        isLender: _isLender,
        interestCalculationType: widget.khataType == KhataType.withInterest 
            ? _interestCalculationType 
            : InterestCalculationType.simple,
      );
      
      await DatabaseService.instance.addKhata(khata);
      
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _selectContact(Contact contact) {
    setState(() {
      _selectedContact = contact;
      _contactNameController.text = contact.name;
      _contactPhoneController.text = contact.phoneNumber ?? '';
    });
    Navigator.pop(context);
  }
  
  Future<void> _showContactSelectionDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select a Contact'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: _contacts.isEmpty
                ? const Center(child: Text('No contacts found'))
                : ListView.builder(
                    itemCount: _contacts.length,
                    itemBuilder: (context, index) {
                      final contact = _contacts[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: contact.avatarColor,
                          child: Text(contact.initials),
                        ),
                        title: Text(contact.name),
                        subtitle: contact.phoneNumber != null
                            ? Text(contact.phoneNumber!)
                            : null,
                        onTap: () => _selectContact(contact),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isWithInterest = widget.khataType == KhataType.withInterest;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isWithInterest ? 'Add Interest Based Khata' : 'Add Regular Khata'
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Contact selection/creation section
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Contact Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Contact name field
                            TextFormField(
                              controller: _contactNameController,
                              decoration: const InputDecoration(
                                labelText: 'Name',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Phone number field
                            TextFormField(
                              controller: _contactPhoneController,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number (Optional)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.phone),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 16),
                            
                            // Choose from contacts button
                            ElevatedButton.icon(
                              onPressed: _showContactSelectionDialog,
                              icon: const Icon(Icons.contacts),
                              label: const Text('Select from Contacts'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Khata details section
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  widget.khataType == KhataType.withInterest
                                      ? Icons.account_balance
                                      : Icons.account_balance_wallet,
                                  color: widget.khataType == KhataType.withInterest
                                      ? Colors.orange
                                      : Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Khata Details',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: widget.khataType == KhataType.withInterest
                                        ? Colors.orange
                                        : Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Relationship type (lender or borrower)
                            const Text(
                              'Relationship:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<bool>(
                                    title: const Text("I'll get"),
                                    value: true,
                                    groupValue: _isLender,
                                    onChanged: (value) {
                                      setState(() {
                                        _isLender = value!;
                                      });
                                    },
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<bool>(
                                    title: const Text("I'll give"),
                                    value: false,
                                    groupValue: _isLender,
                                    onChanged: (value) {
                                      setState(() {
                                        _isLender = value!;
                                      });
                                    },
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Interest details (only for interest-based khata)
                            if (isWithInterest) ...[
                              TextFormField(
                                controller: _interestRateController,
                                decoration: const InputDecoration(
                                  labelText: 'Interest Rate (%)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.percent),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter an interest rate';
                                  }
                                  final rate = double.tryParse(value);
                                  if (rate == null || rate < 0) {
                                    return 'Please enter a valid interest rate';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              const Text(
                                'Interest Calculation Type:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: RadioListTile<InterestCalculationType>(
                                      title: const Text('Simple'),
                                      value: InterestCalculationType.simple,
                                      groupValue: _interestCalculationType,
                                      onChanged: (value) {
                                        setState(() {
                                          _interestCalculationType = value!;
                                        });
                                      },
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  Expanded(
                                    child: RadioListTile<InterestCalculationType>(
                                      title: const Text('Compound'),
                                      value: InterestCalculationType.compound,
                                      groupValue: _interestCalculationType,
                                      onChanged: (value) {
                                        setState(() {
                                          _interestCalculationType = value!;
                                        });
                                      },
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            // Note field
                            TextFormField(
                              controller: _noteController,
                              decoration: const InputDecoration(
                                labelText: 'Note (Optional)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.note),
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Save button
                    ElevatedButton(
                      onPressed: _saveKhata,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Create Khata',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 