import 'package:firebase_admin/firebase_admin.dart';
import 'dart:io';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() => _instance;

  FirebaseService._internal() {
    try {
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
