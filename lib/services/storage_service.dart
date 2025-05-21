import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Tárolási szolgáltatás osztály
class StorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore példány
  final FirebaseStorage _storage = FirebaseStorage.instance; // Firebase Storage példány

  // Kezdőlap kép URL-nek lekérése
  Future<String> getHomePageImageUrl() async {
    try {
      DocumentSnapshot snapshot = await _firestore.collection('images').doc('homepage').get();

      if (snapshot.exists && snapshot.data() != null) {
        String gsUrl = snapshot['url'] ?? '';

        if (gsUrl.startsWith('gs://')) {
          String filePath = gsUrl.replaceFirst('gs://smartpantri-dc717.appspot.com/', '');
          return await _storage.ref(filePath).getDownloadURL(); // URL lekérése
        } else {
          throw Exception('Invalid GS URL');
        }
      } else {
        throw Exception('No valid data in Firestore');
      }
    } catch (e) {
      print('Error in getHomePageImageUrl: $e');
      return '';
    }
  }
}