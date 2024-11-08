import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return FirebaseOptions(
      apiKey: kIsWeb ? 'WEB_FIREBASE_API_KEY' : dotenv.env['FIREBASE_API_KEY'] ?? '',
      appId: '1:533680516754:android:765749a5ba0cc3db5a404b',
      messagingSenderId: '533680516754',
      projectId: 'smartpantri-dc717',
      authDomain: kIsWeb ? 'WEB_FIREBASE_AUTH_DOMAIN' : dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? 'smartpantri-dc717.firebaseapp.com',
      databaseURL: kIsWeb ? 'WEB_FIREBASE_DATABASE_URL' : dotenv.env['FIREBASE_DATABASE_URL'] ?? 'https://smartpantri-dc717.firebaseio.com',
      storageBucket: 'smartpantri-dc717.appspot.com',
      measurementId: kIsWeb ? 'WEB_FIREBASE_MEASUREMENT_ID' : dotenv.env['FIREBASE_MEASUREMENT_ID'] ?? '',
    );
  }
}
