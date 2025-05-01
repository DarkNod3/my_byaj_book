import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NavItem {
  final String id;
  final String title;
  final IconData icon;

  NavItem({
    required this.id, 
    required this.title, 
    required this.icon,
  });
}

class NavPreferencesProvider with ChangeNotifier {
  // All available tools
  final List<NavItem> _allTools = [
    NavItem(id: 'loans', title: 'Loans', icon: Icons.account_balance_rounded),
    NavItem(id: 'cards', title: 'Cards', icon: Icons.credit_card_rounded),
    NavItem(id: 'bill_diary', title: 'Bill Diary', icon: Icons.receipt_long_rounded),
    NavItem(id: 'emi_calc', title: 'EMI Calculator', icon: Icons.calculate_rounded),
    NavItem(id: 'land_calc', title: 'Land Calculator', icon: Icons.landscape_rounded),
    NavItem(id: 'sip_calc', title: 'SIP Calculator', icon: Icons.savings_rounded),
    NavItem(id: 'tax_calc', title: 'Tax Calculator', icon: Icons.monetization_on_rounded),
    NavItem(id: 'milk_diary', title: 'Milk Diary', icon: Icons.local_drink_rounded),
    NavItem(id: 'work_diary', title: 'Work Diary', icon: Icons.work_rounded),
    NavItem(id: 'tea_diary', title: 'Tea Diary', icon: Icons.emoji_food_beverage_rounded),
  ];

  // Fixed home item
  final NavItem _homeItem = NavItem(id: 'home', title: 'Home', icon: Icons.home_rounded);

  // Default selected tool IDs (first 3)
  List<String> _selectedToolIds = [
    'loans',
    'cards',
    'bill_diary',
  ];

  bool _isLoaded = false;
  
  // Public getters
  bool get isLoaded => _isLoaded;
  NavItem get homeItem => _homeItem;
  List<NavItem> get allTools => _allTools;
  
  // Get the selected tools (max 3)
  List<NavItem> get selectedTools {
    return _selectedToolIds
        .take(3) // Ensure only max 3 selected
        .map((id) => _allTools.firstWhere(
            (tool) => tool.id == id,
            orElse: () => _allTools.first))
        .toList();
  }
  
  // Get the unselected tools
  List<NavItem> get unselectedTools {
    return _allTools
        .where((tool) => !_selectedToolIds.contains(tool.id))
        .toList();
  }
  
  // Check if a tool is selected
  bool isSelected(String id) {
    return _selectedToolIds.contains(id);
  }

  // Load user preferences
  Future<void> loadPreferences() async {
    if (_isLoaded) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTools = prefs.getStringList('selectedTools');
      
      if (savedTools != null && savedTools.isNotEmpty) {
        // Filter to ensure only valid tool IDs are included
        _selectedToolIds = savedTools
            .where((id) => _allTools.any((tool) => tool.id == id))
            .take(3) // Limit to max 3 tools
            .toList();
      }
      
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      print('Error loading navigation preferences: $e');
    }
  }

  // Save user preferences
  Future<void> savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('selectedTools', _selectedToolIds);
    } catch (e) {
      print('Error saving navigation preferences: $e');
    }
  }

  // Add a tool to selected tools
  Future<void> addTool(String id) async {
    // Check if tool exists and isn't already selected
    final toolExists = _allTools.any((tool) => tool.id == id);
    if (!toolExists || _selectedToolIds.contains(id)) {
      return;
    }
    
    // Add tool and limit to max 3
    _selectedToolIds.add(id);
    if (_selectedToolIds.length > 3) {
      _selectedToolIds = _selectedToolIds.take(3).toList();
    }
    
    await savePreferences();
    notifyListeners();
  }
  
  // Remove a tool from selected tools
  Future<void> removeTool(String id) async {
    if (_selectedToolIds.contains(id)) {
      _selectedToolIds.remove(id);
      await savePreferences();
      notifyListeners();
    }
  }
  
  // Reorder tools
  Future<void> reorderTools(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _selectedToolIds.length ||
        newIndex < 0 || newIndex >= _selectedToolIds.length) {
      return;
    }
    
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final item = _selectedToolIds.removeAt(oldIndex);
    _selectedToolIds.insert(newIndex, item);
    
    await savePreferences();
    notifyListeners();
  }
  
  // Reset to default tools
  Future<void> resetToDefaults() async {
    _selectedToolIds = [
      'loans',
      'cards',
      'bill_diary',
    ];
    
    await savePreferences();
    notifyListeners();
  }
} 