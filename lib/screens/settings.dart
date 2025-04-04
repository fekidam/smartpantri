import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartpantri/screens/privacy_settings.dart';
import 'package:smartpantri/screens/profile_settings.dart';
import 'package:smartpantri/screens/theme_settings.dart';
import 'languages_settings.dart';
import 'notifications_settings.dart';

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

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/welcomescreen');
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
                  child: Text(user.email![0].toUpperCase()),
                ),
                title: Text(user.email!),
              ),
            const Divider(),
            if (!widget.isGuest)
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile Settings'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileSettingsScreen()),
                  );
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