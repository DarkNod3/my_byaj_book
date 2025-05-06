import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_byaj_book/screens/tools/diary_test_screen.dart';
import 'package:my_byaj_book/screens/milk_diary/milk_diary_screen.dart';
import 'package:my_byaj_book/screens/bill_diary/bill_diary_screen.dart';
import 'package:my_byaj_book/screens/home/home_screen.dart';
import 'package:my_byaj_book/screens/loan/loan_screen.dart';
import 'package:my_byaj_book/screens/card/card_screen.dart';
import 'package:my_byaj_book/providers/nav_preferences_provider.dart';
import 'package:my_byaj_book/screens/settings/nav_settings_screen.dart';
import 'package:my_byaj_book/screens/tea_diary/tea_diary_screen.dart';
import 'package:my_byaj_book/screens/tools/emi_calculator_screen.dart';
import 'package:my_byaj_book/screens/tools/sip_calculator_screen.dart';
import 'package:my_byaj_book/screens/tools/tax_calculator_screen.dart';
import 'package:my_byaj_book/screens/work_diary/work_diary_screen.dart';
import '../header/app_header.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NavPreferencesProvider>(
      builder: (context, navPrefs, _) {
        // Load preferences if they haven't been loaded
        if (!navPrefs.isLoaded) {
          Future.microtask(() => navPrefs.loadPreferences());
        }
        
        final navItems = navPrefs.selectedNavItems;
        
        return Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Home button (index 0)
              _buildNavItem(context, 0, navItems[0].icon, navItems[0].title),
              
              // First customizable button (index 1)
              if (navItems.length > 1)
                _buildNavItem(context, 1, navItems[1].icon, navItems[1].title),
              
              // Center tools button (index 2)
              _buildToolsButton(context),
              
              // Second customizable button (index 3)
              if (navItems.length > 2)
                _buildNavItem(context, 3, navItems[2].icon, navItems[2].title),
              
              // Third customizable button (index 4) - replaces Manage button
              if (navItems.length > 3)
                _buildNavItem(context, 4, navItems[3].icon, navItems[3].title),
            ],
          ),
        );
      }
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    final isSelected = currentIndex == index;
    
    return InkWell(
      onTap: () {
        print('Nav item tapped: $index with label: $label');
        onTap(index);
      },
      child: Container(
        width: 60,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected 
                ? Colors.blue.shade700
                : Colors.grey.shade600,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected 
                  ? Colors.blue.shade700
                  : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showToolsPopup(context),
      child: Container(
        width: 60,
        height: 60,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade500,
              Colors.blue.shade700,
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade300.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.grid_view_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  void _showToolsPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ToolsPopup(),
    );
  }
}

class ToolsPopup extends StatelessWidget {
  ToolsPopup({Key? key}) : super(key: key);

  // Group tools by category
  final Map<String, List<Map<String, dynamic>>> _toolCategories = {
    'Calculators': [
      {'icon': Icons.calculate_rounded, 'title': 'EMI Calc', 'color': Colors.purple, 'id': 'emi_calc'},
      {'icon': Icons.account_balance_wallet_rounded, 'title': 'SIP Calc', 'color': Colors.indigo, 'id': 'sip_calc'},
      {'icon': Icons.assignment_rounded, 'title': 'Tax Calc', 'color': Colors.red, 'id': 'tax_calc'},
    ],
    'Diaries': [
      {'icon': Icons.note_alt_rounded, 'title': 'Bills', 'color': Colors.blue.shade700, 'id': 'bill_diary'},
      {'icon': Icons.local_drink_rounded, 'title': 'Milk', 'color': Colors.amber.shade700, 'id': 'milk_diary'},
      {'icon': Icons.work_rounded, 'title': 'Work', 'color': Colors.blue, 'id': 'work_diary'},
      {'icon': Icons.emoji_food_beverage_rounded, 'title': 'Tea', 'color': Colors.deepPurple, 'id': 'tea_diary'},
    ],
    'Other': [
      {'icon': Icons.account_balance_rounded, 'title': 'Loans', 'color': Colors.blue, 'id': 'loans'},
      {'icon': Icons.credit_card_rounded, 'title': 'Cards', 'color': Colors.indigo, 'id': 'cards'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    // Get the currently selected nav items to filter them out from the tools popup
    final navPrefs = Provider.of<NavPreferencesProvider>(context, listen: false);
    // Create a list of IDs that are already in the bottom nav
    final selectedNavItemIds = navPrefs.selectedNavItems.map((item) => item.id).toList();
    
    // Flatten all tools into a single list and filter out those in navigation
    List<Map<String, dynamic>> availableTools = [];
    for (var category in _toolCategories.keys) {
      final tools = _toolCategories[category]!;
      availableTools.addAll(
        tools.where((tool) => !selectedNavItemIds.contains(tool['id']))
      );
    }
    
    // Sort tools alphabetically by title
    availableTools.sort((a, b) => a['title'].toString().compareTo(b['title'].toString()));
    
    return Container(
      padding: const EdgeInsets.only(top: 24, bottom: 24),
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'More Tools',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Access additional tools not in your bottom navigation',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: availableTools.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'All tools are in your navigation bar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You can customize your navigation in Settings',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: availableTools.length,
                  itemBuilder: (context, index) {
                    final tool = availableTools[index];
                    return _buildToolItem(
                      context,
                      icon: tool['icon'],
                      title: tool['title'],
                      color: tool['color'],
                      id: tool['id'],
                    );
                  },
                ),
          ),
          
          // Add button to manage navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const NavSettingsScreen())
                );
              },
              icon: const Icon(Icons.tune),
              label: const Text('Customize Navigation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required String id,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _navigateToTool(context, id);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _navigateToTool(BuildContext context, String id) {
    switch (id) {
      case 'emi_calc':
        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const EmiCalculatorScreen(showAppBar: true)));
        break;
      case 'sip_calc':
        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const SipCalculatorScreen(showAppBar: true)));
        break;
      case 'tax_calc':
        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const TaxCalculatorScreen(showAppBar: true)));
        break;
      case 'bill_diary':
        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const BillDiaryScreen()));
        break;
      case 'milk_diary':
        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const MilkDiaryScreen(showAppBar: true)));
        break;
      case 'work_diary':
        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const WorkDiaryScreen()));
        break;
      case 'tea_diary':
        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const TeaDiaryScreen(showAppBar: true)));
        break;
      case 'loans':
        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const LoanScreen(showAppBar: true)));
        break;
      case 'cards':
        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const CardScreen(showAppBar: true)));
        break;
    }
  }
}
