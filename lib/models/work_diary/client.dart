import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/work_diary/work_entry.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class Client {
  final String id;
  final String name;
  final String phoneNumber;
  final double hourlyRate;
  final double halfDayRate;
  final double fullDayRate;
  final List<WorkEntry> workEntries;
  final Color avatarColor;

  Client({
    required this.id,
    required this.name,
    this.phoneNumber = '',
    this.hourlyRate = 0.0,
    this.halfDayRate = 0.0,
    this.fullDayRate = 0.0,
    List<WorkEntry>? workEntries,
    Color? avatarColor,
  }) : 
    this.workEntries = workEntries ?? [],
    this.avatarColor = avatarColor ?? _getRandomColor();

  String get initials {
    final nameParts = name.split(' ');
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  double get totalEarnings {
    return workEntries.fold(0, (sum, entry) => sum + entry.amount);
  }

  double getEarningsForMonth(DateTime date) {
    return workEntries
        .where((entry) => 
            entry.date.month == date.month && 
            entry.date.year == date.year)
        .fold(0, (sum, entry) => sum + entry.amount);
  }

  double get todayEarnings {
    final today = DateTime.now();
    return workEntries
        .where((entry) => 
            entry.date.day == today.day && 
            entry.date.month == today.month && 
            entry.date.year == today.year)
        .fold(0, (sum, entry) => sum + entry.amount);
  }

  int get hoursCount => workEntries.where((e) => e.durationType == 'Hour').length;
  
  int get halfDaysCount => workEntries.where((e) => e.durationType == 'Half Day').length;
  
  int get fullDaysCount => workEntries.where((e) => e.durationType == 'Full Day').length;

  Client copyWith({
    String? name,
    String? phoneNumber,
    double? hourlyRate,
    double? halfDayRate,
    double? fullDayRate,
    List<WorkEntry>? workEntries,
    Color? avatarColor,
  }) {
    return Client(
      id: this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      halfDayRate: halfDayRate ?? this.halfDayRate,
      fullDayRate: fullDayRate ?? this.fullDayRate,
      workEntries: workEntries ?? this.workEntries,
      avatarColor: avatarColor ?? this.avatarColor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'hourlyRate': hourlyRate,
      'halfDayRate': halfDayRate,
      'fullDayRate': fullDayRate,
      'workEntries': workEntries.map((entry) => entry.toJson()).toList(),
      'avatarColor': avatarColor.value,
    };
  }

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phoneNumber'] ?? '',
      hourlyRate: json['hourlyRate']?.toDouble() ?? 0.0,
      halfDayRate: json['halfDayRate']?.toDouble() ?? 0.0,
      fullDayRate: json['fullDayRate']?.toDouble() ?? 0.0,
      workEntries: (json['workEntries'] as List?)
          ?.map((e) => WorkEntry.fromJson(e))
          .toList() ?? [],
      avatarColor: Color(json['avatarColor'] ?? _getRandomColor().value),
    );
  }

  static List<Client> fromJsonList(String jsonString) {
    List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => Client.fromJson(json)).toList();
  }

  static String toJsonList(List<Client> clients) {
    return jsonEncode(clients.map((client) => client.toJson()).toList());
  }

  static Color _getRandomColor() {
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.indigo,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.deepOrange,
      Colors.cyan,
    ];

    return colors[Random().nextInt(colors.length)];
  }
}

// Sample data for testing
List<Client> getSampleClients() {
  return [
    Client(
      id: '1',
      name: 'Rahul Sharma',
      phoneNumber: '9876543210',
      hourlyRate: 500,
      halfDayRate: 2000,
      fullDayRate: 4000,
      workEntries: [
        WorkEntry(
          id: '1',
          date: DateTime.now().subtract(const Duration(days: 1)),
          durationType: 'Full Day',
          amount: 4000,
          description: 'Completed website homepage design',
        ),
        WorkEntry(
          id: '2',
          date: DateTime.now().subtract(const Duration(days: 3)),
          durationType: 'Half Day',
          amount: 2000,
          description: 'Fixed bugs in contact form',
        ),
      ],
    ),
    Client(
      id: '2',
      name: 'Priya Patel',
      phoneNumber: '8765432109',
      hourlyRate: 600,
      halfDayRate: 2500,
      fullDayRate: 4500,
      workEntries: [
        WorkEntry(
          id: '3',
          date: DateTime.now().subtract(const Duration(days: 2)),
          durationType: 'Hour',
          amount: 600,
          description: 'Logo design consultation',
        ),
      ],
    ),
    Client(
      id: '3',
      name: 'Amit Kumar',
      phoneNumber: '7654321098',
      hourlyRate: 450,
      halfDayRate: 1800,
      fullDayRate: 3600,
      workEntries: [],
    ),
    Client(
      id: '4',
      name: 'Neha Gupta',
      phoneNumber: '6543210987',
      hourlyRate: 550,
      halfDayRate: 2200,
      fullDayRate: 4200,
      workEntries: [
        WorkEntry(
          id: '4',
          date: DateTime.now().subtract(const Duration(days: 1)),
          durationType: 'Half Day',
          amount: 2200,
          description: 'UI design for mobile app',
        ),
        WorkEntry(
          id: '5',
          date: DateTime.now().subtract(const Duration(days: 7)),
          durationType: 'Full Day',
          amount: 4200,
          description: 'Complete redesign of product page',
        ),
        WorkEntry(
          id: '6',
          date: DateTime.now().subtract(const Duration(days: 14)),
          durationType: 'Hour',
          amount: 550,
          description: 'Consultation on color scheme',
        ),
      ],
    ),
  ];
} 