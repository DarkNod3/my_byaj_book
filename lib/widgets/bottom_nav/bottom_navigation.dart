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

        // Get home item and selected tools
        final homeItem = navPrefs.homeItem;
        final selectedTools = navPrefs.selectedTools;
        
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
              // Home icon (fixed, index 0)
              _buildNavItem(
                context, 
                0, 
                homeItem.icon, 
                homeItem.title
              ),
              
              // First user-selected tool (index 1)
              if (selectedTools.isNotEmpty)
                _buildNavItem(
                  context, 
                  1, 
                  selectedTools[0].icon, 
                  selectedTools[0].title
                ),
                
              // More button (moved from center to position 2)
              _buildMoreButton(context),
              
              // Second user-selected tool (index moved from 2 to 3)
              if (selectedTools.length > 1)
                _buildNavItem(
                  context, 
                  3, 
                  selectedTools[1].icon, 
                  selectedTools[1].title
                ),
                
              // Third user-selected tool (index moved from 4 to 4)
              if (selectedTools.length > 2)
                _buildNavItem(
                  context, 
                  4, 
                  selectedTools[2].icon, 
                  selectedTools[2].title
                ),
                
              // Empty space if we have fewer than 3 selected tools
              if (selectedTools.length <= 2)
                Container(width: 60),
            ],
          ),
        );
      }
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    final isSelected = currentIndex == index;
    
    return InkWell(
      onTap: () => onTap(index),
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

  Widget _buildMoreButton(BuildContext context) {
    final isSelected = currentIndex == 2;
    
    return GestureDetector(
      onTap: () {
        onTap(2);
        _showMoreTools(context);
      },
      child: Container(
        width: 60,
        height: 60,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isSelected ? Colors.blue.shade700 : Colors.blue.shade500,
              isSelected ? Colors.blue.shade900 : Colors.blue.shade700,
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

  void _showMoreTools(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const MoreToolsModal(),
    );
  }
}

class MoreToolsModal extends StatelessWidget {
  const MoreToolsModal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NavPreferencesProvider>(
      builder: (context, navPrefs, _) {
        final unselectedTools = navPrefs.unselectedTools;
        
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
              // Handle bar
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              
              // Title with Manage button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Text(
                      'Tools & Diaries',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamed(NavSettingsScreen.routeName);
                      },
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Colors.blue.shade700,
                      ),
                      label: Text(
                        'Manage Nav',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // All Tools Section (excluding tools already in bottom nav)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Text(
                      'ALL TOOLS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Tap to open',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // All Tools Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.9,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: unselectedTools.length,
                    itemBuilder: (context, index) {
                      final tool = unselectedTools[index];
                      return _buildToolItemReadOnly(context, tool);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Read-only version without Add to nav button
  Widget _buildToolItemReadOnly(BuildContext context, NavItem tool) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _navigateToTool(context, tool.id);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getToolColor(tool.id).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              tool.icon,
              color: _getToolColor(tool.id),
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tool.title,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getToolColor(String toolId) {
    switch (toolId) {
      case 'loans':
        return Colors.blue.shade700;
      case 'cards':
        return Colors.purple.shade700;
      case 'bill_diary':
        return Colors.orange.shade700;
      case 'emi_calc':
        return Colors.green.shade700;
      case 'land_calc':
        return Colors.teal.shade700;
      case 'sip_calc':
        return Colors.indigo.shade700;
      case 'tax_calc':
        return Colors.red.shade700;
      case 'milk_diary':
        return Colors.amber.shade700;
      case 'work_diary':
        return Colors.brown.shade700;
      case 'tea_diary':
        return Colors.deepPurple.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
  
  void _navigateToTool(BuildContext context, String toolId) {
    switch (toolId) {
      case 'loans':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const LoanScreen()));
        break;
      case 'cards':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const CardScreen()));
        break;
      case 'bill_diary':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const BillDiaryScreen()));
        break;
      case 'emi_calc':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const EmiCalculatorScreen()));
        break;
      case 'land_calc':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const LandCalculatorScreen()));
        break;
      case 'sip_calc':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const SipCalculatorScreen()));
        break;
      case 'tax_calc':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const TaxCalculatorScreen()));
        break;
      case 'milk_diary':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const MilkDiaryScreen()));
        break;
      case 'work_diary':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const WorkDiaryScreen()));
        break;
      case 'tea_diary':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const TeaDiaryScreen()));
        break;
      default:
        // Show "coming soon" message for unimplemented tools
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$toolId coming soon!'),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
    }
  }
}
