import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/customer_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;
  
  bool _initialized = false;
  late Box<Customer> _customersBox;
  
  DatabaseService._internal();
  
  Future<void> init() async {
    if (_initialized) return;
    
    // Initialize Hive
    final appDocumentDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);
    
    // Register adapters
    Hive.registerAdapter(EntryTypeAdapter());
    Hive.registerAdapter(CustomerEntryAdapter());
    Hive.registerAdapter(CustomerAdapter());
    
    // Open boxes
    _customersBox = await Hive.openBox<Customer>('customers');
    
    _initialized = true;
  }
  
  // CRUD operations for Customers
  
  // Get all customers (optimized with compute function)
  Future<List<Customer>> getAllCustomers() async {
    if (!_initialized) await init();
    
    // Using compute to move this operation off the UI thread
    return compute(_extractCustomers, _customersBox.values.toList());
  }
  
  // Helper function to run in isolate
  static List<Customer> _extractCustomers(List<Customer> customers) {
    return customers;
  }
  
  // Get customers for a specific date
  Future<List<Customer>> getCustomersForDate(DateTime date) async {
    final allCustomers = await getAllCustomers();
    
    return compute(_filterCustomersByDate, {
      'customers': allCustomers, 
      'year': date.year,
      'month': date.month,
      'day': date.day
    });
  }
  
  // Helper function to run in isolate
  static List<Customer> _filterCustomersByDate(Map<String, dynamic> params) {
    final List<Customer> customers = params['customers'];
    final int year = params['year'];
    final int month = params['month'];
    final int day = params['day'];
    
    return customers.where((customer) {
      return customer.date.year == year && 
             customer.date.month == month && 
             customer.date.day == day;
    }).toList();
  }
  
  // Add a customer
  Future<void> addCustomer(Customer customer) async {
    if (!_initialized) await init();
    
    await _customersBox.put(customer.id, customer);
  }
  
  // Update a customer
  Future<void> updateCustomer(Customer customer) async {
    if (!_initialized) await init();
    
    await _customersBox.put(customer.id, customer);
  }
  
  // Delete a customer
  Future<void> deleteCustomer(String customerId) async {
    if (!_initialized) await init();
    
    await _customersBox.delete(customerId);
  }
  
  // Calculate summaries (optimized with compute function)
  Future<Map<String, dynamic>> calculateTotals() async {
    final allCustomers = await getAllCustomers();
    
    return compute(_calculateTotals, allCustomers);
  }
  
  // Helper function to run in isolate
  static Map<String, dynamic> _calculateTotals(List<Customer> customers) {
    int totalCups = 0;
    double totalAmount = 0;
    double collectedAmount = 0;
    double remainingAmount = 0;
    
    for (var customer in customers) {
      totalCups += customer.cups;
      totalAmount += customer.totalAmount;
      collectedAmount += customer.paymentsMade;
    }
    
    remainingAmount = totalAmount - collectedAmount;
    
    return {
      'totalCups': totalCups,
      'totalAmount': totalAmount,
      'collectedAmount': collectedAmount,
      'remainingAmount': remainingAmount
    };
  }
  
  // Search for customers by name
  Future<List<Customer>> searchCustomersByName(String query) async {
    final allCustomers = await getAllCustomers();
    
    return compute(_searchCustomers, {
      'customers': allCustomers,
      'query': query.toLowerCase(),
    });
  }
  
  // Helper function to run in isolate
  static List<Customer> _searchCustomers(Map<String, dynamic> params) {
    final List<Customer> customers = params['customers'];
    final String query = params['query'];
    
    if (query.isEmpty) return customers;
    
    return customers
      .where((customer) => customer.name.toLowerCase().contains(query))
      .toList();
  }
  
  // Sort customers (optimized with compute function)
  Future<List<Customer>> sortCustomers(List<Customer> customers, String sortBy) async {
    return compute(_sortCustomers, {
      'customers': customers,
      'sortBy': sortBy,
    });
  }
  
  // Helper function to run in isolate
  static List<Customer> _sortCustomers(Map<String, dynamic> params) {
    final List<Customer> customers = List.from(params['customers']);
    final String sortBy = params['sortBy'];
    
    switch (sortBy) {
      case 'recent':
        customers.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
        break;
      case 'name':
        customers.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'amount':
        customers.sort((a, b) => (b.pendingAmount).compareTo(a.pendingAmount));
        break;
      case 'cups':
        customers.sort((a, b) => b.cups.compareTo(a.cups));
        break;
    }
    
    return customers;
  }
} 