import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class SellerProfileScreen extends StatefulWidget {
  final String? sellerId;
  final String? sellerName;
  final Map<String, dynamic>? sellerData;
  
  const SellerProfileScreen({
    Key? key,
    this.sellerId,
    this.sellerName,
    this.sellerData,
  }) : super(key: key);

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  bool isLoading = true;
  Map<String, dynamic> sellerInfo = {};
  List<Map<String, dynamic>> deliveries = [];
  List<Map<String, dynamic>> payments = [];
  
  @override
  void initState() {
    super.initState();
    _loadSellerProfile();
  }
  
  Future<void> _loadSellerProfile() async {
    // Simulated data loading
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      isLoading = false;
      sellerInfo = widget.sellerData ?? {
        'id': widget.sellerId ?? 'unknown',
        'name': widget.sellerName ?? 'Milk Seller',
        'phone': '9876543210',
        'address': 'Sample Address',
        'rate': 50.0,
        'balance': 2500.0,
        'lastDelivery': DateTime.now().subtract(const Duration(days: 1)),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sellerName ?? 'Seller Profile'),
        backgroundColor: AppConstants.primaryColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seller profile card
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
                          // Seller avatar and name
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.teal.shade100,
                                child: Text(
                                  (sellerInfo['name'] as String?)?.isNotEmpty == true
                                      ? (sellerInfo['name'] as String).substring(0, 1).toUpperCase()
                                      : 'S',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sellerInfo['name'] ?? 'Unknown Seller',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      sellerInfo['phone'] ?? 'No phone',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          
                          // Seller details
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildInfoItem(
                                icon: Icons.attach_money,
                                label: 'Rate',
                                value: '₹${sellerInfo['rate']?.toStringAsFixed(2) ?? '0.00'}/L',
                              ),
                              _buildInfoItem(
                                icon: Icons.account_balance_wallet,
                                label: 'Balance',
                                value: '₹${sellerInfo['balance']?.toStringAsFixed(2) ?? '0.00'}',
                                valueColor: Colors.red,
                              ),
                              _buildInfoItem(
                                icon: Icons.calendar_today,
                                label: 'Last Delivery',
                                value: sellerInfo['lastDelivery'] != null
                                    ? _formatDate(sellerInfo['lastDelivery'])
                                    : 'N/A',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Placeholder for adding milk entry
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Add Milk Entry feature coming soon'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Entry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Placeholder for recording payment
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Record Payment feature coming soon'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.payment),
                          label: const Text('Record Payment'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Placeholder for recent activities
                  const Text(
                    'Recent Activities',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(32),
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
                          'No recent activities',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.teal),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 