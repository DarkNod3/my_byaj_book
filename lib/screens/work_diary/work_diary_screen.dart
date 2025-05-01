import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../widgets/header/app_header.dart';
import '../../models/work_diary/client.dart';
import './client_detail_screen.dart';
import '../../constants/colors.dart';

class WorkDiaryScreen extends StatefulWidget {
  final bool showAppBar;
  const WorkDiaryScreen({Key? key, this.showAppBar = true}) : super(key: key);

  @override
  _WorkDiaryScreenState createState() => _WorkDiaryScreenState();
}

class _WorkDiaryScreenState extends State<WorkDiaryScreen> with SingleTickerProviderStateMixin {
  List<Client> _clients = [];
  List<Client> _filteredClients = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadClients();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _searchController.addListener(_filterClients);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterClients);
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final clientsJson = prefs.getString('workDiaryClients');
      
      if (clientsJson != null) {
        final List<dynamic> decoded = jsonDecode(clientsJson);
        _clients = decoded.map((item) => Client.fromJson(item)).toList();
        _filterClients();
      }
    } catch (e) {
      print('Error loading clients: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading clients: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveClients() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clientsJson = jsonEncode(_clients.map((c) => c.toJson()).toList());
      await prefs.setString('workDiaryClients', clientsJson);
    } catch (e) {
      print('Error saving clients: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving clients: $e')),
      );
    }
  }

  void _filterClients() {
    if (_searchQuery.isEmpty) {
      _filteredClients = List.from(_clients);
    } else {
      _filteredClients = _clients
          .where((client) =>
              client.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              client.phoneNumber.contains(_searchQuery))
          .toList();
    }
    setState(() {});
  }

  void _addClient() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final hourlyRateController = TextEditingController();
    final halfDayRateController = TextEditingController();
    final fullDayRateController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Client'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Client Name *',
                  hintText: 'Enter client name',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter phone number (optional)',
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),
              Text('Rate Information', style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: hourlyRateController,
                decoration: InputDecoration(labelText: 'Hourly Rate (₹)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: halfDayRateController,
                decoration: InputDecoration(labelText: 'Half Day Rate (₹)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: fullDayRateController,
                decoration: InputDecoration(labelText: 'Full Day Rate (₹)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Client name is required')),
                );
                return;
              }
              Navigator.of(context).pop(true);
            },
            child: Text('Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      final newClient = Client(
        id: Uuid().v4(),
        name: nameController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        hourlyRate: double.tryParse(hourlyRateController.text) ?? 0.0,
        halfDayRate: double.tryParse(halfDayRateController.text) ?? 0.0,
        fullDayRate: double.tryParse(fullDayRateController.text) ?? 0.0,
      );

      setState(() {
        _clients.add(newClient);
        _filterClients();
      });

      await _saveClients();
    }
  }

  void _updateClient(Client updatedClient) async {
    setState(() {
      final index = _clients.indexWhere((c) => c.id == updatedClient.id);
      if (index != -1) {
        _clients[index] = updatedClient;
        _filterClients();
      }
    });
    await _saveClients();
  }

  void _deleteClient(String clientId) async {
    setState(() {
      _clients.removeWhere((c) => c.id == clientId);
      _filterClients();
    });
    await _saveClients();
  }

  void _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Handle back button press
        Navigator.of(context).pop();
        return false; // Prevent default back button behavior
      },
      child: Scaffold(
        appBar: widget.showAppBar ? AppBar(
          title: Text('Work Diary'),
          backgroundColor: AppColors.primary,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                _animationController.reset();
                _loadClients();
              },
            ),
            IconButton(
              icon: Icon(Icons.notifications),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Notifications coming soon!')),
                );
              },
            ),
          ],
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ) : null,
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search clients...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: EdgeInsets.symmetric(vertical: 0),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                    _filterClients();
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _filterClients();
                        });
                      },
                    ),
                  ),
                  _buildSummaryCard(),
                  Expanded(
                    child: _filteredClients.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: _filteredClients.length,
                            padding: EdgeInsets.only(bottom: 80),
                            itemBuilder: (context, index) {
                              final client = _filteredClients[index];
                              return _buildClientCard(client);
                            },
                          ),
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addClient,
          backgroundColor: AppColors.primary,
          child: Icon(Icons.add),
          tooltip: 'Add Client',
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalClients = _clients.length;
    final totalEarnings = _clients.fold(
      0.0, 
      (total, client) => total + client.totalEarnings
    );

    final todayEarnings = _clients.fold(0.0, (total, client) {
      return total + client.workEntries
          .where((entry) => 
            entry.date.year == _selectedDate.year && 
            entry.date.month == _selectedDate.month && 
            entry.date.day == _selectedDate.day)
          .fold(0.0, (sum, entry) => sum + entry.amount);
    });

    final currentMonthEarnings = _clients.fold(0.0, (total, client) {
      return total + client.workEntries
          .where((entry) => 
            entry.date.year == _selectedDate.year && 
            entry.date.month == _selectedDate.month)
          .fold(0.0, (sum, entry) => sum + entry.amount);
    });

    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Work Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: _pickDate,
                  child: Row(
                    children: [
                      Text(
                        DateFormat('dd MMM yyyy').format(_selectedDate),
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.calendar_today, size: 16),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildMetricItem(
                    icon: Icons.person,
                    iconColor: Colors.blue,
                    label: 'Clients',
                    value: totalClients.toString(),
                  ),
                  _buildMetricItem(
                    icon: Icons.today,
                    iconColor: Colors.green,
                    label: 'Today',
                    value: currencyFormat.format(todayEarnings),
                  ),
                  _buildMetricItem(
                    icon: Icons.date_range,
                    iconColor: Colors.orange,
                    label: 'This Month',
                    value: currencyFormat.format(currentMonthEarnings),
                  ),
                  _buildMetricItem(
                    icon: Icons.account_balance_wallet,
                    iconColor: Colors.purple,
                    label: 'Total',
                    value: currencyFormat.format(totalEarnings),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      width: 100,
      margin: EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(Client client) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      child: InkWell(
        onTap: () => _openClientDetails(client),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: client.avatarColor,
                radius: 25,
                child: Text(
                  client.initials,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (client.phoneNumber.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          client.phoneNumber,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    SizedBox(height: 4),
                    Text(
                      'Last entry: ${client.workEntries.isNotEmpty ? DateFormat('dd MMM yyyy').format(client.workEntries.first.date) : 'No entries'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(client.totalEarnings),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${client.workEntries.length} entries',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openClientDetails(Client client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientDetailScreen(
          client: client,
          updateClient: _updateClient,
          deleteClient: _deleteClient,
        ),
      ),
    ).then((_) {
      // Refresh client list when returning from detail screen
      setState(() {
        _filterClients();
      });
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No clients yet'
                : 'No clients matching "$_searchQuery"',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16),
          if (_searchQuery.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _filterClients();
                });
              },
              child: Text('Clear Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _addClient,
              icon: Icon(Icons.add),
              label: Text('Add Your First Client'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }
} 