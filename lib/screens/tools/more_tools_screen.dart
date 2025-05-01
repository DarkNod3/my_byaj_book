import 'package:flutter/material.dart';
import 'package:my_byaj_book/screens/settings/nav_settings_screen.dart';
import 'package:my_byaj_book/constants/app_theme.dart';
import 'package:my_byaj_book/screens/tools/sip_calculator_screen.dart';
import 'package:my_byaj_book/screens/tools/tax_calculator_screen.dart';
import 'package:my_byaj_book/screens/tools/land_calculator_screen.dart';
import 'package:my_byaj_book/screens/tools/emi_calculator_screen.dart';
import 'package:my_byaj_book/screens/bill_diary/bill_diary_screen.dart';
import 'package:my_byaj_book/screens/tea_diary/tea_diary_screen.dart';
import 'package:my_byaj_book/screens/work_diary/work_diary_screen.dart';
import 'package:my_byaj_book/screens/tools/milk_diary_screen.dart';
import 'package:my_byaj_book/screens/loan/loan_screen.dart';
import 'package:my_byaj_book/screens/card/card_screen.dart';
import 'package:provider/provider.dart';
import 'package:my_byaj_book/providers/nav_preferences_provider.dart';

class MoreToolsScreen extends StatelessWidget {
  const MoreToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NavPreferencesProvider>(
      builder: (context, navProvider, _) {
        final unselectedTools = navProvider.unselectedTools;
        
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'All Tools',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Access all available financial tools and diaries',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Bottom Nav Tools Section
                Row(
                  children: [
                    const Text(
                      'BOTTOM NAVIGATION',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, NavSettingsScreen.routeName);
                      },
                      child: Text(
                        'Customize',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Home + Selected Tools
                _buildSelectedToolsGrid(context, navProvider),
                
                const SizedBox(height: 24),
                
                // More Tools Section
                Row(
                  children: [
                    const Text(
                      'MORE TOOLS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Add to bottom nav',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Unselected Tools Grid
                _buildUnselectedToolsGrid(context, unselectedTools, navProvider),
                
                const SizedBox(height: 24),
                
                // Financial Tips Card
                _buildFinancialTips(),
              ],
            ),
          ),
        );
      }
    );
  }
  
  Widget _buildSelectedToolsGrid(BuildContext context, NavPreferencesProvider navProvider) {
    // Add home to the start of the list
    final homeItem = navProvider.homeItem;
    final selectedTools = navProvider.selectedTools;
    
    // Create a combined list with home and selected tools
    final combinedTools = [homeItem, ...selectedTools];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: combinedTools.length,
      itemBuilder: (context, index) {
        final tool = combinedTools[index];
        final bool isHomeItem = index == 0;
        
        return _buildToolItem(
          context,
          title: tool.title,
          icon: tool.icon,
          color: isHomeItem 
              ? Colors.blue.shade700
              : _getToolColor(tool.id),
          onTap: () {
            _navigateToTool(context, tool.id);
          },
          badge: isHomeItem ? 'Fixed' : null,
        );
      },
    );
  }

  Widget _buildUnselectedToolsGrid(
    BuildContext context,
    List<NavItem> unselectedTools,
    NavPreferencesProvider navProvider
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: unselectedTools.length,
      itemBuilder: (context, index) {
        final tool = unselectedTools[index];
        final bool canAdd = navProvider.selectedTools.length < 3;
        
        return _buildToolItem(
          context,
          title: tool.title,
          icon: tool.icon,
          color: _getToolColor(tool.id),
          onTap: () {
            _navigateToTool(context, tool.id);
          },
          addToNav: canAdd ? () {
            navProvider.addTool(tool.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${tool.title} added to bottom navigation'),
                duration: const Duration(seconds: 2),
              ),
            );
          } : null,
        );
      },
    );
  }

  Widget _buildToolItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    VoidCallback? addToNav,
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 26,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Badge for fixed items
            if (badge != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ],
            
            // Add to nav button
            if (addToNav != null) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: addToNav,
                child: Text(
                  'Add to nav',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: Colors.amber.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Financial Tip',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Create a budget and track your expenses regularly to maintain financial discipline. This will help you identify unnecessary expenses and save more.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
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
      case 'home':
        // We're already at home, so just close this screen
        Navigator.pop(context);
        break;
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
        // Show "coming soon" message for any other tools
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
