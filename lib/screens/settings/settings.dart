import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../Providers/theme_provider.dart';
import 'profile_settings.dart';
import 'notifications_settings.dart';
import 'languages_settings.dart';
import 'privacy_settings.dart';
import 'theme_settings.dart';
import 'package:smartpantri/generated/l10n.dart';

// Beállítások képernyője
class SettingsScreen extends StatefulWidget {
  final bool isGuest; // Vendég mód állapotának jelzése
  final bool? isShared; // Megosztott mód ellenőrzése
  final Color? groupColor; // Opcionális csoport szín

  const SettingsScreen({
    super.key,
    required this.isGuest,
    this.isShared = true,
    this.groupColor,
  });

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? profilePictureUrl; // Profilkép URL-je

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Felhasználói adatok betöltése
  }

  // Felhasználói adatok betöltése Firestore-ból
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          setState(() {
            profilePictureUrl = (doc.data()!['profilePictureUrl'] as String?) ?? '';
          });
        }
      } catch (e) {
        print("Error loading user data: $e");
      }
    }
  }

  // Kijelentkezés
  Future<void> _signOut() async {
    if (!widget.isGuest) {
      await GoogleSignIn().signOut(); // Google kijelentkezés
    }
    await FirebaseAuth.instance.signOut(); // Firebase kijelentkezés
    print("User logged out, clearing guest mode and skipping FCM setup.");
    await Future.delayed(const Duration(milliseconds: 100));
    Navigator.pushReplacementNamed(context, '/welcomescreen'); // Vissza a kezdőképernyőre
  }

  // Kártya widget generálása
  Card _buildCard({required Widget child}) {
    return Card(
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context); // Témaszolgáltató provider
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    // Határozza meg a használni kívánt színt a globális téma vagy csoportszín alapján
    final effectiveColor = theme.useGlobalTheme
        ? theme.primaryColor
        : (widget.groupColor ?? theme.primaryColor);
    final fontSizeScale = theme.fontSizeScale;

    return Scaffold(
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: effectiveColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            l10n.settings,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 20 * fontSizeScale.toDouble(),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: effectiveColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              effectiveColor.withOpacity(0.2),
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]!
                  : Colors.grey[200]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.only(top: 16, bottom: 32),
          children: [
            if (!widget.isGuest && user != null)
              _buildCard(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: profilePictureUrl?.isNotEmpty == true &&
                        Uri.tryParse(profilePictureUrl!)?.isAbsolute == true
                        ? NetworkImage(profilePictureUrl!)
                        : null,
                    backgroundColor: Theme.of(context).unselectedWidgetColor,
                    child: profilePictureUrl?.isNotEmpty == true &&
                        Uri.tryParse(profilePictureUrl!)?.isAbsolute == true
                        ? null
                        : Text(
                      user.email![0].toUpperCase(),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                  title: Text(
                    user.email!,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              ),

            if (!widget.isGuest)
              _buildCard(
                child: ListTile(
                  leading: Icon(Icons.person, color: effectiveColor),
                  title: Text(
                    l10n.profileSettings,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileSettingsScreen(
                        groupColor: widget.groupColor ?? theme.primaryColor,
                      ),
                    ),
                  ),
                ),
              ),

            if (!widget.isGuest && (widget.isShared ?? true))
              _buildCard(
                child: ListTile(
                  leading: Icon(Icons.notifications, color: effectiveColor),
                  title: Text(
                    l10n.notifications,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NotificationSettingsScreen(
                        groupColor: widget.groupColor ?? theme.primaryColor,
                      ),
                    ),
                  ),
                ),
              ),

            _buildCard(
              child: ListTile(
                leading: Icon(Icons.language, color: effectiveColor),
                title: Text(
                  l10n.languageAndRegion,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LanguageRegionSettingsScreen(
                      groupColor: widget.groupColor ?? theme.primaryColor,
                    ),
                  ),
                ),
              ),
            ),

            if (!widget.isGuest)
              _buildCard(
                child: ListTile(
                  leading: Icon(Icons.security, color: effectiveColor),
                  title: Text(
                    l10n.privacyAndSecurity,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PrivacySecuritySettingsScreen(
                        groupColor: widget.groupColor ?? theme.primaryColor,
                      ),
                    ),
                  ),
                ),
              ),

            _buildCard(
              child: ListTile(
                leading: Icon(Icons.palette, color: effectiveColor),
                title: Text(
                  l10n.themeAndAppearance,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ThemeSettingsScreen(
                      groupColor: widget.groupColor,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (widget.isGuest)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: effectiveColor,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: Text(
                    l10n.register,
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: _signOut,
                child: Text(
                  widget.isGuest
                      ? l10n.returnToWelcomeScreen
                      : l10n.logOut,
                  style: TextStyle(color: Theme.of(context).colorScheme.onError),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}