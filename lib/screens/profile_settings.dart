import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart'; // Provider import hozzáadása
import '../services/theme_provider.dart'; // ThemeProvider import hozzáadása

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
  final TextEditingController currentPasswordController = TextEditingController();
  String? profileImageUrl;
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isPasswordVisible = false;
  bool _isCurrentPasswordVisible = false;
  bool _isLoading = false;
  bool isGoogleUser = false;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.setLanguageCode('hu');
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      setState(() {
        _isLoading = true;
      });

      isGoogleUser = user!.providerData.any((provider) => provider.providerId == 'google.com');

      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          firstNameController.text = data['firstName'] ?? '';
          lastNameController.text = data['lastName'] ?? '';
          emailController.text = user!.email ?? '';
          profileImageUrl = data['profilePictureUrl'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          emailController.text = user!.email ?? '';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    try {
      if (user == null) {
        throw Exception('User not authenticated');
      }

      setState(() {
        _isLoading = true;
      });

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'firstName': firstNameController.text,
        'lastName': lastNameController.text,
      });

      if (!isGoogleUser) {
        if (emailController.text != user!.email) {
          await user!.verifyBeforeUpdateEmail(emailController.text);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification email sent. Please check your inbox.')),
          );
        }

        if (passwordController.text.isNotEmpty) {
          if (passwordController.text.length < 6) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Password must be at least 6 characters long.")),
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }

          if (currentPasswordController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enter your current password to update the new password.')),
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }

          final credential = EmailAuthProvider.credential(
            email: user!.email!,
            password: currentPasswordController.text,
          );
          await user!.reauthenticateWithCredential(credential);

          await user!.updatePassword(passwordController.text);
        }
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your Profile is Updated!')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
    // ThemeProvider lekérése
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to edit your profile.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
        backgroundColor: themeProvider.primaryColor, // AppBar színe a ThemeProvider-ből
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            GestureDetector(
              onTap: _uploadProfilePicture,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: profileImageUrl != null && profileImageUrl!.isNotEmpty
                        ? NetworkImage(profileImageUrl!)
                        : null,
                    child: profileImageUrl == null || profileImageUrl!.isEmpty
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  const CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.camera_alt, size: 20, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(
                labelText: 'First name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Email',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey[500],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                emailController.text,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            if (isGoogleUser) ...[
              const SizedBox(height: 8),
              Text(
                'Managed by Google',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (!isGoogleUser) ...[
              TextField(
                controller: currentPasswordController,
                obscureText: !_isCurrentPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Current Password (required for password update)',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isCurrentPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'New Password (optional)',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
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