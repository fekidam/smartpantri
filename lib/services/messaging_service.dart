import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class MessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // 1. Engedélykérés
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User denied permission');
      return; // ne folytassuk, ha nincs engedély
    }

    // 2. Token lekérése és mentése
    await _saveTokenToFirestore();

    // 3. Token frissülés kezelése
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      print("FCM token refreshed: $newToken");
      await _saveTokenToFirestore(newToken: newToken);
    });

    // 4. Üzenetek kezelése
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a message: ${message.notification?.title}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification clicked!');
    });
  }

  Future<void> _saveTokenToFirestore({String? newToken}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("User not logged in, cannot save FCM token.");
        return;
      }

      final token = newToken ?? await _firebaseMessaging.getToken();
      if (token == null) {
        print("FCM token is null");
        return;
      }

      await FirebaseFirestore.instance
          .collection('fcm_tokens')
          .doc(user.uid)
          .set({'token': token});

      print("FCM token saved to Firestore: $token");
    } catch (e) {
      print("Error saving FCM token: $e");
    }
  }
}
