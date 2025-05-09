import 'package:flutter/material.dart';
import 'package:my_byaj_book/constants/app_theme.dart';

class SpecialThanksScreen extends StatelessWidget {
  static const routeName = '/special-thanks';

  const SpecialThanksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Special Thanks & Dedication"),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tribute Card
            _buildTributeCard(context),
            
            const SizedBox(height: 24),
            
            // Team Section
            _buildTeamSection(context),
            
            const SizedBox(height: 32),
            
            // Footer
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTributeCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.indigo.shade800,
            Colors.indigo.shade500,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Remembrance icon at the top
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 24, bottom: 8),
            child: const Icon(
              Icons.favorite,
              color: Colors.white70,
              size: 60,
            ),
          ),
          
          // Tribute content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              children: [
                const Text(
                  "In Loving Memory",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Rohtash Jangra – My Main Inspiration",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  "This app is dedicated to Rohtash Jangra, who is no longer with us but remains the reason behind this entire creation.",
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSection(BuildContext context) {
    final teamMembers = [
      {
        'name': 'Mr. Jangra',
        'role': 'App Creator & Owner',
        'icon': Icons.code,
      },
      {
        'name': 'Deepak Verma',
        'role': 'Head of Operations (Exam Lover)',
        'icon': Icons.business_center,
      },
      {
        'name': 'Hitender Jangra',
        'role': 'Content Writer',
        'icon': Icons.edit_document,
      },
      {
        'name': 'Ajay Sheoran',
        'role': 'Content Writer',
        'icon': Icons.edit,
      }
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Icon(
                Icons.groups,
                color: AppTheme.primaryColor,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                "My Amazing Team",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // Team member cards
        ...teamMembers.map((member) => _buildTeamMemberCard(
          context,
          name: member['name'] as String,
          role: member['role'] as String,
          icon: member['icon'] as IconData,
        )),
      ],
    );
  }
  
  Widget _buildTeamMemberCard(
    BuildContext context, {
    required String name,
    required String role,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          role,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
  
  Widget _buildFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.favorite_border,
            color: AppTheme.primaryColor.withOpacity(0.7),
            size: 32,
          ),
          const SizedBox(height: 16),
          const Text(
            "Thank you all for being a part of this journey.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
} 