import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartpantri/screens/privacy_settings.dart';
import 'package:smartpantri/screens/profile_settings.dart';
import 'package:smartpantri/screens/theme_settings.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';
import 'languages_settings.dart';
import 'notifications_settings.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smartpantri/generated/l10n.dart'; // AppLocalizations import

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
      if (!widget.isGuest) {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
      }
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/welcomescreen');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorLoggingOut(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.settings),
            backgroundColor: themeProvider.primaryColor,
            foregroundColor: Colors.white,
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
                    title: Text(AppLocalizations.of(context)!.profileSettings),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileSettingsScreen()),
                      );
                      await _loadUserData();
                    },
                  ),
                if (!widget.isGuest && (widget.isShared ?? true))
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: Text(AppLocalizations.of(context)!.notifications),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => NotificationSettingsScreen()),
                      );
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(AppLocalizations.of(context)!.languageAndRegion),
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
                    title: Text(AppLocalizations.of(context)!.privacyAndSecurity),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PrivacySecuritySettingsScreen()),
                      );
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.palette),
                  title: Text(AppLocalizations.of(context)!.themeAndAppearance),
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
                    child: Text(AppLocalizations.of(context)!.register),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _signOut,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text(widget.isGuest
                      ? AppLocalizations.of(context)!.returnToWelcomeScreen
                      : AppLocalizations.of(context)!.logOut),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}