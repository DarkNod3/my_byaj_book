import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum BillCategory {
  all(color: Colors.indigo, icon: Icons.all_inclusive),
  bills(color: Colors.blue, icon: Icons.receipt_long),
  payments(color: Colors.green, icon: Icons.payment),
  reminders(color: Colors.orange, icon: Icons.alarm),
  shopping(color: Colors.purple, icon: Icons.shopping_cart),
  personal(color: Colors.red, icon: Icons.person),
  others(color: Colors.grey, icon: Icons.folder);
  
  final Color color;
  final IconData icon;
  
  const BillCategory({required this.color, required this.icon});
  
  String get name {
    return toString().split('.').last.capitalize();
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class BillNote {
  final String id;
  final String title;
  final String content;
  final BillCategory category;
  final DateTime createdDate;
  final DateTime? reminderDate;
  final double? amount;
  final bool isCompleted;
  final String? imagePath;

  BillNote({
    String? id,
    required this.title,
    required this.content,
    required this.category,
    DateTime? createdDate,
    this.reminderDate,
    this.amount,
    this.isCompleted = false,
    this.imagePath,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.createdDate = createdDate ?? DateTime.now();

  BillNote copyWith({
    String? id,
    String? title,
    String? content,
    BillCategory? category,
    DateTime? createdDate,
    DateTime? reminderDate,
    double? amount,
    bool? isCompleted,
    String? imagePath,
  }) {
    return BillNote(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      createdDate: createdDate ?? this.createdDate,
      reminderDate: reminderDate ?? this.reminderDate,
      amount: amount ?? this.amount,
      isCompleted: isCompleted ?? this.isCompleted,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category.index,
      'createdDate': createdDate.millisecondsSinceEpoch,
      'reminderDate': reminderDate?.millisecondsSinceEpoch,
      'amount': amount,
      'isCompleted': isCompleted ? 1 : 0,
      'imagePath': imagePath,
    };
  }

  factory BillNote.fromMap(Map<String, dynamic> map) {
    return BillNote(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      category: BillCategory.values[map['category']],
      createdDate: DateTime.fromMillisecondsSinceEpoch(map['createdDate']),
      reminderDate: map['reminderDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['reminderDate']) 
          : null,
      amount: map['amount'],
      isCompleted: map['isCompleted'] == 1,
      imagePath: map['imagePath'],
    );
  }

  @override
  String toString() {
    return 'BillNote(id: $id, title: $title, category: $category, reminderDate: $reminderDate, isCompleted: $isCompleted)';
  }
} 