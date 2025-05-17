import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../providers/contact_provider.dart';
import '../contact/contact_detail_screen.dart';
import '../home/home_screen.dart';
import '../../../providers/transaction_provider.dart';

class AddContactScreen extends StatefulWidget {
  final Function? onContactAdded;

  const AddContactScreen({Key? key, this.onContactAdded}) : super(key: key);

  @override
  _AddContactScreenState createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = true;
  bool _hasPermission = false;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoadContacts();
  }
  
  Future<void> _checkPermissionAndLoadContacts() async {
    // Check permission
    final status = await Permission.contacts.status;
    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
      });
      _loadContacts();
    } else if (status.isDenied) {
      // Request permission
      final requestStatus = await Permission.contacts.request();
      if (requestStatus.isGranted) {
        setState(() {
          _hasPermission = true;
        });
        _loadContacts();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadContacts() async {
    try {
      // Check if FlutterContacts is available
      if (await FlutterContacts.requestPermission()) {
        final contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: false,
          sorted: true,
        );
        setState(() {
          _contacts = contacts;
          _filteredContacts = contacts;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _filterContacts(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredContacts = _contacts;
      } else {
        _filteredContacts = _contacts.where((contact) {
          final name = contact.displayName.toLowerCase();
          final phones = contact.phones.map((phone) => phone.number).join(' ').toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || phones.contains(searchLower);
        }).toList();
      }
    });
  }
  
  void _onContactSelected(Contact contact) {
    try {
      // Get name and first phone number
      final name = contact.displayName;
      final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';
      
      // Add to provider and then navigate to contact detail screen
      if (name.isNotEmpty) {
        // Use a Builder to get the correct context that has access to ContactProvider
        final contactProvider = Provider.of<ContactProvider>(context, listen: false);
        
        // Add contact and wait for it to complete
        contactProvider.addContact(name, phone, true, 0.0).then((_) {
          print("Contact added successfully: $name ($phone)");
          
          // Force a save operation to ensure persistence
          Future.delayed(const Duration(milliseconds: 100), () {
            contactProvider.saveContactsNow();
          });
          
          // Create contact data for the callback
          final contactData = {
            'name': name,
            'phone': phone,
            'isGet': true,
            'amount': 0.0,
            'lastEditedAt': DateTime.now(),
          };
          
          // Call the callback if provided
          if (widget.onContactAdded != null) {
            widget.onContactAdded!(contactData);
          }
          
          // Force refresh of home screen contacts
          Future.delayed(Duration.zero, () {
            try {
              // Find home screen context and call static refresh method
              BuildContext? homeContext = Navigator.of(context).context;
              HomeScreen.refreshHomeContent(homeContext);
            } catch (e) {
              print("Error refreshing home content: $e");
            }
          });
          
          // Navigate to contact detail screen immediately
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ContactDetailScreen(
                contact: contactData,
                showTransactionDialogOnLoad: false,
              ),
            ),
          );
        });
      }
    } catch (e) {
      // Show error message if something goes wrong
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting contact: $e')),
      );
    }
  }
  
  void _navigateToCreateNewContact() {
    // Navigate to the custom contact creation form
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: Provider.of<ContactProvider>(context, listen: false),
          child: _CreateContactScreen(
            onContactAdded: (contactData) {
              // When contact is added from create screen, navigate to detail
              if (widget.onContactAdded != null) {
                widget.onContactAdded!(contactData);
              }
              
              // Navigate to contact detail screen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ContactDetailScreen(
                    contact: contactData,
                    showTransactionDialogOnLoad: false,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Contact'),
        backgroundColor: const Color(0xFF6750A4),
      ),
      body: Builder(
        builder: (context) => Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: _filterContacts,
                decoration: InputDecoration(
                  hintText: 'Search contacts...',
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
            
            // Create New Contact button
            InkWell(
              onTap: _navigateToCreateNewContact,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.deepPurple,
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Create New Contact',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
            
            // Contacts list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : !_hasPermission
                      ? _buildPermissionDenied()
                      : _buildContactsList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPermissionDenied() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.no_accounts, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Contacts permission denied',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Allow contacts access to add existing contacts',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _checkPermissionAndLoadContacts,
            child: const Text('Grant Permission'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContactsList() {
    if (_filteredContacts.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        // No search results
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No results found for "$_searchQuery"',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        );
      } else {
        // No contacts at all
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'No contacts found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }
    }
    
    return ListView.builder(
      itemCount: _filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        final name = contact.displayName;
        final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';
        final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
        
        // Get background color based on initial
        final colors = [
          Colors.blue,
          Colors.blue,
          Colors.blue,
          Colors.blue,
          Colors.blue,
          Colors.blue,
          Colors.blue,
          Colors.blue,
          Colors.blue,
          Colors.blue,
        ];
        final colorIndex = initial.codeUnitAt(0) % colors.length;
        final avatarColor = colors[colorIndex];
        
        return InkWell(
          onTap: () => _onContactSelected(contact),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: avatarColor,
                  child: Text(initial, style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (phone.isNotEmpty)
                        Text(
                          phone,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Custom screen for creating a new contact - simplified version
class _CreateContactScreen extends StatefulWidget {
  final Function? onContactAdded;
  
  const _CreateContactScreen({Key? key, this.onContactAdded}) : super(key: key);
  
  @override
  _CreateContactScreenState createState() => _CreateContactScreenState();
}

class _CreateContactScreenState extends State<_CreateContactScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedCategory = 'will receive';
  bool _isSaving = false;
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  Future<void> _saveContact() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Update the loading indicator
      setState(() {
        _isSaving = true;
      });
      
      // Create the contact object
      final contact = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'category': _selectedCategory,
        'lastEditedAt': DateTime.now(),
      };
      
      // Add the contact to both providers for consistency
      try {
        // First add to TransactionProvider (this will save to SharedPreferences)
        final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
        final success = await transactionProvider.addContact(contact);
        
        if (success) {
          print('Successfully added contact to TransactionProvider');
        } else {
          print('Failed to add contact to TransactionProvider');
        }
        
        // Also add to ContactProvider to ensure both providers are in sync
        final contactProvider = Provider.of<ContactProvider>(context, listen: false);
        await contactProvider.addContact(
          _nameController.text.trim(),
          _phoneController.text.trim(),
          true,  // isGet default
          0.0,   // initial amount
        );
        
        // Force sync between providers
        await transactionProvider.syncContactsFromProvider(context);
        
        // Call the callback if provided
        widget.onContactAdded?.call(contact);
        
        // Force refresh of home screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          HomeScreen.refreshHomeContent(context);
        });
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${_nameController.text.trim()} added successfully'))
          );
        }
        
        // Navigate back
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        // Show error message
        print('Error saving contact: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding contact: $e'))
          );
        }
      } finally {
        // Reset loading state
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Contact'),
        backgroundColor: const Color(0xFF6750A4),
      ),
      body: Builder(
        builder: (builderContext) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name Field
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                
                // Phone Field
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 32),
                
                // Category Field
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: ['will receive', 'will give', 'will not receive'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 32),
                
                // Add Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveContact,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFF6750A4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Add Contact',
                      style: TextStyle(fontSize: 16),
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