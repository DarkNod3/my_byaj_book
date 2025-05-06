import 'package:flutter/foundation.dart';
import '../models/customer_model.dart';
import '../services/database_service.dart';

class CustomerProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;
  
  List<Customer> _allCustomers = [];
  List<Customer> _filteredCustomers = [];
  DateTime _selectedDate = DateTime.now();
  String _sortBy = 'recent';
  String _searchQuery = '';
  bool _isLoading = false;
  
  // Getters
  List<Customer> get allCustomers => _allCustomers;
  List<Customer> get filteredCustomers => _filteredCustomers;
  DateTime get selectedDate => _selectedDate;
  String get sortBy => _sortBy;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  
  // Summary data
  int _totalCups = 0;
  double _totalAmount = 0;
  double _collectedAmount = 0;
  double _remainingAmount = 0;
  
  int get totalCups => _totalCups;
  double get totalAmount => _totalAmount;
  double get collectedAmount => _collectedAmount;
  double get remainingAmount => _remainingAmount;
  
  // Initialize provider
  Future<void> init() async {
    _setLoading(true);
    await _databaseService.init();
    await _loadCustomers();
    _setLoading(false);
  }
  
  // Load all customers
  Future<void> _loadCustomers() async {
    _allCustomers = await _databaseService.getAllCustomers();
    await _updateTotals();
    await _applyFilters();
  }
  
  // Apply sorting and filtering
  Future<void> _applyFilters() async {
    List<Customer> filtered = List.from(_allCustomers);
    
    // Apply date filter if needed
    if (_selectedDate != null) {
      filtered = await _databaseService.getCustomersForDate(_selectedDate);
    }
    
    // Apply search query if any
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where(
        (customer) => customer.name.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // Apply sorting
    _filteredCustomers = await _databaseService.sortCustomers(filtered, _sortBy);
    
    notifyListeners();
  }
  
  // Update date filter
  Future<void> setSelectedDate(DateTime date) async {
    _selectedDate = date;
    await _applyFilters();
  }
  
  // Update sort order
  Future<void> setSortBy(String sortBy) async {
    _sortBy = sortBy;
    await _applyFilters();
  }
  
  // Update search query
  Future<void> setSearchQuery(String query) async {
    _searchQuery = query;
    await _applyFilters();
  }
  
  // Add a new customer
  Future<void> addCustomer(Customer customer) async {
    await _databaseService.addCustomer(customer);
    await _loadCustomers();
  }
  
  // Update an existing customer
  Future<void> updateCustomer(Customer customer) async {
    await _databaseService.updateCustomer(customer);
    await _loadCustomers();
  }
  
  // Delete a customer
  Future<void> deleteCustomer(String customerId) async {
    await _databaseService.deleteCustomer(customerId);
    await _loadCustomers();
  }
  
  // Update totals and statistics
  Future<void> _updateTotals() async {
    final totals = await _databaseService.calculateTotals();
    
    _totalCups = totals['totalCups'];
    _totalAmount = totals['totalAmount'];
    _collectedAmount = totals['collectedAmount'];
    _remainingAmount = totals['remainingAmount'];
    
    notifyListeners();
  }
  
  // Helper to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  // Calculate today's pending amount
  Future<double> getTodayPending() async {
    final todayCustomers = await _databaseService.getCustomersForDate(DateTime.now());
    
    double pending = 0;
    for (var customer in todayCustomers) {
      pending += customer.pendingAmount;
    }
    
    return pending;
  }
} 