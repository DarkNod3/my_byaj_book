import 'package:flutter/material.dart';

class HelpResources {
  static final List<Map<String, dynamic>> faqList = [
    {
      'question': 'How do I add a new card?',
      'answer': 'Go to the Cards section, then tap the + button at the bottom of the screen. Fill in the required details like card name, number, limit, and expiry date to create a new card entry.'
    },
    {
      'question': 'How do I track my loan EMIs?',
      'answer': 'Navigate to the Loans section, add your loan details including the principal amount, interest rate, and tenure. The app will automatically calculate your EMI schedule and show upcoming payments.'
    },
    {
      'question': 'Can I delete a transaction?',
      'answer': 'Yes! In the Card details view, swipe left on any transaction to delete it. The card balance will be automatically updated.'
    },
    {
      'question': 'How do I customize my bottom navigation?',
      'answer': 'Go to Settings > Customize Navigation, or tap the Tools button and select "Customize Navigation" at the bottom of the More Tools panel. Drag and drop to rearrange your preferred tools.'
    },
    {
      'question': 'How do I track milk purchases?',
      'answer': 'Use the Milk Diary feature from the bottom navigation or More Tools section. You can add daily milk purchases and view monthly summaries.'
    },
    {
      'question': 'What calculators are available?',
      'answer': 'My Byaj Book offers EMI calculator, SIP calculator, Land calculator, and Tax calculator to help you with financial planning and calculations.'
    },
  ];
  
  static List<Map<String, dynamic>> getTutorialsList() {
    return [
      {
        'title': 'Getting Started',
        'icon': Icons.play_arrow,
        'description': 'Learn the basics of using My Byaj Book',
        'duration': '3:45',
      },
      {
        'title': 'Managing Cards',
        'icon': Icons.credit_card,
        'description': 'Add, edit and track your credit cards',
        'duration': '4:20',
      },
      {
        'title': 'Loan Tracking',
        'icon': Icons.account_balance,
        'description': 'Set up loan tracking and EMI reminders',
        'duration': '5:10',
      },
      {
        'title': 'Using Calculators',
        'icon': Icons.calculate,
        'description': 'How to use the financial calculators',
        'duration': '2:55',
      },
      {
        'title': 'Expense Management',
        'icon': Icons.money,
        'description': 'Track and analyze your expenses',
        'duration': '3:30',
      },
    ];
  }
  
  static List<Map<String, dynamic>> getSupportOptions() {
    return [
      {
        'title': 'Email Support',
        'icon': Icons.email,
        'description': 'support@mybyajbook.com',
      },
      {
        'title': 'WhatsApp Support',
        'icon': Icons.chat,
        'description': '+91 98765 43210',
      },
      {
        'title': 'Call Support',
        'icon': Icons.call,
        'description': '9 AM - 6 PM, Mon-Fri',
      },
    ];
  }
} 