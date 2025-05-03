import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/milk_diary/milk_seller.dart';
import '../../providers/milk_diary/milk_seller_provider.dart';
import '../../providers/milk_diary/daily_entry_provider.dart';
import '../../constants/app_theme.dart';
import 'milk_seller_dialog.dart';
import '../../widgets/dialogs/confirm_dialog.dart';
import 'seller_profile_screen.dart';

class MilkSellerScreen extends StatefulWidget {
  const MilkSellerScreen({Key? key}) : super(key: key);

  @override
  State<MilkSellerScreen> createState() => _MilkSellerScreenState();
}

class _MilkSellerScreenState extends State<MilkSellerScreen> {
  String _searchQuery = '';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Milk Sellers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog();
            },
          ),
        ],
      ),
      body: Consumer<MilkSellerProvider>(
        builder: (context, sellerProvider, child) {
          final filteredSellers = sellerProvider.searchSellers(_searchQuery);
          
          if (filteredSellers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_search, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? 'No milk sellers added yet'
                        : 'No sellers matching "$_searchQuery"',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredSellers.length,
            itemBuilder: (context, index) {
              final seller = filteredSellers[index];
              return _buildSellerCard(seller);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditSellerDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Add New Seller',
      ),
    );
  }

  Widget _buildSellerCard(MilkSeller seller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showSellerProfile(seller),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          seller.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (seller.mobile != null && seller.mobile!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              seller.mobile!,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: seller.isActive ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      seller.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: seller.isActive ? Colors.green.shade800 : Colors.red.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (seller.address != null && seller.address!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    seller.address!,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Default Rate: ₹${seller.defaultRate.toStringAsFixed(2)}/L',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showAddEditSellerDialog(seller: seller),
                        tooltip: 'Edit Seller',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () => _confirmDeleteSeller(seller),
                        tooltip: 'Delete Seller',
                      ),
                    ],
                  ),
                ],
              ),
              Consumer<DailyEntryProvider>(
                builder: (context, entryProvider, child) {
                  final totalEntries = entryProvider.getEntriesForSeller(seller.id).length;
                  return Text(
                    'Total Entries: $totalEntries',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddEditSellerDialog({MilkSeller? seller}) async {
    final result = await showDialog<MilkSeller>(
      context: context,
      builder: (context) => MilkSellerDialog(seller: seller),
    );
    
    if (result != null) {
      final sellerProvider = Provider.of<MilkSellerProvider>(context, listen: false);
      
      try {
        if (seller == null) {
          await sellerProvider.addSeller(result);
          _showSnackBar('Seller added successfully');
        } else {
          await sellerProvider.updateSeller(result);
          _showSnackBar('Seller updated successfully');
        }
      } catch (e) {
        _showSnackBar('Error: ${e.toString()}', isError: true);
      }
    }
  }

  Future<void> _confirmDeleteSeller(MilkSeller seller) async {
    final sellerProvider = Provider.of<MilkSellerProvider>(context, listen: false);
    final entryProvider = Provider.of<DailyEntryProvider>(context, listen: false);
    
    final sellerEntries = entryProvider.getEntriesForSeller(seller.id);
    
    if (sellerEntries.isNotEmpty) {
      _showSnackBar(
        'Cannot delete seller with existing entries (${sellerEntries.length} entries found)',
        isError: true,
      );
      return;
    }
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Delete Seller',
        content: 'Are you sure you want to delete ${seller.name}? This action cannot be undone.',
        confirmText: 'DELETE',
        confirmColor: Colors.red,
      ),
    );
    
    if (confirmed == true) {
      await sellerProvider.deleteSeller(seller.id);
      _showSnackBar('Seller deleted successfully');
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: _searchQuery);
        
        return AlertDialog(
          title: const Text('Search Sellers'),
          content: TextField(
            autofocus: true,
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter name, phone or address',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = controller.text;
                });
                Navigator.pop(context);
              },
              child: const Text('SEARCH'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSellerProfile(MilkSeller seller) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SellerProfileScreen(seller: seller),
      ),
    );
  }
} 