import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smartpantri/screens/add_item.dart';
import 'package:smartpantri/screens/expense_tracker.dart';
import 'package:smartpantri/screens/fridge_items.dart';
import 'package:smartpantri/screens/homescreen.dart';
import 'package:smartpantri/screens/login.dart';
import 'package:smartpantri/screens/register.dart';
import 'package:smartpantri/screens/shopping_lists.dart';
import 'package:smartpantri/screens/verify_email.dart';
import 'package:smartpantri/services/firebase_options.dart';
import 'package:smartpantri/services/storage_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await dotenv.load(fileName: "apikeys.env");
  }

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
            return null;
        }
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final StorageService _storageService = StorageService();
  bool _isImageLoaded = false;

  @override
  void initState() {
    super.initState();
    _preloadImage();
  }

  Future<void> _preloadImage() async {
    await _storageService.getHomePageImageUrl();
    setState(() {
      _isImageLoaded = true;
    });

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => AuthCheck(setGuestMode: (bool isGuest) {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Text(
          'SmartPantri',
          style: TextStyle(
            fontSize: 28,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
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

class WelcomeScreen extends StatefulWidget {
  final Function(bool) setGuestMode;
  const WelcomeScreen({super.key, required this.setGuestMode});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final StorageService _storageService = StorageService();
  String _imageUrl = '';

  @override
  void initState() {
    super.initState();
    _loadHomePageImage();
  }

  Future<void> _loadHomePageImage() async {
    String imageUrl = await _storageService.getHomePageImageUrl();
    setState(() {
      _imageUrl = imageUrl;
    });
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: '533680516754-tarc1mubk9q7eu5qk84si0qv6d1hgd8g.apps.googleusercontent.com',
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

        if (userCredential.user != null) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'SmartPantri',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: _imageUrl,
                width: 200,
                height: 220,
                fit: BoxFit.cover,
                placeholder: (context, url) => const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Log In'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/register');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Register'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => signInWithGoogle(context),
              icon: const Icon(Icons.login, color: Colors.white),
              label: const Text('Continue with Google'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                widget.setGuestMode(true);
                Navigator.of(context).pushReplacementNamed('/home');
              },
              child: const Text(
                'Continue as Guest',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
