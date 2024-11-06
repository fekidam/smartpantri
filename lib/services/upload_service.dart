import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class UploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> uploadImage(File imageFile, String userId) async {
    try {
      String filePath = 'user_images/$userId/profile_picture.png';
      Reference ref = _storage.ref().child(filePath);
      UploadTask uploadTask = ref.putFile(imageFile);

      TaskSnapshot snapshot = await uploadTask;
      String downloadURL = await snapshot.ref.getDownloadURL();

      await _firestore.collection('users').doc(userId).set({
        'profileImageUrl': downloadURL,
      }, SetOptions(merge: true));

      print("Kép sikeresen feltöltve és URL elmentve a Firestore-ba.");
    } catch (e) {
      print("Hiba történt a kép feltöltésekor: $e");
    }
  }
}
