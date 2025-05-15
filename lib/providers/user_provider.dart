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
  
  // New keys for storing user data by mobile number
  static String _userDataKey(String mobile) => 'user_data_$mobile';
  static const String _registeredUsersKey = 'registered_users';

  // Check if user exists by checking if we have stored their data
  Future<bool> checkUserExists(String mobile) async {
    try {
      debugPrint("Checking if user exists with mobile: $mobile");
      final prefs = await SharedPreferences.getInstance();
      
      // Check if we have data stored for this mobile number
      final userData = prefs.getString(_userDataKey(mobile));
      
      // Also check the legacy hardcoded check for backward compatibility
      final isHardcodedUser = mobile == '9876543210';
      
      final exists = userData != null || isHardcodedUser;
      debugPrint("User exists check result: $exists (userData: ${userData != null}, hardcoded: $isHardcodedUser)");
      return exists;
    } catch (e) {
      debugPrint("Error checking if user exists: $e");
      // Fallback to hardcoded check for safety
      return mobile == '9876543210';
    }
  }

  // Login with mobile
  Future<void> loginWithMobile(String mobile) async {
    try {
      debugPrint("Logging in user with mobile: $mobile");
      final prefs = await SharedPreferences.getInstance();
      
      // Try to load existing user data
      final userData = prefs.getString(_userDataKey(mobile));
      
      if (userData != null) {
        // We have stored data for this user
        debugPrint("Found stored user data");
        final userJson = json.decode(userData) as Map<String, dynamic>;
        _user = User.fromJson(userJson);
      } else {
        // Fallback for existing hardcoded user
        debugPrint("No stored data found, using fallback data");
        _user = User(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'Existing User',
          mobile: mobile,
        );
        
        // Save this user data so it's available next time
        await _saveUserDataByMobile(mobile, _user!);
      }
      
      // Update login status
      await prefs.setBool(_isLoggedInKey, true);
      await _saveUserData(); // Save to standard keys as well
      
      debugPrint("User logged in successfully: ${_user?.name} (${_user?.mobile})");
      notifyListeners();
    } catch (e) {
      debugPrint("Login error: $e");
      throw Exception('Failed to login: $e');
    }
  }

  // Register new user
  Future<void> registerUser({
    required String name,
    String? mobile = '',
  }) async {
    try {
      debugPrint("Registering new user: $name, $mobile");
      // Create new user
      _user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        mobile: mobile,
      );
      
      // Save user data to both traditional way and by mobile
      await _saveUserData();
      
      if (mobile != null && mobile.isNotEmpty) {
        await _saveUserDataByMobile(mobile, _user!);
        
        // Add to list of registered users
        await _addToRegisteredUsers(mobile);
      }
      
      debugPrint("User registered successfully: ${_user?.name} (${_user?.mobile})");
      notifyListeners();
    } catch (e) {
      debugPrint("Registration error: $e");
      throw Exception('Failed to register: $e');
    }
  }

  // Helper to save user data by mobile number
  Future<void> _saveUserDataByMobile(String mobile, User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = json.encode(user.toJson());
      await prefs.setString(_userDataKey(mobile), userJson);
      debugPrint("Saved user data by mobile: $mobile");
    } catch (e) {
      debugPrint("Error saving user data by mobile: $e");
    }
  }
  
  // Helper to add mobile to registered users list
  Future<void> _addToRegisteredUsers(String mobile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final registeredUsers = prefs.getStringList(_registeredUsersKey) ?? [];
      if (!registeredUsers.contains(mobile)) {
        registeredUsers.add(mobile);
        await prefs.setStringList(_registeredUsersKey, registeredUsers);
        debugPrint("Added to registered users: $mobile");
      }
    } catch (e) {
      debugPrint("Error adding to registered users: $e");
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
      final oldMobile = _user!.mobile;
      
      if (name != null) _user!.name = name;
      if (mobile != null) _user!.mobile = mobile;
      if (profileImagePath != null) _user!.profileImagePath = profileImagePath;

      // Save updated user data
      await _saveUserData();
      
      // Also update the user data by mobile
      if (_user!.mobile != null && _user!.mobile!.isNotEmpty) {
        await _saveUserDataByMobile(_user!.mobile!, _user!);
      }
      
      // If mobile changed, update the registered users list
      if (mobile != null && oldMobile != mobile && mobile.isNotEmpty) {
        await _addToRegisteredUsers(mobile);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint("Update profile error: $e");
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
        
        debugPrint("Saved user data to shared preferences");
      }
    } catch (e) {
      debugPrint("Error saving user data: $e");
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
        
        if (id != null && name != null) {
          _user = User(
            id: id,
            name: name,
            mobile: mobile,
            profileImagePath: profileImagePath,
          );
          
          debugPrint("Loaded user data from SharedPreferences: ${_user?.name} (${_user?.mobile})");
        }
      } else {
        debugPrint("No logged in user found");
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
    }
  }

  // Initialize provider and load persisted user data
  Future<void> initialize() async {
    try {
      await _loadUserData();
      debugPrint('UserProvider initialization complete: user = ${_user?.name} (${_user?.mobile})');
      
      // Add a persistence check to prevent auto-logout on reinstall
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      final userId = prefs.getString(_userIdKey);
      
      debugPrint('Login state check: isLoggedIn=$isLoggedIn, userId=$userId');
      
      // If we have a user ID but no logged-in status, maintain the login
      if (userId != null && userId.isNotEmpty && !isLoggedIn) {
        debugPrint('Found user data but login state was lost - restoring login state');
        await prefs.setBool(_isLoggedInKey, true);
        
        // Make sure user object is properly loaded
        if (_user == null) {
          final name = prefs.getString(_userNameKey) ?? 'User';
          final mobile = prefs.getString(_userMobileKey);
          final profileImagePath = prefs.getString(_userProfileImageKey);
          
          _user = User(
            id: userId,
            name: name,
            mobile: mobile,
            profileImagePath: profileImagePath,
          );
          
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error initializing UserProvider: $e');
      // Ensure we don't leave the user in a stuck state
      _user = null;
    }
  }

  // Use this instead of direct logout
  Future<bool> logoutUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear login status but PRESERVE user data
      debugPrint('Logging out user');
      await prefs.setBool(_isLoggedInKey, false);
      
      // Only clear current user in memory
      _user = null;
      notifyListeners();
      
      return true;
    } catch (e) {
      debugPrint('Error during logout: $e');
      return false;
    }
  }
} 