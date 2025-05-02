import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_byaj_book/screens/tools/diary_test_screen.dart';
import 'package:my_byaj_book/screens/tools/milk_diary_screen.dart';
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
import 'package:my_byaj_book/screens/tools/land_calculator_screen.dart';
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
              // Build the first two nav items (index 0 and 1)
              if (navItems.isNotEmpty)
                _buildNavItem(context, 0, navItems[0].icon, navItems[0].title),
              if (navItems.length > 1)
                _buildNavItem(context, 1, navItems[1].icon, navItems[1].title),
              
              // Center tools button (index 2)
              _buildToolsButton(context),
              
              // Build the last two nav items (index 3 and 4)
              if (navItems.length > 2)
                _buildNavItem(context, 3, navItems[2].icon, navItems[2].title),
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

  final List<Map<String, dynamic>> _tools = [
    {'icon': Icons.calculate_rounded, 'title': 'EMI Calc', 'color': Colors.purple},
    {'icon': Icons.landscape_rounded, 'title': 'Land Calc', 'color': Colors.teal},
    {'icon': Icons.account_balance_wallet_rounded, 'title': 'SIP Calc', 'color': Colors.indigo},
    {'icon': Icons.assignment_rounded, 'title': 'Tax Calc', 'color': Colors.red},
    {'icon': Icons.note_alt_rounded, 'title': 'Bill Diary', 'color': Colors.blue.shade700},
    {'icon': Icons.local_drink_rounded, 'title': 'Milk Diary', 'color': Colors.amber.shade700},
    {'icon': Icons.work_rounded, 'title': 'Work Diary', 'color': Colors.blue},
    {'icon': Icons.emoji_food_beverage_rounded, 'title': 'Tea Diary', 'color': Colors.deepPurple},
    {'icon': Icons.settings, 'title': 'Settings', 'color': Colors.grey.shade700},
  ];

  @override
  Widget build(BuildContext context) {
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
            'Tools & Diaries',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Access financial tools and business diary templates',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.9,
                crossAxisSpacing: 16,
                mainAxisSpacing: 24,
              ),
              itemCount: _tools.length,
              itemBuilder: (context, index) {
                final tool = _tools[index];
                return _buildToolItem(
                  context,
                  icon: tool['icon'],
                  title: tool['title'],
                  color: tool['color'],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolItem(BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _handleToolNavigation(context, title);
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
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
    );
  }
  
  void _handleToolNavigation(BuildContext context, String tool) {
    // Close the dialog and nav drawer
    Navigator.pop(context);

    switch (tool) {
      case 'Tea Diary':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TeaDiaryScreen(),
          ),
        );
        break;
      case 'EMI Calc':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EmiCalculatorScreen(),
          ),
        );
        break;
      case 'SIP Calc':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SipCalculatorScreen(),
          ),
        );
        break;
      case 'Milk Diary':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MilkDiaryScreen()),
        );
        break;
      case 'Work Diary':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WorkDiaryScreen()),
        );
        break;
      case 'Bill Diary':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BillDiaryScreen()),
        );
        break;
      case 'Settings':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NavSettingsScreen()),
        );
        break;
      case 'Land Calc':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LandCalculatorScreen(),
          ),
        );
        break;
      case 'Tax Calc':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TaxCalculatorScreen(),
          ),
        );
        break;
      default:
        // Show "coming soon" message for these tools
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$tool coming soon!'),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
    }
  }
}
