import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'welcome_screen.dart';
import 'homescreen.dart';
import 'login.dart';
import 'register.dart';

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
        if (snapshot.hasData) {
          print("User is logged in with UID: ${snapshot.data?.uid}");
          return HomeScreen(isGuest: isGuestMode);
        } else {
          print("No user logged in.");
        }
        return WelcomeScreen(setGuestMode: setGuestMode);
      },
    );
  }
}


