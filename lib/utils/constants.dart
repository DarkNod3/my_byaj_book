import 'package:flutter/material.dart';

/// Application Constants
class AppConstants {
  // App Info
  static const String appName = 'My Byaj Book';
  static const String appVersion = '1.0.0';
  
  // API URLs and Keys
  static const String baseApiUrl = '';
  static const String privacyPolicyUrl = '';
  
  // Shared Preferences Keys
  static const String prefUserId = 'user_id';
  static const String prefTheme = 'app_theme';
  static const String prefLanguage = 'app_language';
  
  // Default Settings
  static const int defaultInterestRate = 10;
  static const String defaultCurrency = 'Rs. ';
  
  // UI Related
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  
  // Color Constants
  static const Color primaryColor = Color(0xFF008080); // Teal
  static const Color secondaryColor = Color(0xFF009688);
  static const Color accentColor = Color(0xFFFF5722); // Deep Orange
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardColor = Colors.white;
  static const Color errorColor = Color(0xFFB00020);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color textColor = Color(0xFF212121);
  static const Color secondaryTextColor = Color(0xFF757575);
  
  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);
}

/// Text Constants
class TextConstants {
  // General
  static const String ok = 'OK';
  static const String cancel = 'Cancel';
  static const String yes = 'Yes';
  static const String no = 'No';
  static const String save = 'Save';
  static const String add = 'Add';
  static const String edit = 'Edit';
  static const String delete = 'Delete';
  
  // App Sections
  static const String home = 'Home';
  static const String khatas = 'Khatas';
  static const String transactions = 'Transactions';
  static const String reports = 'Reports';
  static const String settings = 'Settings';
  
  // Error Messages
  static const String errorGeneric = 'Something went wrong, please try again later';
  static const String errorNoInternet = 'No internet connection available';
  static const String errorInvalidInput = 'Please enter valid information';
}

/// Asset Paths
class AssetPaths {
  static const String imagesPath = 'assets/images/';
  static const String iconsPath = 'assets/icons/';
  static const String lottiePath = 'assets/lottie/';
  
  // Common Images
  static const String logoImage = '${imagesPath}logo.png';
  static const String placeholderImage = '${imagesPath}placeholder.png';
  static const String emptyStateImage = '${imagesPath}empty_state.png';
} 