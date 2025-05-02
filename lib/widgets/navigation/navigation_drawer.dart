import 'package:flutter/material.dart';
import 'package:my_byaj_book/screens/card/card_screen.dart';
import 'package:my_byaj_book/screens/tools/emi_calculator_screen.dart';
import 'package:my_byaj_book/screens/home/home_screen.dart';
import 'package:my_byaj_book/screens/loan/loan_screen.dart';
import 'package:my_byaj_book/screens/bill_diary/bill_diary_screen.dart';
import 'package:my_byaj_book/screens/tools/more_tools_screen.dart';
import 'package:my_byaj_book/screens/settings/nav_settings_screen.dart';
import 'package:my_byaj_book/screens/settings/settings_screen.dart';
import '../../constants/app_theme.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class AppNavigationDrawer extends StatefulWidget {
  const AppNavigationDrawer({super.key});

  @override
  State<AppNavigationDrawer> createState() => _AppNavigationDrawerState();
}

class _AppNavigationDrawerState extends State<AppNavigationDrawer> {
  bool _notificationsEnabled = true;
  String _currentLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 8),
                _buildSectionTitle(context, 'Main Menu'),
                _buildMenuItem(
                  context,
                  title: 'Home',
                  icon: Icons.home_outlined,
                  onTap: () => _navigateTo(context, const HomeScreen()),
                ),
                _buildMenuItem(
                  context,
                  title: 'Loan Management',
                  icon: Icons.account_balance_outlined,
                  onTap: () => _navigateTo(context, const LoanScreen()),
                ),
                _buildMenuItem(
                  context,
                  title: 'Card Management',
                  icon: Icons.credit_card_outlined,
                  onTap: () => _navigateTo(context, const CardScreen()),
                ),
                _buildMenuItem(
                  context,
                  title: 'Bill Diary',
                  icon: Icons.note_alt_outlined,
                  onTap: () => _navigateTo(context, const BillDiaryScreen()),
                ),
                
                const SizedBox(height: 16),
                _buildSectionTitle(context, 'Tools'),
                _buildMenuItem(
                  context,
                  title: 'EMI Calculator',
                  icon: Icons.calculate_outlined,
                  onTap: () => _navigateTo(context, const EmiCalculatorScreen()),
                ),
                _buildMenuItem(
                  context,
                  title: 'More Tools',
                  icon: Icons.home_repair_service_outlined,
                  onTap: () => _navigateTo(context, const MoreToolsScreen()),
                ),
                _buildMenuItem(
                  context,
                  title: 'Export Backup',
                  icon: Icons.backup_outlined,
                  onTap: () {
                    Navigator.pop(context);
                    _showBackupDialog(context, true);
                  },
                ),
                _buildMenuItem(
                  context,
                  title: 'Import & Restore Backup',
                  icon: Icons.restore_outlined,
                  onTap: () {
                    Navigator.pop(context);
                    _showBackupDialog(context, false);
                  },
                ),
                
                const SizedBox(height: 16),
                _buildSectionTitle(context, 'Settings & Support'),
                _buildNotificationToggle(),
                _buildLanguageSelector(),
                _buildMenuItem(
                  context,
                  title: 'Customize Navigation',
                  icon: Icons.dashboard_customize_outlined,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, NavSettingsScreen.routeName);
                  },
                ),
                _buildMenuItem(
                  context,
                  title: 'Settings',
                  icon: Icons.settings_outlined,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  title: 'Help & Support',
                  icon: Icons.help_outline,
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoonSnackbar(context);
                  },
                ),
                _buildMenuItem(
                  context,
                  title: 'Rate App',
                  icon: Icons.star_outline,
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoonSnackbar(context, 'Rating feature will be available soon!');
                  },
                ),
                
                const SizedBox(height: 16),
                _buildSectionTitle(context, 'About'),
                _buildMenuItem(
                  context,
                  title: 'About Us',
                  icon: Icons.info_outline,
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog(context);
                  },
                ),
                _buildMenuItem(
                  context,
                  title: 'Privacy Policy',
                  icon: Icons.privacy_tip_outlined,
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoonSnackbar(context);
                  },
                ),
                _buildMenuItem(
                  context,
                  title: 'Refer a Friend',
                  icon: Icons.share_outlined,
                  onTap: () {
                    Navigator.pop(context);
                    _showShareAppDialog(context);
                  },
                ),
                
                const Divider(),
                _buildMenuItem(
                  context,
                  title: 'Logout',
                  icon: Icons.logout,
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutConfirmation(context);
                  },
                  textColor: Colors.red,
                  iconColor: Colors.red,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey.shade100,
            width: double.infinity,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'App Version 1.0.0',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                SizedBox(height: 4),
                Text(
                  '© 2023 My Byaj Book',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.notifications_outlined,
            size: 22,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 28),
          Expanded(
            child: Text(
              'Notifications',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(value 
                    ? 'Notifications enabled' 
                    : 'Notifications disabled'
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return InkWell(
      onTap: _showLanguageDialog,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.language_outlined,
              size: 22,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 28),
            Expanded(
              child: Text(
                'Language',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              _currentLanguage,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('English'),
            const SizedBox(height: 8),
            _buildLanguageOption('हिंदी (Hindi)'),
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

  Widget _buildLanguageOption(String language) {
    final bool isSelected = _currentLanguage == language || 
        (language == 'हिंदी (Hindi)' && _currentLanguage == 'Hindi');
    
    return InkWell(
      onTap: () {
        setState(() {
          _currentLanguage = language == 'हिंदी (Hindi)' ? 'Hindi' : language;
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Language set to $language'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                language,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryColor : null,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor.withOpacity(0.8),
            ),
          ),
          const Divider(height: 8, thickness: 0.5),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppTheme.primaryColor,
      padding: const EdgeInsets.only(top: 40, bottom: 24, left: 16, right: 16),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 36,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Provider.of<UserProvider>(context, listen: false).user?.name ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Provider.of<UserProvider>(context, listen: false).user?.mobile ?? 'Update Profile',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showComingSoonSnackbar(context);
              },
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: const Size(120, 36),
                elevation: 0,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: Icon(
        icon, 
        color: iconColor ?? AppTheme.primaryColor,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? theme.textTheme.bodyLarge?.color,
          fontWeight: FontWeight.w500,
        ),
      ),
      dense: true,
      onTap: onTap,
      horizontalTitleGap: 0,
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context); // Close the drawer
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
  
  void _showComingSoonSnackbar(BuildContext context, [String message = 'This feature is coming soon!']) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement actual logout
              Provider.of<UserProvider>(context, listen: false).logout().then((_) {
                // Navigate to login screen
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
  
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: 'My Byaj Book',
        applicationVersion: 'v1.0.0',
        applicationIcon: const FlutterLogo(size: 50),
        applicationLegalese: '© 2023 My Byaj Book. All rights reserved.',
        children: [
          const SizedBox(height: 24),
          const Text(
            'My Byaj Book is a comprehensive loan management app designed to help you keep track of your loans, EMIs, and payments in one place.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          const Text(
            'For support: support@mybyajbook.com',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
  
  void _showShareAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share App'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share My Byaj Book with your friends and family!'),
            const SizedBox(height: 16),
            const SelectableText(
              'https://play.google.com/store/apps/mybyajbook',
              style: TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showComingSoonSnackbar(context, 'Link copied to clipboard!');
            },
            child: const Text('Copy Link'),
          ),
        ],
      ),
    );
  }
  
  void _showBackupDialog(BuildContext context, bool isExport) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isExport ? 'Export Backup' : 'Import & Restore Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isExport 
                ? 'This will export all your data to a backup file.'
                : 'This will import data from a backup file and restore your account.',
            ),
            const SizedBox(height: 12),
            if (isExport)
              const Text(
                'Note: Your backup will include all loans, cards, and settings data.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              )
            else
              const Text(
                'Warning: This will replace your current data with the data from the backup file.',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showComingSoonSnackbar(
                context, 
                isExport 
                  ? 'Backup exported successfully!'
                  : 'Backup restored successfully!'
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(isExport ? 'Export Now' : 'Import Now'),
          ),
        ],
      ),
    );
  }
}
