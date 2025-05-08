import 'package:flutter/material.dart';
import '../models/khata.dart';
import '../models/contact.dart';
import '../services/database_service.dart';
import '../widgets/khata_list_item.dart';
import 'khata_detail_screen.dart';
import 'khata_type_selection_screen.dart';
import 'package:my_byaj_book/widgets/balance_summary.dart';
import 'package:my_byaj_book/screens/contact/edit_contact_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _databaseService = DatabaseService.instance;
  
  List<Khata> _withInterestKhatas = [];
  List<Khata> _withoutInterestKhatas = [];
  Map<int, Contact> _contactsMap = {};
  String _searchQuery = '';
  
  double _totalToGive = 0;
  double _totalToGet = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    // Load contacts
    final contacts = await _databaseService.getContacts();
    _contactsMap = {for (var contact in contacts) contact.id! : contact};
    
    // Load khatas
    _withInterestKhatas = await _databaseService.getKhatasByType(KhataType.withInterest);
    _withoutInterestKhatas = await _databaseService.getKhatasByType(KhataType.withoutInterest);
    
    // Calculate balances
    await _calculateBalances();
    
    setState(() {
      _isLoading = false;
    });
  }
  
  Future<void> _calculateBalances() async {
    _totalToGive = 0;
    _totalToGet = 0;
    
    // Calculate for with interest khatas
    for (var khata in _withInterestKhatas) {
      double balance = await _calculateKhataBalance(khata.id!);
      if (balance > 0) {
        _totalToGet += balance;
      } else {
        _totalToGive += balance.abs();
      }
    }
    
    // Calculate for without interest khatas
    for (var khata in _withoutInterestKhatas) {
      double balance = await _calculateKhataBalance(khata.id!);
      if (balance > 0) {
        _totalToGet += balance;
      } else {
        _totalToGive += balance.abs();
      }
    }
  }
  
  Future<double> _calculateKhataBalance(int khataId) async {
    final transactions = await _databaseService.getTransactionsByKhataId(khataId);
    double balance = 0;
    
    for (var transaction in transactions) {
      if (transaction.isReceived) {
        balance += transaction.amount;
      } else if (transaction.isGiven) {
        balance -= transaction.amount;
      }
    }
    
    return balance;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Byaj Book'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings screen
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Without Interest'),
            Tab(text: 'With Interest'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBalanceSummary(),
                _buildSearchBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildKhataList(_withoutInterestKhatas),
                      _buildKhataList(_withInterestKhatas),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const KhataTypeSelectionScreen(),
            ),
          );
          
          if (result == true) {
            _loadData();
          }
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'HOME',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.money),
            label: 'LOAN',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: 'CALC',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card),
            label: 'CARDS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'MORE',
          ),
        ],
        onTap: (index) {
          // TODO: Implement navigation
        },
      ),
    );
  }

  Widget _buildBalanceSummary() {
    return BalanceSummary(
      toGet: _totalToGet,
      toGive: _totalToGive,
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search customers',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildKhataList(List<Khata> khatas) {
    final filteredKhatas = _searchQuery.isEmpty
        ? khatas
        : khatas.where((khata) {
            final contact = _contactsMap[khata.contactId];
            return contact != null && 
                contact.name.toLowerCase().contains(_searchQuery);
          }).toList();

    return Column(
      children: [
        // Add Contact Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.person_add),
            label: const Text('Add Contact'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 45),
            ),
            onPressed: _navigateToAddContact,
          ),
        ),
        
        Expanded(
          child: filteredKhatas.isEmpty
              ? Center(
                  child: Text(
                    khatas.isEmpty 
                        ? 'No records found. Add a new khata.'
                        : 'No matching records found.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  itemCount: filteredKhatas.length,
                  itemBuilder: (context, index) {
                    final khata = filteredKhatas[index];
                    final contact = _contactsMap[khata.contactId];
                    
                    return FutureBuilder<double>(
                      future: _calculateKhataBalance(khata.id!),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const ListTile(
                            title: Text('Loading...'),
                            trailing: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        
                        final balance = snapshot.data!;
                        
                        return KhataListItem(
                          name: contact?.name ?? 'Unknown',
                          balance: balance,
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => KhataDetailScreen(khataId: khata.id.toString()),
                              ),
                            );
                            
                            if (result == true) {
                              _loadData();
                            }
                          },
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
  
  void _navigateToAddContact() async {
    // Create an empty contact map to pass to the EditContactScreen
    final emptyContact = {
      'name': '',
      'phone': '',
      'category': 'Personal',
    };
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditContactScreen(contact: emptyContact),
      ),
    );
    
    // Reload data if contact was successfully added
    if (result == true) {
      _loadData();
    }
  }
} 