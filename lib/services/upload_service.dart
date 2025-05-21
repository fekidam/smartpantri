import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

// Képfeltöltési szolgáltatás osztály
class UploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance; // Firebase Storage példány
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore példány

  // Kép feltöltése és URL mentése Firestore-ba
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

      print("Image successfully uploaded and URL saved to Firestore.");
    } catch (e) {
      print("An error occurred while uploading the image: $e");
    }
  }
}