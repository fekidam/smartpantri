import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/scheduler.dart' hide Priority;
import 'package:provider/provider.dart';
import 'package:smartpantri/screens/ai_chat_screen.dart';
import 'package:smartpantri/screens/chat_screen.dart';
import 'package:smartpantri/screens/theme_settings.dart';
import 'package:smartpantri/services/storage_service.dart';
import 'services/firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'groups/group_home.dart';
import 'screens/login.dart';
import 'screens/register.dart';
import 'screens/verify_email.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/theme_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smartpantri/screens/notifications.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> initializeLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('app_icon');
  const DarwinInitializationSettings initializationSettingsIOS =
  DarwinInitializationSettings();
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      print("Notification clicked: ${response.payload}");
    },
  );
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

  await initializeLocalNotifications();

  final themeProvider = await ThemeProvider.loadFromPrefs();

  runApp(
    ChangeNotifierProvider(
      create: (_) => themeProvider,
      child: const MyApp(),
    ),
  );
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupFCM(context);
    });
  }

  void _setupFCM(BuildContext context) async {
    try {
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
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'email': user.email,
        }, SetOptions(merge: true));
      }

      messaging.onTokenRefresh.listen((newToken) async {
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'fcmToken': newToken,
          }, SetOptions(merge: true));
        }
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("Message received while app is open: ${message.notification?.title}");
        print("Message body: ${message.notification?.body}");

        if (message.notification != null) {
          flutterLocalNotificationsPlugin.show(
            0,
            message.notification!.title,
            message.notification!.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                'channel_id',
                'Channel Name',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
          );
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print("Notification clicked and app opened: ${message.notification?.title}");
        if (message.data['screen'] == 'notifications') {
          String groupId = message.data['groupId'];
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NotificationsScreen(groupId: groupId),
            ),
          );
        }
      });

      FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
        if (message != null && message.data['screen'] == 'notifications') {
          String groupId = message.data['groupId'];
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NotificationsScreen(groupId: groupId),
            ),
          );
        }
      });
    } catch (e) {
      print("Error setting up FCM: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'SmartPantri',
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/welcomescreen': (context) => WelcomeScreen(setGuestMode: setGuestMode),
            '/home': (context) => HomeScreen(isGuest: isGuestMode),
            '/verify-email': (context) => const VerifyEmailScreen(),
            '/group-chat': (context) => GroupChatScreen(groupId: 'groupId1'),
            '/ai-chat': (context) => const AIChatScreen(),
            '/theme-settings': (context) => const ThemeSettingsScreen(),
            '/notifications': (context) => NotificationsScreen(
              groupId: ModalRoute.of(context)!.settings.arguments as String? ?? 'default_group_id',
            ),
          },
        );
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
      _imageUrl = await _storageService.getHomePageImageUrl();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading image: $e')),
        );
      }
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => WelcomeScreen(
            setGuestMode: (bool isGuest) {
              final myAppState = context.findAncestorStateOfType<_MyAppState>();
              myAppState?.setGuestMode(isGuest);
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}