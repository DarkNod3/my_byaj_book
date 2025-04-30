import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/khata.dart';
import '../models/transaction.dart';
import '../models/contact.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;
  
  DatabaseService._internal();
  
  Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'byaj_book.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }
  
  Future<void> _createDatabase(Database db, int version) async {
    // Create contacts table
    await db.execute('''
      CREATE TABLE contacts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    
    // Create khatas table
    await db.execute('''
      CREATE TABLE khatas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contact_id INTEGER NOT NULL,
        type INTEGER NOT NULL,
        interest_rate REAL,
        note TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (contact_id) REFERENCES contacts (id) ON DELETE CASCADE
      )
    ''');
    
    // Create transactions table
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        khata_id INTEGER NOT NULL,
        type INTEGER NOT NULL,
        amount REAL NOT NULL,
        note TEXT,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (khata_id) REFERENCES khatas (id) ON DELETE CASCADE
      )
    ''');
  }
  
  // Contact methods
  Future<int> insertContact(Contact contact) async {
    final db = await database;
    return await db.insert('contacts', {
      'name': contact.name,
      'phone': contact.phone,
      'email': contact.email,
      'address': contact.address,
      'created_at': contact.createdAt.toIso8601String(),
      'updated_at': contact.updatedAt.toIso8601String(),
    });
  }
  
  Future<List<Contact>> getContacts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('contacts');
    
    return List.generate(maps.length, (i) {
      return Contact(
        id: maps[i]['id'],
        name: maps[i]['name'],
        phone: maps[i]['phone'],
        email: maps[i]['email'],
        address: maps[i]['address'],
        createdAt: DateTime.parse(maps[i]['created_at']),
        updatedAt: DateTime.parse(maps[i]['updated_at']),
      );
    });
  }
  
  // Khata methods
  Future<int> insertKhata(Khata khata) async {
    final db = await database;
    return await db.insert('khatas', {
      'contact_id': khata.contactId,
      'type': khata.type.index,
      'interest_rate': khata.interestRate,
      'note': khata.note,
      'created_at': khata.createdAt.toIso8601String(),
      'updated_at': khata.updatedAt.toIso8601String(),
    });
  }
  
  Future<List<Khata>> getKhatasByType(KhataType type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'khatas',
      where: 'type = ?',
      whereArgs: [type.index],
    );
    
    return List.generate(maps.length, (i) {
      return Khata(
        id: maps[i]['id'],
        contactId: maps[i]['contact_id'],
        type: KhataType.values[maps[i]['type']],
        interestRate: maps[i]['interest_rate'],
        note: maps[i]['note'],
        createdAt: DateTime.parse(maps[i]['created_at']),
        updatedAt: DateTime.parse(maps[i]['updated_at']),
      );
    });
  }
  
  Future<Khata?> getKhataById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'khatas',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) return null;
    
    return Khata(
      id: maps[0]['id'],
      contactId: maps[0]['contact_id'],
      type: KhataType.values[maps[0]['type']],
      interestRate: maps[0]['interest_rate'],
      note: maps[0]['note'],
      createdAt: DateTime.parse(maps[0]['created_at']),
      updatedAt: DateTime.parse(maps[0]['updated_at']),
    );
  }
  
  // Transaction methods
  Future<int> insertTransaction(Transaction transaction) async {
    final db = await database;
    return await db.insert('transactions', {
      'khata_id': transaction.khataId,
      'type': transaction.type.index,
      'amount': transaction.amount,
      'note': transaction.note,
      'date': transaction.date.toIso8601String(),
      'created_at': transaction.createdAt.toIso8601String(),
      'updated_at': transaction.updatedAt.toIso8601String(),
    });
  }
  
  Future<List<Transaction>> getTransactionsByKhataId(int khataId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'khata_id = ?',
      whereArgs: [khataId],
    );
    
    return List.generate(maps.length, (i) {
      return Transaction(
        id: maps[i]['id'],
        khataId: maps[i]['khata_id'],
        type: TransactionType.values[maps[i]['type']],
        amount: maps[i]['amount'],
        note: maps[i]['note'],
        date: DateTime.parse(maps[i]['date']),
        createdAt: DateTime.parse(maps[i]['created_at']),
        updatedAt: DateTime.parse(maps[i]['updated_at']),
      );
    });
  }
} 