import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'welcome_screen.dart';
import 'login.dart';
import 'register.dart';
import 'verify_email.dart';
import 'homescreen.dart';
import 'recipe_suggestions.dart';
import 'chat_screen.dart';
import 'notifications.dart';
import 'settings.dart';
import 'add_item.dart';
import 'shopping_lists.dart'; // Import the necessary files
import 'expense_tracker.dart';
import 'fridge_items.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isGuestMode = false;
  int _currentIndex = 0;

  void setGuestMode(bool isGuest) {
    setState(() {
      isGuestMode = isGuest;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartPantri',
      theme: ThemeData(
        primarySwatch: Colors.green,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          color: Colors.black,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
        ),
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/verify-email': (context) => const VerifyEmailScreen(),
        '/home': (context) => HomeScreen(isGuest: isGuestMode),
        '/recipe-suggestions': (context) => const RecipeSuggestionsScreen(),
        '/chat': (context) => const ChatScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/add-item': (context) => const AddItemScreen(collectionName: 'shopping_list'),
        '/add-expense': (context) => const AddItemScreen(collectionName: 'expenses'),
        '/add-fridge-item': (context) => const AddItemScreen(collectionName: 'fridge_items'),
        '/shopping-lists': (context) => ShoppingListsScreen(isGuest: isGuestMode),
        '/expenses': (context) => ExpenseTrackerScreen(isGuest: isGuestMode),
        '/fridge-items': (context) => FridgeItemsScreen(isGuest: isGuestMode),
      },
      home: WelcomeScreen(setGuestMode: setGuestMode),
    );
  }
}
