import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:my_byaj_book/screens/card/card_screen.dart';
import 'package:my_byaj_book/screens/loan/loan_screen.dart';
import 'package:my_byaj_book/screens/tools/more_tools_screen.dart';
import 'package:my_byaj_book/screens/bill_diary/bill_diary_screen.dart';
import 'package:my_byaj_book/screens/milk_diary/milk_diary_screen.dart';
import 'package:my_byaj_book/screens/work_diary/work_diary_screen.dart';
import 'package:my_byaj_book/screens/history/history_screen.dart';
import 'package:my_byaj_book/screens/contact/contact_detail_screen.dart';
import 'package:my_byaj_book/widgets/bottom_nav/bottom_navigation.dart';
import 'package:my_byaj_book/widgets/header/app_header.dart';
import 'package:my_byaj_book/widgets/navigation/navigation_drawer.dart';
import 'package:my_byaj_book/constants/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:my_byaj_book/providers/nav_preferences_provider.dart';
import 'package:my_byaj_book/providers/transaction_provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:my_byaj_book/screens/contact/edit_contact_screen.dart';
import 'package:my_byaj_book/screens/tools/emi_calculator_screen.dart';
import 'package:my_byaj_book/screens/tools/sip_calculator_screen.dart';
import 'package:my_byaj_book/screens/tools/tax_calculator_screen.dart';
import 'package:my_byaj_book/widgets/notification_badge.dart';
import 'package:intl/intl.dart';
import 'package:my_byaj_book/utils/permission_handler.dart';
import 'package:my_byaj_book/utils/image_picker_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/contact_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/image_picker_helper.dart';
import '../contact/contact_detail_screen.dart';
import '../contact/add_contact_screen.dart';

// Simple lifecycle observer for app state
class AppLifecycleObserver with WidgetsBindingObserver {
  final VoidCallback? onResume;
  final VoidCallback? onPause;
  
  AppLifecycleObserver({this.onResume, this.onPause}) {
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume?.call();
    } else if (state == AppLifecycleState.paused) {
      onPause?.call();
    }
  }
  
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
  
  // Add a static method that can be called from other files to refresh the home screen
  static void refreshHomeContent(BuildContext context) {
    print("HomeScreen.refreshHomeContent: Refreshing home screen content");
    
    // First, force the providers to rebuild their contacts lists
    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final contactProvider = Provider.of<ContactProvider>(context, listen: false);
      
      // Clear cached data in providers
      print("Reloading providers data");
      
      // Reset sync attempts counter in any HomeContent states
      void resetSyncCounter(Element element) {
        if (element.widget is HomeContent) {
          final state = (element as StatefulElement).state;
          if (state is _HomeContentState) {
            state._syncAttempts = 0;
          }
        }
        element.visitChildElements(resetSyncCounter);
      }
      
      // Start from the root to reset sync counters
      try {
        final app = WidgetsBinding.instance.renderViewElement;
        if (app != null) {
          app.visitChildElements(resetSyncCounter);
        }
      } catch (e) {
        print('Error resetting sync counters: $e');
      }
      
      // Force reload of contacts in both providers
      contactProvider.loadContacts().then((_) {
        transactionProvider.syncContactsFromProvider(context).then((_) {
          // Ensure the home content widgets refresh their content
          // Find all instances of HomeContent states and refresh them
          void visitor(Element element) {
            if (element.widget is HomeContent) {
              final state = (element as StatefulElement).state;
              if (state is _HomeContentState) {
                state.setState(() {
          // Force a complete refresh
                  state._contacts.clear();
                  state._syncContactsWithTransactions();
        });
      }
    }
            element.visitChildElements(visitor);
          }
          
          // Start visiting from the root to find all HomeContent widgets
          try {
            final app = WidgetsBinding.instance.renderViewElement;
            if (app != null) {
              app.visitChildElements(visitor);
              print("HomeScreen.refreshHomeContent: Finished refreshing home content");
            }
          } catch (e) {
            print('Error finding HomeContent: $e');
          }
        });
      });
    } catch (e) {
      print('Error refreshing providers: $e');
    }
  }
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  DateTime? _lastBackPressTime;
  
  // App lifecycle observer
  late final AppLifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    _checkAndCreateAutomaticBackup();
    
    // Immediately start loading data to prevent blank screens
    _loadInitialData();
    
    // Add app lifecycle listener to refresh data when app resumes
    _lifecycleObserver = AppLifecycleObserver(
      onResume: () {
        // Find the HomeContent state and refresh its data
        final homeContentState = _findHomeContentState(context);
        if (homeContentState != null) {
          homeContentState.setState(() {
            homeContentState._contacts.clear();
            homeContentState._syncContactsWithTransactions();
          });
        }
      }
    );
  }
  
  // New method to explicitly handle data loading at startup
  void _loadInitialData() {
    // Find the HomeContent state and refresh its data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeContentState = _findHomeContentState(context);
      if (homeContentState != null) {
        homeContentState.refresh();
      }
    });
  }
  
  @override
  void dispose() {
    _lifecycleObserver.dispose();
    super.dispose();
  }
  
  Future<void> _checkAndCreateAutomaticBackup() async {
    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      await transactionProvider.createAutomaticBackup();
    } catch (e) {
      // Error during automatic backup - silent in release
    }
  }

  // Handle back button press to exit the app
  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      // If not on the home tab, navigate to home tab
      setState(() {
        _currentIndex = 0;
      });
      return false;
    }
    
    // If we're already on the home tab, check if we should exit
    final now = DateTime.now();
    if (_lastBackPressTime == null || 
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      // First back press, show toast and update time
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }
    
    // Second back press within 2 seconds, exit the app
    await SystemNavigator.pop();
    return true;
  }

  // Helper method to find HomeContent state
  _HomeContentState? _findHomeContentState(BuildContext context) {
    _HomeContentState? result;
    
    void visitor(Element element) {
      if (element.widget is HomeContent) {
        final state = (element as StatefulElement).state;
        if (state is _HomeContentState) {
          result = state;
        }
      }
      element.visitChildElements(visitor);
    }
    
    context.visitChildElements(visitor);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavPreferencesProvider>(context);
    
    // Create a map of screen IDs to screen widgets
    final Map<String, Widget> screenMap = {
      'home': const HomeContent(),
      'loans': const LoanScreen(showAppBar: false),
      'cards': const CardScreen(),
      'bill_diary': const BillDiaryScreen(showAppBar: false),
      'milk_diary': const MilkDiaryScreen(showAppBar: false),
      'work_diary': const WorkDiaryScreen(showAppBar: false),
      'tools': const MoreToolsScreen(),
      'emi_calc': const EmiCalculatorScreen(showAppBar: false),
      'sip_calc': const SipCalculatorScreen(showAppBar: false),
      'tax_calc': const TaxCalculatorScreen(showAppBar: false),
    };
    
    // Get selected screens from navigation preferences
    final List<Widget> selectedScreens = navProvider.selectedNavItems
        .map((item) => screenMap[item.id] ?? const HomeContent())
        .toList();
    
    // Ensure we have at least one screen
    if (selectedScreens.isEmpty) {
      selectedScreens.add(const HomeContent());
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        drawer: const AppNavigationDrawer(),
        body: Column(
          children: [
            AppHeader(
              title: _getScreenTitle(navProvider),
              showBackButton: false,
              actions: [
                const NotificationBadge(),
                IconButton(
                  icon: const Icon(Icons.history, color: Colors.white, size: 24),
                  tooltip: 'Transaction History',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistoryScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            Expanded(
              child: _getActiveScreen(selectedScreens),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            // Make sure we don't exceed the available screens
            if (index == 2) {
              // Center button for tools
              setState(() {
                _currentIndex = index;
              });
            } else if (index == 3 || index == 4) {
              // We need to handle positions 3 and 4 specially
              final adjustedIndex = index - 1; // Adjust for the center button
              if (adjustedIndex - 1 < selectedScreens.length) { // -1 because we're 0-indexed
                setState(() {
                  _currentIndex = index;
                });
              }
            } else if (index < selectedScreens.length) {
              // Normal case for positions 0 and 1
              setState(() {
                _currentIndex = index;
              });
            }
          },
        ),
      ),
    );
  }

  String _getScreenTitle(NavPreferencesProvider navProvider) {
    // If we're on the tools button (index 2), return "Tools"
    if (_currentIndex == 2) {
      return 'Tools';
    }
    
    // Get the list of selected nav items
    final navItems = navProvider.selectedNavItems;
    
    // Make sure we don't exceed the list length
    int adjustedIndex;
    if (_currentIndex > 2) {
      adjustedIndex = _currentIndex - 1; // Adjust for the center button
    } else {
      adjustedIndex = _currentIndex;
    }
    
    // Return the title if it exists
    if (adjustedIndex < navItems.length) {
      return navItems[adjustedIndex].title;
    }
    
    return 'My Byaj Book';
  }

  Widget _getActiveScreen(List<Widget> screens) {
    // For the center button (index 2), show the tools screen
    if (_currentIndex == 2) {
      return const MoreToolsScreen();
    }
    
    // For other indices, we need to adjust because of the center button
    int adjustedIndex;
    if (_currentIndex > 2) {
      adjustedIndex = _currentIndex - 1; // Adjust for the center button (index 2)
    } else {
      adjustedIndex = _currentIndex;
    }
    
    // Make sure we don't exceed the list length
    if (adjustedIndex < screens.length) {
      return screens[adjustedIndex];
    } else {
      // Handle the case where adjustedIndex is out of bounds
      return screens.isNotEmpty ? screens.first : const HomeContent();
    }
  }
}

// Add HomeContent widget
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String _searchQuery = '';
  
  // Add the needed variables
  String _sortMode = 'Recent';  // 'Recent', 'High to Low', 'Low to High', 'By Name'
  String _filterMode = 'All';   // 'All', 'You received', 'You paid'
  
  // Cached total values
  double _cachedTotalToGive = 0.0;
  double _cachedTotalToGet = 0.0;
  
  // List for contacts
  final List<Map<String, dynamic>> _contacts = [];
  bool _isInitialized = false;
  int _syncAttempts = 0;
  bool _isLoading = true;

  // Method to refresh contacts and totals
  void refresh() {
    if (mounted) {
      setState(() {
        // Clear existing contacts to ensure fresh data
        _contacts.clear();
        _syncContactsWithTransactions();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    
    // Delay to ensure the provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Clear any existing data first
      _contacts.clear();
      
      // Load fresh data
      _syncContactsWithTransactions();
      
      // Set up a second delayed load to ensure data is properly loaded
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _contacts.isEmpty) {
          setState(() {
            _syncContactsWithTransactions();
          });
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sync contacts when dependencies change
    if (!_isInitialized) {
      // Clear any existing data first
      _contacts.clear();
      
      // Load fresh data
      _syncContactsWithTransactions();
      _isInitialized = true;
      
      // Set up a delayed second load if needed
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _contacts.isEmpty) {
          setState(() {
            _syncContactsWithTransactions();
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(HomeContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Force a refresh of data when the widget updates
    _syncContactsWithTransactions();
  }

  // Sync method to load contacts and transactions
  Future<void> _syncContactsWithTransactions() async {
    if (!mounted) return;
    
    try {
      // Get transaction provider and contact provider
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final contactProvider = Provider.of<ContactProvider>(context, listen: false);
      
      print('===== DEBUG: HOME SCREEN SYNC START =====');
      print('Sync attempt #: $_syncAttempts');
      
      // Safety check to prevent infinite loops
      if (_syncAttempts > 3) {
        print('Too many sync attempts, stopping to prevent infinite loop');
          setState(() {
          _isLoading = false;
        });
        return;
      }
      _syncAttempts++;
      
      // CRITICAL FIX: First make sure we load the contacts directly from SharedPreferences
      // This ensures we have the most up-to-date list regardless of provider state
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final contactsList = prefs.getStringList('contacts') ?? [];
      print('Raw contacts in SharedPreferences: ${contactsList.length}');
      
      // Force both providers to reload their contacts
      await contactProvider.loadContacts();
      print('ContactProvider contacts count after reload: ${contactProvider.contacts.length}');
      
      // Ensure the transaction provider is in sync with the contact provider
      await transactionProvider.syncContactsFromProvider(context);
      print('TransactionProvider contacts count after sync: ${transactionProvider.contacts.length}');
      
      // Now get a combined list from both providers to ensure we have all contacts
      Set<String> contactIds = {};
      final combinedContacts = <Map<String, dynamic>>[];
      
      // First add all contacts from the ContactProvider
      for (var contact in contactProvider.contacts) {
        if (!contactIds.contains(contact['phone'])) {
          contactIds.add(contact['phone'] as String);
          combinedContacts.add(Map<String, dynamic>.from(contact));
        }
      }
      
      // Then add any contacts from the TransactionProvider that aren't already in the list
      for (var contact in transactionProvider.contacts) {
        final phone = contact['phone'] as String?;
        if (phone != null && !contactIds.contains(phone)) {
          contactIds.add(phone);
          combinedContacts.add(Map<String, dynamic>.from(contact));
        }
      }
      
      // Also check for any contacts with transactions that might be missing
      final transactionContactIds = prefs.getStringList('transaction_contacts') ?? [];
      for (var contactId in transactionContactIds) {
        if (!contactIds.contains(contactId)) {
          // Create a minimal contact for this ID
          combinedContacts.add({
            'name': 'Contact $contactId',
            'phone': contactId,
            'lastEditedAt': DateTime.now(),
          });
          contactIds.add(contactId);
        }
      }
      
      print('Combined contacts total: ${combinedContacts.length}');
    
      // Reset totals
    _cachedTotalToGive = 0.0;
    _cachedTotalToGet = 0.0;
      
      // Clear existing contacts to ensure we have a clean slate
      _contacts.clear();
    
      // Process all contacts
      for (final contact in combinedContacts) {
        final phone = contact['phone'] as String?;
        if (phone == null || phone.isEmpty) {
          print('Skipping contact with empty phone number');
          continue;
        }
        
        // Calculate balance with the latest transactions
        final balance = transactionProvider.calculateBalance(phone, includeInterest: false);
        print('Contact: ${contact['name']}, Phone: $phone, Balance: $balance');
        
        // Update totals based on the calculated balance
        if (balance >= 0) {
          _cachedTotalToGet += balance.abs();
        } else {
          _cachedTotalToGive += balance.abs();
        }
        
        // Create a copy of the contact to avoid modifying the original
        final updatedContact = Map<String, dynamic>.from(contact);
        
        // Update contact with calculated amount and direction
        updatedContact['amount'] = balance.abs();
        updatedContact['isGet'] = balance >= 0;
      
        // Apply search filtering if needed
        if (_searchQuery.isNotEmpty) {
          final name = updatedContact['name'] as String? ?? '';
          final amount = updatedContact['amount'] as double? ?? 0.0;
          
          // Check if contact matches search query by name or amount
          final searchLower = _searchQuery.toLowerCase();
          final nameLower = name.toLowerCase();
          final amountStr = amount.toStringAsFixed(2);
          
          if (!nameLower.contains(searchLower) && !amountStr.contains(_searchQuery)) {
            print('Contact ${contact['name']} filtered out by search query: $_searchQuery');
            continue; // Skip this contact if not matching search
          }
        }
        
        // Add this contact to our display list regardless of balance
        _contacts.add(updatedContact);
        print('Added ${updatedContact['name']} to visible contacts list');
      }
      
      print('Final contacts count to display: ${_contacts.length}');
      
      // Apply sort logic
      _applySearchAndFilter();
      
      // Update the UI
      setState(() {
        _isLoading = false;
      });
      print('Updated home with ${_contacts.length} contacts to display');
      print('Totals: Pay=${_cachedTotalToGive}, Receive=${_cachedTotalToGet}');
      print('===== DEBUG: HOME SCREEN SYNC END =====');
    } catch (e) {
      // Handle any errors
      print('Error syncing contacts: $e');
      print(e.toString());
      if (e is Error) {
        print(e.stackTrace);
      }
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Method to apply search and filtering
  void _applySearchAndFilter() {
    // Sort contacts based on the selected sort mode
    switch (_sortMode) {
      case 'Recent':
        // Sort by lastEditedAt (newest first)
    _contacts.sort((a, b) {
      final aTime = a['lastEditedAt'] as DateTime?;
      final bTime = b['lastEditedAt'] as DateTime?;
      if (aTime == null || bTime == null) {
        return 0;
      }
      return bTime.compareTo(aTime);
    });
        break;
      case 'High to Low':
        // Sort by amount (highest first)
        _contacts.sort((a, b) {
          final aAmount = a['amount'] as double? ?? 0.0;
          final bAmount = b['amount'] as double? ?? 0.0;
          return bAmount.compareTo(aAmount);
        });
        break;
      case 'Low to High':
        // Sort by amount (lowest first)
        _contacts.sort((a, b) {
          final aAmount = a['amount'] as double? ?? 0.0;
          final bAmount = b['amount'] as double? ?? 0.0;
          return aAmount.compareTo(bAmount);
        });
        break;
      case 'By Name':
        // Sort alphabetically by name
        _contacts.sort((a, b) {
          final aName = a['name'] as String? ?? '';
          final bName = b['name'] as String? ?? '';
          return aName.compareTo(bName);
        });
        break;
    }
  }
  
  // Update cached totals
  void _updateCachedTotals() {
    _cachedTotalToGive = 0.0;
    _cachedTotalToGet = 0.0;
    
    for (final contact in _contacts) {
      final amount = contact['amount'] as double? ?? 0.0;
      final isGet = contact['isGet'] as bool? ?? true;
      
      if (isGet) {
        _cachedTotalToGet += amount;
    } else {
        _cachedTotalToGive += amount;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Summary card at the top
          _buildSummaryCard(),
          
          // Search bar
          _buildSearchBar(),
          
          // Contacts list
        Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _contacts.isEmpty
                ? _buildEmptyState()
                : _buildContactsList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddContactDialog,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.person_add, color: Colors.white),
          ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // You Will Pay section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                  const Icon(Icons.arrow_upward, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  const Text('You Will Pay', style: TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                      const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                      ),
                      child: Text(
                  '₹ ${_cachedTotalToGive.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.red.shade700,
                    ),
                ),
                  ),
                ],
            ),
              ),
          
          // Vertical divider
          Container(width: 1, height: 60, color: Colors.white.withOpacity(0.5)),
          
          // You Will Receive section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                  const Icon(Icons.arrow_downward, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  const Text('You Will Receive', style: TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                      const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                      ),
                      child: Text(
                  '₹ ${_cachedTotalToGet.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 16,
                      color: Colors.green.shade700,
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
  
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30),
      ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
            _contacts.clear();
            _syncContactsWithTransactions();
                    });
                  },
        decoration: InputDecoration(
          hintText: 'Find person by name or amount...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
        children: [
              IconButton(
                icon: const Icon(Icons.sort, color: Colors.grey),
                onPressed: _showSortOptions,
              ),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner, color: Colors.grey),
                onPressed: () {
                  // Implement QR code scanning functionality
                },
              ),
            ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_alt_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No contacts yet',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                    ),
                      const SizedBox(height: 8),
          Text(
            'Add a contact to track your payments',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddContactDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('Add Contact'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
      ),
    );
  }
  
  Widget _buildContactsList() {
    print('Building contacts list with ${_contacts.length} contacts');
    
    return ListView.builder(
      itemCount: _contacts.length,
      padding: const EdgeInsets.only(bottom: 80), // Space for FAB
      itemBuilder: (context, index) {
        final contact = _contacts[index];
        final name = contact['name'] as String? ?? 'Unknown';
        final amount = contact['amount'] as double? ?? 0.0;
        final isGet = contact['isGet'] as bool? ?? true;
        final lastEditedAt = contact['lastEditedAt'] as DateTime?;
        
        print('Rendering contact: $name with amount: $amount');
        
        // Create initials for avatar
        final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => _navigateToContactDetails(contact),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    child: Text(initials, style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  
                  // Contact details
              Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                        Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (lastEditedAt != null)
                          Text(
                            '${_getTimeAgo(lastEditedAt)}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
                  ),
                  
                  // Amount
                    Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                      color: isGet ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                    children: [
                        Icon(
                          isGet ? Icons.arrow_downward : Icons.arrow_upward,
                          size: 16,
                          color: isGet ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '₹${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                            color: isGet ? Colors.green : Colors.red,
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
            ),
                        ),
                      );
                    },
    );
  }
  
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min ago';
    } else {
      return 'Just now';
    }
  }
  
  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sort by',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 20),
            _buildSortOption('Recent', Icons.access_time),
            _buildSortOption('High to Low', Icons.arrow_downward),
            _buildSortOption('Low to High', Icons.arrow_upward),
            _buildSortOption('By Name', Icons.sort_by_alpha),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSortOption(String title, IconData icon) {
    final isSelected = _sortMode == title;
    
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.deepPurple : Colors.grey),
      title: Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.deepPurple : Colors.black,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.deepPurple) : null,
      onTap: () {
                    setState(() {
          _sortMode = title;
          Navigator.pop(context);
          _contacts.clear();
          _syncContactsWithTransactions();
                    });
                  },
    );
  }
  
  void _showAddContactDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddContactScreen(
          onContactAdded: (contact) {
            // This callback is called when a contact is successfully added
            // Clear the contacts list first to ensure we get fresh data
            setState(() {
              _contacts.clear();
            });
            
            // Use Future.microtask to ensure this runs after the current frame
            Future.microtask(() {
              if (mounted) {
                // Refresh contacts and update totals
              _syncContactsWithTransactions();
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${contact['name']} added successfully')),
            );
              }
            });
                  },
                ),
              ),
    );
  }
  
  void _navigateToContactDetails(Map<String, dynamic> contact) {
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => ContactDetailScreen(contact: contact),
      ),
    ).then((_) {
      // Refresh contacts when returning from details page
      // Clear contacts first to ensure we get fresh data
      setState(() {
        _contacts.clear();
      });
      
      // Use Future.microtask to ensure this runs after the current frame
      Future.microtask(() {
                                      if (mounted) {
        _syncContactsWithTransactions();
        }
      });
    });
  }
}