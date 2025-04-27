import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode;
  Color _primaryColor;

  ThemeProvider({required bool isDarkMode, required Color primaryColor})
      : _isDarkMode = isDarkMode,
        _primaryColor = primaryColor;

  bool get isDarkMode => _isDarkMode;
  Color get primaryColor => _primaryColor;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'isDarkMode': value,
        }, SetOptions(merge: true));
      } catch (e) {
        print("Error saving dark mode to Firestore: $e");
      }
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', value);
    }
  }

  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    notifyListeners();

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'primaryColor': color.value,
        }, SetOptions(merge: true));
      } catch (e) {
        print("Error saving primary color to Firestore: $e");
      }
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('primaryColor', color.value);
    }
  }

  Future<void> loadThemeAsync() async {
    bool isDarkMode = true;
    Color primaryColor = Colors.blue;

    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (e) {
      print("Error checking auth state: $e");
    }

    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          isDarkMode = doc.data() != null && (doc.data() as Map).containsKey('isDarkMode')
              ? doc.get('isDarkMode')
              : true;

          if (doc.data() != null && (doc.data() as Map).containsKey('primaryColor')) {
            int? colorValue = doc.get('primaryColor');
            primaryColor = colorValue != null ? Color(colorValue) : Colors.blue;
          }
        } else {
          print("User document does not exist for UID: ${user.uid}, using default theme values.");
          isDarkMode = true;
          primaryColor = Colors.blue;
        }
      } catch (e) {
        print("Error loading theme from Firestore: $e");
        isDarkMode = true;
        primaryColor = Colors.blue;
      }
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      isDarkMode = prefs.getBool('isDarkMode') ?? true;
      int? colorValue = prefs.getInt('primaryColor');
      primaryColor = colorValue != null ? Color(colorValue) : Colors.blue;
    }

    _isDarkMode = isDarkMode;
    _primaryColor = primaryColor;
    notifyListeners();
  }

  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        foregroundColor: Colors.white,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black),
        bodyMedium: TextStyle(color: Colors.black87),
      ),
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.grey[900],
      appBarTheme: const AppBarTheme(
        foregroundColor: Colors.white,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
    );
  }
}