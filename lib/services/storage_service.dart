import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> getHomePageImageUrl() async {
    DocumentSnapshot snapshot = await _firestore.collection('images').doc('homepage').get();
    if (snapshot.exists && snapshot.data() != null) {
      String gsUrl = snapshot['url'] ?? '';
      
      // Ellenőrizzük, hogy a gsUrl "gs://" URL-e
      if (gsUrl.startsWith('gs://')) {
        // Kinyerjük a fájl elérési útját a "gs://" URL-ből
        String filePath = gsUrl.replaceFirst('gs://smartpantri-dc717.appspot.com/', '');
        // Letöltési URL kérése a Storage API-tól
        String downloadUrl = await _storage.ref(filePath).getDownloadURL();
        return downloadUrl;
      }
    }
    return '';
  }
}
