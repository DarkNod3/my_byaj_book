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
      width: MediaQuery.of(context).size.width * 0.65, // Increase from 0.3 to 0.65 for better usability
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 4),
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
                
                const SizedBox(height: 8),
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
                
                const Divider(height: 8),
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
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey.shade100,
            width: double.infinity,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'App Version 1.0.0',
                  style: TextStyle(color: Colors.grey, fontSize: 10),
                ),
                Text(
                  '© 2023 My Byaj Book',
                  style: TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppTheme.primaryColor,
      padding: const EdgeInsets.only(top: 24, bottom: 12, left: 12, right: 12),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  size: 24,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              Provider.of<UserProvider>(context, listen: false).user?.name ?? 'User',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              Provider.of<UserProvider>(context, listen: false).user?.mobile ?? 'Update Profile',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showComingSoonSnackbar(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: const Size(60, 24),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Edit'),
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
        size: 18,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? theme.textTheme.bodyLarge?.color,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
      dense: true,
      visualDensity: const VisualDensity(horizontal: -4, vertical: -2),
      onTap: onTap,
      horizontalTitleGap: 8,
      minLeadingWidth: 20,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
    );
  }

  Widget _buildNotificationToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.notifications_outlined,
            size: 18,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Notifications',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w500,
                fontSize: 13,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.language_outlined,
              size: 18,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                'Language',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              _currentLanguage,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                  fontSize: 13,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 2, top: 6),
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
          Divider(height: 6, thickness: 0.5, color: AppTheme.primaryColor.withOpacity(0.2)),
        ],
      ),
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
