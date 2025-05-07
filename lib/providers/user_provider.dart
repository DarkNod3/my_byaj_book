import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class User {
  final String id;
  String name;
  String? mobile;
  String? profileImagePath;

  User({
    required this.id,
    required this.name,
    this.mobile = '',
    this.profileImagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile ?? '',
      'profileImagePath': profileImagePath,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      mobile: json['mobile'] ?? '',
      profileImagePath: json['profileImagePath'],
    );
  }
}

class UserProvider with ChangeNotifier {
  User? _user;
  User? get user => _user;

  // Keys for SharedPreferences
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userMobileKey = 'user_mobile';
  static const String _userProfileImageKey = 'user_profile_image';
  static const String _isLoggedInKey = 'is_logged_in';

  // Check if user exists (in a real app, this would check with a server)
  Future<bool> checkUserExists(String mobile) async {
    // For demo, just a dummy implementation
    await Future.delayed(const Duration(milliseconds: 500));
    return mobile == '9876543210'; // Example existing user
  }

  // Login with mobile (in a real app, this would validate with a server)
  Future<void> loginWithMobile(String mobile) async {
    try {
      // For demo, just create a user with the mobile and a default name
      _user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Existing User',
        mobile: mobile,
      );
      
      // Save user data to SharedPreferences for persistence
      await _saveUserData();
      
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to login: $e');
    }
  }

  // Register new user
  Future<void> registerUser({
    required String name,
    String? mobile = '',
  }) async {
    try {
      // For demo, just create a new user
      _user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        mobile: mobile,
      );
      
      // Save user data to SharedPreferences for persistence
      await _saveUserData();
      
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? mobile,
    String? profileImagePath,
  }) async {
    if (_user == null) return;

    try {
      if (name != null) _user!.name = name;
      if (mobile != null) _user!.mobile = mobile;
      if (profileImagePath != null) _user!.profileImagePath = profileImagePath;

      // Save updated user data
      await _saveUserData();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Save user data to SharedPreferences
  Future<void> _saveUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_user != null) {
        await prefs.setString(_userIdKey, _user!.id);
        await prefs.setString(_userNameKey, _user!.name);
        if (_user!.mobile != null && _user!.mobile!.isNotEmpty) {
          await prefs.setString(_userMobileKey, _user!.mobile!);
        }
        if (_user!.profileImagePath != null) {
          await prefs.setString(_userProfileImageKey, _user!.profileImagePath!);
        }
        await prefs.setBool(_isLoggedInKey, true);
      }
    } catch (e) {
    }
  }

  // Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      
      if (isLoggedIn) {
        final id = prefs.getString(_userIdKey);
        final name = prefs.getString(_userNameKey);
        final mobile = prefs.getString(_userMobileKey);
        final profileImagePath = prefs.getString(_userProfileImageKey);
        
        if (id != null && name != null && mobile != null) {
          _user = User(
            id: id,
            name: name,
            mobile: mobile,
            profileImagePath: profileImagePath,
          );
        }
      }
    } catch (e) {
    }
  }

  // Initialize provider and load persisted user data
  Future<void> initialize() async {
    await _loadUserData();
    notifyListeners();
  }

  // Logout user
  Future<void> logout() async {
    try {
      _user = null;
      
      // Clear saved data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userIdKey);
      await prefs.remove(_userNameKey);
      await prefs.remove(_userMobileKey);
      await prefs.remove(_userProfileImageKey);
      await prefs.setBool(_isLoggedInKey, false);
      
      notifyListeners();
    } catch (e) {
    }
  }
} 