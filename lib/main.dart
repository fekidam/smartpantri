import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:smartpantri/screens/ai_chat_screen.dart';
import 'package:smartpantri/screens/chat_screen.dart';
import 'package:smartpantri/services/storage_service.dart';
import 'services/firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'groups/group_home.dart';
import 'screens/login.dart';
import 'screens/register.dart';
import 'screens/verify_email.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: "apikeys.env");

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      name: 'smartpantri-dc717',
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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
  void initState() {
    super.initState();
    _setupFCM();
  }

  void _setupFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("Notification permission granted.");
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print("Provisional notification permission granted.");
    } else {
      print("Notification permission denied.");
    }

    String? token = await messaging.getToken();
    print("FCM Device Token: $token");

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && token != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'fcmToken': token,
      });
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Message received while app is open: ${message.notification?.title}");
      print("Message body: ${message.notification?.body}");
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Notification clicked and app opened: ${message.notification?.title}");
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
        '/group-chat': (context) => GroupChatScreen(groupId: 'groupId1'),
        '/ai-chat': (context) => const AIChatScreen(),
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
