import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'welcome_screen.dart';
import 'homescreen.dart';
import 'login.dart';
import 'register.dart';
import 'verify_email.dart';
import 'expense_tracker.dart';
import 'fridge_items.dart';
import 'shopping_lists.dart';
import 'add_item.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isGuestMode = false;

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
      ),
      home: AuthCheck(setGuestMode: setGuestMode, isGuestMode: isGuestMode),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => HomeScreen(isGuest: isGuestMode),
        '/verify-email': (context) => const VerifyEmailScreen(),
      },
      onGenerateRoute: (settings) {
        final args = settings.arguments as Map<String, dynamic>?;

        switch (settings.name) {
          case '/expenses':
            return MaterialPageRoute(
              builder: (context) => ExpenseTrackerScreen(
                isGuest: isGuestMode,
                groupId: args?['groupId'] ?? '',
              ),
            );
          case '/fridge-items':
            return MaterialPageRoute(
              builder: (context) => FridgeItemsScreen(
                isGuest: isGuestMode,
                groupId: args?['groupId'] ?? '',
              ),
            );
          case '/shopping-lists':
            return MaterialPageRoute(
              builder: (context) => ShoppingListScreen(
                isGuest: isGuestMode,
                groupId: args?['groupId'] ?? '',
              ),
            );
          case '/add-expense':
            return MaterialPageRoute(
              builder: (context) => AddItemScreen(
                collectionName: 'expense_tracker',
                groupId: args?['groupId'] ?? '',
              ),
            );
          case '/add-fridge-item':
            return MaterialPageRoute(
              builder: (context) => AddItemScreen(
                collectionName: 'fridge_items',
                groupId: args?['groupId'] ?? '',
              ),
            );
          default:
            return null;
        }
      },
    );
  }
}

class AuthCheck extends StatelessWidget {
  final Function(bool) setGuestMode;
  final bool isGuestMode;

  const AuthCheck({Key? key, required this.setGuestMode, required this.isGuestMode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && snapshot.data!.emailVerified) {
          print("User is logged in with UID: ${snapshot.data?.uid}");
          return HomeScreen(isGuest: isGuestMode);
        } else if (snapshot.hasData && !snapshot.data!.emailVerified) {
          print("User is logged in but email not verified.");
          return const VerifyEmailScreen();
        }

        print("No user logged in.");
        return WelcomeScreen(setGuestMode: setGuestMode);
      },
    );
  }
}
