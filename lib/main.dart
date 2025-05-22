import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartpantri/screens/notifications/notifications.dart';
import 'package:smartpantri/screens/settings/settings.dart';
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
import 'Providers/theme_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:smartpantri/models/data.dart';
import 'package:smartpantri/screens/groups/group_detail.dart';
import 'package:smartpantri/generated/l10n.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> initializeLocalNotifications() async {
  tz.initializeTimeZones();
  try {
    final currentTimeZone = await FlutterTimezone.getLocalTimezone();
    final localLocation = tz.getLocation(currentTimeZone);
    tz.setLocalLocation(localLocation);
  } catch (e) {
    tz.setLocalLocation(tz.getLocation('UTC'));
  }

  const initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('app_icon'),
    iOS: DarwinInitializationSettings(),
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (response) {
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
    }
  } catch (_) {
    return;
  }

  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
  } catch (_) {}

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await initializeLocalNotifications();

  final languageProvider = LanguageProvider();
  await languageProvider.loadLocale();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(isDarkMode: true, primaryColor: Colors.blue)..loadThemeAsync()),
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
      FirebaseAuth.instance.authStateChanges().listen((user) async {
        if (user != null) {
          await _setupFCM(context);
        } else {
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
    appStateProvider.setAppState(state == AppLifecycleState.resumed);
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
    await FirebaseMessaging.instance.deleteToken();
  }

  Future<void> _setupFCM(BuildContext context) async {
    if (isGuestMode) return;

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(alert: true, badge: true, sound: true);
    if (settings.authorizationStatus != AuthorizationStatus.authorized && settings.authorizationStatus != AuthorizationStatus.provisional) return;

    String? token = await messaging.getToken();
    if (token == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _saveFCMToken(user.uid, token);

    messaging.onTokenRefresh.listen((newToken) async {
      if (newToken != null && user.uid == FirebaseAuth.instance.currentUser?.uid) {
        await _saveFCMToken(user.uid, newToken);
      }
    });

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null) {
        flutterLocalNotificationsPlugin.show(
          0,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails('channel_id', 'Channel Name', importance: Importance.max, priority: Priority.high),
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final screen = message.data['screen'];
      final groupId = message.data['groupId'];
      if (screen == 'notifications' && groupId != null) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsScreen(groupId: groupId, isGuest: isGuestMode)));
      } else if (screen == 'group_home') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => HomeScreen(isGuest: isGuestMode)));
      }
    });

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      final screen = initialMessage.data['screen'];
      final groupId = initialMessage.data['groupId'];
      if (screen == 'notifications' && groupId != null) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsScreen(groupId: groupId, isGuest: isGuestMode)));
      } else if (screen == 'group_home') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => HomeScreen(isGuest: isGuestMode)));
      }
    }
  }

  Future<void> _saveFCMToken(String userId, String token) async {
    if (FirebaseAuth.instance.currentUser == null) return;

    try {
      final tokenRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('tokens').doc(token);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final existingTokens = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('tokens')
            .get();
        for (var doc in existingTokens.docs) {
          if (doc.id != token) {
            transaction.delete(doc.reference); // Törli a régi tokeneket
          }
        }
        transaction.set(tokenRef, {
          'token': token,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  Future<Group?> _fetchGroup(BuildContext context) async {
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    final groupId = args?['groupId'];
    if (groupId == null) return null;

    try {
      final doc = await FirebaseFirestore.instance.collection('groups').doc(groupId).get();
      if (!doc.exists) return null;
      return Group.fromJson(groupId, doc.data()!);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (_, themeProvider, __) {
        return Consumer<LanguageProvider>(
          builder: (_, languageProvider, __) {
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
              home: SplashScreen(myAppState: this),
              routes: {
                '/login': (_) => LoginScreen(setGuestMode: setGuestMode),
                '/register': (_) => RegisterScreen(setGuestMode: setGuestMode),
                '/welcomescreen': (_) => WelcomeScreen(setGuestMode: setGuestMode),
                '/home': (_) => HomeScreen(isGuest: isGuestMode),
                '/verify-email': (_) => isGuestMode
                    ? WelcomeScreen(setGuestMode: setGuestMode)
                    : const VerifyEmailScreen(),
                '/group-chat': (_) => isGuestMode
                    ? WelcomeScreen(setGuestMode: setGuestMode)
                    : FutureBuilder<Group?>(
                    future: _fetchGroup(context),
                    builder: (_, snapshot) {
                      if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
                      final group = snapshot.data!;
                      return GroupDetailScreen(group: group, isGuest: isGuestMode, isShared: group.sharedWith.length > 1, arguments: {'selectedIndex': 2});
                    }),
                '/ai-chat': (_) => isGuestMode
                    ? WelcomeScreen(setGuestMode: setGuestMode)
                    : FutureBuilder<Group?>(
                    future: _fetchGroup(context),
                    builder: (_, snapshot) {
                      if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
                      final group = snapshot.data!;
                      return GroupDetailScreen(group: group, isGuest: isGuestMode, isShared: group.sharedWith.length > 1, arguments: {'selectedIndex': 2});
                    }),
                '/theme-settings': (_) => const ThemeSettingsScreen(),
                '/settings': (_) => SettingsScreen(isGuest: isGuestMode, groupColor: themeProvider.primaryColor),
                '/notifications': (_) => isGuestMode
                    ? WelcomeScreen(setGuestMode: setGuestMode)
                    : NotificationsScreen(groupId: ModalRoute.of(context)!.settings.arguments as String? ?? 'default_group_id', isGuest: isGuestMode),
              },
            );
          },
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  final _MyAppState myAppState;
  const SplashScreen({super.key, required this.myAppState});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final StorageService _storageService = StorageService();
  String _imageUrl = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      _imageUrl = await _storageService.getHomePageImageUrl();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.failedToLoadImage ?? 'Failed to load image',
            ),
          ),
        );
      }
    }

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    final isGuestMode = prefs.getBool('isGuestMode') ?? false;

    if (user != null && !isGuestMode) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomeScreen(isGuest: false)),
        );
      }
    } else {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => WelcomeScreen(
              setGuestMode: widget.myAppState.setGuestMode,
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
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}