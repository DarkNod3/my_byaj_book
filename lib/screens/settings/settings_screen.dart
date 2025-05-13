import 'package:flutter/material.dart';
import 'package:my_byaj_book/constants/app_theme.dart';
import '../../resources/privacy_policy.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);
  
  static const routeName = '/settings';

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        children: [
          // App information section
          _buildSectionHeader('About'),
          
          // Version info
          _buildSettingItem(
            title: 'Version',
            value: '1.0.0',
            icon: Icons.info_outline,
            onTap: null,
          ),
          
          // Privacy policy
          _buildSettingItem(
            title: 'Privacy Policy',
            icon: Icons.shield_outlined,
            onTap: () {
              _showPrivacyPolicy(context);
            },
          ),
          
          // Terms of service
          _buildSettingItem(
            title: 'Terms of Service',
            icon: Icons.description_outlined,
            onTap: () {
              _showTermsOfService(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    String? value,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        trailing: value != null 
          ? Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            )
          : const Icon(Icons.chevron_right),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Text(PrivacyPolicy.policyText),
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

  void _showTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'These Terms of Service ("Terms") govern your access to and use of the My Byaj Book application. '
            'By using our application, you agree to these Terms. '
            '\n\n'
            'Our application is designed to help you track and manage loans, interests, and other financial data. '
            'We do not provide financial advice, and all data is stored locally on your device. '
            '\n\n'
            'You are responsible for maintaining the confidentiality of your account information and for all activities that occur under your account. '
            '\n\n'
            'We reserve the right to modify these Terms at any time. Your continued use of the application after any modifications indicates your acceptance of the modified Terms.'
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
} 