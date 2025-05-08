import 'package:flutter/material.dart';
import 'package:my_byaj_book/screens/settings/nav_settings_screen.dart';
import 'package:my_byaj_book/screens/settings/settings_screen.dart';
import 'package:my_byaj_book/screens/profile/profile_edit_screen.dart';
import '../../constants/app_theme.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../resources/help_resources.dart';
import 'dart:io';
import '../../resources/privacy_policy.dart';
import 'package:url_launcher/url_launcher.dart';

class AppNavigationDrawer extends StatefulWidget {
  const AppNavigationDrawer({super.key});

  @override
  State<AppNavigationDrawer> createState() => _AppNavigationDrawerState();
}

class _AppNavigationDrawerState extends State<AppNavigationDrawer> {
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
      padding: const EdgeInsets.only(top: 24, bottom: 16, left: 12, right: 12),
      width: double.infinity,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipOval(
                child: user?.profileImagePath != null 
                  ? Image.file(
                      File(user!.profileImagePath!),
                      fit: BoxFit.cover,
                      width: 60,
                      height: 60,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.person,
                        size: 28,
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      size: 28,
                      color: AppTheme.primaryColor,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user?.name ?? 'User',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 30,
              width: 80,
              child: ElevatedButton(
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
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'Edit',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
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
                // Navigate to login screen after successful logout
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
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
      builder: (context) => const AboutDialog(
        applicationName: 'My Byaj Book',
        applicationVersion: 'v1.0.0',
        applicationIcon: FlutterLogo(size: 50),
        applicationLegalese: '© 2023 My Byaj Book. All rights reserved.',
        children: [
          SizedBox(height: 24),
          Text(
            'My Byaj Book is a comprehensive loan management app designed to help you keep track of your loans, EMIs, and payments in one place.',
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(height: 16),
          Text(
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
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Share My Byaj Book with your friends and family!'),
            SizedBox(height: 16),
            SelectableText(
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
        content: SizedBox(
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
        content: SizedBox(
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
    final supportOptions = [
      {
        'icon': Icons.message,
        'title': 'WhatsApp',
        'description': '+91 8570051543',
        'url': 'https://wa.me/918570051543'
      },
      {
        'icon': Icons.email,
        'title': 'Email',
        'description': 'darknod3@gmail.com',
        'url': 'mailto:darknod3@gmail.com'
      },
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: SizedBox(
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
                  leading: Icon(option['icon'] as IconData, color: AppTheme.primaryColor),
                  title: Text(option['title'] as String),
                  subtitle: Text(option['description'] as String),
                  onTap: () {
                    Navigator.pop(context);
                    launchUrl(
                      Uri.parse(option['url'] as String),
                      mode: LaunchMode.externalApplication,
                    ).catchError((error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Could not open ${option['title']}. Please try again later.'),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                      return false; // Return false to indicate the operation failed
                    });
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
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: SingleChildScrollView(
          child: SizedBox(
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
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.2,
                  ),
                  child: TextField(
                    controller: bugDescriptionController,
                    decoration: const InputDecoration(
                      hintText: 'Describe the bug here...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Get the bug description
              final bugDescription = bugDescriptionController.text.trim();
              if (bugDescription.isNotEmpty) {
                // Close the dialog
                Navigator.pop(context);
                
                // Compose email with bug report
                final Uri emailUri = Uri.parse(
                  'mailto:darknod3@gmail.com?subject=Bug Report - My Byaj Book&body=${Uri.encodeComponent(bugDescription)}'
                );
                
                // Launch email app
                launchUrl(emailUri).then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bug report email prepared. Thank you for your feedback!'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not open email app. Please send your report to darknod3@gmail.com manually.'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a description of the bug.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
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
    // Define the Play Store URL for the app
    final Uri playStoreUrl = Uri.parse('https://play.google.com/store/apps/details?id=com.rjinnovativemedia.mybyajbook');
    
    // Launch the URL to open Play Store
    try {
      launchUrl(
        playStoreUrl,
        mode: LaunchMode.externalApplication, // Open in external app (Play Store)
      );
    } catch (e) {
      // Show error if unable to open Play Store
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Play Store. Please rate us directly on the Play Store.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
  
  void _showPrivacyPolicyDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrivacyPolicy.buildPrivacyPolicyWidget(context),
      ),
    );
  }

  Future<bool> _confirmDeleteAccount(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Account Deletion'),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) => confirmed ?? false).catchError((error) {
      print('Error in confirmation dialog: $error');
      return false; // Return false when there's an error
    });
  }
}
