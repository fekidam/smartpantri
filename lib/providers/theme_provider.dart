import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode;
  Color _primaryColor;
  bool _useGlobalTheme;
  double _fontSizeScale;
  double _gradientOpacity;
  String _iconStyle;

  ThemeProvider({
    required bool isDarkMode,
    required Color primaryColor,
    bool useGlobalTheme = false,
    double fontSizeScale = 1.0,
    double gradientOpacity = 0.2,
    String iconStyle = 'filled',
  })  : _isDarkMode = isDarkMode,
        _primaryColor = primaryColor,
        _useGlobalTheme = useGlobalTheme,
        _fontSizeScale = fontSizeScale,
        _gradientOpacity = gradientOpacity,
        _iconStyle = iconStyle;

  bool get isDarkMode => _isDarkMode;
  Color get primaryColor => _primaryColor;
  bool get useGlobalTheme => _useGlobalTheme;
  double get fontSizeScale => _fontSizeScale;
  double get gradientOpacity => _gradientOpacity;
  String get iconStyle => _iconStyle;
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

  Future<void> toggleGlobalTheme(bool value) async {
    _useGlobalTheme = value;
    notifyListeners();
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'useGlobalTheme': value,
        }, SetOptions(merge: true));
      } catch (e) {
        print("Error saving global theme to Firestore: $e");
      }
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('useGlobalTheme', value);
    }
  }

  Future<void> setFontSizeScale(double value) async {
    _fontSizeScale = value;
    notifyListeners();
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fontSizeScale': value,
        }, SetOptions(merge: true));
      } catch (e) {
        print("Error saving font size scale to Firestore: $e");
      }
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('fontSizeScale', value);
    }
  }

  Future<void> setGradientOpacity(double value) async {
    _gradientOpacity = value;
    notifyListeners();
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'gradientOpacity': value,
        }, SetOptions(merge: true));
      } catch (e) {
        print("Error saving gradient opacity to Firestore: $e");
      }
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('gradientOpacity', value);
    }
  }

  Future<void> setIconStyle(String value) async {
    _iconStyle = value;
    notifyListeners();
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'iconStyle': value,
        }, SetOptions(merge: true));
      } catch (e) {
        print("Error saving icon style to Firestore: $e");
      }
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('iconStyle', value);
    }
  }

  Future<void> loadThemeAsync() async {
    bool isDarkMode = true;
    Color primaryColor = Colors.blue;
    bool useGlobalTheme = false;
    double fontSizeScale = 1.0;
    double gradientOpacity = 0.2;
    String iconStyle = 'filled';
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
          useGlobalTheme = doc.data() != null && (doc.data() as Map).containsKey('useGlobalTheme')
              ? doc.get('useGlobalTheme')
              : false;
          fontSizeScale = doc.data() != null && (doc.data() as Map).containsKey('fontSizeScale')
              ? doc.get('fontSizeScale')
              : 1.0;
          gradientOpacity = doc.data() != null && (doc.data() as Map).containsKey('gradientOpacity')
              ? doc.get('gradientOpacity')
              : 0.2;
          iconStyle = doc.data() != null && (doc.data() as Map).containsKey('iconStyle')
              ? doc.get('iconStyle')
              : 'filled';
          if (doc.data() != null && (doc.data() as Map).containsKey('primaryColor')) {
            int? colorValue = doc.get('primaryColor');
            primaryColor = colorValue != null ? Color(colorValue) : Colors.blue;
          }
        } else {
          print("User document does not exist for UID: ${user.uid}, using default theme values.");
        }
      } catch (e) {
        print("Error loading theme from Firestore: $e");
      }
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      isDarkMode = prefs.getBool('isDarkMode') ?? true;
      useGlobalTheme = prefs.getBool('useGlobalTheme') ?? false;
      fontSizeScale = prefs.getDouble('fontSizeScale') ?? 1.0;
      gradientOpacity = prefs.getDouble('gradientOpacity') ?? 0.2;
      iconStyle = prefs.getString('iconStyle') ?? 'filled';
      int? colorValue = prefs.getInt('primaryColor');
      primaryColor = colorValue != null ? Color(colorValue) : Colors.blue;
    }
    _isDarkMode = isDarkMode;
    _primaryColor = primaryColor;
    _useGlobalTheme = useGlobalTheme;
    _fontSizeScale = fontSizeScale;
    _gradientOpacity = gradientOpacity;
    _iconStyle = iconStyle;
    notifyListeners();
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
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.black, fontSize: 16 * _fontSizeScale),
        bodyMedium: TextStyle(color: Colors.black87, fontSize: 14 * _fontSizeScale),
      ),
      iconTheme: IconThemeData(
        size: 24 * _fontSizeScale,
        color: _iconStyle == 'filled' ? Colors.black87 : Colors.grey,
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
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.white, fontSize: 16 * _fontSizeScale),
        bodyMedium: TextStyle(color: Colors.white70, fontSize: 14 * _fontSizeScale),
      ),
      iconTheme: IconThemeData(
        size: 24 * _fontSizeScale,
        color: _iconStyle == 'filled' ? Colors.white70 : Colors.grey[400],
      ),
    );
  }
}