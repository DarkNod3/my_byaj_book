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
    // First, force the providers to rebuild their contacts lists
    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final contactProvider = Provider.of<ContactProvider>(context, listen: false);
      
      // Clear loading flag to force reload
      contactProvider.clearLoadingFlag();
      
      // Reset sync attempts counter in any HomeContent states
      void resetSyncCounter(Element element) {
        if (element.widget is HomeContent) {
          final state = (element as StatefulElement).state;
          if (state is _HomeContentState) {
            state._syncAttempts = 0;
            state._isSyncing = false; // Clear syncing lock
            state._contacts.clear(); // Force refresh by clearing contacts
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
        // Silent error handling
      }
      
      // Schedule the reloads with a short delay
      Future.delayed(const Duration(milliseconds: 200), () async {
        try {
          // Force reload of contacts in both providers with robust error handling and retry
          await contactProvider.loadContacts().then((_) {
            // Verify contacts were actually loaded
            print('Contact provider loaded ${contactProvider.contacts.length} contacts');
            
            // Retry after a short delay if needed
            if (contactProvider.contacts.isEmpty && transactionProvider.contacts.isNotEmpty) {
              print('Warning: ContactProvider still has no contacts after reload but TransactionProvider has ${transactionProvider.contacts.length}');
              // Retry with delay
              Future.delayed(const Duration(milliseconds: 300), () {
                contactProvider.loadContacts().then((_) {
                  // After retry, process with transaction provider sync
                  transactionProvider.syncContactsFromProvider(context).then((_) {
                    print('Completed transaction provider sync after retry');
                    _refreshHomeContentStates(context);
                  });
                });
              });
            } else {
              // Normal flow if contacts were loaded successfully
              transactionProvider.syncContactsFromProvider(context).then((_) {
                print('Completed initial transaction provider sync');
                _refreshHomeContentStates(context);
              });
            }
          });
        } catch (e) {
          print('Error in refreshHomeContent delayed processing: $e');
        }
      });
    } catch (e) {
      print('Error refreshing home content: $e');
    }
  }

  // Helper method to refresh HomeContent states
  static void _refreshHomeContentStates(BuildContext context) {
    // Find the active HomeContent and refresh just it, not all instances
    void visitor(Element element) {
      if (element.widget is HomeContent) {
        final state = (element as StatefulElement).state;
        if (state is _HomeContentState) {
          state._contacts.clear();
          state._isLoading = true;
          state._syncContactsWithTransactions();
        }
      }
      element.visitChildElements(visitor);
    }
    
    // Only search in the current context subtree to be more efficient
    try {
      if (context is BuildContext && context.mounted) {
        context.visitChildElements(visitor);
      }
    } catch (e) {
      // Silent error handling
      print('Error in _refreshHomeContentStates: $e');
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
    _forceLoadContactsAfterDelay();
    
    // Add app lifecycle listener to refresh data when app resumes
    _lifecycleObserver = AppLifecycleObserver(
      onResume: () {
        // Always force a reload when app resumes
        _forceLoadContactsAfterDelay();
        
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
      // First ensure providers are loaded
      try {
        final contactProvider = Provider.of<ContactProvider>(context, listen: false);
        final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
        
        // Force reload contacts to ensure we have fresh data
        contactProvider.loadContacts().then((_) {
          if (contactProvider.contacts.isEmpty) {
            // If still empty, try another approach to recover contacts
            transactionProvider.syncContactsFromProvider(context);
          }
          
          // Find and refresh HomeContent state
          final homeContentState = _findHomeContentState(context);
          if (homeContentState != null) {
            homeContentState.refresh();
          }
        });
      } catch (e) {
        print('Error in _loadInitialData: $e');
      }
    });
  }
  
  // Force load contacts after a delay
  void _forceLoadContactsAfterDelay() {
    // Add a delayed forced reload to ensure contacts are loaded after app initialization
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        try {
          final contactProvider = Provider.of<ContactProvider>(context, listen: false);
          final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
          
          // First, clear any existing data to prevent stale data
          contactProvider.clearLoadingFlag();
          
          // Force reload contacts with await to ensure it completes
          contactProvider.loadContacts().then((_) {
            if (mounted) {
              // Force sync transactions with contacts - passing the context for real-time updates
              transactionProvider.syncContactsFromProvider(context).then((_) {
                if (mounted) {
                  // Find and refresh all HomeContent states
                  final homeContentState = _findHomeContentState(context);
                  if (homeContentState != null) {
                    homeContentState.refresh();
                  }
                  
                  // Force another reload after a delay to ensure data persistence
                  Future.delayed(const Duration(seconds: 1), () {
                    if (mounted) {
                      HomeScreen.refreshHomeContent(context);
                    }
                  });
                }
              });
            }
          });
        } catch (e) {
          print('Error in _forceLoadContactsAfterDelay: $e');
        }
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
  
  // Add debounce timer for search
  Timer? _searchDebounce;
  
  // Cached total values
  double _cachedTotalToGive = 0.0;
  double _cachedTotalToGet = 0.0;
  
  // List for contacts
  final List<Map<String, dynamic>> _contacts = [];
  bool _isInitialized = false;
  int _syncAttempts = 0;
  bool _isLoading = true;
  
  // Add a lock to prevent concurrent synchronization
  bool _isSyncing = false;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  // Method to refresh contacts and totals
  void refresh() {
    if (mounted) {
      setState(() {
        // Only set loading state, don't clear contacts immediately
        // This prevents the "no contacts" screen from flashing
        _isLoading = true;
      });
      _syncContactsWithTransactions();
    }
  }

  @override
  void initState() {
    super.initState();
    
    // Load data once after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureContactsLoaded();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only sync on first initialization
    if (!_isInitialized) {
      _isInitialized = true;
      _syncContactsWithTransactions();
    }
  }

  @override
  void didUpdateWidget(HomeContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // No need to refresh on every update
  }

  // Sync method to load contacts and transactions
  Future<void> _syncContactsWithTransactions() async {
    if (!mounted) return;
    
    // If already syncing, avoid starting another sync operation
    if (_isSyncing) {
      print('HomeContent: Sync already in progress, skipping');
      return;
    }
    
    // Set syncing lock to prevent concurrent syncs
    setState(() {
      _isSyncing = true;
      // Don't set _isLoading = true here if we already have contacts
      // This prevents UI flicker when refreshing
      if (_contacts.isEmpty) {
        _isLoading = true;
      }
    });
    
    try {
      // Add slight delay to ensure SharedPreferences has been updated
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Get transaction provider and contact provider
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final contactProvider = Provider.of<ContactProvider>(context, listen: false);
      
      // Safety check to prevent infinite loops
      if (_syncAttempts > 2) {
        setState(() {
          _isLoading = false;
          _isSyncing = false;
        });
        return;
      }
      _syncAttempts++;
      
      // Use the providers' existing data instead of forcing reloads
      final contactProviderContacts = contactProvider.contacts;
      final transactionProviderContacts = transactionProvider.contacts;
      
      // Force a reload if either provider has empty contacts
      if (contactProviderContacts.isEmpty && _contacts.isNotEmpty) {
        print('HomeContent: ContactProvider empty but home has contacts, forcing reload');
        await contactProvider.loadContacts();
      }
      
      // Log for debugging
      print('HomeContent: Found ${contactProviderContacts.length} contacts in ContactProvider');
      print('HomeContent: Found ${transactionProviderContacts.length} contacts in TransactionProvider');
      
      // Create efficient map for lookup
      Map<String, Map<String, dynamic>> contactsMap = {};
      
      // Process ContactProvider contacts
      for (var contact in contactProviderContacts) {
        final phone = contact['phone'] as String?;
        if (phone != null && phone.isNotEmpty) {
          contactsMap[phone] = Map<String, dynamic>.from(contact);
        }
      }
      
      // Add any additional contacts from TransactionProvider
      for (var contact in transactionProviderContacts) {
        final phone = contact['phone'] as String?;
        if (phone != null && phone.isNotEmpty && !contactsMap.containsKey(phone)) {
          contactsMap[phone] = Map<String, dynamic>.from(contact);
        }
      }
      
      // Reset totals
      _cachedTotalToGive = 0.0;
      _cachedTotalToGet = 0.0;
      
      // Create new contacts list
      List<Map<String, dynamic>> newContacts = [];
      
      // Process all contacts
      for (final contact in contactsMap.values) {
        final phone = contact['phone'] as String?;
        if (phone == null || phone.isEmpty) continue;
        
        // Calculate balance with the latest transactions
        final balance = transactionProvider.calculateBalance(phone, includeInterest: false);
        
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
            continue; // Skip this contact if not matching search
          }
        }
        
        // Add this contact to our new contacts list
        newContacts.add(updatedContact);
      }
      
      // Apply sort to the new contacts list
      _applySortToContacts(newContacts);
      
      // Now update the state with the new contacts list
      if (mounted) {
        setState(() {
          // Clear and replace all at once to prevent flicker
          _contacts.clear();
          _contacts.addAll(newContacts);
          _isLoading = false;
          _isSyncing = false;
        });
        
        print('HomeContent: Updated UI with ${_contacts.length} contacts');
        
        // Force a commit of contact data to ensure it's persisted
        if (contactProviderContacts.isNotEmpty) {
          contactProvider.saveContactsNow();
        }
      }
    } catch (e) {
      // Handle any errors
      print('Error syncing contacts: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSyncing = false;
        });
      }
    } finally {
      // Make absolutely sure we reset the syncing lock
      if (mounted && _isSyncing) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }
  
  // Method to apply sort to a contacts list
  void _applySortToContacts(List<Map<String, dynamic>> contactsList) {
    // Sort contacts based on the selected sort mode
    switch (_sortMode) {
      case 'Recent':
        // Sort by lastEditedAt (newest first)
        contactsList.sort((a, b) {
          final aTime = a['lastEditedAt'] as DateTime?;
          final bTime = b['lastEditedAt'] as DateTime?;
          if (aTime == null && bTime == null) {
            return 0;
          } else if (aTime == null) {
            return 1; // null dates go last
          } else if (bTime == null) {
            return -1;
          }
          return bTime.compareTo(aTime);
        });
        break;
      case 'High to Low':
        // Sort by amount (highest first)
        contactsList.sort((a, b) {
          final aAmount = a['amount'] as double? ?? 0.0;
          final bAmount = b['amount'] as double? ?? 0.0;
          final result = bAmount.compareTo(aAmount);
          // If amounts are equal, sort by name for stable order
          return result != 0 ? result : (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? '');
        });
        break;
      case 'Low to High':
        // Sort by amount (lowest first)
        contactsList.sort((a, b) {
          final aAmount = a['amount'] as double? ?? 0.0;
          final bAmount = b['amount'] as double? ?? 0.0;
          final result = aAmount.compareTo(bAmount);
          // If amounts are equal, sort by name for stable order
          return result != 0 ? result : (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? '');
        });
        break;
      case 'By Name':
        // Sort alphabetically by name
        contactsList.sort((a, b) {
          final aName = (a['name'] as String? ?? '').toLowerCase();
          final bName = (b['name'] as String? ?? '').toLowerCase();
          return aName.compareTo(bName);
        });
        break;
    }
  }
  
  // Method to apply search and filtering
  void _applySearchAndFilter() {
    // Add the debounce for searches
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _syncContactsWithTransactions();
      }
    });
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
      floatingActionButton: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: FloatingActionButton(
        onPressed: _showAddContactDialog,
        backgroundColor: Colors.deepPurple,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          child: const Icon(Icons.person_add, color: Colors.white, size: 22),
        ),
          ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7D3AC1), Color(0xFF6A2FBA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A2FBA).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 2,
          ),
        ],
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
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
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
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
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
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      height: 46,
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
                child: TextField(
                  onChanged: (value) {
                    // Set the query immediately
                    _searchQuery = value;
                    
                    // Apply the search and filter with debounce
                    _applySearchAndFilter();
                  },
        decoration: InputDecoration(
          hintText: 'Find person by name or amount...',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 6),
            child: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
          isDense: true,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
        children: [
              Container(
                height: 24,
                width: 1,
                margin: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.grey.shade300,
              ),
              IconButton(
                icon: Icon(Icons.sort, color: Colors.grey.shade600, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: _showSortOptions,
              ),
              Container(
                height: 24,
                width: 1,
                margin: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.grey.shade300,
              ),
              IconButton(
                icon: Icon(Icons.qr_code_scanner, color: Colors.grey.shade600, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 15,
                  spreadRadius: 5,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              Icons.people_alt_outlined, 
              size: 80, 
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No contacts yet',
            style: TextStyle(
              fontSize: 20, 
              color: Colors.grey.shade700, 
              fontWeight: FontWeight.bold,
            ),
                    ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
            'Add a contact to track your payments',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
            onPressed: _showAddContactDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('Add Contact'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              ),
            ),
          ],
      ),
    );
  }
  
  Widget _buildContactsList() {
    return ListView.builder(
      itemCount: _contacts.length,
      padding: const EdgeInsets.only(bottom: 80), // Space for FAB
      itemBuilder: (context, index) {
        final contact = _contacts[index];
        final name = contact['name'] as String? ?? 'Unknown';
        final amount = contact['amount'] as double? ?? 0.0;
        final isGet = contact['isGet'] as bool? ?? true;
        final lastEditedAt = contact['lastEditedAt'] as DateTime?;
        
        // Create initials for avatar
        final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';
        
        // Get different colors for avatar background based on name
        final avatarColor = _getAvatarColor(name);
        final buttonColor = isGet ? Colors.green.shade100 : Colors.red.shade100;
        final textColor = isGet ? Colors.green.shade700 : Colors.red.shade700;
        final iconData = isGet ? Icons.arrow_downward : Icons.arrow_upward;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => _navigateToContactDetails(contact),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Avatar with 3D effect
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: avatarColor.withOpacity(0.3),
                          blurRadius: 4,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: avatarColor,
                      radius: 18,
                      child: Text(
                        initials, 
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Contact details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        if (lastEditedAt != null)
                          Text(
                            '${_getTimeAgo(lastEditedAt)}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                  
                  // Amount with 3D effect
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: buttonColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: buttonColor.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          iconData,
                          size: 14,
                          color: textColor,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '₹${amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: textColor,
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
  
  // Helper method to generate consistent colors based on name
  Color _getAvatarColor(String name) {
    if (name.isEmpty) return Colors.deepPurple;
    
    // Use a hash of the first character to determine a color
    final colorIndex = name.toLowerCase().codeUnitAt(0) % _avatarColors.length;
    return _avatarColors[colorIndex];
  }
  
  // List of colors for avatars
  final List<Color> _avatarColors = [
    Colors.deepPurple,
    Colors.blue,
    Colors.teal,
    Colors.indigo,
    Colors.green,
    Colors.orange,
    Colors.pink,
    Colors.blueGrey,
    Colors.amber.shade800,
    Colors.cyan.shade700,
  ];
  
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
            // Simply refresh contacts when a contact is added
            setState(() {
              _contacts.clear();
              _isLoading = true;
            });
            _syncContactsWithTransactions();
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${contact['name']} added successfully')),
            );
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
      setState(() {
        _contacts.clear();
        _isLoading = true;
      });
      _syncContactsWithTransactions();
    });
  }

  // New method to ensure contacts are properly loaded
  Future<void> _ensureContactsLoaded() async {
    if (!mounted) return;
    
    // Check both providers to see if contacts exist
    final contactProvider = Provider.of<ContactProvider>(context, listen: false);
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    
    // If contact provider is empty but transaction provider has contacts, sync them
    if (contactProvider.contacts.isEmpty && transactionProvider.contacts.isNotEmpty) {
      await contactProvider.loadContacts();
    }
    
    // If transaction provider is empty but contact provider has contacts, sync them
    if (transactionProvider.contacts.isEmpty && contactProvider.contacts.isNotEmpty) {
      await transactionProvider.syncContactsFromProvider(context);
    }
    
    // Finally, sync contacts with transactions to update the UI
    _syncContactsWithTransactions();
  }
}