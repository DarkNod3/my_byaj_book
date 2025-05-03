import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import '../../widgets/header/app_header.dart';
import '../../models/work_diary/client.dart';
import '../../models/work_diary/work_entry.dart';
import './client_detail_screen.dart';
import '../../constants/colors.dart';

class WorkDiaryScreen extends StatefulWidget {
  final bool showAppBar;
  
  const WorkDiaryScreen({
    Key? key,
    this.showAppBar = true
  }) : super(key: key);

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
  bool _isDialOpen = false;

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

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 16,
                left: 16, 
                right: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Handle bar at top
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add New Client',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Client Name
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Client Name *',
                      hintText: 'Enter client name',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  
                  // Phone Number
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'Enter phone number (optional)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  
                  // Rate Information header
                  Text(
                    'Rate Information',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Hourly Rate
                  TextField(
                    controller: hourlyRateController,
                    decoration: InputDecoration(
                      labelText: 'Hourly Rate (₹)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  
                  // Half Day Rate
                  TextField(
                    controller: halfDayRateController,
                    decoration: InputDecoration(
                      labelText: 'Half Day Rate (₹)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  
                  // Full Day Rate
                  TextField(
                    controller: fullDayRateController,
                    decoration: InputDecoration(
                      labelText: 'Full Day Rate (₹)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text('Cancel'),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text('Add'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          );
          },
        );
      },
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
      child: GestureDetector(
        onTap: () {
          if (_isDialOpen) {
            setState(() {
              _isDialOpen = false;
            });
          }
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
              IconButton(
                icon: Icon(Icons.picture_as_pdf),
                onPressed: _generateAllClientsPDF,
                tooltip: 'Generate PDF Report',
              ),
            ],
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ) : null,
          body: _isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView(
                  children: [
                    _buildSummaryCard(),
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
                    _filteredClients.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _filteredClients.length,
                          padding: EdgeInsets.only(bottom: 80),
                          itemBuilder: (context, index) {
                            final client = _filteredClients[index];
                            return _buildClientCard(client);
                          },
                        ),
                  ],
                ),
          floatingActionButton: _buildFloatingActionButtons(),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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

    // Calculate pending earnings by separating work entries (earnings) from payment entries (deductions)
    final pendingEarnings = _clients.fold(0.0, (total, client) {
      // Calculate total work/service earnings (not payments)
      final totalWork = client.workEntries
          .where((entry) => 
            !entry.description.toLowerCase().contains('received') && 
            !entry.description.toLowerCase().contains('payment'))
          .fold(0.0, (sum, entry) => sum + entry.amount);
      
      // Calculate total payments received
      final totalPayments = client.workEntries
          .where((entry) => 
            entry.description.toLowerCase().contains('received') || 
            entry.description.toLowerCase().contains('payment'))
          .fold(0.0, (sum, entry) => sum + entry.amount);
      
      // Calculate pending amount (work minus payments)
      final clientPending = totalWork - totalPayments;
      
      // Add to total, ensuring we don't add negative values
      return total + (clientPending > 0 ? clientPending : 0);
    });

    return Column(
      children: [
        // Main Summary Card
        Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Work Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Row(
                        children: [
                          Text(
                            DateFormat('dd MMM yyyy').format(_selectedDate),
                            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.calendar_today, size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                
                // New 2x2 grid layout for metrics
                Row(
                  children: [
                    Expanded(
                      child: _buildNewMetricItem(
                        icon: Icons.people,
                        iconColor: Colors.blue,
                        label: 'Total Clients',
                        value: totalClients.toString(),
                        backgroundColor: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildNewMetricItem(
                        icon: Icons.today,
                        iconColor: Colors.green,
                        label: "Today's Earnings",
                        value: currencyFormat.format(todayEarnings),
                        backgroundColor: Colors.green.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildNewMetricItem(
                        icon: Icons.account_balance_wallet,
                        iconColor: Colors.purple,
                        label: 'Total Earnings',
                        value: currencyFormat.format(totalEarnings),
                        backgroundColor: Colors.purple.withOpacity(0.1),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildNewMetricItem(
                        icon: Icons.pending_actions,
                        iconColor: Colors.orange,
                        label: 'Pending Earnings',
                        value: currencyFormat.format(pendingEarnings),
                        backgroundColor: Colors.orange.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Filter button for pending amounts
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
          child: _buildFilterOptions(),
        ),
      ],
    );
  }
  
  Widget _buildNewMetricItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color backgroundColor,
  }) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 2),
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
          ),
        ],
      ),
    );
  }
  
  // New filter options widget
  Widget _buildFilterOptions() {
    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: () {
          _showPendingAmountsFilter();
        },
        icon: Icon(Icons.filter_list, size: 16),
        label: Text('Show Clients with Pending Amounts', style: TextStyle(fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  void _showPendingAmountsFilter() {
    // Create a list of clients with pending amounts
    final clientsWithPending = _clients.where((client) {
      // Calculate total work/service earnings (not payments)
      final totalWork = client.workEntries
          .where((entry) => 
            !entry.description.toLowerCase().contains('received') && 
            !entry.description.toLowerCase().contains('payment'))
          .fold(0.0, (sum, entry) => sum + entry.amount);
      
      // Calculate total payments received
      final totalPayments = client.workEntries
          .where((entry) => 
            entry.description.toLowerCase().contains('received') || 
            entry.description.toLowerCase().contains('payment'))
          .fold(0.0, (sum, entry) => sum + entry.amount);
      
      // Check if client has pending amount
      return (totalWork - totalPayments) > 0;
    }).toList();
    
    // Sort by highest pending amount
    clientsWithPending.sort((a, b) {
      // Calculate pending amount for client A
      final aTotalWork = a.workEntries
          .where((entry) => 
            !entry.description.toLowerCase().contains('received') && 
            !entry.description.toLowerCase().contains('payment'))
          .fold(0.0, (sum, entry) => sum + entry.amount);
      
      final aTotalPayments = a.workEntries
          .where((entry) => 
            entry.description.toLowerCase().contains('received') || 
            entry.description.toLowerCase().contains('payment'))
          .fold(0.0, (sum, entry) => sum + entry.amount);
      
      final aPending = aTotalWork - aTotalPayments;
      
      // Calculate pending amount for client B
      final bTotalWork = b.workEntries
          .where((entry) => 
            !entry.description.toLowerCase().contains('received') && 
            !entry.description.toLowerCase().contains('payment'))
          .fold(0.0, (sum, entry) => sum + entry.amount);
      
      final bTotalPayments = b.workEntries
          .where((entry) => 
            entry.description.toLowerCase().contains('received') || 
            entry.description.toLowerCase().contains('payment'))
          .fold(0.0, (sum, entry) => sum + entry.amount);
      
      final bPending = bTotalWork - bTotalPayments;
          
      return bPending.compareTo(aPending);
    });
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Clients with Pending Amounts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Expanded(
                child: clientsWithPending.isEmpty
                    ? Center(
                        child: Text(
                          'No clients with pending amounts',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: clientsWithPending.length,
                        itemBuilder: (context, index) {
                          final client = clientsWithPending[index];
                          
                          // Calculate total work amount (not including payments)
                          final totalWork = client.workEntries
                              .where((entry) => 
                                !entry.description.toLowerCase().contains('received') && 
                                !entry.description.toLowerCase().contains('payment'))
                              .fold(0.0, (sum, entry) => sum + entry.amount);
                          
                          // Calculate total payments received
                          final paymentsReceived = client.workEntries
                              .where((entry) => 
                                entry.description.toLowerCase().contains('received') || 
                                entry.description.toLowerCase().contains('payment'))
                              .fold(0.0, (sum, entry) => sum + entry.amount);
                          
                          // Calculate pending amount (work minus payments)
                          final pendingAmount = totalWork - paymentsReceived > 0 ? 
                              totalWork - paymentsReceived : 0;
                          
                          return Card(
                            margin: EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: client.avatarColor,
                                child: Text(
                                  client.initials,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(client.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        'Work: ',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      Text(
                                        currencyFormat.format(totalWork),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '  |  Paid: ',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      Text(
                                        currencyFormat.format(paymentsReceived),
                                        style: TextStyle(
                                          fontSize: 12, 
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Pending',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    currencyFormat.format(pendingAmount),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _openClientDetails(client);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Add this helper method to calculate the true pending balance
  double _calculateClientPendingBalance(Client client) {
    // Calculate total work amount (not including payments)
    final totalWork = client.workEntries
        .where((entry) => 
          !entry.description.toLowerCase().contains('received') && 
          !entry.description.toLowerCase().contains('payment'))
        .fold(0.0, (sum, entry) => sum + entry.amount);
    
    // Calculate total payments received
    final totalPayments = client.workEntries
        .where((entry) => 
          entry.description.toLowerCase().contains('received') || 
          entry.description.toLowerCase().contains('payment'))
        .fold(0.0, (sum, entry) => sum + entry.amount);
    
    // Calculate pending amount (work minus payments)
    final pendingAmount = totalWork - totalPayments;
    
    return pendingAmount > 0 ? pendingAmount : 0;
  }

  Widget _buildClientCard(Client client) {
    // Calculate pending balance
    final pendingBalance = _calculateClientPendingBalance(client);
    
    // Calculate total work and total payments for displaying
    final totalWork = client.workEntries
        .where((entry) => 
          !entry.description.toLowerCase().contains('received') && 
          !entry.description.toLowerCase().contains('payment'))
        .fold(0.0, (sum, entry) => sum + entry.amount);
    
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            client.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // PDF icon button
                        IconButton(
                          icon: Icon(Icons.picture_as_pdf, size: 20, color: Colors.red),
                          onPressed: () => _generateClientPDF(client),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(minWidth: 30),
                          tooltip: 'Generate PDF Report',
                        ),
                      ],
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
                  Row(
                    children: [
                      if (pendingBalance > 0)
                        Icon(Icons.warning, size: 14, color: Colors.orange),
                      SizedBox(width: pendingBalance > 0 ? 4 : 0),
                      Text(
                        currencyFormat.format(pendingBalance > 0 ? pendingBalance : totalWork),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: pendingBalance > 0 ? Colors.orange : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    pendingBalance > 0 ? 'Pending' : '${client.workEntries.length} entries',
                    style: TextStyle(
                      fontSize: 12,
                      color: pendingBalance > 0 ? Colors.orange : Colors.grey[600],
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

  Future<void> _generateAllClientsPDF() async {
    if (_clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No clients to generate report')),
      );
      return;
    }

    // Show a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating PDF report...'),
            ],
          ),
        );
      },
    );

    try {
      // In a real implementation, you would use a PDF generation library like pdf or flutter_pdfview
      // For this example, we'll just show a success message after a delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Close the loading dialog
      Navigator.of(context).pop();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF report generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close the loading dialog
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addPayment() async {
    if (_clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a client first')),
      );
      return;
    }

    Client? selectedClient = _clients.isNotEmpty ? _clients[0] : null;
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final paymentDateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar at top
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add Payment',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Client Dropdown
                  DropdownButtonFormField<Client>(
                    decoration: InputDecoration(
                      labelText: 'Select Client',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedClient,
                    items: _clients.map((client) {
                      return DropdownMenuItem<Client>(
                        value: client,
                        child: Text(client.name),
                      );
                    }).toList(),
                    onChanged: (Client? value) {
                      setState(() {
                        selectedClient = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Payment amount
                  TextField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: 'Payment Amount (₹)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  
                  // Payment date
                  GestureDetector(
                    onTap: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          paymentDateController.text = 
                              DateFormat('yyyy-MM-dd').format(pickedDate);
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        controller: paymentDateController,
                        decoration: InputDecoration(
                          labelText: 'Payment Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        final amount = double.tryParse(amountController.text);
                        if (selectedClient == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select a client')),
                          );
                          return;
                        }
                        if (amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid amount')),
                          );
                          return;
                        }
                        
                        Navigator.pop(context, {
                          'client': selectedClient,
                          'amount': amount,
                          'date': DateTime.parse(paymentDateController.text),
                          'description': descriptionController.text,
                        });
                      },
                      child: const Text(
                        'SAVE PAYMENT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
          },
        );
      },
    );

    if (result != null) {
      final Client client = result['client'];
      final double amount = result['amount'];
      final DateTime date = result['date'];
      String description = result['description'];
      
      // Ensure the description contains the word "payment" to properly track it
      if (description.isEmpty) {
        description = "Payment received";
      } else if (!description.toLowerCase().contains("payment") && 
                !description.toLowerCase().contains("received")) {
        description = "Payment: $description";
      }
      
      final newEntry = WorkEntry(
        id: Uuid().v4(),
        date: date,
        durationType: 'Payment',
        amount: amount,
        description: description,
      );

      final index = _clients.indexWhere((c) => c.id == client.id);
      if (index != -1) {
        final updatedEntries = List<WorkEntry>.from(_clients[index].workEntries)..add(newEntry);
        final updatedClient = _clients[index].copyWith(workEntries: updatedEntries);
        
        setState(() {
          _clients[index] = updatedClient;
          _filterClients();
        });
        
        await _saveClients();
        
        // Calculate the remaining pending amount using the same method used elsewhere
        final remainingBalance = _calculateClientPendingBalance(updatedClient);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment of ${currencyFormat.format(amount)} added to ${client.name}.' + 
              (remainingBalance > 0 ? ' Remaining balance: ${currencyFormat.format(remainingBalance)}' : ' All payments settled!')
            ),
            duration: Duration(seconds: 3),
            backgroundColor: remainingBalance > 0 ? Colors.orange : Colors.green,
          ),
        );
      }
    }
  }

  // Add new method for generating individual client PDF
  Future<void> _generateClientPDF(Client client) async {
    if (client.workEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No entries to generate report for ${client.name}')),
      );
      return;
    }

    // Show a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating PDF report for ${client.name}...'),
            ],
          ),
        );
      },
    );

    try {
      // Get directory for storing PDFs
      final directory = await getExternalStorageDirectory();
      final String formattedDate = DateFormat('dd-MM-yyyy_HH-mm').format(DateTime.now());
      final fileName = 'client_report_${client.name.replaceAll(' ', '_')}_$formattedDate.pdf';
      final filePath = '${directory!.path}/$fileName';
      
      // Format currency for PDF
      String formatCurrencyForPdf(double amount) {
        return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(amount);
      }

      // Generate PDF
      final pdf = pw.Document();
      
      // Add client summary page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  padding: pw.EdgeInsets.all(16),
                  color: PdfColors.blue700,
                  child: pw.Row(
                    children: [
                      pw.Container(
                        width: 50,
                        height: 50,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          shape: pw.BoxShape.circle,
                        ),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          client.initials,
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue700,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 16),
                      pw.Text(
                        client.name,
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Work Statistics
                pw.Text(
                  'Work Statistics',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Hours: ${client.hoursCount}'),
                    pw.Text('Half Days: ${client.halfDaysCount}'),
                    pw.Text('Full Days: ${client.fullDaysCount}'),
                  ],
                ),
                
                pw.SizedBox(height: 20),
                
                // Calculate work and payment amounts
                pw.Builder(
                  builder: (context) {
                    // Calculate total work amount (not including payments)
                    final totalWork = client.workEntries
                        .where((entry) => 
                          !entry.description.toLowerCase().contains('received') && 
                          !entry.description.toLowerCase().contains('payment'))
                        .fold(0.0, (sum, entry) => sum + entry.amount);
                    
                    // Calculate total payments received
                    final amountReceived = client.workEntries
                        .where((entry) => 
                          entry.description.toLowerCase().contains('received') || 
                          entry.description.toLowerCase().contains('payment'))
                        .fold(0.0, (sum, entry) => sum + entry.amount);
                    
                    // Calculate pending amount (work minus payments)
                    final amountDue = totalWork - amountReceived;
                    
                    return pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Payment Summary',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Total Amount:'),
                            pw.Text(formatCurrencyForPdf(totalWork)),
                          ],
                        ),
                        pw.SizedBox(height: 5),
                        
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Amount Received:'),
                            pw.Text(formatCurrencyForPdf(amountReceived)),
                          ],
                        ),
                        pw.SizedBox(height: 5),
                        
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Amount Due:'),
                            pw.Text(formatCurrencyForPdf(amountDue)),
                          ],
                        ),
                      ],
                    );
                  }
                ),
                
                pw.SizedBox(height: 30),
                
                // Work History
                pw.Text(
                  'Work History',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                
                // Table header
                pw.Container(
                  color: PdfColors.grey200,
                  padding: pw.EdgeInsets.all(8),
                  child: pw.Row(
                    children: [
                      pw.Expanded(flex: 2, child: pw.Text('Date')),
                      pw.Expanded(flex: 2, child: pw.Text('Type')),
                      pw.Expanded(flex: 3, child: pw.Text('Description')),
                      pw.Expanded(flex: 2, child: pw.Text('Amount')),
                    ],
                  ),
                ),
                
                // List of entries (limited to avoid overflow)
                ...client.workEntries.take(20).map((entry) {
                  final isPayment = entry.description.toLowerCase().contains('received') || 
                                   entry.description.toLowerCase().contains('payment');
                  
                  return pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.grey300),
                      ),
                    ),
                    padding: pw.EdgeInsets.all(8),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 2, 
                          child: pw.Text(DateFormat('dd/MM/yyyy').format(entry.date))
                        ),
                        pw.Expanded(
                          flex: 2, 
                          child: pw.Text(entry.durationType)
                        ),
                        pw.Expanded(
                          flex: 3, 
                          child: pw.Text(
                            entry.description,
                            maxLines: 1,
                            overflow: pw.TextOverflow.clip,
                          )
                        ),
                        pw.Expanded(
                          flex: 2, 
                          child: pw.Text(
                            formatCurrencyForPdf(entry.amount),
                            style: pw.TextStyle(
                              color: isPayment ? PdfColors.green : PdfColors.black,
                            ),
                          )
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            );
          },
        ),
      );

      // Save the PDF file
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      
      // Close the loading dialog
      Navigator.of(context).pop();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF report for ${client.name} generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Automatically open the PDF file
      await OpenFile.open(filePath);
      
    } catch (e) {
      // Close the loading dialog
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildFloatingActionButtons() {
    return Container(
      height: 240, // Fixed height for the stack
      width: 180, // Fixed width for the stack
      alignment: Alignment.bottomRight,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // Semi-transparent background overlay when menu is open
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_isDialOpen,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isDialOpen ? 1.0 : 0.0,
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          
          // Add Payment Button
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            right: 4,
            bottom: _isDialOpen ? 160 : 4,
            child: AnimatedOpacity(
              opacity: _isDialOpen ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Label container
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: _isDialOpen ? 1.0 : 0.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Add Payment',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  // Button
                  FloatingActionButton(
                    mini: true,
                    heroTag: 'addPayment',
                    elevation: _isDialOpen ? 6 : 0,
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.payments, color: Colors.white),
                    onPressed: _isDialOpen ? () {
                      setState(() {
                        _isDialOpen = false;
                      });
                      _addPayment();
                    } : null,
                  ),
                ],
              ),
            ),
          ),
          
          // Add Client Button
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            right: 4,
            bottom: _isDialOpen ? 80 : 4,
            child: AnimatedOpacity(
              opacity: _isDialOpen ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Label container
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: _isDialOpen ? 1.0 : 0.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Add Client',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  // Button
                  FloatingActionButton(
                    mini: true,
                    heroTag: 'addClient',
                    elevation: _isDialOpen ? 6 : 0,
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.person_add, color: Colors.white),
                    onPressed: _isDialOpen ? () {
                      setState(() {
                        _isDialOpen = false;
                      });
                      _addClient();
                    } : null,
                  ),
                ],
              ),
            ),
          ),
          
          // Main FAB that toggles the dial
          Positioned(
            right: 0,
            bottom: 0,
            child: FloatingActionButton(
              heroTag: 'mainFAB',
              elevation: 6,
              backgroundColor: _isDialOpen ? Colors.red : AppColors.primary,
              onPressed: () {
                setState(() {
                  _isDialOpen = !_isDialOpen;
                });
              },
              child: AnimatedRotation(
                turns: _isDialOpen ? 0.125 : 0, // Rotate 45 degrees when open
                duration: const Duration(milliseconds: 250),
                child: Icon(_isDialOpen ? Icons.close : Icons.add, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 