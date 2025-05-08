import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/customer_model.dart';
import '../models/khata.dart';
import '../models/transaction.dart';
import '../models/contact.dart';

// Define adapters for use with Hive
class KhataAdapter extends TypeAdapter<Khata> {
  @override
  final int typeId = 2;

  @override
  Khata read(BinaryReader reader) {
    // Simple adapter to prevent errors. In a real app, implement full serialization
    return Khata(
      contactId: 0,
      contactName: '',
      type: KhataType.withoutInterest,
      currentBalance: 0.0,
    );
  }

  @override
  void write(BinaryWriter writer, Khata obj) {
    // Simple adapter to prevent errors. In a real app, implement full serialization
  }
}

class KhataTypeAdapter extends TypeAdapter<KhataType> {
  @override
  final int typeId = 3;

  @override
  KhataType read(BinaryReader reader) {
    return KhataType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, KhataType obj) {
    writer.writeByte(obj.index);
  }
}

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 4;

  @override
  Transaction read(BinaryReader reader) {
    // Simple adapter to prevent errors. In a real app, implement full serialization
    return Transaction(
      khataId: 0,
      type: TransactionType.received,
      amount: 0.0,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    // Simple adapter to prevent errors. In a real app, implement full serialization
  }
}

class TransactionTypeAdapter extends TypeAdapter<TransactionType> {
  @override
  final int typeId = 5;

  @override
  TransactionType read(BinaryReader reader) {
    return TransactionType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, TransactionType obj) {
    writer.writeByte(obj.index);
  }
}

class ContactAdapter extends TypeAdapter<Contact> {
  @override
  final int typeId = 6;

  @override
  Contact read(BinaryReader reader) {
    // Simple adapter to prevent errors. In a real app, implement full serialization
    return Contact(name: '');
  }

  @override
  void write(BinaryWriter writer, Contact obj) {
    // Simple adapter to prevent errors. In a real app, implement full serialization
  }
}

class InterestCalculationTypeAdapter extends TypeAdapter<InterestCalculationType> {
  @override
  final int typeId = 7;

  @override
  InterestCalculationType read(BinaryReader reader) {
    return InterestCalculationType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, InterestCalculationType obj) {
    writer.writeByte(obj.index);
  }
}

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;
  
  bool _initialized = false;
  late Box<Customer> _customersBox;
  late Box<Khata> _khataBox;
  late Box<Transaction> _transactionBox;
  late Box<Contact> _contactBox;
  
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
    Hive.registerAdapter(KhataAdapter());
    Hive.registerAdapter(KhataTypeAdapter());
    Hive.registerAdapter(TransactionAdapter());
    Hive.registerAdapter(TransactionTypeAdapter());
    Hive.registerAdapter(ContactAdapter());
    Hive.registerAdapter(InterestCalculationTypeAdapter());
    
    // Open boxes
    _customersBox = await Hive.openBox<Customer>('customers');
    _khataBox = await Hive.openBox<Khata>('khatas');
    _transactionBox = await Hive.openBox<Transaction>('transactions');
    _contactBox = await Hive.openBox<Contact>('contacts');
    
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
    
    // First check if the customer exists
    if (_customersBox.containsKey(customerId)) {
      // Permanently delete from Hive box
      await _customersBox.delete(customerId);
      
      // Compact the database to reclaim space after deletion
      await _customersBox.compact();
      
      // Flush all pending writes to ensure changes are persisted
      await _customersBox.flush();
    }
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
  
  // === KHATA RELATED METHODS ===
  
  // Get khatas by type
  Future<List<Khata>> getKhatasByType(KhataType type) async {
    if (!_initialized) await init();
    
    final List<Khata> khatas = _khataBox.values.where((khata) => khata.type == type).toList();
    return khatas;
  }
  
  // Get all khatas
  Future<List<Khata>> getAllKhatas() async {
    if (!_initialized) await init();
    
    return _khataBox.values.toList();
  }
  
  // Add a khata
  Future<void> addKhata(Khata khata) async {
    if (!_initialized) await init();
    
    await _khataBox.add(khata);
  }
  
  // Update a khata
  Future<void> updateKhata(Khata khata) async {
    if (!_initialized) await init();
    
    if (khata.id != null) {
      await _khataBox.put(khata.id, khata);
    }
  }
  
  // Delete a khata
  Future<void> deleteKhata(int khataId) async {
    if (!_initialized) await init();
    
    await _khataBox.delete(khataId);
  }
  
  // === TRANSACTION RELATED METHODS ===
  
  // Get transactions by khata ID
  Future<List<Transaction>> getTransactionsByKhataId(int khataId) async {
    if (!_initialized) await init();
    
    return _transactionBox.values
        .where((transaction) => transaction.khataId == khataId)
        .toList();
  }
  
  // Add a transaction
  Future<void> addTransaction(Transaction transaction) async {
    if (!_initialized) await init();
    
    await _transactionBox.add(transaction);
  }
  
  // Update a transaction
  Future<void> updateTransaction(Transaction transaction) async {
    if (!_initialized) await init();
    
    if (transaction.id != null) {
      await _transactionBox.put(transaction.id, transaction);
    }
  }
  
  // Delete a transaction
  Future<void> deleteTransaction(int transactionId) async {
    if (!_initialized) await init();
    
    await _transactionBox.delete(transactionId);
  }
  
  // === CONTACT RELATED METHODS ===
  
  // Get all contacts
  Future<List<Contact>> getContacts() async {
    if (!_initialized) await init();
    
    return _contactBox.values.toList();
  }
  
  // Add a contact
  Future<void> addContact(Contact contact) async {
    if (!_initialized) await init();
    
    await _contactBox.add(contact);
  }
  
  // Update a contact
  Future<void> updateContact(Contact contact) async {
    if (!_initialized) await init();
    
    if (contact.id != null) {
      await _contactBox.put(contact.id, contact);
    }
  }
  
  // Delete a contact
  Future<void> deleteContact(int contactId) async {
    if (!_initialized) await init();
    
    await _contactBox.delete(contactId);
  }
} 