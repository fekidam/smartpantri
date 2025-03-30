import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  _ProfileSettingsScreenState createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? profileImageUrl;
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          firstNameController.text = data['firstName'] ?? '';
          lastNameController.text = data['lastName'] ?? '';
          emailController.text = user!.email ?? '';
          profileImageUrl = data['profilePictureUrl'] ?? '';
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    try {
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
          'firstName': firstNameController.text,
          'lastName': lastNameController.text,
        });
        if (emailController.text != user!.email) {
          await user!.verifyBeforeUpdateEmail(emailController.text);
        }
        if (passwordController.text.isNotEmpty) {
          await user!.updatePassword(passwordController.text);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your Profile is Updated!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong: $e")),
      );
    }
  }

  Future<void> _uploadProfilePicture() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 50,
      );

      if (pickedFile == null) {
        return;
      }

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile == null) {
        return;
      }

      final bytes = await File(croppedFile.path).length();
      if (bytes > 2 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image too large. Max 2MB.')),
        );
        return;
      }

      File image = File(croppedFile.path);
      if (!await image.exists()) {
        throw Exception('Cropped image file does not exist: ${croppedFile.path}');
      }

      if (user == null || user!.uid.isEmpty) {
        throw Exception('User not authenticated');
      }

      String fileName = 'profile_${user!.uid}.jpg';

      Reference storageRef = FirebaseStorage.instanceFor(bucket: 'gs://smartpantri-dc717.firebasestorage.app')
          .ref()
          .child('profile_pics')
          .child(fileName);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      UploadTask uploadTask = storageRef.putFile(
        image,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'profilePictureUrl': downloadUrl,
      });

      setState(() {
        profileImageUrl = downloadUrl;
      });

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully!')),
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
      }

      print('Profile Picture Upload Error: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            GestureDetector(
              onTap: _uploadProfilePicture,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: profileImageUrl != null && profileImageUrl!.isNotEmpty
                    ? NetworkImage(profileImageUrl!)
                    : null,
                child: profileImageUrl == null || profileImageUrl!.isEmpty
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(labelText: 'First name'),
            ),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(labelText: 'Last name'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'New Password (optional)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProfile,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}