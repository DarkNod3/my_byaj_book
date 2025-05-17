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

// Add dummy MyApp class as requested
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Scaffold(body: Text('Test App')));
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
  
  // Add a static method that can be called from other files to refresh the home screen
  static void refreshHomeContent(BuildContext context) {
    // Find the home screen state
    final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
    if (homeScreenState != null) {
      // Try to find HomeContent state to refresh its contacts
      final homeContentState = homeScreenState._findHomeContentState(context);
      if (homeContentState != null) {
        homeContentState.setState(() {
          // Force a complete refresh
          homeContentState._withoutInterestContacts.clear();
          homeContentState._withInterestContacts.clear();
          homeContentState._syncContactsWithTransactions();
        });
      }
    }
  }
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  DateTime? _lastBackPressTime;
  
  // Timer for automatic backups
  Timer? _backupTimer;
  // App lifecycle observer
  late final AppLifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    _checkAndCreateAutomaticBackup();
    // Auto backup temporarily disabled
    // _setupAutomaticBackups();
    
    // Immediately start loading data to prevent blank screens
    _loadInitialData();
    
    // Add app lifecycle listener to refresh data when app resumes
    _lifecycleObserver = AppLifecycleObserver(
      onResume: () {
        // Find the HomeContent state and refresh its data
        final homeContentState = _findHomeContentState(context);
        if (homeContentState != null) {
          homeContentState.setState(() {
            homeContentState._withoutInterestContacts.clear();
            homeContentState._withInterestContacts.clear();
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
    _backupTimer?.cancel();
    _lifecycleObserver.dispose();
    super.dispose();
  }
  
  Future<void> _checkAndCreateAutomaticBackup() async {
    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      await transactionProvider.createAutomaticBackup();
      // Automatic backup created successfully
    } catch (e) {
      // Error during automatic backup - silent in release
    }
  }
  
  // Setup automatic backup timer - Commented out as it's unused
  /*
  void _setupAutomaticBackups() {
    // Feature temporarily disabled
    /*
    // Create an immediate backup when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createBackup();
    });
    
    // Schedule periodic backups every 30 minutes
    _backupTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      _createBackup();
    });
    */
  }
  
  // Create a backup of all app data
  Future<void> _createBackup() async {
    // Feature temporarily disabled
    /*
    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final success = await transactionProvider.createAutomaticBackup();
      
      if (success) {
        // Removed debug print
      } else {
        // Removed debug print
      }
    } catch (e) {
      // Removed debug print
    }
    */
  }
  */

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
        floatingActionButton: _currentIndex == 0 ? Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppTheme.primaryColor,
                Color.fromARGB(255, 124, 58, 237),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
            _showAddContactOptions(context);
          },
            borderRadius: BorderRadius.circular(30),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_add,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Add Person',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ) : null,
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            // Removed debug print
            
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

  void _showAddContactOptions(BuildContext context) {
    // Find HomeContent state to get the current tab (with interest or without interest)
    final homeContentState = _findHomeContentState(context);
    final bool isWithInterest = homeContentState?._isWithInterest ?? false;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectContactScreen(isWithInterest: isWithInterest),
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
    // Removed debug print
    
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
      // Removed debug print
      return screens.isNotEmpty ? screens.first : const HomeContent();
    }
  }

  // _createContact and related methods are unused - commenting out for now
  /* 
  void _createContact(BuildContext context, String name, String phone, bool withInterest) {
    // For without interest, directly show transaction entry dialog without asking for relationship type
    if (!withInterest) {
      _showTransactionEntryDialog(context, name, phone, withInterest, null);
    } else {
      // For with interest, show borrower/lender selection dialog
      _showBorrowerLenderSelectionDialog(context, name, phone);
    }
  }

  void _showBorrowerLenderSelectionDialog(BuildContext context, String name, String phone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Relationship'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Contact: $name'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildTypeButton(
                    context,
                    title: 'Borrower',
                    icon: Icons.person_outline,
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      _showTransactionEntryDialog(context, name, phone, true, 'borrower');
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTypeButton(
                    context,
                    title: 'Lender',
                    icon: Icons.account_balance,
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _showTransactionEntryDialog(context, name, phone, true, 'lender');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Borrower: They borrow money from you\nLender: They lend money to you',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionEntryDialog(BuildContext context, String name, String phone, bool withInterest, String? relationshipType) {
    // Determine which button to show first based on relationship type
    bool showGetFirst = relationshipType == 'lender'; // For lender, 'You'll Get' should be first
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(withInterest 
            ? 'With Interest ${relationshipType != null ? "(${StringUtils.capitalizeFirstLetter(relationshipType)})" : ""}' 
            : 'Without Interest Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Contact: $name'),
            const SizedBox(height: 16),
            Row(
              children: [
                // Conditionally order the buttons based on relationship type
                if (showGetFirst) ...[
                  // For lender: Get button first
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showAmountEntryDialog(context, name, phone, withInterest, true, relationshipType);
                    },
                    icon: const Icon(Icons.arrow_downward),
                    label: const Text('You\'ll Get'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade100,
                      foregroundColor: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showAmountEntryDialog(context, name, phone, withInterest, false, relationshipType);
                    },
                    icon: const Icon(Icons.arrow_upward),
                    label: const Text('You\'ll Give'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
                ] else ...[
                  // For borrower or non-interest: Give button first
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showAmountEntryDialog(context, name, phone, withInterest, false, relationshipType);
                      },
                      icon: const Icon(Icons.arrow_upward),
                      label: const Text('You\'ll Give'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade100,
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showAmountEntryDialog(context, name, phone, withInterest, true, relationshipType);
                      },
                      icon: const Icon(Icons.arrow_downward),
                      label: const Text('You\'ll Get'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade100,
                        foregroundColor: Colors.green,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAmountEntryDialog(BuildContext context, String name, String phone, bool withInterest, bool isGet, String? relationshipType) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController interestRateController = TextEditingController();
    // Default interest rate if needed
    if (withInterest) {
      interestRateController.text = '12';
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Amount'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                hintText: 'Enter amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            if (withInterest) ...[
              const SizedBox(height: 16),
              TextField(
                controller: interestRateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Interest Rate (% p.a.)',
                  hintText: 'Enter interest rate',
                  suffixText: '%',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Validate amount
              if (amountController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter an amount'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              
              final amount = double.tryParse(amountController.text) ?? 0.0;
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid amount'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              
              // Get interest rate if applicable
              double interestRate = 0;
              if (withInterest) {
                interestRate = double.tryParse(interestRateController.text) ?? 0;
                if (interestRate <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid interest rate'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }
              }
              
              // Use the new method to ensure contact is added
              _ensureContactAdded(
                name,
                phone,
                amount,
                isGet,
                withInterest,
                interestRate,
                relationshipType
              );
              
              // Close all dialogs and navigate back to home
              Navigator.popUntil(context, (route) => route.isFirst);
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Contact added ${withInterest ? "with" : "without"} interest'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  */

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
      element.visitChildren(visitor);
    }
    
    context.visitChildElements(visitor);
    return result;
  }
  
  // _buildTypeButton is unused - commenting out
  /*
  Widget _buildTypeButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  */

  // New function to ensure contacts are added even when HomeContent state can't be found
  void _ensureContactAdded(String name, String phone, double amount, bool isGet, bool withInterest, double interestRate, String? relationshipType) {
    // Check if contact with this phone number already exists
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final existingContact = transactionProvider.getContactById(phone);
    
    if (existingContact != null) {
      // Check if the contact is in the same tab type we're trying to add to
      final existingTabType = existingContact['tabType'] ?? 
          (existingContact['type'] != null ? 'withInterest' : 'withoutInterest');
      final newTabType = withInterest ? 'withInterest' : 'withoutInterest';
      
      // If the contact already exists in the same tab we're adding to, update it
      if (existingTabType == newTabType) {
        // Update the existing contact instead of adding a new one
        final updatedContact = Map<String, dynamic>.from(existingContact);
        
        // Update only certain fields to avoid overriding transaction data
        updatedContact['name'] = name;
        if (withInterest) {
          updatedContact['interestRate'] = interestRate;
          updatedContact['type'] = relationshipType ?? 'borrower';
        }
        
        // Always update the timestamp when modifying a contact
        updatedContact['lastEditedAt'] = DateTime.now();
        
        // Update the contact
        transactionProvider.updateContact(updatedContact);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact information updated'),
            duration: Duration(seconds: 2),
          ),
        );
        
        return;
      }
    }
    
    // Create contact data
    final nameInitials = name.split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').join('');
    final initials = nameInitials.isEmpty ? 'AA' : nameInitials.substring(0, min(2, nameInitials.length));
    final color = Colors.primaries[name.length % Colors.primaries.length];
    
    // Create a unique ID for the contact if it exists in the other tab
    String contactId = phone;
    if (existingContact != null) {
      // This contact exists in the other tab, so create a unique ID
      final newTabType = withInterest ? 'withInterest' : 'withoutInterest';
      contactId = "${phone}_$newTabType";
    }
    
    // Create contact map
    final contactMap = {
      'name': name,
      'phone': contactId, // Use potentially modified contactId here
      'displayPhone': phone, // Store the original phone for display purposes
      'initials': initials,
      'color': color,
      'amount': amount,
      'isGet': isGet,
      'daysAgo': 0,
      'lastEditedAt': DateTime.now(), // Always set a fresh timestamp for new contacts
      'tabType': withInterest ? 'withInterest' : 'withoutInterest', // Set tab type based on interest
    };
    
    // Add interest-related fields if applicable
    if (withInterest) {
      contactMap['interestRate'] = interestRate;
      contactMap['type'] = relationshipType ?? 'borrower'; // Default to borrower if not specified
    }
    
    // Add contact using the transaction provider
    transactionProvider.addContact(contactMap);
    
    // Try to find HomeContent state and update it too
    final homeContentState = _findHomeContentState(context);
    if (homeContentState != null) {
      homeContentState.addContact(
        name: name,
        phone: contactId, // Use the potentially modified contactId
        amount: amount,
        isGet: isGet,
        withInterest: withInterest,
        interestRate: interestRate,
        relationshipType: relationshipType ?? '',
        initials: initials,
        color: color,
      );
      
      // If this is a with-interest contact, make sure we switch to that tab
      if (withInterest) {
        homeContentState._tabController.animateTo(1); // Index 1 is the With Interest tab
      }
      
      // Force a rebuild of the HomeContent
      homeContentState.setState(() {});
    }
    
    // Ensure the home screen rebuilds
    setState(() {
      _currentIndex = 0; // Switch to home tab
    });
  }

  void _navigateToLoanScreen() {
    setState(() {
      _currentIndex = 3; // Switch to Loans tab
    });
  }
  
  void _navigateToToolsScreen() {
    setState(() {
      _currentIndex = 4; // Switch to Tools tab
    });
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isWithInterest = false;
  String _searchQuery = '';
  final String _interestViewMode = 'all'; // 'all', 'get', 'pay'
  String _filterMode = 'All'; // 'All', 'You received', 'You paid'
  String _sortMode = 'Recent'; // 'Recent', 'High to Low', 'Low to High', 'By Name'
  
  // Interest calculation variables
  double _interestToPay = 0.0;     // Interest to pay
  double _interestToReceive = 0.0; // Interest to receive
  double _principalToPay = 0.0;    // Principal to pay
  double _principalToReceive = 0.0; // Principal to receive
  
  // Add cached total values
  double _cachedTotalToGive = 0.0;
  double _cachedTotalToGet = 0.0;
  
  // Empty lists instead of sample data
  final List<Map<String, dynamic>> _withoutInterestContacts = [];
  final List<Map<String, dynamic>> _withInterestContacts = [];
  bool _isInitialized = false;

  // Method to refresh contacts and totals
  void refresh() {
    if (mounted) {
      setState(() {
        // Clear existing contacts to ensure fresh data
        _withoutInterestContacts.clear();
        _withInterestContacts.clear();
        _syncContactsWithTransactions();
        // Force rebuild UI
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging || _tabController.index != (_isWithInterest ? 1 : 0)) {
        setState(() {
          _isWithInterest = _tabController.index == 1;
          
          // Clear existing data for the target tab
          if (_isWithInterest) {
            _withInterestContacts.clear();
          } else {
            _withoutInterestContacts.clear();
          }
          
          // Force data reload immediately after tab change
          _syncContactsWithTransactions();
          
          // Update cached totals after data is loaded
          _updateCachedTotals();
        });
      }
    });
    
    // Delay to ensure the provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Clear any existing data first
      _withoutInterestContacts.clear();
      _withInterestContacts.clear();
      
      // Load fresh data
      _syncContactsWithTransactions();
      
      // Set up a second delayed load to ensure data is properly loaded
      // This helps when SharedPreferences is slow to initialize
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && (_isWithInterest ? _withInterestContacts.isEmpty : _withoutInterestContacts.isEmpty)) {
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
    // Sync contacts when dependencies change (like after adding transactions)
    if (!_isInitialized) {
      // Clear any existing data first
      _withoutInterestContacts.clear();
      _withInterestContacts.clear();
      
      // Load fresh data
      _syncContactsWithTransactions();
      _isInitialized = true;
      
      // Set up a delayed second load if needed
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && (_withoutInterestContacts.isEmpty && _withInterestContacts.isEmpty)) {
          setState(() {
            _syncContactsWithTransactions();
          });
        }
      });
    }
    
    // Set up a transaction provider listener to specifically update cached totals
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    // We'll use listen: false above and implement our own listener to control exactly what happens
    
    // First, remove any existing listeners to avoid duplicates
    transactionProvider.removeListener(_updateOnTransactionChange);
    
    // Add a new listener that will update cached totals and sync contacts
    transactionProvider.addListener(_updateOnTransactionChange);
  }
  
  // Method called when transaction provider changes
  void _updateOnTransactionChange() {
    if (mounted) {
      // Reset all accumulated values before recalculating to prevent doubling
      _principalToPay = 0.0;
      _principalToReceive = 0.0;
      _interestToPay = 0.0;
      _interestToReceive = 0.0;
      _cachedTotalToGive = 0.0;
      _cachedTotalToGet = 0.0;
      
      // Clear existing contacts to ensure fresh data
      _withoutInterestContacts.clear();
      _withInterestContacts.clear();
      
      // Restart from scratch with a clean slate
      _syncContactsWithTransactions();
    }
  }
  
  @override
  void dispose() {
    // Remove our transaction provider listener when widget is disposed
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    transactionProvider.removeListener(_updateOnTransactionChange);
    
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(HomeContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Force a refresh of data when the widget updates
    _syncContactsWithTransactions();
  }

  // New method to update contact amounts based on transaction data
  void _syncContactsWithTransactions() {
    if (!mounted) return;
    
    // Get transaction provider
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    
    // Get all contacts from the provider
    final allContacts = transactionProvider.contacts;
    if (allContacts.isEmpty) {
      // If there are no contacts in the provider, retry after a short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _syncContactsWithTransactions();
          });
        }
      });
      return;
    }
    
    // Reset totals before processing any contacts to prevent accumulation
    _principalToPay = 0.0;
    _principalToReceive = 0.0;
    _interestToPay = 0.0;
    _interestToReceive = 0.0;
    _cachedTotalToGive = 0.0;
    _cachedTotalToGet = 0.0;
    
    // Clear current contact lists to rebuild them
    _withoutInterestContacts.clear();
    _withInterestContacts.clear();
    
    // Process all contacts - for both tabs to ensure data is available
    for (final contact in allContacts) {
      final phone = contact['phone'] ?? '';
      if (phone.isEmpty) continue;
      
      // Get transactions for this contact
      final transactions = transactionProvider.getTransactionsForContact(phone);
      
      // Calculate balance - this is real money exchange recorded in transactions
      final balance = transactionProvider.calculateBalance(phone);
      
      // Update contact with calculated amount
      contact['amount'] = balance.abs();
      contact['isGet'] = balance >= 0;
      
      // Always add the contact to appropriate list, even if transactions are empty
      if (contact['type'] != null && (contact['type'] == 'borrower' || contact['type'] == 'lender')) {
        // With interest contacts
        _withInterestContacts.add(contact);
      } else {
        // Without interest contacts
        _withoutInterestContacts.add(contact);
      }
    }
    
    // Sort contacts by lastEditedAt (newest first)
    _withoutInterestContacts.sort((a, b) {
      final aTime = a['lastEditedAt'] as DateTime?;
      final bTime = b['lastEditedAt'] as DateTime?;
      if (aTime == null || bTime == null) {
        return 0;
      }
      return bTime.compareTo(aTime);
    });
    
    _withInterestContacts.sort((a, b) {
      final aTime = a['lastEditedAt'] as DateTime?;
      final bTime = b['lastEditedAt'] as DateTime?;
      if (aTime == null || bTime == null) {
        return 0;
      }
      return bTime.compareTo(aTime);
    });
    
    // For with-interest mode, calculate interest for all contacts
    if (_withInterestContacts.isNotEmpty) {
      _calculateInterestValues();
    }
    
    // Update cached totals based on current display mode
    _updateCachedTotals();
  }
  
  // Add a new helper method to apply search and filtering
  void _applySearchAndFilter() {
    // This method would handle search, filter, and sort logic
    // For now, we'll just handle basic search by name
    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      
      // Filter withoutInterest contacts
      _withoutInterestContacts.removeWhere((contact) {
        final name = (contact['name'] as String?)?.toLowerCase() ?? '';
        return !name.contains(lowerQuery);
      });
      
      // Filter withInterest contacts
      _withInterestContacts.removeWhere((contact) {
        final name = (contact['name'] as String?)?.toLowerCase() ?? '';
        return !name.contains(lowerQuery);
      });
    }
    
    // Apply sorting based on sort mode
    switch (_sortMode) {
      case 'Recent':
        // Sort by most recent transaction (lastEditedAt)
        _withoutInterestContacts.sort((a, b) {
          final DateTime aDate = a['lastEditedAt'] as DateTime? ?? DateTime(2000);
          final DateTime bDate = b['lastEditedAt'] as DateTime? ?? DateTime(2000);
          return bDate.compareTo(aDate); // Newest first
        });
        
        _withInterestContacts.sort((a, b) {
          final DateTime aDate = a['lastEditedAt'] as DateTime? ?? DateTime(2000);
          final DateTime bDate = b['lastEditedAt'] as DateTime? ?? DateTime(2000);
          return bDate.compareTo(aDate); // Newest first
        });
        break;
        
      case 'High to Low':
        // Sort by amount (highest first)
        _withoutInterestContacts.sort((a, b) {
          final double aAmount = a['amount'] as double? ?? 0.0;
          final double bAmount = b['amount'] as double? ?? 0.0;
          return bAmount.compareTo(aAmount);
        });
        
        _withInterestContacts.sort((a, b) {
          final double aAmount = a['amount'] as double? ?? 0.0;
          final double bAmount = b['amount'] as double? ?? 0.0;
          return bAmount.compareTo(aAmount);
        });
        break;
        
      case 'Low to High':
        // Sort by amount (lowest first)
        _withoutInterestContacts.sort((a, b) {
          final double aAmount = a['amount'] as double? ?? 0.0;
          final double bAmount = b['amount'] as double? ?? 0.0;
          return aAmount.compareTo(bAmount);
        });
        
        _withInterestContacts.sort((a, b) {
          final double aAmount = a['amount'] as double? ?? 0.0;
          final double bAmount = b['amount'] as double? ?? 0.0;
          return aAmount.compareTo(bAmount);
        });
        break;
        
      case 'By Name':
        // Sort alphabetically by name
        _withoutInterestContacts.sort((a, b) {
          final String aName = a['name'] as String? ?? '';
          final String bName = b['name'] as String? ?? '';
          return aName.compareTo(bName);
        });
        
        _withInterestContacts.sort((a, b) {
          final String aName = a['name'] as String? ?? '';
          final String bName = b['name'] as String? ?? '';
          return aName.compareTo(bName);
        });
        break;
    }
    
    // Apply filter mode if set to something other than 'All'
    if (_filterMode != 'All') {
      // For 'You received' filter, show only contacts where isGet is true
      if (_filterMode == 'You received') {
        _withoutInterestContacts.removeWhere((contact) => !(contact['isGet'] ?? false));
        _withInterestContacts.removeWhere((contact) => !(contact['isGet'] ?? false));
      }
      // For 'You paid' filter, show only contacts where isGet is false
      else if (_filterMode == 'You paid') {
        _withoutInterestContacts.removeWhere((contact) => contact['isGet'] ?? true);
        _withInterestContacts.removeWhere((contact) => contact['isGet'] ?? true);
      }
    }
  }

  // Calculate interest values for all with-interest contacts
  void _calculateInterestValues() {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    
    // Reset totals before calculation
    _interestToPay = 0.0;
    _interestToReceive = 0.0;
    _principalToPay = 0.0;
    _principalToReceive = 0.0;
    
    for (int i = 0; i < _withInterestContacts.length; i++) {
      final contact = _withInterestContacts[i];
      final phone = contact['phone'] ?? '';
      if (phone.isEmpty) continue;
      
      // Get contact type and transaction info
      final String contactType = contact['type'] as String? ?? 'borrower';
      final double interestRate = contact['interestRate'] as double? ?? 12.0;
      final bool isMonthly = contact['interestPeriod'] == 'monthly';
      
      final transactions = transactionProvider.getTransactionsForContact(phone);
        
      // If there are no transactions, skip interest calculation
      if (transactions.isEmpty) {
        // Reset interest values for this contact
        contact['interestDue'] = 0.0;
        contact['displayAmount'] = contact['amount'];
        continue;
      }
              
      // Calculate principal (use amount from contact which is already set)
      double principalAmount = contact['amount'] as double? ?? 0.0;
      
      // Calculate interest directly using helper method
      double totalInterestDue = _calculateInterestForContact(
        contact,
        transactions,
        interestRate,
        isMonthly,
        contactType
      );
      
      // Store the calculated interest value in the contact
      contact['interestDue'] = totalInterestDue;
      
      // Update the display amount to include interest
      contact['displayAmount'] = principalAmount + totalInterestDue;
      
      // Make sure we update the contact in the list
      _withInterestContacts[i] = contact;
      
      // Add to totals based on relationship type
      if (contactType == 'borrower') {
        // For borrowers, we get the money
        _principalToReceive += principalAmount;
        _interestToReceive += totalInterestDue;
      } else if (contactType == 'lender') {
        // For lenders, we pay the money
        _principalToPay += principalAmount;
        _interestToPay += totalInterestDue;
      }
    }
    
    // Always update cached totals after calculating interest
    _updateCachedTotals();
  }

  double get _totalToGive => _cachedTotalToGive;

  double get _totalToGet => _cachedTotalToGet;

  List<Map<String, dynamic>> get _filteredInterestContacts {
    if (_interestViewMode == 'all') {
      return _withInterestContacts;
    } else {
      return _withInterestContacts.where((contact) => 
        _interestViewMode == 'get' ? contact['isGet'] == true : 
        _interestViewMode == 'pay' ? contact['isGet'] == false : true).toList();
    }
  }

  List<Map<String, dynamic>> get _filteredContacts {
    // First get contacts from the right tab
    final contacts = _isWithInterest 
        ? _withInterestContacts 
        : _withoutInterestContacts;
    
    // Apply filtering
    List<Map<String, dynamic>> filtered = [];
    
    if (_isWithInterest) {
      // Apply 'With Interest' tab filtering
      if (_filterMode == 'Borrower') {
        filtered = contacts.where((contact) => contact['type'] == 'borrower').toList();
      } else if (_filterMode == 'Lender') {
        filtered = contacts.where((contact) => contact['type'] == 'lender').toList();
      } else {
        // 'All' filter - include everything
        filtered = List.from(contacts);
      }
    } else {
      // Apply 'Without Interest' tab filtering
      if (_filterMode == 'You received') {
        filtered = contacts.where((contact) => contact['isGet'] == true).toList();
      } else if (_filterMode == 'You paid') {
        filtered = contacts.where((contact) => contact['isGet'] == false).toList();
      } else {
        // 'All' filter - include everything
        filtered = List.from(contacts);
      }
    }
    
    // Apply search filtering
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((contact) => 
        contact['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // Apply sorting
    _applySorting(filtered);
    
    return filtered;
  }
  
  void _applySorting(List<Map<String, dynamic>> contacts) {
    switch (_sortMode) {
      case 'Recent':
        // Sort by lastEditedAt timestamp (most recent first)
        contacts.sort((a, b) {
          final DateTime aTime = a['lastEditedAt'] ?? DateTime.now().subtract(const Duration(days: 1000));
          final DateTime bTime = b['lastEditedAt'] ?? DateTime.now().subtract(const Duration(days: 1000));
          return bTime.compareTo(aTime); // Descending order (newest first)
        });
        break;
      case 'High to Low':
        contacts.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
        break;
      case 'Low to High':
        contacts.sort((a, b) => (a['amount'] as double).compareTo(b['amount'] as double));
        break;
      case 'By Name':
        contacts.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
        break;
    }
  }
  
  // Format a timestamp into a relative time string (e.g. "5 minutes ago", "1 hour ago", "2 days ago")
  String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    // Less than a minute
    if (difference.inMinutes < 1) {
      return "Just now";
    }
    // Less than an hour
    else if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return "$minutes ${minutes == 1 ? 'min' : 'min'} ago";
    }
    // Less than a day
    else if (difference.inDays < 1) {
      final hours = difference.inHours;
      return "$hours ${hours == 1 ? 'hr' : 'hrs'} ago";
    }
    // Less than a month
    else if (difference.inDays < 30) {
      final days = difference.inDays;
      return "$days ${days == 1 ? 'day' : 'days'} ago";
    }
    // Months
    else {
      final months = (difference.inDays / 30).floor();
      return "$months ${months == 1 ? 'mo' : 'mos'} ago";
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes in transaction provider to update UI when transactions change
    final transactionProvider = Provider.of<TransactionProvider>(context);
    
    // Ensure contacts are synchronized with transactions
    // This is crucial when the app first starts
    if ((_isWithInterest && _withInterestContacts.isEmpty) || 
        (!_isWithInterest && _withoutInterestContacts.isEmpty)) {
      // If no contacts are loaded yet, load them now
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            // Trigger a full refresh
            _syncContactsWithTransactions();
          });
        }
      });
    }
    
    return Column(
      children: [
        _buildTabBar(),
        Expanded(
          child: GestureDetector(
            // Add swipe gesture detection
            onHorizontalDragEnd: (details) {
              // Detect the direction of the swipe
              if (details.primaryVelocity! > 0) {
                // Swiping from left to right (go to previous tab)
                if (_tabController.index > 0) {
                  _tabController.animateTo(_tabController.index - 1);
                }
              } else if (details.primaryVelocity! < 0) {
                // Swiping from right to left (go to next tab)
                if (_tabController.index < _tabController.length - 1) {
                  _tabController.animateTo(_tabController.index + 1);
                }
              }
            },
            child: Column(
              children: [
                _buildBalanceSummary(),
                if (_isWithInterest) 
                  // Remove the interest type selector for With Interest tab
                  Container(),
                _buildSearchBar(),
                Expanded(
                  child: _buildContactsList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(20, 6, 20, 6),
            height: 42,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              onTap: (index) {
                // Force a refresh when tab is tapped (not just when animation completes)
                setState(() {
                  _isWithInterest = index == 1;
                  
                  // Clear existing data for the target tab to guarantee fresh data
                  if (_isWithInterest) {
                    _withInterestContacts.clear();
                  } else {
                    _withoutInterestContacts.clear();
                  }
                  
                  // Force immediate data reload
                  _syncContactsWithTransactions();
                });
              },
              indicatorColor: Colors.transparent,
              indicatorWeight: 0,
              dividerColor: Colors.transparent,
              indicatorPadding: EdgeInsets.zero,
              labelPadding: EdgeInsets.zero,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade700,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              tabs: const [
                Tab(
                  text: 'Standard Entries',
                  height: 36,
                ),
                Tab(
                  text: 'Interest Entries',
                  height: 36,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to format large currency values in a compact way
  String _formatCompactCurrency(double amount) {
    // Only abbreviate for amounts of 1 crore (10 million) or more
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
    } 
    // For all other amounts, use proper Indian number formatting
    else {
      final currencyFormat = NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: 2,
      );
      return currencyFormat.format(amount);
    }
  }
  
  Widget _buildBalanceSummary() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.9),
            AppTheme.primaryColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                            padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_upward_rounded,
                              color: Colors.white,
                              size: 16,
                          ),
                        ),
                          const SizedBox(width: 8),
                        const Text(
                            'You Will Pay',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                      const SizedBox(height: 8),
                    // Remove the original FittedBox display and keep only the white button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _formatCompactCurrency(_cachedTotalToGive),
                        style: TextStyle(
                          fontSize: _getButtonFontSize(_cachedTotalToGive),
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                      if (_isWithInterest) ...[
                        // Add small text below showing interest details
                        SizedBox(
                          height: 14,
                          child: FittedBox(
                          fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                          child: Text(
                            'P: ${_formatCompactCurrency(_principalToPay)} + I: ${_formatCompactCurrency(_interestToPay)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                  ],
                ),
              ),
              Container(
                  height: 50,
                width: 1,
                  color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                            padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_downward_rounded,
                              color: Colors.white,
                              size: 16,
                          ),
                        ),
                          const SizedBox(width: 8),
                        const Text(
                            'You Will Receive',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                      const SizedBox(height: 8),
                    // Remove the original FittedBox display and keep only the white button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _formatCompactCurrency(_cachedTotalToGet),
                        style: TextStyle(
                          fontSize: _getButtonFontSize(_cachedTotalToGet),
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                      if (_isWithInterest) ...[
                        // Add small text below showing interest details
                        SizedBox(
                          height: 14,
                          child: FittedBox(
                          fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                          child: Text(
                            'P: ${_formatCompactCurrency(_principalToReceive)} + I: ${_formatCompactCurrency(_interestToReceive)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                  ],
                ),
              ),
            ],
          ),
                ],
              ),
      ),
    );
  }
  
  // Helper method to determine font size based on amount
  double _getAdaptiveFontSize(double amount) {
    if (amount >= 10000000) { // ≥ 1 crore
      return 16;
    } else if (amount >= 1000000) { // ≥ 10 lakh
      return 18;
    } else if (amount >= 100000) { // ≥ 1 lakh
      return 20;
    } else {
      return 22;
    }
  }
  
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(
              Icons.search,
              color: Colors.grey.shade600,
              size: 20,
            ),
            Expanded(
              child: Focus(
                onFocusChange: (hasFocus) {
                  if (hasFocus) {
                    // When focused, scroll to top of the page to show more results
                    Scrollable.ensureVisible(
                      context,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      alignment: 0.0,
                    );
                  }
                },
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Find person by name or amount',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  style: const TextStyle(fontSize: 14),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  textInputAction: TextInputAction.search,
                  onTap: () {
                    // When tapped, also ensure visibility by scrolling
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Scrollable.ensureVisible(
                        context,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        alignment: 0.0,
                      );
                    });
                  },
                ),
              ),
            ),
            Container(
              height: 26,
              width: 1,
              color: Colors.grey.shade200,
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () {
                _showFilterOptions(context);
              },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.tune,
                    color: AppTheme.primaryColor,
                    size: 22,
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () {
                _showQRCodeOptions(context);
              },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    color: AppTheme.primaryColor,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showFilterOptions(BuildContext context) {
    // Use the current filter and sort modes as defaults
    String selectedFilter = _filterMode;
    String selectedSort = _sortMode;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter & Sort',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setStateModal(() {
                          selectedFilter = 'All';
                          selectedSort = 'Recent';
                        });
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Filter by',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Different filter options based on current tab
                if (_isWithInterest) ...[
                  // With Interest filter options - Borrower/Lender
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip(
                        label: 'All',
                        isSelected: selectedFilter == 'All',
                        onSelected: () => setStateModal(() => selectedFilter = 'All'),
                      ),
                      _buildFilterChip(
                        label: 'Borrower',
                        isSelected: selectedFilter == 'Borrower',
                        onSelected: () => setStateModal(() => selectedFilter = 'Borrower'),
                      ),
                      _buildFilterChip(
                        label: 'Lender',
                        isSelected: selectedFilter == 'Lender',
                        onSelected: () => setStateModal(() => selectedFilter = 'Lender'),
                      ),
                    ],
                  ),
                ] else ...[
                  // Without Interest filter options - You received/You paid
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip(
                        label: 'All',
                        isSelected: selectedFilter == 'All',
                        onSelected: () => setStateModal(() => selectedFilter = 'All'),
                      ),
                      _buildFilterChip(
                        label: 'You received',
                        isSelected: selectedFilter == 'You received',
                        onSelected: () => setStateModal(() => selectedFilter = 'You received'),
                      ),
                      _buildFilterChip(
                        label: 'You paid',
                        isSelected: selectedFilter == 'You paid',
                        onSelected: () => setStateModal(() => selectedFilter = 'You paid'),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),
                const Text(
                  'Sort by',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Simplified sort options
                _buildSortOption(
                  title: 'Recent',
                  isSelected: selectedSort == 'Recent',
                  onTap: () => setStateModal(() => selectedSort = 'Recent'),
                ),
                _buildSortOption(
                  title: 'High to Low',
                  isSelected: selectedSort == 'High to Low',
                  onTap: () => setStateModal(() => selectedSort = 'High to Low'),
                ),
                _buildSortOption(
                  title: 'Low to High',
                  isSelected: selectedSort == 'Low to High',
                  onTap: () => setStateModal(() => selectedSort = 'Low to High'),
                ),
                _buildSortOption(
                  title: 'By Name',
                  isSelected: selectedSort == 'By Name',
                  onTap: () => setStateModal(() => selectedSort = 'By Name'),
                ),
                
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      
                      // Apply the selected filters and sorting by setting state variables
                      setState(() {
                        _filterMode = selectedFilter;
                        _sortMode = selectedSort;
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Applied: $selectedFilter, $selectedSort'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
  
  Widget _buildSortOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryColor : Colors.black87,
                ),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                ? Center(
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  )
                : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsList() {
    return Container(
      color: AppTheme.backgroundColor,
      child: _filteredContacts.isEmpty
          ? Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FutureBuilder(
                      future: Future.delayed(const Duration(milliseconds: 300)),
                      builder: (context, snapshot) {
                        // Check if we need to try syncing contacts again after a short delay
                        if (snapshot.connectionState == ConnectionState.done && 
                            _filteredContacts.isEmpty &&
                            Provider.of<TransactionProvider>(context).contacts.isNotEmpty) {
                          // If provider has contacts but our list is empty, try syncing again
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) _syncContactsWithTransactions();
                          });
                        }
                        
                        // If we're still waiting or if we have no contacts after syncing
                        if (Provider.of<TransactionProvider>(context).contacts.isEmpty) {
                          // No contacts in the provider
                          return Column(
                            children: [
                              Icon(
                                Icons.person_add_alt_1_rounded,
                                size: 60,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No contacts added yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.secondaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add your first contact with the button below',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          );
                        } else {
                          // We have contacts in the provider but none are showing
                          return Column(
                            children: [
                              Icon(
                                Icons.person_search,
                                size: 60,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No contacts found',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.secondaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'Try a different search term'
                                    : 'Try changing the tab or filter',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              itemCount: _filteredContacts.length,
              padding: const EdgeInsets.only(bottom: 100), // For FAB clearance
              itemBuilder: (context, index) {
                final contact = _filteredContacts[index];
                return _buildContactItem(contact);
              },
            ),
    );
  }

  // Build an individual contact item in the list
  Widget _buildContactItem(Map<String, dynamic> contact) {
    final isGet = contact['isGet'];
    final phone = contact['phone'] ?? '';
    
    // Get last edited time and format it (update this to ensure consistent formatting)
    String timeText;
    if (contact.containsKey('lastEditedAt') && contact['lastEditedAt'] is DateTime) {
      // Use formatRelativeTime for all contacts to get consistent time display
      timeText = formatRelativeTime(contact['lastEditedAt']);
    } else {
      // Fallback to a default timestamp if no lastEditedAt is present
      contact['lastEditedAt'] = DateTime.now();
      timeText = 'Just now';
    }
    
    // Truncate long names to prevent pixel overflow
    final String originalName = contact['name'] ?? '';
    final String displayName = originalName.length > 15
        ? "${originalName.substring(0, 15)}..."
        : originalName;
    
    // Get transaction provider
    final transactionProvider = Provider.of<TransactionProvider>(context);
    
    // Get balance from transactions
    double originalBalance = contact['amount'] ?? 0.0;
    double displayAmount = originalBalance;
    
    // Get updated balance from transactions if available
    if (transactionProvider.getTransactionsForContact(phone).isNotEmpty) {
      final balance = transactionProvider.calculateBalance(phone);
      displayAmount = balance.abs();
      
      // Update showing status based on transaction balance
      bool showYouWillGet = balance >= 0;
      contact['isGet'] = showYouWillGet;
      
      // Update the local variable too
      // showYouWillGet = isGet;  // This line is incorrect - comment it out
    }
    
    // Calculate interest details if this is an interest-based contact
    double totalInterestDue = 0.0;
    double principalAmount = displayAmount;
    
    if (_isWithInterest && transactionProvider.getTransactionsForContact(phone).isNotEmpty) {
      // Get interest rate from contact
      final double interestRate = contact['interestRate'] as double? ?? 12.0;
      final String contactType = contact['type'] as String? ?? 'borrower';
      final bool isMonthly = contact['interestPeriod'] == 'monthly';
      
      // Get interest due from contact or calculate it if missing
      totalInterestDue = contact['interestDue'] as double? ?? 0.0;
      
      // If interest due is missing, calculate it
      if (totalInterestDue <= 0) {
        // Call calculateInterestForContact to get accurate interest
        totalInterestDue = _calculateInterestForContact(
          contact,
          transactionProvider.getTransactionsForContact(phone),
          interestRate,
          isMonthly,
          contactType
        );
        
        // Store it in the contact for future use
        contact['interestDue'] = totalInterestDue;
      }
      
      // Update the display amount to include interest
      contact['displayAmount'] = principalAmount + totalInterestDue;
    }
    
    // Format amount for display with compact notation for large values
    String amountText = _formatCompactCurrency(displayAmount);
    // Determine font size based on amount value
    double fontSize = 15.0;
    if (displayAmount >= 1000000) { // More than 10 lakhs
      fontSize = 13.0;
    } else if (displayAmount >= 100000) { // More than 1 lakh
      fontSize = 14.0;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              isGet 
                  ? Colors.green.shade50.withOpacity(0.5) 
                  : Colors.red.shade50.withOpacity(0.5),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContactDetailScreen(
                    contact: contact,
                    dailyInterestNote: '(${_getMonthAbbreviation()} - ${DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day} days)',
                  ),
                ),
              ).then((_) {
                setState(() {
                  // Force a full refresh when returning
                  _withoutInterestContacts.clear();
                  _withInterestContacts.clear();
                  _syncContactsWithTransactions();
                });
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Hero(
                        tag: 'avatar_${contact['phone']}',
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: contact['color'].withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: contact['color'],
                            child: Text(
                              contact['initials'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppTheme.textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 12,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  timeText,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (_isWithInterest) ...[
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.amber.shade200, width: 0.5),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.percent,
                                          size: 10,
                                          color: Colors.amber.shade800,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${contact['interestRate']} PA',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.amber.shade800,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(
                            width: 100, // Fixed width container
                            height: 22, // Fixed height for consistent UI
                            child: FittedBox(
                            fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                            child: Text(
                              amountText,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                  fontSize: fontSize,
                                color: isGet ? Colors.green.shade700 : Colors.red.shade700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isGet ? Colors.green.shade100 : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isGet ? Colors.green.shade300 : Colors.red.shade300,
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isGet ? Icons.arrow_downward : Icons.arrow_upward,
                                  size: 12,
                                  color: isGet ? Colors.green.shade700 : Colors.red.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isGet ? 'Receive' : 'Pay',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isGet ? Colors.green.shade700 : Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  if (_isWithInterest) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInterestBreakdownItem(
                            label: 'Principal',
                            amount: principalAmount,
                            iconData: Icons.attach_money_rounded,
                            color: Colors.indigo,
                          ),
                          Container(
                            height: 24,
                            width: 1,
                            color: Colors.grey.shade300,
                          ),
                          _buildInterestBreakdownItem(
                            label: 'Interest Due',
                            amount: totalInterestDue,
                            iconData: Icons.timeline,
                            color: Colors.orange.shade700,
                          ),
                          Container(
                            height: 24,
                            width: 1,
                            color: Colors.grey.shade300,
                          ),
                          _buildInterestBreakdownItem(
                            label: 'Total',
                            amount: principalAmount + totalInterestDue,
                            iconData: Icons.account_balance_wallet,
                            color: Colors.teal,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInterestBreakdownItem({
    required String label,
    required double amount,
    required IconData iconData,
    required Color color,
  }) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconData,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // Improved FittedBox with fixed height container
                SizedBox(
                  height: 14,
                  child: FittedBox(
                  fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                  child: Text(
                    _formatCompactCurrency(amount),
                    style: TextStyle(
                        fontSize: amount >= 100000 ? 8 : 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                      ),
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

  void _showContactOptions(BuildContext context, Map<String, dynamic> contact) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: contact['color'],
                  child: Text(
                    contact['initials'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      if (_isWithInterest)
                        Text(
                          'Interest: ${contact['interestRate']} PA',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: Colors.green),
              title: const Text('Add Transaction'),
              onTap: () {
                Navigator.pop(context);
                // Add transaction logic
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.blue),
              title: const Text('View Transaction History'),
              onTap: () {
                Navigator.pop(context);
                // View history logic
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.orange),
              title: const Text('Edit Contact'),
              onTap: () {
                Navigator.pop(context);
                // Edit contact logic
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Contact'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, contact);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Map<String, dynamic> contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Are you sure you want to delete ${contact['name']}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                if (_isWithInterest) {
                  _withInterestContacts.remove(contact);
                } else {
                  _withoutInterestContacts.remove(contact);
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${contact['name']} has been deleted'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Method to add a new contact
  void addContact({
    required String name,
    required String phone,
    required double amount,
    required bool isGet,
    required bool withInterest,
    required double interestRate,
    required String relationshipType,
    required String initials,
    required Color color,
  }) {
    final contactMap = {
      'name': name,
      'phone': phone,
      'initials': initials,
      'color': color,
      'amount': amount,
      'isGet': isGet,
      'daysAgo': 0,
    };
    
    if (withInterest) {
      contactMap['interestRate'] = interestRate;
      contactMap['type'] = relationshipType;
      
      setState(() {
        _withInterestContacts.add(contactMap);
        // Set tab to "With Interest" if not already
        if (!_isWithInterest) {
          _tabController.animateTo(1);
        }
      });
    } else {
      setState(() {
        _withoutInterestContacts.add(contactMap);
        // Set tab to "Without Interest" if not already
        if (_isWithInterest) {
          _tabController.animateTo(0);
        }
      });
    }
    
    // Use a longer delay and trigger multiple rebuilds to ensure contacts appear
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {});
        
        // Another rebuild after a short delay
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {});
          }
        });
      }
    });
  }

  // Add this new method for QR code management
  void _showQRCodeOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Payment QR Code',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                await _pickQRCodeImage();
                                Navigator.pop(context);
                                _showQRCodeOptions(context);
                              },
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await _deleteQRCode();
                                Navigator.pop(context);
                                _showQRCodeOptions(context);
                              },
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Set your QR code for receiving payments',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Check if QR code exists
                    FutureBuilder<String?>(
                      future: _getStoredQRCodePath(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        
                        final qrCodePath = snapshot.data;
                        
                        if (qrCodePath != null && qrCodePath.isNotEmpty) {
                          // Show existing QR code
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 200,
                                  maxHeight: 200,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300, width: 1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      // Show full screen image with zoom capability
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => Scaffold(
                                            appBar: AppBar(
                                              backgroundColor: Colors.black,
                                              iconTheme: const IconThemeData(color: Colors.white),
                                            ),
                                            backgroundColor: Colors.black,
                                            body: Center(
                                              child: InteractiveViewer(
                                                panEnabled: true,
                                                boundaryMargin: const EdgeInsets.all(20),
                                                minScale: 0.5,
                                                maxScale: 4.0,
                                                child: Image.file(
                                                  File(qrCodePath),
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(qrCodePath),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close', style: TextStyle(fontSize: 16)),
                              ),
                              const SizedBox(height: 10),
                            ],
                          );
                        } else {
                          // No QR code set yet
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 200,
                                  maxHeight: 200,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300, width: 1),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey.shade100,
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.qr_code,
                                          size: 64,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No QR code set',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await _pickQRCodeImage();
                                  Navigator.pop(context);
                                  _showQRCodeOptions(context);
                                },
                                icon: const Icon(Icons.upload),
                                label: const Text('Upload QR Code'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(height: 10),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  // Add methods to handle QR code storage
  Future<String?> _getStoredQRCodePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('payment_qr_code_path');
  }
  
  Future<void> _pickQRCodeImage() async {
    try {
      final imagePickerHelper = ImagePickerHelper();
      final imageFile = await imagePickerHelper.pickImage(context, ImageSource.gallery);
      
      if (imageFile != null) {
        // Save the image path to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('payment_qr_code_path', imageFile.path);
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('QR code uploaded successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading QR code: $e')),
        );
      }
    }
  }
  
  Future<void> _deleteQRCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('payment_qr_code_path');
      
      // No need to update the removed _qrCodePath variable
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR code deleted successfully')),
      );
    } catch (e) {
      // Removed debug print
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting QR code: $e')),
      );
    }
  }

  // Helper method to get month abbreviation
  String _getMonthAbbreviation() {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[now.month - 1]; // Month is 1-based, array is 0-based
  }

  // Helper method to calculate interest for an individual contact
  double _calculateInterestForContact(
    Map<String, dynamic> contact,
    List<Map<String, dynamic>> transactions,
    double interestRate,
    bool isMonthly,
    String contactType
  ) {
    // If there are no transactions, return 0
    if (transactions.isEmpty) {
      return 0.0;
    }
    
    // Sort transactions chronologically
    transactions.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    
    // Calculate interest using the transaction history
    DateTime? lastInterestDate = transactions.first['date'] as DateTime;
    double runningPrincipal = 0.0;
    double accumulatedInterest = 0.0;
    double interestPaid = 0.0;
    
    for (var tx in transactions) {
      final note = (tx['note'] ?? '').toLowerCase();
      final amount = tx['amount'] as double;
      final isGave = tx['type'] == 'gave';
      final txDate = tx['date'] as DateTime;
      
      // Calculate interest up to this transaction
      if (lastInterestDate != null && runningPrincipal > 0) {
        final daysSinceLastCalculation = txDate.difference(lastInterestDate).inDays;
        if (daysSinceLastCalculation > 0) {
          // Calculate interest based on complete months and remaining days
          double interestForPeriod = 0.0;
          
          if (isMonthly) {
            // Monthly interest calculation logic
            int completeMonths = 0;
            DateTime tempDate = DateTime(lastInterestDate.year, lastInterestDate.month, lastInterestDate.day);
            
            while (true) {
              // Try to add one month
              DateTime nextMonth = DateTime(tempDate.year, tempDate.month + 1, tempDate.day);
              
              // If adding one month exceeds the transaction date, break
              if (nextMonth.isAfter(txDate)) {
                break;
              }
              
              // Count this month and move to next
              completeMonths++;
              tempDate = nextMonth;
            }
            
            // Apply full monthly interest for complete months
            if (completeMonths > 0) {
              interestForPeriod += runningPrincipal * (interestRate / 100) * completeMonths;
            }
            
            // Add remaining days as fraction of a month
            final remainingDays = txDate.difference(tempDate).inDays;
            if (remainingDays > 0) {
              final daysInMonth = DateTime(tempDate.year, tempDate.month + 1, 0).day;
              double monthProportion = remainingDays / daysInMonth;
              interestForPeriod += runningPrincipal * (interestRate / 100) * monthProportion;
            }
          } else {
            // Yearly interest calculation converted to daily rate
            final dailyRate = interestRate / 365;
            interestForPeriod += runningPrincipal * (dailyRate / 100) * daysSinceLastCalculation;
          }
          
          accumulatedInterest += interestForPeriod;
        }
      }
      
      // Update based on transaction type
      if (note.contains('interest:')) {
        if (isGave) {
          // Interest payment made
          if (contactType == 'borrower') {
            // For borrowers: interest payment adds to accumulated interest
            accumulatedInterest += amount;
          } else {
            // For lenders: interest payment reduces accumulated interest
            accumulatedInterest = (accumulatedInterest - amount > 0) ? accumulatedInterest - amount : 0;
          }
        } else {
          // Interest payment received
          interestPaid += amount;
        }
      } else {
        // Principal transaction
        if (isGave) {
          // Payment sent
          if (contactType == 'borrower') {
            // For borrowers: principal payment adds to debt
            runningPrincipal += amount;
          } else {
            // For lenders: principal payment reduces debt
            runningPrincipal = (runningPrincipal - amount > 0) ? runningPrincipal - amount : 0;
          }
        } else {
          // Payment received
          if (contactType == 'borrower') {
            // For borrowers, receiving payment decreases principal
            runningPrincipal = (runningPrincipal - amount > 0) ? runningPrincipal - amount : 0;
          } else {
            // For lenders, receiving payment increases principal (lender gave money)
            runningPrincipal += amount;
          }
        }
      }
      
      lastInterestDate = txDate;
    }
    
    // Calculate interest from last transaction to now
    if (lastInterestDate != null && runningPrincipal > 0) {
      // Calculate interest from last transaction to today
      double interestFromLastTx = 0.0;
      final now = DateTime.now();
      
      if (isMonthly) {
        // Monthly interest calculation logic for current period
        int completeMonths = 0;
        DateTime tempDate = DateTime(lastInterestDate.year, lastInterestDate.month, lastInterestDate.day);
        
        while (true) {
          DateTime nextMonth = DateTime(tempDate.year, tempDate.month + 1, tempDate.day);
          if (nextMonth.isAfter(now)) {
            break;
          }
          completeMonths++;
          tempDate = nextMonth;
        }
        
        if (completeMonths > 0) {
          interestFromLastTx += runningPrincipal * (interestRate / 100) * completeMonths;
        }
        
        final remainingDays = now.difference(tempDate).inDays;
        if (remainingDays > 0) {
          final daysInMonth = DateTime(tempDate.year, tempDate.month + 1, 0).day;
          double monthProportion = remainingDays / daysInMonth;
          interestFromLastTx += runningPrincipal * (interestRate / 100) * monthProportion;
        }
      } else {
        // Yearly interest calculation for current period
        final daysSinceLastTx = now.difference(lastInterestDate).inDays;
        final dailyRate = interestRate / 365;
        interestFromLastTx += runningPrincipal * (dailyRate / 100) * daysSinceLastTx;
      }
      
      accumulatedInterest += interestFromLastTx;
    }
    
    // Adjust for interest already paid - show net interest due
    double totalInterestDue = (accumulatedInterest - interestPaid > 0) ? accumulatedInterest - interestPaid : 0;
    
    return totalInterestDue;
  }

  // Update cached total values
  void _updateCachedTotals() {
    if (_isWithInterest) {
      // For interest entries, use the pre-calculated values
      // The _principalToPay, _principalToReceive, _interestToPay, and _interestToReceive 
      // values should already be calculated in _calculateInterestValues
      
      // Simply set the final totals 
      _cachedTotalToGive = _principalToPay + _interestToPay;
      _cachedTotalToGet = _principalToReceive + _interestToReceive;
    } else {
      // For standard entries, reset and calculate the totals fresh each time
      _cachedTotalToGive = 0.0;
      _cachedTotalToGet = 0.0;
      
      // Use direct balance calculation for each contact
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);

      for (var contact in _withoutInterestContacts) {
        final phone = contact['phone'] ?? '';
        if (phone.isEmpty) continue;

        // Get transaction-based balance directly from provider
        final balance = transactionProvider.calculateBalance(phone);
        
        if (balance < 0) {
          _cachedTotalToGive += balance.abs();
        } else if (balance > 0) {
          _cachedTotalToGet += balance;
        }
      }
    }
  }

  // Helper method to determine font size for amount buttons based on the amount
  double _getButtonFontSize(double amount) {
    if (amount >= 10000000) { // ≥ 1 crore (always abbreviated)
      return 16.0;
    } else if (amount >= 1000000) { // ≥ 10 lakh
      return 14.0;
    } else if (amount >= 100000) { // ≥ 1 lakh
      return 15.0;
    } else {
      return 16.0; // Default size for smaller amounts
    }
  }
}

class SelectContactScreen extends StatefulWidget {
  const SelectContactScreen({super.key, required this.isWithInterest});

  final bool isWithInterest;

  @override
  State<SelectContactScreen> createState() => _SelectContactScreenState();
}

class _SelectContactScreenState extends State<SelectContactScreen> {
  String _searchQuery = '';
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;
  bool _hasPermission = false;

  // Helper method to find HomeContent state - added to fix the error
  _HomeContentState? _findHomeContentState(BuildContext context) {
    _HomeContentState? result;
    
    void visitor(Element element) {
      if (element.widget is HomeContent) {
        final state = (element as StatefulElement).state;
        if (state is _HomeContentState) {
          result = state;
        }
      }
      element.visitChildren(visitor);
    }
    
    context.visitChildElements(visitor);
    return result;
  }

  @override
  void initState() {
    super.initState();
    // Check permission status directly when the screen loads
    _checkAndRequestContactPermission();
  }

  // Replace _requestContactPermission with a more robust implementation
  Future<void> _checkAndRequestContactPermission() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Use the centralized permission utility
      final permissionUtils = PermissionUtils();
      final hasPermission = await permissionUtils.requestContactsPermission(context);
      
        setState(() {
        _hasPermission = hasPermission;
      });
      
      if (hasPermission) {
          await _loadContacts();
          // Force refresh of home screen when contacts are loaded
          _refreshHomeScreen();
        } else {
          setState(() {
            _isLoading = false;
          });
        }
    } catch (e) {
      // Error handling
      setState(() {
        _hasPermission = false;
        _isLoading = false;
      });
    }
  }
  
  // Add a helper method to refresh the home screen
  void _refreshHomeScreen() {
    // Find the home screen state to refresh contacts
    final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
    if (homeScreenState != null) {
      // Try to find HomeContent state to refresh its contacts
      final homeContentState = homeScreenState._findHomeContentState(context);
      if (homeContentState != null) {
        homeContentState.setState(() {
          // Force refresh
          homeContentState._syncContactsWithTransactions();
        });
      }
      
      // Force a refresh of the home screen itself
      homeScreenState.setState(() {});
      
      // Show a message to confirm contacts are loaded
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contacts loaded successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
        withThumbnail: false,
      );
      
      final formattedContacts = contacts
          .where((contact) => 
            contact.displayName.isNotEmpty && 
            contact.phones.isNotEmpty)
          .map((contact) => {
            'name': contact.displayName,
            'phone': contact.phones.first.number,
          }).toList();
      
      // Sort contacts by name
      formattedContacts.sort((a, b) => 
        a['name'].toString().compareTo(b['name'].toString()));
      
      setState(() {
        _contacts = formattedContacts;
        _isLoading = false;
      });
    } catch (e) {
      // Removed debug print
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  List<Map<String, dynamic>> get _filteredContacts {
    if (_searchQuery.isEmpty) {
      return _contacts;
    }
    return _contacts
        .where((contact) => contact['name']
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()) ||
            contact['phone']
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isWithInterest ? 'Add With Interest Contact' : 'Add Contact'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCreateNewButton(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !_hasPermission
                    ? _buildPermissionDeniedView()
                    : _buildContactList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search contacts...',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }
  
  Widget _buildCreateNewButton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: InkWell(
        onTap: () {
          _showAddContactDialog(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Create New Contact',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.primaryColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildContactList() {
    return _filteredContacts.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_search,
                  size: 60,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No contacts found',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            itemCount: _filteredContacts.length,
            padding: const EdgeInsets.only(bottom: 20),
            itemBuilder: (context, index) {
              final contact = _filteredContacts[index];
              return _buildContactItem(contact);
            },
          );
  }
  
  Widget _buildContactItem(Map<String, dynamic> contact) {
    // Check if this contact already exists in the transaction provider
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final phone = contact['phone'] ?? '';
    final existingContact = transactionProvider.getContactById(phone);
    final bool hasExistingInterestType = existingContact != null && 
        (existingContact['type'] != null || existingContact['interestRate'] != null);
    
    // For contacts from device, use a simpler display without transaction info
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: Colors.primaries[
          contact['name'].toString().length % Colors.primaries.length],
        child: Text(
          contact['name'].toString().isNotEmpty 
              ? contact['name'].toString().substring(0, 1).toUpperCase() 
              : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        contact['name'] ?? '',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        contact['phone'] ?? '',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 14,
        ),
      ),
      onTap: () {
        // Close select contact screen
        Navigator.pop(context);
        
        // Create a new contact and navigate to detail screen
        final name = contact['name'] ?? '';
        final phone = contact['phone'] ?? '';
        
        // If contact exists with interest type, respect that setting regardless of current tab
        if (hasExistingInterestType) {
          final contactData = Map<String, dynamic>.from(existingContact);
          _refreshHomeScreenAndNavigateToDetail(context, contactData);
        } 
        // Otherwise, if we're in the With Interest tab, show the relationship selection
        else if (widget.isWithInterest) {
          // Skip relationship selection dialog and create a borrower contact by default
          // The user can change the relationship type in the contact profile
          _createContactWithType(context, name, phone, 'borrower');
        } 
        // If we're in Without Interest tab, create a non-interest contact
        else {
          // Create a new contact map with required fields for ContactDetailScreen
          final contactData = {
            'name': name,
            'phone': phone,
            'initials': name.isNotEmpty ? name.substring(0, min(2, name.length)).toUpperCase() : 'AA',
            'color': Colors.primaries[name.length % Colors.primaries.length],
            'amount': 0.0,
            'isGet': true,
            'daysAgo': 0,
            'tabType': 'withoutInterest', // Explicitly mark this contact for the without interest tab
          };
          
          // Get transaction provider to add this contact if it doesn't exist
          transactionProvider.addContactIfNotExists(contactData);
          
          // Find the home screen state to refresh contacts
          _refreshHomeScreenAndNavigateToDetail(context, contactData);
        }
      },
    );
  }
  
  void _showRelationshipTypeDialog(BuildContext context, String name, String phone) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Relationship',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Contact: $name',
                style: const TextStyle(
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _createContactWithType(context, name, phone, 'borrower');
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red, width: 1.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_downward_rounded,
                                  color: Colors.red,
                                  size: 24,
                                ),
                                SizedBox(width: 6),
                                Icon(
                                  Icons.handshake_outlined,
                                  color: Colors.red,
                                  size: 24,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Borrower',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            Text(
                              'Lene Wale',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'They borrow money from you',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _createContactWithType(context, name, phone, 'lender');
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green, width: 1.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_upward_rounded,
                                  color: Colors.green,
                                  size: 24,
                                ),
                                SizedBox(width: 6),
                                Icon(
                                  Icons.account_balance_outlined,
                                  color: Colors.green,
                                  size: 24,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Lender',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              'Dene Wale',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'They lend money to you',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRelationshipCard({
    required String title,
    required String emoji,
    required Color color,
    required Color borderColor,
    required String description,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 36),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: borderColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  void _createContactWithType(BuildContext context, String name, String phone, String relationshipType) {
    // Check if contact with this phone number already exists in the other tab
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final existingContact = transactionProvider.getContactById(phone);
    
    // Generate a unique ID if necessary
    String contactId = phone;
    
    if (existingContact != null) {
      // Check if the contact is in a different tab than we're trying to add to
      final existingTabType = existingContact['tabType'] ?? 
          (existingContact['type'] != null ? 'withInterest' : 'withoutInterest');
      
      // We're creating a with-interest contact
      const newTabType = 'withInterest';
      
      if (existingTabType != newTabType) {
        // This contact exists in the other tab, so create a unique ID
        contactId = "${phone}_$newTabType";
      } else {
        // The contact exists in the same tab, update rather than create
        final updatedContact = Map<String, dynamic>.from(existingContact);
        updatedContact['name'] = name;
        updatedContact['type'] = relationshipType;
        updatedContact['interestRate'] = 12.0; // Default interest rate
        updatedContact['lastEditedAt'] = DateTime.now();
        
        // Update the contact
        transactionProvider.updateContact(updatedContact);
        
        // Navigate to edit screen
        _navigateToEditContact(context, updatedContact, transactionProvider);
        return;
      }
    }
    
    // Create contact data with interest type
    final contactData = {
      'name': name,
      'phone': contactId,
      'displayPhone': phone, // Store original phone if it's cross-tab
      'initials': name.isNotEmpty ? name.substring(0, min(2, name.length)).toUpperCase() : 'AA',
      'color': Colors.primaries[name.length % Colors.primaries.length],
      'amount': 0.0,
      'isGet': true,
      'daysAgo': 0,
      'type': relationshipType,
      'interestRate': 12.0, // Default interest rate
      'tabType': 'withInterest', // Explicitly mark this contact for the with interest tab
      'isNewContact': true, // Flag to indicate this is a newly created contact
    };
    
    // Get transaction provider to add this contact
    transactionProvider.addContactIfNotExists(contactData);
    
    // Navigate directly to edit contact screen instead of contact details with setup prompt
    _navigateToEditContact(context, contactData, transactionProvider);
  }
  
  void _navigateToEditContact(BuildContext context, Map<String, dynamic> contactData, TransactionProvider transactionProvider) {
    // Find the home screen state to refresh contacts
    final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
    if (homeScreenState != null) {
      // Try to find HomeContent state to refresh its contacts
      final homeContentState = homeScreenState._findHomeContentState(context);
      if (homeContentState != null) {
        homeContentState.setState(() {
          // Force refresh
          homeContentState._syncContactsWithTransactions();
          
          // If this is a with-interest contact, switch to with-interest tab
          if (contactData.containsKey('type')) {
            homeContentState._tabController.animateTo(1); // Index 1 is With Interest tab
          }
        });
      }
    }
    
    // Navigate directly to edit contact screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditContactScreen(
          contact: contactData,
          transactionProvider: transactionProvider,
        ),
      ),
    ).then((result) {
      // If contact was successfully updated, navigate to contact detail screen
      if (result == true) {
        // Get the updated contact
        final updatedContact = transactionProvider.getContactById(contactData['phone']);
        if (updatedContact != null) {
          // Navigate to contact detail screen with the updated contact
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContactDetailScreen(
                contact: updatedContact,
                showSetupPrompt: false, // No need for setup prompt since we already set up in edit screen
              ),
            ),
          );
        }
      }
      
      // Refresh the contacts list when returning
      if (homeScreenState != null) {
        final homeContentState = homeScreenState._findHomeContentState(context);
        if (homeContentState != null) {
          homeContentState.setState(() {
            homeContentState._syncContactsWithTransactions();
          });
        }
      }
    });
  }
  
  void _showAddContactDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.isWithInterest ? 'Add With Interest Contact' : 'Add New Contact'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Enter contact name',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number (Optional)',
                    hintText: 'Enter mobile number (optional)',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a name')),
                  );
                  return;
                }
                
                final phoneNumber = phoneController.text.trim();
                // Generate a unique ID for this contact using UUID if phone is empty
                final String contactId = phoneNumber.isEmpty 
                    ? 'contact_${DateTime.now().millisecondsSinceEpoch}'
                    : phoneNumber;
                
                // Get transaction provider
                  final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
                
                // Check if contact with this ID already exists
                final existingContact = transactionProvider.getContactById(contactId);
                
                if (existingContact != null) {
                      // Contact already exists in the same tab we're trying to add to,
                      // just update the existing contact
                      Navigator.pop(context);
                      
                        final contactData = Map<String, dynamic>.from(existingContact);
                        contactData['name'] = name;
                        contactData['lastEditedAt'] = DateTime.now();
                        
                        transactionProvider.updateContact(contactData);
                        _refreshHomeScreenAndNavigateToDetail(context, contactData);
                      return;
                  }
                  
                  Navigator.pop(context);
                  
                // Create new contact data
                    final contactData = {
                      'name': name,
                      'phone': contactId,
                  'displayPhone': phoneNumber.isEmpty ? 'No Phone' : phoneNumber,
                      'initials': name.isNotEmpty ? name.substring(0, min(2, name.length)).toUpperCase() : 'AA',
                      'color': Colors.primaries[name.length % Colors.primaries.length],
                      'amount': 0.0,
                      'isGet': true,
                      'daysAgo': 0,
                  'lastEditedAt': DateTime.now(),
                  'tabType': widget.isWithInterest ? 'withInterest' : 'withoutInterest',
                };
                
                // Add interest-related fields if applicable
                if (widget.isWithInterest) {
                  contactData['interestRate'] = 12.0; // Default interest rate
                  contactData['type'] = 'borrower'; // Default to borrower
                }
                
                // Add the contact
                    transactionProvider.addContactIfNotExists(contactData);
                    
                // Navigate to contact detail screen
                    _refreshHomeScreenAndNavigateToDetail(context, contactData);
              },
              child: const Text('Next'),
            ),
          ],
        );
      },
    );
  }
  
  void _refreshHomeScreenAndNavigateToDetail(BuildContext context, Map<String, dynamic> contact) {
    // Find the home content state to refresh contacts
    final homeContentState = _findHomeContentState(context);
      if (homeContentState != null) {
      // Update the contact list
      homeContentState.refresh();
    }
    
    // Navigate to the contact detail screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactDetailScreen(
          contact: contact,
          showSetupPrompt: false, // Skip setup prompt for all contacts
        ),
      ),
    );
  }
  
  Widget _buildPermissionDeniedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.no_accounts,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Contacts Permission Required',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Please allow permission to access your contacts in the app settings',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              await openAppSettings();
              
              // Wait longer for settings to fully update
              await Future.delayed(const Duration(seconds: 2));
              
              if (mounted) {
                // Check if permission was granted in settings
                final permissionStatus = await Permission.contacts.status;
                
                if (permissionStatus.isGranted) {
                  setState(() {
                    _hasPermission = true;
                  });
                  
                  // Load contacts and refresh home screen
                  await _loadContacts();
                  _refreshHomeScreen();
                  
                  // Show a success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Permission granted! Loading contacts...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  // Show an error message if permission is still denied
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Permission is still denied. Please grant contacts permission in settings.'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                  
                  // Recheck permission
                  _checkAndRequestContactPermission();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}

// Helper class to handle app lifecycle events
class AppLifecycleObserver with WidgetsBindingObserver {
  final VoidCallback? onResume;
  final VoidCallback? onPause;
  final VoidCallback? onInactive;
  final VoidCallback? onDetached;
  
  AppLifecycleObserver({
    this.onResume,
    this.onPause,
    this.onInactive,
    this.onDetached,
  }) {
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        onResume?.call();
        break;
      case AppLifecycleState.paused:
        onPause?.call();
        break;
      case AppLifecycleState.inactive:
        onInactive?.call();
        break;
      case AppLifecycleState.detached:
        onDetached?.call();
        break;
      default: 
        break;
    }
  }
  
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}
