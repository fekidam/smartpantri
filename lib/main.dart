import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartpantri/screens/chats/ai_chat.dart';
import 'package:smartpantri/screens/chats/group_and_ai_chat.dart';
import 'package:smartpantri/screens/settings/theme_settings.dart';
import 'package:smartpantri/Providers/app_state_provider.dart';
import 'package:smartpantri/Providers/language_provider.dart';
import 'package:smartpantri/services/storage_service.dart';
import 'Config/firebase_options.dart';
import 'screens/welcomescreen/welcome_screen.dart';
import 'screens/groups/group_home.dart';
import 'screens/welcomescreen/login.dart';
import 'screens/welcomescreen/register.dart';
import 'screens/welcomescreen/verify_email.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Providers/theme_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smartpantri/screens/notifications/notifications.dart';
import 'package:smartpantri/screens/settings/settings.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:smartpantri/models/data.dart';
import 'package:smartpantri/screens/groups/group_detail.dart';
import 'package:smartpantri/generated/l10n.dart';

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
    return;
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

  // LanguageProvider inicializálása és a mentett nyelv betöltése
  final languageProvider = LanguageProvider();
  await languageProvider.loadLocale();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(
            isDarkMode: true,
            primaryColor: Colors.blue,
          )..loadThemeAsync(),
        ),
        ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),
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
      FirebaseAuth.instance.authStateChanges().listen((User? user) async {
        if (user != null) {
          print("User logged in: ${user.uid}, setting up FCM...");
          await _setupFCM(context);
        } else {
          print("User logged out, clearing guest mode and skipping FCM setup.");
          await clearGuestMode();
        }
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
    // Ellenőrizzük, hogy a felhasználó be van-e jelentkezve
    if (FirebaseAuth.instance.currentUser == null) {
      print("User is not logged in, skipping FCM token save.");
      return;
    }

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

        if (tokenDoc.exists) {
          final tokenData = tokenDoc.data()!;
          final existingUserId = tokenData['userId'];
          if (existingUserId != userId) {
            print("Token $token is already associated with user $existingUserId. It will be reassigned to $userId.");
          }
        }

        for (var tokenDoc in existingTokens.docs) {
          transaction.delete(tokenDoc.reference);
          print("Cleared old token ${tokenDoc['token']} from user $userId in tokens subcollection");
        }

        final newTokenRef = userTokensRef.doc();
        transaction.set(newTokenRef, {
          'token': token,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.set(tokenRef, {
          'userId': userId,
          'updatedAt': FieldValue.serverTimestamp(),
        });

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

  Future<Group?> _fetchGroup(BuildContext context) async {
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    final groupId = args != null && args.containsKey('groupId') ? args['groupId'] as String : null;
    if (groupId == null) {
      print('No groupId provided in route arguments');
      return null;
    }
    try {
      final groupDoc = await FirebaseFirestore.instance.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) {
        print('Group not found: $groupId');
        return null;
      }
      return Group.fromJson(groupId, groupDoc.data()!);
    } catch (e) {
      print('Error fetching group: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Consumer<LanguageProvider>(
          builder: (context, languageProvider, child) {
            return MaterialApp(
              title: AppLocalizations.of(context)?.appTitle ?? 'SmartPantry',
              theme: themeProvider.lightTheme,
              darkTheme: themeProvider.darkTheme,
              themeMode: themeProvider.themeMode,
              locale: languageProvider.locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
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
                    : FutureBuilder<Group?>(
                  future: _fetchGroup(context),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                      return Scaffold(
                        body: Center(
                          child: Text(
                            AppLocalizations.of(context)!.failedToLoadGroup(
                                snapshot.error?.toString() ?? "Group not found"),
                          ),
                        ),
                      );
                    }
                    final group = snapshot.data!;
                    final isShared = group.sharedWith.length > 1;
                    return GroupDetailScreen(
                      group: group,
                      isGuest: isGuestMode,
                      isShared: isShared,
                      arguments: {'selectedIndex': 2},
                    );
                  },
                ),
                '/ai-chat': (context) => isGuestMode
                    ? WelcomeScreen(setGuestMode: setGuestMode)
                    : FutureBuilder<Group?>(
                  future: _fetchGroup(context),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                      return Scaffold(
                        body: Center(
                          child: Text(
                            AppLocalizations.of(context)!.failedToLoadGroup(
                                snapshot.error?.toString() ?? "Group not found"),
                          ),
                        ),
                      );
                    }
                    final group = snapshot.data!;
                    final isShared = group.sharedWith.length > 1;
                    return GroupDetailScreen(
                      group: group,
                      isGuest: isGuestMode,
                      isShared: isShared,
                      arguments: {'selectedIndex': 2},
                    );
                  },
                ),
                '/theme-settings': (context) => const ThemeSettingsScreen(),
                '/settings': (context) => Builder(
                  builder: (context) {
                    final theme = Provider.of<ThemeProvider>(context, listen: false);
                    return SettingsScreen(
                      isGuest: isGuestMode,
                      groupColor: theme.primaryColor,
                    );
                  },
                ),
                '/notifications': (context) => isGuestMode
                    ? WelcomeScreen(setGuestMode: setGuestMode)
                    : NotificationsScreen(
                  groupId: ModalRoute.of(context)!.settings.arguments as String? ??
                      'default_group_id',
                  isGuest: isGuestMode,
                ),
              },
            );
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
          SnackBar(
            content: Text(AppLocalizations.of(context)?.failedToLoadImage ?? 'Failed to load image'),
          ),
        );
      }
    }

    if (mounted) {
      User? user = FirebaseAuth.instance.currentUser;
      final prefs = await SharedPreferences.getInstance();
      bool isGuestMode = prefs.getBool('isGuestMode') ?? false;

      if (user != null && !isGuestMode) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(isGuest: false),
          ),
        );
      } else {
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