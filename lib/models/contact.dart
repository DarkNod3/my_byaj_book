import 'package:flutter/material.dart';

class Contact {
  final int? id;
  final String name;
  final String? phoneNumber;
  final String? address;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  Contact({
    this.id,
    required this.name,
    this.phoneNumber,
    this.address,
    this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();
    
  Contact copyWith({
    int? id,
    String? name,
    String? phoneNumber,
    String? address,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
  
  // Get initials for avatar
  String get initials {
    if (name.isEmpty) return '';
    
    final nameParts = name.trim().split(' ');
    if (nameParts.length == 1) {
      return nameParts[0][0].toUpperCase();
    } else {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
  }

  Color get avatarColor {
    // Generate a deterministic color based on the name
    final int hashCode = name.hashCode;
    final int colorValue = hashCode & 0xFFFFFF;
    return Color(0xFF000000 + colorValue);
  }
} 