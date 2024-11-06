import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'AIzaSyAn88hyOzzza0xWcqUBcnk8cWgnsHrQ2wI',
      appId: '1:533680516754:android:765749a5ba0cc3db5a404b',
      messagingSenderId: '533680516754',
      projectId: 'smartpantri-dc717',
      authDomain: 'smartpantri-dc717.firebaseapp.com', // Replace if necessary
      databaseURL: 'https://smartpantri-dc717.firebaseio.com', // Replace if necessary
      storageBucket: 'smartpantri-dc717.appspot.com',
      measurementId: 'YOUR_MEASUREMENT_ID', // Optional
    );
  }
}
