import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartpantri/screens/add_item.dart';
import 'package:smartpantri/screens/expense_tracker.dart';
import 'package:smartpantri/screens/fridge_items.dart';
import 'package:smartpantri/screens/shopping_lists.dart';
import 'package:smartpantri/services/storage_service.dart';
import 'services/firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'groups/group_home.dart';
import 'screens/login.dart';
import 'screens/register.dart';
import 'screens/verify_email.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: "apikeys.env");

  print("Firebase alkalmazások száma: ${Firebase.apps.length}");
  if (Firebase.apps.isEmpty) {
    print("Inicializálás szükséges.");
    await Firebase.initializeApp(
      name: 'smartpantri-dc717',
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Inicializálás sikeres.");
  } else {
    print("Firebase már inicializálva.");
  }

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
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/welcomescreen': (context) => WelcomeScreen(setGuestMode: setGuestMode),
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
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                body: Center(child: Text('404: Page not found')),
              ),
            );
        }
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final StorageService _storageService = StorageService();
  String _imageUrl = '';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await Firebase.initializeApp();
      _imageUrl = await _storageService.getHomePageImageUrl();
    } catch (e) {
      print('Initialization error: $e');
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => WelcomeScreen(setGuestMode: (bool isGuest) {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}


class AuthCheck extends StatelessWidget {
  final Function(bool) setGuestMode;

  const AuthCheck({super.key, required this.setGuestMode});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && snapshot.data!.emailVerified) {
          return HomeScreen(isGuest: false);
        } else if (snapshot.hasData && !snapshot.data!.emailVerified) {
          return const VerifyEmailScreen();
        }

        return WelcomeScreen(setGuestMode: setGuestMode);
      },
    );
  }
}
