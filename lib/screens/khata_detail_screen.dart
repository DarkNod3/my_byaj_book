import 'package:flutter/material.dart';
import '../utils/constants.dart';

class KhataDetailScreen extends StatefulWidget {
  final String? khataId;
  final String? khataName;
  
  const KhataDetailScreen({
    Key? key, 
    this.khataId,
    this.khataName,
  }) : super(key: key);

  @override
  State<KhataDetailScreen> createState() => _KhataDetailScreenState();
}

class _KhataDetailScreenState extends State<KhataDetailScreen> {
  bool isLoading = true;
  Map<String, dynamic> khataData = {};
  List<Map<String, dynamic>> transactions = [];
  
  @override
  void initState() {
    super.initState();
    _loadKhataDetails();
  }
  
  Future<void> _loadKhataDetails() async {
    // This is a placeholder implementation
    // In a real app, this would load data from a database or provider
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      isLoading = false;
      // Set some placeholder data
      khataData = {
        'id': widget.khataId ?? 'unknown',
        'name': widget.khataName ?? 'Khata Detail',
        'balance': 5000.0,
        'date': DateTime.now(),
        'type': 'personal',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.khataName ?? 'Khata Detail'),
        backgroundColor: AppConstants.primaryColor,
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Khata Summary Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              khataData['name'] ?? 'Untitled Khata',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Chip(
                              label: Text(khataData['type'] ?? 'unknown'),
                              backgroundColor: Colors.teal.shade100,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Balance',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${khataData['balance']?.toStringAsFixed(2) ?? '0.00'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                    color: Colors.teal,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // Placeholder for adding transaction
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Add Transaction feature coming soon'),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Add Transaction'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Placeholder for transactions list
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No transactions yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add your first transaction to get started',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Placeholder for adding transaction
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Add Transaction feature coming soon'),
            ),
          );
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
} 