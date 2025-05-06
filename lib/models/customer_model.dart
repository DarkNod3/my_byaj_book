import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

part 'customer_model.g.dart';

@HiveType(typeId: 0)
enum EntryType {
  @HiveField(0)
  tea,
  @HiveField(1)
  payment
}

@HiveType(typeId: 1)
class CustomerEntry {
  @HiveField(0)
  final EntryType type;
  
  @HiveField(1)
  final int cups;
  
  @HiveField(2)
  final double amount;
  
  @HiveField(3)
  final DateTime timestamp;
  
  @HiveField(4)
  final String? beverageType; // 'tea', 'coffee', or 'milk'
  
  CustomerEntry({
    required this.type,
    this.cups = 0,
    required this.amount,
    required this.timestamp,
    this.beverageType,
  });
}

@HiveType(typeId: 2)
class Customer extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String? phoneNumber;
  
  @HiveField(3)
  int cups;
  
  @HiveField(4)
  final double teaRate;
  
  @HiveField(5)
  final double coffeeRate;
  
  @HiveField(6)
  final double milkRate;
  
  @HiveField(7)
  double totalAmount;
  
  @HiveField(8)
  double paymentsMade;
  
  @HiveField(9)
  final DateTime date;
  
  @HiveField(10)
  DateTime lastUpdated;
  
  @HiveField(11)
  List<CustomerEntry> history;
  
  Customer({
    required this.id,
    required this.name,
    this.phoneNumber,
    required this.cups,
    required this.teaRate,
    this.coffeeRate = 0.0,
    this.milkRate = 0.0,
    required this.totalAmount,
    required this.paymentsMade,
    required this.date,
    required this.lastUpdated,
    this.history = const [],
  });
  
  // Helper getter for backward compatibility
  double get rate => teaRate;
  
  // Helper method to get pending amount
  double get pendingAmount => totalAmount - paymentsMade;
  
  // Format time for display
  static String getFormattedTime(DateTime time) {
    final now = DateTime.now();
    if (time.year == now.year && time.month == now.month && time.day == now.day) {
      return 'Today, ${DateFormat('hh:mm a').format(time)}';
    } else if (time.year == now.year && time.month == now.month && time.day == now.day - 1) {
      return 'Yesterday, ${DateFormat('hh:mm a').format(time)}';
    } else {
      return DateFormat('dd MMM, hh:mm a').format(time);
    }
  }
} 