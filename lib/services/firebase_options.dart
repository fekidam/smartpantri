import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
      appId: '1:533680516754:android:765749a5ba0cc3db5a404b',
      messagingSenderId: '533680516754',
      projectId: 'smartpantri-dc717',
      authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? 'smartpantri-dc717.firebaseapp.com',
      databaseURL: dotenv.env['FIREBASE_DATABASE_URL'] ?? 'https://smartpantri-dc717.firebaseio.com',
      storageBucket: 'smartpantri-dc717.appspot.com',
      measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID'] ?? '',
    );
  }
}
