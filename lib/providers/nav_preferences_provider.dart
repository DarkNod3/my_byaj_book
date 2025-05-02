import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NavItem {
  final String id;
  final String title;
  final IconData icon;
  final bool isFixed;

  NavItem({
    required this.id, 
    required this.title, 
    required this.icon,
    this.isFixed = false
  });
}

class NavPreferencesProvider with ChangeNotifier {
  final List<NavItem> _availableNavItems = [
    NavItem(id: 'home', title: 'Home', icon: Icons.home_rounded, isFixed: true),
    NavItem(id: 'loans', title: 'Loans', icon: Icons.account_balance_rounded),
    NavItem(id: 'cards', title: 'Cards', icon: Icons.credit_card_rounded),
    NavItem(id: 'bill_diary', title: 'Bill Diary', icon: Icons.receipt_long_rounded),
    NavItem(id: 'emi_calc', title: 'EMI Calc', icon: Icons.calculate_rounded),
    NavItem(id: 'land_calc', title: 'Land Calc', icon: Icons.landscape_rounded),
    NavItem(id: 'sip_calc', title: 'SIP Calc', icon: Icons.savings_rounded),
    NavItem(id: 'tax_calc', title: 'Tax Calc', icon: Icons.monetization_on_rounded),
    NavItem(id: 'milk_diary', title: 'Milk Diary', icon: Icons.local_drink_rounded),
    NavItem(id: 'work_diary', title: 'Work Diary', icon: Icons.work_rounded),
    NavItem(id: 'tea_diary', title: 'Tea Diary', icon: Icons.emoji_food_beverage_rounded),
  ];

  // Default nav items
  List<String> _selectedNavItemIds = [
    'home',
    'loans',
    'cards', 
    'bill_diary'
  ];

  bool _isLoaded = false;
  
  // Public getters
  bool get isLoaded => _isLoaded;
  
  // Return only available items that are not fixed
  List<NavItem> get availableNavItems {
    return _availableNavItems.where((item) => !item.isFixed).toList();
  }
  
  // Return all available items including fixed ones
  List<NavItem> get allNavItems => _availableNavItems;

  List<NavItem> get selectedNavItems {
    // Always include fixed items and then the selected ones
    List<NavItem> fixedItems = _availableNavItems.where((item) => item.isFixed).toList();
    
    List<NavItem> selectedItems = _selectedNavItemIds
        .where((id) => !fixedItems.any((item) => item.id == id)) // Don't duplicate fixed items
        .map((id) => _availableNavItems.firstWhere(
            (item) => item.id == id,
            orElse: () => _availableNavItems.firstWhere((item) => !item.isFixed)))
        .toList();
    
    return [...fixedItems, ...selectedItems];
  }

  bool isSelected(String id) {
    // A fixed item is always "selected"
    final navItem = _availableNavItems.firstWhere(
      (item) => item.id == id,
      orElse: () => NavItem(id: '', title: '', icon: Icons.error),
    );
    
    if (navItem.isFixed) {
      return true;
    }
    
    return _selectedNavItemIds.contains(id);
  }

  Future<void> loadPreferences() async {
    if (_isLoaded) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedNavItems = prefs.getStringList('selected_nav_items');
      
      if (savedNavItems != null && savedNavItems.isNotEmpty) {
        // Always ensure fixed items like 'home' are included
        final fixedItemIds = _availableNavItems
            .where((item) => item.isFixed)
            .map((item) => item.id)
            .toList();
        
        _selectedNavItemIds = [
          ...fixedItemIds,
          ...savedNavItems.where((id) => !fixedItemIds.contains(id))
        ];
      }
      
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      print('Error loading navigation preferences: $e');
    }
  }

  Future<void> savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('selected_nav_items', _selectedNavItemIds);
    } catch (e) {
      print('Error saving navigation preferences: $e');
    }
  }

  Future<void> toggleNavItem(String id) async {
    // Don't allow toggling fixed items
    final navItem = _availableNavItems.firstWhere(
      (item) => item.id == id,
      orElse: () => NavItem(id: '', title: '', icon: Icons.error),
    );
    
    if (navItem.isFixed) {
      return;
    }
    
    if (_selectedNavItemIds.contains(id)) {
      // Don't allow removing the last item
      if (_selectedNavItemIds.length > 1) {
        _selectedNavItemIds.remove(id);
      }
    } else {
      // Maximum 4 items in the nav bar (including fixed items and tools button)
      final fixedItemsCount = _availableNavItems.where((item) => item.isFixed).length;
      if (_selectedNavItemIds.length < 4) {
        _selectedNavItemIds.add(id);
      }
    }
    
    await savePreferences();
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    // Make sure to include fixed items
    final fixedItemIds = _availableNavItems
        .where((item) => item.isFixed)
        .map((item) => item.id)
        .toList();
    
    _selectedNavItemIds = [
      ...fixedItemIds,
      'loans', 
      'cards', 
      'bill_diary'
    ];
    
    // Ensure we don't exceed 4 items total (including tools button)
    if (_selectedNavItemIds.length > 4) {
      _selectedNavItemIds = _selectedNavItemIds.sublist(0, 4);
    }
    
    await savePreferences();
    notifyListeners();
  }
} 