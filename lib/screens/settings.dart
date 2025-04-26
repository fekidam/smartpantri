import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartpantri/screens/privacy_settings.dart';
import 'package:smartpantri/screens/profile_settings.dart';
import 'package:smartpantri/screens/theme_settings.dart';
import 'languages_settings.dart';
import 'notifications_settings.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Hozzáadjuk a GoogleSignIn importot

class SettingsScreen extends StatefulWidget {
  final bool isGuest;
  final bool? isShared;

  const SettingsScreen({
    super.key,
    required this.isGuest,
    this.isShared = true,
  });

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool openLastUsedAtLaunch = true;
  bool keepScreenOn = false;
  String? profilePictureUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          profilePictureUrl = data['profilePictureUrl'] ?? '';
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      // Ha nem vendég módban vagyunk, akkor kijelentkeztetjük a Google-fiókot is
      if (!widget.isGuest) {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        await googleSignIn.signOut(); // Google Sign-In munkamenet törlése
      }
      // Firebase Authentication kijelentkezés
      await FirebaseAuth.instance.signOut();
      // Navigáció a WelcomeScreen-re
      Navigator.pushReplacementNamed(context, '/welcomescreen');
    } catch (e) {
      // Hiba esetén értesítjük a felhasználót
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            if (!widget.isGuest && user != null)
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: profilePictureUrl != null && profilePictureUrl!.isNotEmpty
                      ? NetworkImage(profilePictureUrl!)
                      : null,
                  child: profilePictureUrl == null || profilePictureUrl!.isEmpty
                      ? Text(user.email![0].toUpperCase())
                      : null,
                ),
                title: Text(user.email!),
              ),
            const Divider(),
            if (!widget.isGuest)
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile Settings'),
                onTap: () async {
                  // Navigálunk a ProfileSettingsScreen-re, és várjuk meg a visszatérést
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileSettingsScreen()),
                  );
                  // Frissítjük az adatokat, hogy a profilkép megjelenjen, ha megváltozott
                  await _loadUserData();
                },
              ),
            if (!widget.isGuest && (widget.isShared ?? true)) // Ha isShared null, akkor true
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notifications'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NotificationSettingsScreen()),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Language and Region'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LanguageRegionSettingsScreen()),
                );
              },
            ),
            if (!widget.isGuest)
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Privacy and Security'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PrivacySecuritySettingsScreen()),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.palette),
              title: const Text("Theme and Appearance"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ThemeSettingsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            if (widget.isGuest)
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Register'),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signOut,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(widget.isGuest ? 'Return to Welcome Screen' : 'Log out'),
            ),
          ],
        ),
      ),
    );
  }
}