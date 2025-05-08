import 'package:flutter/material.dart';

class PrivacyPolicy {
  static const String appName = 'My Byaj Book';
  static const String supportEmail = 'darknod3@gmail.com';
  static const String lastUpdated = 'August 15, 2023';
  
  static const String policyText = '''
# Privacy Policy

**Last Updated: $lastUpdated**

## Introduction

Welcome to $appName. We respect your privacy and are committed to protecting your personal data. This Privacy Policy explains how we collect, use, and safeguard your information when you use our mobile application.

## Information We Collect

### Personal Information
- **Account Information**: When you create an account, we may collect your name and user ID.
- **Transaction Data**: Details of transactions you enter in the app, including customer information, loan details, and payment records.
- **Device Information**: We collect information about your device, including device type, operating system, and unique device identifiers.

### Non-Personal Information
- **Usage Data**: We collect anonymous statistics about how you use the app, including features used and time spent.
- **App Performance**: Data about app crashes and performance issues to improve our service.

## How We Use Your Information

We use your information for the following purposes:
- To provide and maintain our service
- To notify you about changes to our service
- To provide customer support
- To improve our app based on how you use it
- To detect and prevent technical issues

## Data Storage

All your data is primarily stored locally on your device. When you use our backup feature, this data is temporarily processed to create the backup file, which you can then choose to share or store as you wish.

## Data Sharing

We do not sell or rent your personal information to third parties. We may share your information in the following circumstances:
- With your consent
- To comply with legal obligations
- To protect our rights, privacy, safety, or property

## Your Rights

You have the right to:
- Access the personal information we have about you
- Correct inaccurate information
- Delete your data from the app
- Export your data in a common format

## Security

We implement appropriate technical and organizational measures to protect your personal information from unauthorized access, alteration, disclosure, or destruction.

## Children's Privacy

Our app is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13.

## Changes to This Privacy Policy

We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.

## Contact Us

If you have any questions about this Privacy Policy, please contact us at:
- Email: $supportEmail

By using the app, you agree to the collection and use of information in accordance with this policy.
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
              'Introduction',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Welcome to $appName. We respect your privacy and are committed to protecting your personal data. This Privacy Policy explains how we collect, use, and safeguard your information when you use our mobile application.',
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
            const Text(
              'Personal Information:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            _buildBulletPoint('Account Information: When you create an account, we may collect your name and user ID.'),
            _buildBulletPoint('Transaction Data: Details of transactions you enter in the app, including customer information, loan details, and payment records.'),
            _buildBulletPoint('Device Information: We collect information about your device, including device type, operating system, and unique device identifiers.'),
            const SizedBox(height: 8),
            const Text(
              'Non-Personal Information:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            _buildBulletPoint('Usage Data: We collect anonymous statistics about how you use the app, including features used and time spent.'),
            _buildBulletPoint('App Performance: Data about app crashes and performance issues to improve our service.'),
            
            const SizedBox(height: 16),
            const Text(
              'How We Use Your Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We use your information for the following purposes:',
              style: TextStyle(fontSize: 14),
            ),
            _buildBulletPoint('To provide and maintain our service'),
            _buildBulletPoint('To notify you about changes to our service'),
            _buildBulletPoint('To provide customer support'),
            _buildBulletPoint('To improve our app based on how you use it'),
            _buildBulletPoint('To detect and prevent technical issues'),
            
            const SizedBox(height: 16),
            const Text(
              'Data Storage',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'All your data is primarily stored locally on your device. When you use our backup feature, this data is temporarily processed to create the backup file, which you can then choose to share or store as you wish.',
              style: TextStyle(fontSize: 14),
            ),
            
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
              'We do not sell or rent your personal information to third parties. We may share your information in the following circumstances:',
              style: TextStyle(fontSize: 14),
            ),
            _buildBulletPoint('With your consent'),
            _buildBulletPoint('To comply with legal obligations'),
            _buildBulletPoint('To protect our rights, privacy, safety, or property'),
            
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
              'You have the right to:',
              style: TextStyle(fontSize: 14),
            ),
            _buildBulletPoint('Access the personal information we have about you'),
            _buildBulletPoint('Correct inaccurate information'),
            _buildBulletPoint('Delete your data from the app'),
            _buildBulletPoint('Export your data in a common format'),
            
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
              'We implement appropriate technical and organizational measures to protect your personal information from unauthorized access, alteration, disclosure, or destruction.',
              style: TextStyle(fontSize: 14),
            ),
            
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
              'Our app is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13.',
              style: TextStyle(fontSize: 14),
            ),
            
            const SizedBox(height: 16),
            const Text(
              'Changes to This Privacy Policy',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.',
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
              'If you have any questions about this Privacy Policy, please contact us at:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              'Email: $supportEmail',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'By using the app, you agree to the collection and use of information in accordance with this policy.',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  static Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
} 