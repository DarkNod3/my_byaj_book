import 'package:flutter/material.dart';
import 'package:my_byaj_book/screens/card/card_screen.dart';
import 'package:my_byaj_book/screens/tools/emi_calculator_screen.dart';
import 'package:my_byaj_book/screens/home/home_screen.dart';
import 'package:my_byaj_book/screens/loan/loan_screen.dart';
import 'package:my_byaj_book/screens/bill_diary/bill_diary_screen.dart';
import 'package:my_byaj_book/screens/tools/more_tools_screen.dart';
import 'package:my_byaj_book/screens/settings/nav_settings_screen.dart';
import 'package:my_byaj_book/screens/settings/settings_screen.dart';
import 'package:my_byaj_book/screens/profile/profile_edit_screen.dart';
import '../../constants/app_theme.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../resources/help_resources.dart';
import 'dart:io';
import '../../resources/privacy_policy.dart';

class AppNavigationDrawer extends StatefulWidget {
  const AppNavigationDrawer({super.key});

  @override
  State<AppNavigationDrawer> createState() => _AppNavigationDrawerState();
}

class _AppNavigationDrawerState extends State<AppNavigationDrawer> {
  bool _notificationsEnabled = true;

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
                _buildMenuItem(
                  context,
                  title: 'Customize Navigation',
                  icon: Icons.dashboard_customize_outlined,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, NavSettingsScreen.routeName);
                  },
                  description: 'Arrange your bottom navigation bar tabs',
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
                  description: 'App preferences and account settings',
                ),
                _buildMenuItem(
                  context,
                  title: 'Help & Support',
                  icon: Icons.help_outline,
                  onTap: () {
                    Navigator.pop(context);
                    _showHelpAndSupportDialog(context);
                  },
                  description: 'Get assistance with using the app',
                ),
                _buildMenuItem(
                  context,
                  title: 'Rate App',
                  icon: Icons.star_outline,
                  onTap: () {
                    Navigator.pop(context);
                    _showRateAppDialog(context);
                  },
                  description: 'Tell us what you think about the app',
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
                  description: 'Learn more about My Byaj Book',
                ),
                _buildMenuItem(
                  context,
                  title: 'Privacy Policy',
                  icon: Icons.privacy_tip_outlined,
                  onTap: () {
                    Navigator.pop(context);
                    _showPrivacyPolicyDialog(context);
                  },
                  description: 'How we handle your data',
                ),
                _buildMenuItem(
                  context,
                  title: 'Refer a Friend',
                  icon: Icons.share_outlined,
                  onTap: () {
                    Navigator.pop(context);
                    _showShareAppDialog(context);
                  },
                  description: 'Share the app with friends and family',
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
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    
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
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white,
                backgroundImage: user?.profileImagePath != null 
                    ? FileImage(File(user!.profileImagePath!)) 
                    : null,
                child: user?.profileImagePath == null
                    ? const Icon(
                        Icons.person,
                        size: 24,
                        color: AppTheme.primaryColor,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user?.name ?? 'User',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
                );
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
    String? description,
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
      subtitle: description != null 
          ? Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ) 
          : null,
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
  
  void _showHelpAndSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSupportOption(
                'FAQs', 
                'Get answers to common questions',
                Icons.question_answer_outlined,
                () {
                  Navigator.pop(context);
                  _showFAQsDialog(context);
                },
              ),
              const SizedBox(height: 12),
              _buildSupportOption(
                'Contact Support', 
                'Email our support team',
                Icons.email_outlined,
                () {
                  Navigator.pop(context);
                  _showContactSupportDialog(context);
                },
              ),
              const SizedBox(height: 12),
              _buildSupportOption(
                'Report a Bug', 
                'Let us know if something isn\'t working',
                Icons.bug_report_outlined,
                () {
                  Navigator.pop(context);
                  _showReportBugDialog(context);
                },
              ),
              const SizedBox(height: 12),
              _buildSupportOption(
                'Video Tutorials', 
                'Learn how to use My Byaj Book',
                Icons.play_circle_outline,
                () {
                  Navigator.pop(context);
                  _showVideoTutorialsDialog(context);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _showFAQsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Frequently Asked Questions'),
        content: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: HelpResources.faqList.map((faq) {
                return ExpansionTile(
                  title: Text(
                    faq['question'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        faq['answer'],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _showContactSupportDialog(BuildContext context) {
    final supportOptions = HelpResources.getSupportOptions();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose your preferred way to reach our support team:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ...supportOptions.map((option) {
                return ListTile(
                  leading: Icon(option['icon'], color: AppTheme.primaryColor),
                  title: Text(option['title']),
                  subtitle: Text(option['description']),
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoonSnackbar(context, '${option['title']} feature coming soon!');
                  },
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _showReportBugDialog(BuildContext context) {
    final bugDescriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report a Bug'),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please describe the issue you encountered:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bugDescriptionController,
                decoration: const InputDecoration(
                  hintText: 'Describe the bug here...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
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
              Navigator.pop(context);
              _showComingSoonSnackbar(context, 'Bug report submitted successfully!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
  
  void _showVideoTutorialsDialog(BuildContext context) {
    final tutorials = HelpResources.getTutorialsList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Video Tutorials'),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Watch these helpful tutorials to learn how to use My Byaj Book:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ...tutorials.map((tutorial) {
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(tutorial['icon'], color: AppTheme.primaryColor),
                  ),
                  title: Text(tutorial['title']),
                  subtitle: Text(tutorial['description']),
                  trailing: Text(
                    tutorial['duration'],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoonSnackbar(context, 'Video tutorials will be available soon!');
                  },
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSupportOption(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
  
  void _showRateAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate My Byaj Book'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enjoying My Byaj Book? Please take a moment to rate your experience and provide feedback.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    Icons.star,
                    color: index < 3 ? Colors.amber : Colors.grey[300],
                    size: 36,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _showComingSoonSnackbar(
                      context, 
                      'Thanks for rating! Rating functionality coming soon.'
                    );
                  },
                );
              }),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showComingSoonSnackbar(context, 'Rating functionality coming soon!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
  
  void _showPrivacyPolicyDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrivacyPolicy.buildPrivacyPolicyWidget(context),
      ),
    );
  }
}
