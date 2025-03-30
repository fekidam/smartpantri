import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier{
  bool _isDarkMode;
  Color _primaryColor;

  ThemeProvider({required bool isDarkMode, required Color primaryColor})
    : _isDarkMode = isDarkMode,
      _primaryColor = primaryColor;

  bool get isDarkMode => _isDarkMode;
  Color get primaryColor => _primaryColor;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  void toggleDarkMode(bool value) async{
    _isDarkMode = value;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
  }

  void setPrimaryColor (Color color) async{
    _primaryColor = color;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('primaryColor', color.value);
  }

  static Future<ThemeProvider> loadFromPrefs() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isDarkMode = prefs.getBool('isDarkMode') ?? true;
    int? colorValue = prefs.getInt('primaryColor');
    Color primaryColor = colorValue != null ? Color(colorValue) : Colors.blue;
    return ThemeProvider(isDarkMode: isDarkMode, primaryColor: primaryColor);
  }

  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: _primaryColor,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black),
        bodyMedium: TextStyle(color: Colors.black87),
      ),
    );
  }

  ThemeData get darkTheme{
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: _primaryColor,
      scaffoldBackgroundColor: Colors.grey[900],
      appBarTheme: AppBarTheme(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
    );
  }
}