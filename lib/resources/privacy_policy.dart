import 'package:flutter/material.dart';

class PrivacyPolicy {
  static const String appName = 'My Byaj Book';
  static const String supportEmail = 'darknod3@gmail.com';
  static const String lastUpdated = 'May 10, 2025';
  
  static const String policyText = '''
# Privacy Policy

**Last Updated: $lastUpdated**

Welcome to My Byaj Book. We value your privacy and are committed to protecting your personal data. This Privacy Policy explains how we collect, use, and safeguard your information when you use our mobile application.

## Information We Collect

### 🔹 Personal Information
- **Account Details**: Name, mobile number, and UID if created
- **Transaction Data**: Loan details, interest amounts, payment records, notes, and customer names (if entered by you)
- **Device Info**: Operating system, device type, and unique identifiers

### 🔹 Permissions We Use
- **Contacts**: We request access to your contacts to help you easily add and manage people in your loan records
- **Camera**: Used only when you choose to take photos for profile pictures or transaction receipts
- **Storage**: Used to store images and backup files locally on your device
- **Phone**: Used only when you initiate a call to a contact from within the app

### 🔹 Non-Personal Information
- **Usage Statistics**: Features used, session duration, and app interaction logs
- **Crash Reports**: Technical errors and bugs to improve app performance

## How We Use Your Data
We use the information we collect to:
- Provide and maintain app services
- Offer reminders and backup features
- Notify users of critical app updates
- Improve user experience based on usage
- Provide technical support and customer care
- Prevent fraud, misuse, or illegal activity

## Data Storage
- All your transaction data is stored locally on your device by default
- When you use our backup feature, your data is temporarily processed to create a backup file (which you may save to Google Drive or email manually)
- We do not upload your financial data to our servers

## Data Sharing
We do not sell, rent, or share your personal data with third parties.
We may share limited information only:
- With your explicit consent
- To comply with legal requirements
- To protect our users or enforce app policies

## Children's Privacy
Our app is not intended for use by children under 13 years of age.
We do not knowingly collect personal information from anyone under 13.

## Your Rights
As a user, you have the right to:
- Access your stored data
- Request correction of inaccurate entries
- Delete your data from within the app
- Export your data in a common format (e.g., JSON)

## Security
We implement appropriate technical measures (such as local encryption and permission-based access) to protect your data from unauthorized access, alteration, or disclosure.

## Changes to This Policy
We may update this Privacy Policy occasionally. When we do, we'll notify users via app update notes and update the "Last Updated" date above.

## Contact Us
If you have any questions about this Privacy Policy or your data:
- 📧 Email: $supportEmail
- 📞 Support Hours: Mon–Fri, 10:00 AM – 6:00 PM IST

## 📌 Legal Compliance
This Privacy Policy complies with:
- Google Play's User Data Policy
- Indian IT Act (Reasonable Security Practices)
- GDPR guidelines for basic user rights (where applicable)
''';

  static Widget buildPrivacyPolicyWidget(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last Updated: $lastUpdated',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Welcome to My Byaj Book. We value your privacy and are committed to protecting your personal data. This Privacy Policy explains how we collect, use, and safeguard your information when you use our mobile application.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'Information We Collect',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                children: [
                  TextSpan(
                    text: '🔹 ',
                    style: TextStyle(color: Colors.blue),
                  ),
                  TextSpan(text: 'Personal Information'),
                ],
              ),
            ),
            const SizedBox(height: 4),
            _buildBulletPoint('Account Details: Name, mobile number, and UID if created'),
            _buildBulletPoint('Transaction Data: Loan details, interest amounts, payment records, notes, and customer names (if entered by you)'),
            _buildBulletPoint('Device Info: Operating system, device type, and unique identifiers'),
            const SizedBox(height: 8),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                children: [
                  TextSpan(
                    text: '🔹 ',
                    style: TextStyle(color: Colors.blue),
                  ),
                  TextSpan(text: 'Permissions We Use'),
                ],
              ),
            ),
            const SizedBox(height: 4),
            _buildBulletPoint('Contacts: We request access to your contacts to help you easily add and manage people in your loan records'),
            _buildBulletPoint('Camera: Used only when you choose to take photos for profile pictures or transaction receipts'),
            _buildBulletPoint('Storage: Used to store images and backup files locally on your device'),
            _buildBulletPoint('Phone: Used only when you initiate a call to a contact from within the app'),
            const SizedBox(height: 8),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                children: [
                  TextSpan(
                    text: '🔹 ',
                    style: TextStyle(color: Colors.blue),
                  ),
                  TextSpan(text: 'Non-Personal Information'),
                ],
              ),
            ),
            const SizedBox(height: 4),
            _buildBulletPoint('Usage Statistics: Features used, session duration, and app interaction logs'),
            _buildBulletPoint('Crash Reports: Technical errors and bugs to improve app performance'),
            
            const SizedBox(height: 16),
            const Text(
              'How We Use Your Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We use the information we collect to:',
              style: TextStyle(fontSize: 14),
            ),
            _buildBulletPoint('Provide and maintain app services'),
            _buildBulletPoint('Offer reminders and backup features'),
            _buildBulletPoint('Notify users of critical app updates'),
            _buildBulletPoint('Improve user experience based on usage'),
            _buildBulletPoint('Provide technical support and customer care'),
            _buildBulletPoint('Prevent fraud, misuse, or illegal activity'),
            
            const SizedBox(height: 16),
            const Text(
              'Data Storage',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildBulletPoint('All your transaction data is stored locally on your device by default'),
            _buildBulletPoint('When you use our backup feature, your data is temporarily processed to create a backup file (which you may save to Google Drive or email manually)'),
            _buildBulletPoint('We do not upload your financial data to our servers'),
            
            const SizedBox(height: 16),
            const Text(
              'Data Sharing',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We do not sell, rent, or share your personal data with third parties. We may share limited information only:',
              style: TextStyle(fontSize: 14),
            ),
            _buildBulletPoint('With your explicit consent'),
            _buildBulletPoint('To comply with legal requirements'),
            _buildBulletPoint('To protect our users or enforce app policies'),
            
            const SizedBox(height: 16),
            const Text(
              'Children\'s Privacy',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Our app is not intended for use by children under 13 years of age. We do not knowingly collect personal information from anyone under 13.',
              style: TextStyle(fontSize: 14),
            ),
            
            const SizedBox(height: 16),
            const Text(
              'Your Rights',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'As a user, you have the right to:',
              style: TextStyle(fontSize: 14),
            ),
            _buildBulletPoint('Access your stored data'),
            _buildBulletPoint('Request correction of inaccurate entries'),
            _buildBulletPoint('Delete your data from within the app'),
            _buildBulletPoint('Export your data in a common format (e.g., JSON)'),
            
            const SizedBox(height: 16),
            const Text(
              'Security',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We implement appropriate technical measures (such as local encryption and permission-based access) to protect your data from unauthorized access, alteration, or disclosure.',
              style: TextStyle(fontSize: 14),
            ),
            
            const SizedBox(height: 16),
            const Text(
              'Changes to This Policy',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We may update this Privacy Policy occasionally. When we do, we\'ll notify users via app update notes and update the "Last Updated" date above.',
              style: TextStyle(fontSize: 14),
            ),
            
            const SizedBox(height: 16),
            const Text(
              'Contact Us',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'If you have any questions about this Privacy Policy or your data:',
              style: TextStyle(fontSize: 14),
            ),
            _buildBulletPoint('📧 Email: $supportEmail'),
            _buildBulletPoint('📞 Support Hours: Mon–Fri, 10:00 AM – 6:00 PM IST'),
            
            const SizedBox(height: 16),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                children: [
                  TextSpan(
                    text: '📌 ',
                    style: TextStyle(color: Colors.red),
                  ),
                  TextSpan(text: 'Legal Compliance'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This Privacy Policy complies with:',
              style: TextStyle(fontSize: 14),
            ),
            _buildBulletPoint('Google Play\'s User Data Policy'),
            _buildBulletPoint('Indian IT Act (Reasonable Security Practices)'),
            _buildBulletPoint('GDPR guidelines for basic user rights (where applicable)'),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  static Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
} 