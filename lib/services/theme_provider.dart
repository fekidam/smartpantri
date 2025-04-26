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
      // Bejelentkezett felhasználó esetén Firestore-ba mentünk
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'isDarkMode': value,
        }, SetOptions(merge: true));
      } catch (e) {
        print("Error saving dark mode to Firestore: $e");
      }
    } else {
      // Vendég mód esetén SharedPreferences-be mentünk
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', value);
    }
  }

  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    notifyListeners();

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Bejelentkezett felhasználó esetén Firestore-ba mentünk
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'primaryColor': color.value,
        }, SetOptions(merge: true));
      } catch (e) {
        print("Error saving primary color to Firestore: $e");
      }
    } else {
      // Vendég mód esetén SharedPreferences-be mentünk
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('primaryColor', color.value);
    }
  }

  static Future<ThemeProvider> loadFromPrefs() async {
    bool isDarkMode = true; // Alapértelmezett érték
    Color primaryColor = Colors.blue; // Alapértelmezett szín

    // Ellenőrizzük a hitelesítési állapotot aszinkron módon
    User? user;
    try {
      user = await FirebaseAuth.instance.authStateChanges().first;
    } catch (e) {
      print("Error checking auth state: $e");
    }

    if (user != null) {
      // Bejelentkezett felhasználó esetén Firestore-ból töltünk
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          // Ellenőrizzük, hogy az isDarkMode mező létezik-e, ha nem, alapértelmezett érték
          isDarkMode = doc.data() != null && (doc.data() as Map).containsKey('isDarkMode')
              ? doc.get('isDarkMode')
              : true;

          // Ellenőrizzük, hogy a primaryColor mező létezik-e, ha nem, alapértelmezett érték
          if (doc.data() != null && (doc.data() as Map).containsKey('primaryColor')) {
            int? colorValue = doc.get('primaryColor');
            primaryColor = colorValue != null ? Color(colorValue) : Colors.blue;
          }
        } else {
          // Ha a dokumentum nem létezik, nem hozunk létre újat, csak alapértelmezett értékeket használunk
          print("User document does not exist for UID: ${user.uid}, using default theme values.");
          isDarkMode = true;
          primaryColor = Colors.blue;
        }
      } catch (e) {
        print("Error loading theme from Firestore: $e");
        // Ha a Firestore lekérdezés sikertelen, alapértelmezett értékeket használunk
        isDarkMode = true;
        primaryColor = Colors.blue;
      }
    } else {
      // Vendég mód esetén SharedPreferences-ből töltünk
      SharedPreferences prefs = await SharedPreferences.getInstance();
      isDarkMode = prefs.getBool('isDarkMode') ?? true;
      int? colorValue = prefs.getInt('primaryColor');
      primaryColor = colorValue != null ? Color(colorValue) : Colors.blue;
    }

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

  ThemeData get darkTheme {
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