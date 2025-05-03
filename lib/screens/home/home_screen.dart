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
import 'package:my_byaj_book/screens/tools/diary_test_screen.dart';
import 'package:my_byaj_book/screens/reminder/reminder_screen.dart';
import 'package:my_byaj_book/screens/history/history_screen.dart';
import 'package:my_byaj_book/screens/contact/contact_detail_screen.dart';
import 'package:my_byaj_book/widgets/bottom_nav/bottom_navigation.dart';
import 'package:my_byaj_book/widgets/header/app_header.dart';
import 'package:my_byaj_book/widgets/navigation/navigation_drawer.dart';
import 'package:my_byaj_book/widgets/user_profile_card.dart';
import 'package:my_byaj_book/constants/app_theme.dart';
import 'package:my_byaj_book/utils/string_utils.dart';
import 'package:provider/provider.dart';
import 'package:my_byaj_book/providers/nav_preferences_provider.dart';
import 'package:my_byaj_book/screens/settings/nav_settings_screen.dart';
import 'package:my_byaj_book/providers/transaction_provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:my_byaj_book/screens/tea_diary/tea_diary_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:my_byaj_book/screens/settings/settings_screen.dart';
import 'package:my_byaj_book/screens/contact/edit_contact_screen.dart';
import 'package:my_byaj_book/screens/tools/emi_calculator_screen.dart';
import 'package:my_byaj_book/screens/tools/land_calculator_screen.dart';
import 'package:my_byaj_book/screens/tools/sip_calculator_screen.dart';
import 'package:my_byaj_book/screens/tools/tax_calculator_screen.dart';
import 'package:my_byaj_book/providers/card_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  DateTime? _lastBackPressTime;
  
  // Timer for automatic backups
  Timer? _backupTimer;

  @override
  void initState() {
    super.initState();
    // Auto backup temporarily disabled
    // _setupAutomaticBackups();
  }
  
  @override
  void dispose() {
    _backupTimer?.cancel();
    super.dispose();
  }
  
  // Setup automatic backup timer
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
        debugPrint('Automatic backup created successfully');
      } else {
        debugPrint('Failed to create automatic backup');
      }
    } catch (e) {
      debugPrint('Error during automatic backup: $e');
    }
    */
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

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavPreferencesProvider>(context);
    
    // Create a map of screen IDs to screen widgets
    final Map<String, Widget> screenMap = {
      'home': const HomeContent(),
      'loans': const LoanScreen(),
      'cards': const CardScreen(),
      'bill_diary': const BillDiaryScreen(showAppBar: false),
      'milk_diary': const MilkDiaryScreen(showAppBar: false),
      'work_diary': const WorkDiaryScreen(showAppBar: false),
      'tea_diary': const TeaDiaryScreen(),
      'tools': const MoreToolsScreen(),
      'emi_calc': const EmiCalculatorScreen(showAppBar: false),
      'land_calc': const LandCalculatorScreen(showAppBar: false),
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
                IconButton(
                  icon: Consumer<CardProvider>(
                    builder: (context, cardProvider, child) {
                      // Check for upcoming card payment due dates
                      int upcomingCardDueDates = 0;
                      
                      // Find cards with due dates coming up in the next 5 days
                      for (final card in cardProvider.cards) {
                        if (card['dueDate'] != null && card['dueDate'] != 'N/A') {
                          try {
                            // Parse the due date
                            final String dueDateStr = card['dueDate'] as String;
                            final parts = dueDateStr.split(' ');
                            
                            if (parts.length >= 3) {
                              final int day = int.tryParse(parts[0]) ?? 1;
                              final String monthName = parts[1].replaceAll(',', '');
                              
                              // Get month number
                              final List<String> monthNames = [
                                'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                              ];
                              final int month = monthNames.indexOf(monthName) + 1;
                              
                              // Create date for current month's due date
                              final now = DateTime.now();
                              DateTime dueDate = DateTime(now.year, now.month, day);
                              
                              // If the day has already passed, use next month
                              if (dueDate.isBefore(now)) {
                                dueDate = DateTime(now.year, now.month + 1, day);
                              }
                              
                              // Check if the due date is within the next 5 days
                              final difference = dueDate.difference(now).inDays;
                              if (difference >= 0 && difference <= 5) {
                                upcomingCardDueDates++;
                              }
                            }
                          } catch (e) {
                            print('Error parsing due date: $e');
                          }
                        }
                      }
                      
                      // Return the appropriate icon with a badge if needed
                      if (upcomingCardDueDates > 0) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(Icons.notifications, color: Colors.white, size: 24),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 14,
                                  minHeight: 14,
                                ),
                                child: Text(
                                  '$upcomingCardDueDates',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        );
                      } else {
                        return const Icon(Icons.notifications, color: Colors.white, size: 24);
                      }
                    },
                  ),
                  tooltip: 'Reminders',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReminderScreen(),
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
        floatingActionButton: _currentIndex == 0 ? FloatingActionButton.extended(
          onPressed: () {
            _showAddContactOptions(context);
          },
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text(
            'Add Contact',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ) : null,
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            print('Bottom nav onTap called with index: $index. Available screens: ${selectedScreens.length}');
            
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
    print('Getting active screen for index: $_currentIndex, available screens: ${screens.length}');
    
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
      print('Warning: Adjusted index $adjustedIndex is out of bounds for screens list of length ${screens.length}. Using first screen instead.');
      return screens.isNotEmpty ? screens.first : const HomeContent();
    }
  }

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
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
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
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
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

  // New function to ensure contacts are added even when HomeContent state can't be found
  void _ensureContactAdded(String name, String phone, double amount, bool isGet, bool withInterest, double interestRate, String? relationshipType) {
    // Create contact data
    final nameInitials = name.split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').join('');
    final initials = nameInitials.isEmpty ? 'AA' : nameInitials.substring(0, min(2, nameInitials.length));
    final color = Colors.primaries[name.length % Colors.primaries.length];
    
    // Create contact map
    final contactMap = {
      'name': name,
      'phone': phone,
      'initials': initials,
      'color': color,
      'amount': amount,
      'isGet': isGet,
      'daysAgo': 0,
      'tabType': withInterest ? 'withInterest' : 'withoutInterest', // Set tab type based on interest
    };
    
    // Add interest-related fields if applicable
    if (withInterest) {
      contactMap['interestRate'] = interestRate;
      contactMap['type'] = relationshipType ?? 'borrower'; // Default to borrower if not specified
    }
    
    // Add contact using the transaction provider
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    transactionProvider.addContact(contactMap);
    
    // Try to find HomeContent state and update it too
    final homeContentState = _findHomeContentState(context);
    if (homeContentState != null) {
      homeContentState.addContact(
        name: name,
        phone: phone,
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
  String _interestViewMode = 'all'; // 'all', 'borrower', 'lender'
  String? _qrCodePath; // Add this variable for QR code path
  
  // Interest calculation variables
  double _totalPrincipal = 0.0;
  double _totalInterestDue = 0.0;
  double _interestPerDay = 0.0;
  final double _dailyInterestRate = 65.0; // ₹65 per day as mentioned by user
  
  // Empty lists instead of sample data
  final List<Map<String, dynamic>> _withoutInterestContacts = [];
  final List<Map<String, dynamic>> _withInterestContacts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _isWithInterest = _tabController.index == 1;
      });
    });
    
    // Delay to ensure the provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncContactsWithTransactions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // New method to update contact amounts based on transaction data
  void _syncContactsWithTransactions() {
    // Get transaction provider
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    
    // Get all contacts from the provider
    final allContacts = transactionProvider.contacts;
    
    // Clear existing contact lists to rebuild them properly
    _withoutInterestContacts.clear();
    _withInterestContacts.clear();
    
    // Process each contact from provider to ensure it's in our local lists
    for (var providerContact in allContacts) {
      final phone = providerContact['phone'] ?? '';
      if (phone.isEmpty) continue;
      
      // Determine if this is a "with interest" contact
      final isWithInterest = providerContact['type'] != null || providerContact['interestRate'] != null;
      
      // Make a copy of the contact to work with
      final contactCopy = Map<String, dynamic>.from(providerContact);
      
      // Ensure the contact has a tabType field that marks which tab it belongs to
      if (!contactCopy.containsKey('tabType')) {
        contactCopy['tabType'] = isWithInterest ? 'withInterest' : 'withoutInterest';
        
        // Update the contact in the provider to persist this change
        transactionProvider.updateContact(contactCopy);
      }
      
      // Only add contacts to their respective tabs based on tabType
      final String tabType = contactCopy['tabType'] ?? (isWithInterest ? 'withInterest' : 'withoutInterest');
      
      if (tabType == 'withInterest') {
        // Add to with-interest list only
        _withInterestContacts.add(contactCopy);
      } else if (tabType == 'withoutInterest') {
        // Add to without-interest list only
        _withoutInterestContacts.add(contactCopy);
      }
    }
    
    // Update amounts for non-interest contacts
    for (var contact in _withoutInterestContacts) {
      final phone = contact['phone'] ?? '';
      if (phone.isEmpty) continue;
      
      final transactions = transactionProvider.getTransactionsForContact(phone);
      if (transactions.isNotEmpty) {
        // Update the contact's amount based on transaction balance
        double balance = transactionProvider.calculateBalance(phone);
        
        // Update the daysAgo based on the most recent transaction
        final mostRecentTransaction = transactions.first; // Assuming newest first
        if (mostRecentTransaction['date'] is DateTime) {
          final transactionDate = mostRecentTransaction['date'] as DateTime;
          final today = DateTime.now();
          final difference = today.difference(transactionDate).inDays;
          contact['daysAgo'] = difference;
        }
        
        // Update the contact's amount and isGet property
        contact['amount'] = balance.abs();
        contact['isGet'] = balance >= 0;
      }
    }
    
    // Update amounts for with-interest contacts
    for (var contact in _withInterestContacts) {
      final phone = contact['phone'] ?? '';
      if (phone.isEmpty) continue;
      
      final transactions = transactionProvider.getTransactionsForContact(phone);
      if (transactions.isNotEmpty) {
        // Update the contact's amount based on transaction balance
        double balance = transactionProvider.calculateBalance(phone);
        
        // Update the daysAgo based on the most recent transaction
        final mostRecentTransaction = transactions.first; // Assuming newest first
        if (mostRecentTransaction['date'] is DateTime) {
          final transactionDate = mostRecentTransaction['date'] as DateTime;
          final today = DateTime.now();
          final difference = today.difference(transactionDate).inDays;
          contact['daysAgo'] = difference;
        }
        
        // Update the contact's amount and isGet property
        contact['amount'] = balance.abs();
        contact['isGet'] = balance >= 0;
      }
    }
    
    // Calculate interest for interest-based contacts
    _calculateInterestValues();
    
    // Force a rebuild
    setState(() {});
  }

  // Calculate interest values for all with-interest contacts
  void _calculateInterestValues() {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    DateTime now = DateTime.now();
    
    // Reset totals before calculation
    _totalPrincipal = 0.0;
    _totalInterestDue = 0.0;
    _interestPerDay = 0.0;
    
    for (var contact in _withInterestContacts) {
      final phone = contact['phone'] ?? '';
      if (phone.isEmpty) continue;
      
      // Skip if there are no transactions
      final transactions = transactionProvider.getTransactionsForContact(phone);
      if (transactions.isEmpty) continue;
      
      // Get the principal amount (balance)
      final double balance = contact['isGet'] 
          ? contact['amount'] as double 
          : -(contact['amount'] as double);
          
      // Add to total principal
      _totalPrincipal += balance.abs();
      
      // Calculate daily interest for this contact
      double contactInterestPerDay = 0.0;
      
      // Get interest rate from contact
      final double interestRate = contact['interestRate'] as double? ?? 12.0;
      
      // Calculate daily rate based on contact's interest rate (convert annual rate to daily)
      contactInterestPerDay = interestRate / 365 / 100 * balance.abs();
      
      // Add to total interest per day
      _interestPerDay += contactInterestPerDay;
      
      // Get the first transaction date (loan start date)
      transactions.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
      final DateTime loanStartDate = transactions.first['date'] as DateTime;
      
      // Calculate days since loan started
      int daysSinceLoan = now.difference(loanStartDate).inDays;
      
      // Calculate total interest due for this contact
      double contactInterestDue = contactInterestPerDay * daysSinceLoan;
      
      // Check if there are partial payments to reduce interest
      double totalPaid = 0.0;
      for (var transaction in transactions) {
        if (transaction['isPaid'] == true) {
          totalPaid += (transaction['amount'] as double).abs();
        }
      }
      
      // If principal has been partially paid, adjust interest due
      if (totalPaid > 0) {
        // Calculate what percentage of principal has been paid
        final double originalPrincipal = balance.abs() + totalPaid;
        final double paidPrincipalRatio = totalPaid / originalPrincipal;
        
        // Adjust interest by proportion of principal paid
        contactInterestDue *= (1 - paidPrincipalRatio);
      }
      
      // Add this contact's interest to total interest due
      _totalInterestDue += contactInterestDue;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sync contacts when dependencies change (like after adding transactions)
    _syncContactsWithTransactions();
  }

  double get _totalToGive {
    double total = 0;
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final contacts = _isWithInterest ? _filteredInterestContacts : _withoutInterestContacts;

    for (var contact in contacts) {
      final phone = contact['phone'] ?? '';
      if (phone.isEmpty) continue;

      // Get transaction-based balance if available
      if (transactionProvider.getTransactionsForContact(phone).isNotEmpty) {
        final balance = transactionProvider.calculateBalance(phone);
        // If balance is negative, it means "You'll Give"
        if (balance < 0) {
          total += balance.abs();
        }
      } else if (!contact['isGet']) {
        // Otherwise, use the static amount only for "You'll Give" contacts
        total += contact['amount'] as double;
      }
    }
    return total;
  }

  double get _totalToGet {
    double total = 0;
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final contacts = _isWithInterest ? _filteredInterestContacts : _withoutInterestContacts;

    for (var contact in contacts) {
      final phone = contact['phone'] ?? '';
      if (phone.isEmpty) continue;

      // Get transaction-based balance if available
      if (transactionProvider.getTransactionsForContact(phone).isNotEmpty) {
        final balance = transactionProvider.calculateBalance(phone);
        // If balance is positive, it means "You'll Get"
        if (balance > 0) {
          total += balance;
        }
      } else if (contact['isGet']) {
        // Otherwise, use the static amount only for "You'll Get" contacts
        total += contact['amount'] as double;
      }
    }
    return total;
  }

  List<Map<String, dynamic>> get _filteredInterestContacts {
    if (_interestViewMode == 'all') {
      return _withInterestContacts;
    } else {
      return _withInterestContacts.where((contact) => 
        contact['type'] == _interestViewMode).toList();
    }
  }

  List<Map<String, dynamic>> get _filteredContacts {
    final contacts = _isWithInterest 
        ? _filteredInterestContacts 
        : _withoutInterestContacts;
    
    // Create a copy for sorting
    final sortedContacts = List<Map<String, dynamic>>.from(contacts);
    
    // Sort by daysAgo (recent first)
    sortedContacts.sort((a, b) {
      final daysAgoA = a['daysAgo'] as int? ?? 0;
      final daysAgoB = b['daysAgo'] as int? ?? 0;
      return daysAgoA.compareTo(daysAgoB); // Ascending order (0 = today, most recent first)
    });
        
    if (_searchQuery.isEmpty) {
      return sortedContacts;
    }
    return sortedContacts
        .where((contact) => contact['name']
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes in transaction provider to update UI when transactions change
    Provider.of<TransactionProvider>(context);
    
    // Ensure contacts are synchronized with transactions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncContactsWithTransactions();
      }
    });
    
    return Column(
      children: [
        _buildTabBar(),
        _buildBalanceSummary(),
        if (_isWithInterest) _buildInterestTypeSelector(),
        _buildSearchBar(),
        Expanded(
          child: _buildContactsList(),
        ),
      ],
    );
  }

  Widget _buildInterestTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.filter_alt_outlined,
                size: 18,
                color: AppTheme.textColor,
              ),
              const SizedBox(width: 8),
              const Text(
                'Filter by Type',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.info_outline,
                size: 18,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                'Select a category',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                _buildInterestTypeOption('All', 'all'),
                _buildInterestTypeOption('Borrowers', 'borrower'),
                _buildInterestTypeOption('Lenders', 'lender'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestTypeOption(String label, String value) {
    final isSelected = _interestViewMode == value;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _interestViewMode = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            boxShadow: isSelected ? [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ] : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    value == 'all' ? Icons.list_alt :
                    value == 'borrower' ? Icons.person_outline :
                    Icons.account_balance,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.secondaryTextColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
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
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.2),
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
                borderRadius: BorderRadius.circular(7),
              ),
              indicatorColor: Colors.transparent,
              indicatorWeight: 0,
              dividerColor: Colors.transparent,
              indicatorPadding: EdgeInsets.zero,
              labelPadding: EdgeInsets.zero,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.primaryColor,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              tabs: const [
                Tab(
                  text: 'Without Interest',
                  height: 36,
                ),
                Tab(
                  text: 'With Interest',
                  height: 36,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSummary() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
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
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.arrow_upward_rounded,
                            color: AppTheme.accentColor,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'You will give',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${_totalToGive.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.grey.shade200,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.arrow_downward_rounded,
                            color: AppTheme.secondaryColor,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'You will get',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${_totalToGet.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Add interest details section when on With Interest tab
          if (_isWithInterest) ...[
            // Interest summary card removed as requested
          ],
          
          const SizedBox(height: 8),
          if (_totalToGet > 0 || _totalToGive > 0)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppTheme.infoColor,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _totalToGet > _totalToGive 
                          ? 'You will get net ₹${(_totalToGet - _totalToGive).abs().toStringAsFixed(2)}'
                          : 'You will give net ₹${(_totalToGive - _totalToGet).abs().toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.secondaryTextColor,
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
  
  Widget _buildInterestInfoItem({
    required String title, 
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 12,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        height: 46,
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
        child: Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search Customer',
                  hintStyle: TextStyle(
                    color: AppTheme.secondaryTextColor,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                ),
                style: const TextStyle(fontSize: 14),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                textInputAction: TextInputAction.search,
              ),
            ),
            Container(
              height: 26,
              width: 1,
              color: Colors.grey.shade200,
            ),
            IconButton(
              icon: const Icon(Icons.filter_list, color: AppTheme.secondaryTextColor, size: 18),
              tooltip: 'Filter',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
              onPressed: () {
                _showFilterOptions(context);
              },
            ),
            IconButton(
              icon: const Icon(Icons.qr_code_scanner, color: AppTheme.primaryColor, size: 18),
              tooltip: 'Payment QR',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
              onPressed: () {
                _showQRCodeOptions(context);
              },
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
  
  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
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
            const Text(
              'Sort & Filter',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 24),
            _buildFilterOption(
              title: 'Sort by Name',
              icon: Icons.sort_by_alpha,
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  // Implement sort by name
                  _withoutInterestContacts.sort((a, b) => 
                    a['name'].toString().compareTo(b['name'].toString()));
                  _withInterestContacts.sort((a, b) => 
                    a['name'].toString().compareTo(b['name'].toString()));
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sorted by name'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            _buildFilterOption(
              title: 'Sort by Amount (High to Low)',
              icon: Icons.arrow_downward,
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  // Implement sort by amount high to low
                  _withoutInterestContacts.sort((a, b) => 
                    b['amount'].compareTo(a['amount']));
                  _withInterestContacts.sort((a, b) => 
                    b['amount'].compareTo(a['amount']));
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sorted by amount (High to Low)'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            _buildFilterOption(
              title: 'Sort by Amount (Low to High)',
              icon: Icons.arrow_upward,
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  // Implement sort by amount low to high
                  _withoutInterestContacts.sort((a, b) => 
                    a['amount'].compareTo(b['amount']));
                  _withInterestContacts.sort((a, b) => 
                    a['amount'].compareTo(b['amount']));
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sorted by amount (Low to High)'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            _buildFilterOption(
              title: 'Sort by Latest Activity',
              icon: Icons.access_time,
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  // Implement sort by date
                  _withoutInterestContacts.sort((a, b) => 
                    a['daysAgo'].compareTo(b['daysAgo']));
                  _withInterestContacts.sort((a, b) => 
                    a['daysAgo'].compareTo(b['daysAgo']));
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sorted by latest activity'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFilterOption({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildContactsList() {
    return Container(
      color: AppTheme.backgroundColor,
      child: _filteredContacts.isEmpty
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
                  const SizedBox(height: 8),
                  Text(
                    'Try a different search term',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
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

  Widget _buildContactItem(Map<String, dynamic> contact) {
    final isGet = contact['isGet'];
    final daysAgo = contact['daysAgo'];
    final daysText = daysAgo == 0 ? 'Today' : '$daysAgo days ago';
    final contactType = contact['type'];
    final phone = contact['phone'] ?? '';
    final name = contact['name'] ?? '';
    
    // Get transaction provider
    final transactionProvider = Provider.of<TransactionProvider>(context);
    
    // Get balance from transactions
    double originalBalance = 0.0;
    double balanceFromTransactions = 0.0;
    
    if (phone.isNotEmpty) {
      balanceFromTransactions = transactionProvider.calculateBalance(phone);
      
      // The original amount (what was set when creating the contact)
      originalBalance = contact['amount'] as double;
    }
    
    // Decide whether to use transaction-based balance or original balance
    double displayAmount;
    bool showYouWillGet = false;
    
    if (phone.isNotEmpty && transactionProvider.getTransactionsForContact(phone).isNotEmpty) {
      // Use transaction-based balance
      displayAmount = balanceFromTransactions.abs();
      // Determine if it's "You'll Get" or "You'll Give" based on sign
      showYouWillGet = balanceFromTransactions > 0;
    } else {
      // Use original balance if no transactions
      displayAmount = originalBalance;
      showYouWillGet = isGet;
    }
    
    // Calculate interest details if this is an interest-based contact
    double interestPerDay = 0.0;
    double totalInterestDue = 0.0;
    double principalAmount = displayAmount;
    
    if (_isWithInterest && transactionProvider.getTransactionsForContact(phone).isNotEmpty) {
      // Get interest rate from contact
      final double interestRate = contact['interestRate'] as double? ?? 12.0;
      final String contactType = contact['type'] as String? ?? 'borrower';
      
      // Sort transactions chronologically for accurate interest calculation
      final transactions = transactionProvider.getTransactionsForContact(phone);
      transactions.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
      
      // INTEREST CALCULATION LOGIC:
      // --------------------------
      // For both borrowers and lenders, we calculate interest in the same way:
      // 1. Interest accrues daily on the outstanding principal
      // 2. Interest payments are tracked separately and don't reduce principal
      // 3. Principal payments reduce future interest by reducing the outstanding amount
      // 4. Total interest due = accumulated interest - interest payments received
      
      // Calculate interest using a similar approach to the contact detail screen
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
            final interestForPeriod = runningPrincipal * interestRate / 100 / 365 * daysSinceLastCalculation;
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
        final daysUntilNow = DateTime.now().difference(lastInterestDate).inDays;
        final interestFromLastTx = runningPrincipal * interestRate / 100 / 365 * daysUntilNow;
        accumulatedInterest += interestFromLastTx;
      }
      
      // Update display values
      principalAmount = runningPrincipal;
      totalInterestDue = accumulatedInterest > interestPaid ? accumulatedInterest - interestPaid : 0;
      interestPerDay = runningPrincipal * interestRate / 100 / 365;
      
      // Update the display amount to include interest if appropriate
      if (contactType == 'lender' || contactType == 'borrower') {
        displayAmount = principalAmount + totalInterestDue;
      }
    }
    
    final amountText = '₹${displayAmount.toStringAsFixed(2)}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 2,
      shadowColor: AppTheme.primaryColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.1)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContactDetailScreen(contact: contact),
            ),
          ).then((_) {
            // Force refresh when returning from contact detail
            setState(() {});
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 18,
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
                      if (_isWithInterest && contactType != null)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: contactType == 'borrower' ? AppTheme.secondaryColor : AppTheme.accentColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: Icon(
                              contactType == 'borrower' ? Icons.person_outline : Icons.account_balance,
                              color: Colors.white,
                              size: 8,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 10,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              daysText,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_isWithInterest) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.percent,
                                      size: 8,
                                      color: Colors.amber.shade800,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${contact['interestRate']}% p.a.',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.amber.shade800,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (contactType != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: contactType == 'borrower' 
                                        ? AppTheme.secondaryColor.withOpacity(0.1)
                                        : AppTheme.accentColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    StringUtils.capitalizeFirstLetter(contactType),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: contactType == 'borrower' ? AppTheme.secondaryColor : AppTheme.accentColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        amountText,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: showYouWillGet ? AppTheme.secondaryColor : AppTheme.accentColor,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: showYouWillGet ? AppTheme.secondaryColor.withOpacity(0.1) : AppTheme.accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          showYouWillGet ? 'You\'ll Get' : 'You\'ll Give',
                          style: TextStyle(
                            color: showYouWillGet ? AppTheme.secondaryColor : AppTheme.accentColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Add interest breakdown for with interest contacts
              if (_isWithInterest && totalInterestDue > 0) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber.shade100),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInterestBreakdownItem(
                        label: 'Principal',
                        amount: principalAmount,
                        iconData: Icons.money,
                        color: AppTheme.primaryColor,
                      ),
                      Container(
                        height: 20,
                        width: 1,
                        color: Colors.amber.shade200,
                      ),
                      _buildInterestBreakdownItem(
                        label: 'Interest Due',
                        amount: totalInterestDue,
                        iconData: Icons.monetization_on,
                        color: Colors.orange,
                      ),
                      Container(
                        height: 20,
                        width: 1,
                        color: Colors.amber.shade200,
                      ),
                      _buildInterestBreakdownItem(
                        label: 'Per Day',
                        amount: interestPerDay,
                        iconData: Icons.today,
                        color: Colors.amber.shade800,
                      ),
                    ],
                  ),
                ),
              ],
            ],
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
                Text(
                  '₹${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
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
                          'Interest: ${contact['interestRate']}% p.a.',
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
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          tooltip: 'Close',
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
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(qrCodePath),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 16,
                                runSpacing: 10,
                                alignment: WrapAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      await _pickQRCodeImage();
                                      Navigator.pop(context);
                                      _showQRCodeOptions(context);
                                    },
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Change QR'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      await _deleteQRCode();
                                      Navigator.pop(context);
                                      _showQRCodeOptions(context);
                                    },
                                    icon: const Icon(Icons.delete),
                                    label: const Text('Delete'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
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
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        // Save the image path to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('payment_qr_code_path', pickedFile.path);
        
        // Update state if needed
        setState(() {
          _qrCodePath = pickedFile.path;
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR code uploaded successfully')),
        );
      }
    } catch (e) {
      print('Error picking QR code: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading QR code: $e')),
      );
    }
  }
  
  Future<void> _deleteQRCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('payment_qr_code_path');
      
      setState(() {
        _qrCodePath = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR code deleted successfully')),
      );
    } catch (e) {
      print('Error deleting QR code: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting QR code: $e')),
      );
    }
  }

  void _showContactTypeSelectionDialog(BuildContext context, String name, String phone) {
    // Create a new contact map with required fields for ContactDetailScreen
    final contact = {
      'name': name,
      'phone': phone,
      'initials': name.isNotEmpty ? name.substring(0, min(2, name.length)).toUpperCase() : 'AA',
      'color': Colors.primaries[name.length % Colors.primaries.length],
      'amount': 0.0,
      'isGet': true,
      'daysAgo': 0,
    };
    
    // Get transaction provider to add this contact if it doesn't exist
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    transactionProvider.addContactIfNotExists(contact);
    
    // Navigate directly to contact detail screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactDetailScreen(contact: contact),
      ),
    );
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
      // First check if we already have permission
      final permissionStatus = await Permission.contacts.status;
      
      if (permissionStatus.isGranted) {
        // Permission already granted, load contacts
        setState(() {
          _hasPermission = true;
        });
        _loadContacts();
        return;
      }
      
      // If permission is denied but not permanently, request it
      if (permissionStatus.isDenied) {
        final result = await FlutterContacts.requestPermission();
        setState(() {
          _hasPermission = result;
        });
        
        if (result) {
          _loadContacts();
        } else {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }
      
      // If permission is permanently denied, we can only ask user to open settings
      setState(() {
        _hasPermission = false;
        _isLoading = false;
      });
    } catch (e) {
      print('Error checking contact permission: $e');
      setState(() {
        _hasPermission = false;
        _isLoading = false;
      });
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
      print('Error loading contacts: $e');
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
                decoration: BoxDecoration(
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
              Icon(
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
          final contactData = Map<String, dynamic>.from(existingContact!);
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
                            Row(
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
                            Text(
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
                            Text(
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
                            Row(
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
                            Text(
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
                            Text(
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
    // Create contact data with interest type
    final contactData = {
      'name': name,
      'phone': phone,
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
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
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
                    labelText: 'Mobile Number',
                    hintText: 'Enter mobile number',
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
                if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                  Navigator.pop(context);
                  
                  final name = nameController.text;
                  final phone = phoneController.text;
                  
                  if (widget.isWithInterest) {
                    // For with interest contacts, show the relationship type dialog
                    _showRelationshipTypeDialog(context, name, phone);
                  } else {
                    // For without interest contacts, create contact directly
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
                    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
                    transactionProvider.addContactIfNotExists(contactData);
                    
                    // Refresh home screen and navigate to detail
                    _refreshHomeScreenAndNavigateToDetail(context, contactData);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Next'),
            ),
          ],
        );
      },
    );
  }
  
  void _refreshHomeScreenAndNavigateToDetail(BuildContext context, Map<String, dynamic> contactData) {
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
          if (contactData['tabType'] == 'withInterest') {
            homeContentState._tabController.animateTo(1); // Index 1 is With Interest tab
          } else {
            homeContentState._tabController.animateTo(0); // Index 0 is Without Interest tab
          }
        });
      }
    }
    
    // Navigate to contact detail screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactDetailScreen(contact: contactData),
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
              // Check if permission was granted after returning from settings
              await Future.delayed(const Duration(seconds: 1));
              if (mounted) {
                _checkAndRequestContactPermission();
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
