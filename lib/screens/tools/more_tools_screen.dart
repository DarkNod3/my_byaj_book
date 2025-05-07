import 'package:flutter/material.dart';
import 'package:my_byaj_book/screens/settings/nav_settings_screen.dart';
import 'package:my_byaj_book/constants/app_theme.dart';
import 'package:my_byaj_book/screens/tools/sip_calculator_screen.dart';
import 'package:my_byaj_book/screens/tools/tax_calculator_screen.dart';
import 'package:my_byaj_book/screens/loan/loan_screen.dart';

class MoreToolsScreen extends StatelessWidget {
  const MoreToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Financial Tools',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use these tools to make better financial decisions',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            _buildToolsGrid(context),
            const SizedBox(height: 24),
            _buildFeaturedTool(context),
            const SizedBox(height: 24),
            _buildFinancialTips(),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildToolItem(
          context,
          title: 'Loans',
          icon: Icons.account_balance_wallet,
          color: Colors.indigo,
          onTap: () {
            // Navigate to Loan Screen with error handling
            try {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    // Wrap in try-catch to catch any exceptions during build
                    try {
                      return const LoanScreen();
                    } catch (e) {
                      // Show a fallback UI instead of crashing
                      return Scaffold(
                        appBar: AppBar(title: const Text('Loans')),
                        body: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 48),
                              const SizedBox(height: 16),
                              const Text('Error loading loans', style: TextStyle(fontSize: 18)),
                              const SizedBox(height: 8),
                              Text('Error details: $e', style: TextStyle(color: Colors.grey[600])),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Go Back'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          },
        ),
        _buildToolItem(
          context,
          title: 'EMI Calculator',
          icon: Icons.calculate,
          color: Colors.blue,
          onTap: () {
            // Navigate to EMI calculator
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('EMI Calculator coming soon!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        _buildToolItem(
          context,
          title: 'SIP Calculator',
          icon: Icons.pie_chart,
          color: Colors.purple,
          onTap: () {
            // Navigate to SIP calculator
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SipCalculatorScreen(),
              ),
            );
          },
        ),
        _buildToolItem(
          context,
          title: 'FD Calculator',
          icon: Icons.account_balance,
          color: Colors.green,
          onTap: () {
            // Navigate to FD calculator
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('FD Calculator coming soon!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        _buildToolItem(
          context,
          title: 'Compare Loans',
          icon: Icons.compare_arrows,
          color: Colors.orange,
          onTap: () {
            // Navigate to loan comparison
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Loan Comparison coming soon!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        _buildToolItem(
          context,
          title: 'Tax Calculator',
          icon: Icons.receipt_long,
          color: Colors.red,
          onTap: () {
            // Navigate to tax calculator
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TaxCalculatorScreen(),
              ),
            );
          },
        ),
        _buildToolItem(
          context,
          title: 'Loan Eligibility',
          icon: Icons.check_circle,
          color: Colors.cyan,
          onTap: () {
            // Navigate to loan eligibility
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Loan Eligibility Calculator coming soon!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        _buildToolItem(
          context,
          title: 'Interest Rates',
          icon: Icons.percent,
          color: Colors.teal,
          onTap: () {
            // Navigate to interest rates
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Interest Rates coming soon!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        _buildToolItem(
          context,
          title: 'Customize Navigation',
          icon: Icons.dashboard_customize_outlined,
          color: AppTheme.primaryColor,
          onTap: () {
            // Navigate to customize navigation
            Navigator.pushNamed(context, NavSettingsScreen.routeName);
          },
        ),
        _buildToolItem(
          context,
          title: 'More',
          icon: Icons.more_horiz,
          color: Colors.grey,
          onTap: () {
            // Show more tools
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('More tools coming soon!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildToolItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
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
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedTool(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade700,
              Colors.blue.shade900,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.insights,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Featured Tool',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Loan Prepayment Calculator',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Find out how much you can save by prepaying your loan. Calculate the impact on your loan tenure and interest payments.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navigate to loan prepayment calculator
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue.shade700,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: const Text('Try Calculator'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialTips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Financial Tips',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'See All',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTipCard(
          title: 'How to improve your credit score?',
          description: 'Learn the key factors that impact your credit score and strategies to improve it over time.',
          icon: Icons.trending_up,
          color: Colors.green,
        ),
        _buildTipCard(
          title: 'Smart ways to repay your loans faster',
          description: 'Discover effective strategies to pay off your loans quicker and save on interest payments.',
          icon: Icons.speed,
          color: Colors.orange,
        ),
        _buildTipCard(
          title: 'Understanding loan interest rates',
          description: 'Learn about different types of interest rates and how they affect your loan repayments.',
          icon: Icons.attach_money,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildTipCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Read More',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
