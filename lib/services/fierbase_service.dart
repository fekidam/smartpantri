import 'package:firebase_admin/firebase_admin.dart';

// Firebase Admin SDK inicializálására szolgáló szolgáltatás osztály
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal(); // Singleton példány

  factory FirebaseService() => _instance; // Singleton factory konstruktor

  FirebaseService._internal() {
    try {
      // Firebase Admin SDK inicializálása hitelesítő adatokkal
      FirebaseAdmin.instance.initializeApp(
        AppOptions(
          credential: FirebaseAdmin.instance.certFromPath(
            'lib/config/smartpantri-dc717-36d8a433832f.json',
          ),
        ),
      );
      print('Firebase Admin SDK initialized successfully.');
    } catch (e) {
      print('Error initializing Firebase Admin SDK: $e');
    }
  }
}