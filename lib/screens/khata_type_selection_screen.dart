import 'package:flutter/material.dart';
import '../models/khata.dart';
import 'add_khata_screen.dart';

class KhataTypeSelectionScreen extends StatelessWidget {
  const KhataTypeSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Khata Type'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'What type of khata would you like to create?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          _buildKhataTypeCard(
            context,
            title: 'Without Interest',
            icon: Icons.account_balance_wallet,
            color: Colors.blue,
            description: 'Create a simple khata without any interest calculation.',
            onTap: () => _navigateToAddKhata(context, KhataType.withoutInterest),
          ),
          const SizedBox(height: 16),
          _buildKhataTypeCard(
            context,
            title: 'With Interest',
            icon: Icons.account_balance,
            color: Colors.orange,
            description: 'Create a khata with interest calculation (simple or compound).',
            onTap: () => _navigateToAddKhata(context, KhataType.withInterest),
          ),
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'You can add transactions to the khata after creation.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKhataTypeCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String description,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(25, 211, 211, 211),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 32,
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToAddKhata(BuildContext context, KhataType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddKhataScreen(khataType: type),
      ),
    ).then((result) {
      if (result == true) {
        Navigator.pop(context, true);
      }
    });
  }
} 