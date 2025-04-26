import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartpantri/screens/ai_chat_screen.dart';
import 'package:smartpantri/screens/chat_screen.dart';
import 'package:smartpantri/screens/theme_settings.dart';
import 'package:smartpantri/services/app_state_provider.dart';
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
import 'package:smartpantri/screens/settings.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> initializeLocalNotifications() async {
  tz.initializeTimeZones();

  try {
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    final localLocation = tz.getLocation(currentTimeZone);
    tz.setLocalLocation(localLocation);
    print("Local timezone set to: $currentTimeZone");
  } catch (e) {
    print("Error getting local timezone: $e");
    final localLocation = tz.getLocation('UTC');
    tz.setLocalLocation(localLocation);
    print("Fallback to UTC timezone");
  }

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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: "apikeys.env");

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        name: 'smartpantri-dc717',
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("Firebase initialized successfully");
    }
  } catch (e) {
    print("Error initializing Firebase: $e");
    return; // Ha a Firebase inicializálás sikertelen, ne folytassuk
  }

  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
    print("Firebase App Check activated successfully");
  } catch (e) {
    print("Error activating Firebase App Check: $e");
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await initializeLocalNotifications();

  final themeProvider = await ThemeProvider.loadFromPrefs();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => themeProvider),
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool isGuestMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadGuestMode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      ThemeProvider.loadFromPrefs().then((newProvider) async {
        await themeProvider.toggleDarkMode(newProvider.isDarkMode);
        await themeProvider.setPrimaryColor(newProvider.primaryColor);

        FirebaseAuth.instance.authStateChanges().listen((User? user) async {
          if (user != null) {
            print("User logged in: ${user.uid}, setting up FCM...");
            await _setupFCM(context); // A _setupFCM már kezeli az aktuális user-t
          } else {
            print("User logged out, clearing guest mode and skipping FCM setup.");
            await clearGuestMode();
          }
        });
      }).catchError((e) {
        print("Error loading theme preferences: $e");
        themeProvider.toggleDarkMode(false);
        themeProvider.setPrimaryColor(Colors.blue);
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
    if (state == AppLifecycleState.resumed) {
      appStateProvider.setAppState(true);
      print("App is in foreground");
    } else if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      appStateProvider.setAppState(false);
      print("App is in background or inactive");
    }
  }

  Future<void> _loadGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isGuestMode = prefs.getBool('isGuestMode') ?? false;
    });
  }

  Future<void> setGuestMode(bool isGuest) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isGuestMode = isGuest;
      prefs.setBool('isGuestMode', isGuest);
    });
  }

  Future<void> clearGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isGuestMode = false;
      prefs.remove('isGuestMode');
    });
    FirebaseMessaging.instance.deleteToken();
  }

  Future<void> _setupFCM(BuildContext context) async {
    if (isGuestMode) {
      print("Guest mode is enabled, skipping FCM setup.");
      return;
    }

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
        return;
      }

      String? token;
      try {
        token = await messaging.getToken();
        if (token == null) {
          print("Failed to get FCM token: token is null.");
          return;
        }
        print("FCM Device Token: $token");
      } catch (e) {
        print("Error getting FCM token: $e");
        return;
      }

      // Mindig az aktuális felhasználót használd
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("No user logged in, skipping FCM setup.");
        return;
      }

      await _saveFCMToken(user.uid, token);

      messaging.onTokenRefresh.listen((newToken) async {
        User? refreshedUser = FirebaseAuth.instance.currentUser;
        if (refreshedUser != null) {
          await _saveFCMToken(refreshedUser.uid, newToken);
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
              builder: (context) => NotificationsScreen(groupId: groupId, isGuest: isGuestMode),
            ),
          );
        } else if (message.data['screen'] == 'group_home') {
          String groupId = message.data['groupId'];
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(isGuest: isGuestMode),
            ),
          );
        }
      });

      FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          if (message.data['screen'] == 'notifications') {
            String groupId = message.data['groupId'];
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotificationsScreen(groupId: groupId, isGuest: isGuestMode),
              ),
            );
          } else if (message.data['screen'] == 'group_home') {
            String groupId = message.data['groupId'];
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(isGuest: isGuestMode),
              ),
            );
          }
        }
      });
    } catch (e) {
      print("Error setting up FCM: $e");
    }
  }

  Future<void> _saveFCMToken(String userId, String token) async {
    try {
      final tokenRef = FirebaseFirestore.instance.collection('fcm_tokens').doc(token);
      final userTokensRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tokens');
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final tokenDoc = await transaction.get(tokenRef);
        final existingTokens = await userTokensRef.get();
        final userDoc = await transaction.get(userRef);

        // Ha a token már létezik az fcm_tokens-ban, de egy másik felhasználóhoz tartozik,
        // akkor azt később egy Cloud Function segítségével tisztítjuk ki.
        if (tokenDoc.exists) {
          final tokenData = tokenDoc.data()!;
          final existingUserId = tokenData['userId'];
          if (existingUserId != userId) {
            print("Token $token is already associated with user $existingUserId. It will be reassigned to $userId.");
            // Itt nem töröljük a másik felhasználó tokenjét, mert nincs rá jogosultságunk.
            // Ehelyett egy Cloud Function-t hívhatunk, amely admin jogosultságokkal törli a tokent.
          }
        }

        // Töröljük a saját régi tokenjeinket
        for (var tokenDoc in existingTokens.docs) {
          transaction.delete(tokenDoc.reference);
          print("Cleared old token ${tokenDoc['token']} from user $userId in tokens subcollection");
        }

        // Új token hozzáadása a saját tokens almappához
        final newTokenRef = userTokensRef.doc();
        transaction.set(newTokenRef, {
          'token': token,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Az fcm_tokens kollekció frissítése
        transaction.set(tokenRef, {
          'userId': userId,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Régi fcmToken mező törlése a users dokumentumból, ha létezik
        if (userDoc.exists && userDoc.data()!.containsKey('fcmToken')) {
          transaction.update(userRef, {
            'fcmToken': FieldValue.delete(),
          });
          print("Ensured fcmToken field is deleted for user $userId");
        }
      });

      print("Successfully saved token $token for user $userId");
    } catch (e) {
      print("Error saving FCM token for user $userId: $e");
      rethrow;
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
            '/login': (context) => LoginScreen(setGuestMode: setGuestMode),
            '/register': (context) => RegisterScreen(setGuestMode: setGuestMode),
            '/welcomescreen': (context) => WelcomeScreen(setGuestMode: setGuestMode),
            '/home': (context) => HomeScreen(isGuest: isGuestMode),
            '/verify-email': (context) => isGuestMode
                ? WelcomeScreen(setGuestMode: setGuestMode)
                : const VerifyEmailScreen(),
            '/group-chat': (context) => isGuestMode
                ? WelcomeScreen(setGuestMode: setGuestMode)
                : GroupChatScreen(
              groupId: (ModalRoute.of(context)!.settings.arguments as Map)['groupId'] ?? 'groupId1',
              isGuest: isGuestMode,
            ),
            '/ai-chat': (context) => const AIChatScreen(),
            '/theme-settings': (context) => const ThemeSettingsScreen(),
            '/settings': (context) => SettingsScreen(
              isGuest: isGuestMode,
            ),
            '/notifications': (context) => isGuestMode
                ? WelcomeScreen(setGuestMode: setGuestMode)
                : NotificationsScreen(
              groupId: ModalRoute.of(context)!.settings.arguments as String? ?? 'default_group_id',
              isGuest: isGuestMode,
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