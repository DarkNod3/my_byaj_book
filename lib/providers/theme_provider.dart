import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  Color _primaryColor = Colors.blue;
  Color _accentColor = Colors.blueAccent;

  bool get isDarkMode => _isDarkMode;
  Color get primaryColor => _primaryColor;
  Color get accentColor => _accentColor;
  
  ThemeData get themeData => _isDarkMode ? _darkTheme : _lightTheme;

  ThemeData get _lightTheme => ThemeData(
    primaryColor: _primaryColor,
    colorScheme: ColorScheme.light(
      primary: _primaryColor,
      secondary: _accentColor,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryColor,
      ),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.3),
    ),
  );

  ThemeData get _darkTheme => ThemeData(
    primaryColor: _primaryColor,
    colorScheme: ColorScheme.dark(
      primary: _primaryColor,
      secondary: _accentColor,
      background: Colors.grey[900]!,
      surface: Colors.grey[800]!,
    ),
    scaffoldBackgroundColor: Colors.grey[900],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[850],
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryColor,
      ),
    ),
    cardTheme: CardTheme(
      color: Colors.grey[800],
      shadowColor: Colors.black.withOpacity(0.3),
    ),
  );

  ThemeProvider() {
    _loadThemePreferences();
  }

  Future<void> _loadThemePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    final primaryColorValue = prefs.getInt('primaryColor');
    if (primaryColorValue != null) {
      _primaryColor = Color(primaryColorValue);
    }
    final accentColorValue = prefs.getInt('accentColor');
    if (accentColorValue != null) {
      _accentColor = Color(accentColorValue);
    }
    notifyListeners();
  }

  Future<void> toggleThemeMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> updatePrimaryColor(Color color) async {
    _primaryColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('primaryColor', color.value);
    notifyListeners();
  }

  Future<void> updateAccentColor(Color color) async {
    _accentColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accentColor', color.value);
    notifyListeners();
  }
} 