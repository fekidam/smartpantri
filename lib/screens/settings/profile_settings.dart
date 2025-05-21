import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../Providers/theme_provider.dart';
import 'package:smartpantri/generated/l10n.dart';

// Profilbeállítások képernyője
class ProfileSettingsScreen extends StatefulWidget {
  final Color groupColor; // Csoport színe

  const ProfileSettingsScreen({
    super.key,
    required this.groupColor, // Kötelező paraméter
  });

  @override
  _ProfileSettingsScreenState createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final TextEditingController _firstName = TextEditingController(); // Keresztnév beviteli mező
  final TextEditingController _lastName = TextEditingController(); // Vezetéknév beviteli mező
  final TextEditingController _email = TextEditingController(); // Email beviteli mező
  final TextEditingController _currentPwd = TextEditingController(); // Jelenlegi jelszó beviteli mező
  final TextEditingController _newPwd = TextEditingController(); // Új jelszó beviteli mező

  String? _photoUrl; // Profilképek URL-je
  bool _loading = false; // Betöltési állapot
  bool _isGoogle = false; // Google fiók ellenőrzése
  bool _showCurrent = false; // Jelenlegi jelszó láthatósága
  bool _showNew = false; // Új jelszó láthatósága

  @override
  void initState() {
    super.initState();
    _loadUser(); // Felhasználói adatok betöltése
  }

  // Felhasználói adatok betöltése Firestore-ból
  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _loading = true);

    _isGoogle = user.providerData.any((p) => p.providerId == 'google.com');

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.exists ? doc.data()! : {};

    _firstName.text = data['firstName'] ?? '';
    _lastName.text = data['lastName'] ?? '';
    _email.text = user.email ?? '';
    _photoUrl = data['profilePictureUrl'] ?? '';

    setState(() => _loading = false);
  }

  // Profil mentése
  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser!;
    setState(() => _loading = true);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({
      'firstName': _firstName.text,
      'lastName': _lastName.text,
    });

    if (!_isGoogle) {
      if (_email.text != user.email) {
        await user.verifyBeforeUpdateEmail(_email.text);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.verificationEmailSent)),
        );
      }

      if (_newPwd.text.isNotEmpty) {
        if (_newPwd.text.length < 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.passwordTooShortError)),
          );
        } else {
          final cred = EmailAuthProvider.credential(email: user.email!, password: _currentPwd.text);
          await user.reauthenticateWithCredential(cred);
          await user.updatePassword(_newPwd.text);
        }
      }
    }

    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.profileUpdated)),
    );
  }

  // Profilkép kiválasztása és feltöltése
  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 50,
    );
    if (picked == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: AppLocalizations.of(context)!.cropImage,
          toolbarColor: widget.groupColor, // groupColor használata
          toolbarWidgetColor: Theme.of(context).colorScheme.onPrimary,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: AppLocalizations.of(context)!.cropImage,
          aspectRatioLockEnabled: true,
        ),
      ],
    );
    if (cropped == null) return;

    final file = File(cropped.path);
    final user = FirebaseAuth.instance.currentUser!;
    final ref = FirebaseStorage.instanceFor(bucket: 'gs://smartpantri-dc717.firebasestorage.app')
        .ref()
        .child('profile_pics')
        .child('profile_${user.uid}.jpg');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final snap = await ref.putFile(file).whenComplete(() {});
    final url = await snap.ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'profilePictureUrl': url});

    setState(() => _photoUrl = url);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.profilePictureUpdated)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context); // Témaszolgáltató provider
    // Határozza meg a használni kívánt színt a globális téma vagy csoportszín alapján
    final effectiveColor = theme.useGlobalTheme ? theme.primaryColor : widget.groupColor;
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (FirebaseAuth.instance.currentUser == null) {
      return Scaffold(
        body: Center(
          child: Text(
            AppLocalizations.of(context)!.pleaseLogInToEditProfile,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.profileSettings,
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
        backgroundColor: effectiveColor, // effectiveColor használata
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              effectiveColor.withOpacity(0.2), // effectiveColor használata
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]!
                  : Colors.grey[200]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickPhoto, // Profilkép kiválasztása
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _photoUrl?.isNotEmpty == true
                          ? NetworkImage(_photoUrl!)
                          : null,
                      backgroundColor: Theme.of(context).unselectedWidgetColor,
                      child: _photoUrl?.isNotEmpty == true
                          ? null
                          : Icon(Icons.person,
                          size: 50, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: widget.groupColor, // groupColor használata
                      child: Icon(Icons.camera_alt,
                          size: 20, color: Theme.of(context).colorScheme.onPrimary),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: _firstName,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.firstName,
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _lastName,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.lastName,
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),

            const SizedBox(height: 16),

            Text(AppLocalizations.of(context)!.email,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_email.text,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            ),

            if (_isGoogle) ...[
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context)!.managedByGoogle,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54),
                      fontStyle: FontStyle.italic)),
            ],

            if (!_isGoogle) ...[
              const SizedBox(height: 16),

              TextField(
                controller: _currentPwd,
                obscureText: !_showCurrent,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.currentPasswordLabel,
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showCurrent ? Icons.visibility : Icons.visibility_off,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54),
                    ),
                    onPressed: () => setState(() => _showCurrent = !_showCurrent),
                  ),
                ),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _newPwd,
                obscureText: !_showNew,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.newPasswordLabel,
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showNew ? Icons.visibility : Icons.visibility_off,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54),
                    ),
                    onPressed: () => setState(() => _showNew = !_showNew),
                  ),
                ),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            ],

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _saveProfile, // Profil mentése
              child: Text(AppLocalizations.of(context)!.save,
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
              style: ElevatedButton.styleFrom(
                backgroundColor: effectiveColor, // effectiveColor használata
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}