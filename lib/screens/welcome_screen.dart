import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smartpantri/services/storage_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

class WelcomeScreen extends StatefulWidget {
  final Function(bool) setGuestMode;
  const WelcomeScreen({super.key, required this.setGuestMode});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final StorageService _storageService = StorageService();
  String _imageUrl = '';
  File? _localImageFile;

  @override
  void initState() {
    super.initState();
    _loadHomePageImage();
  }

  Future<void> _loadHomePageImage() async {
    String imageUrl = await _storageService.getHomePageImageUrl();
    setState(() {
      _imageUrl = imageUrl;
    });

    // Ellenőrizzük, hogy létezik-e a helyi fájl
    final Directory appDir = await getApplicationDocumentsDirectory();
    final localImagePath = '${appDir.path}/homepage_image.png';
    final localImageFile = File(localImagePath);

    if (await localImageFile.exists()) {
      // Helyi tárolóból töltjük be a képet, ha létezik
      setState(() {
        _localImageFile = localImageFile;
      });
    } else {
      // Letöltjük és elmentjük, ha még nincs letöltve
      await _downloadAndSaveImage(imageUrl, localImageFile);
      setState(() {
        _localImageFile = localImageFile;
      });
    }
  }

  Future<void> _downloadAndSaveImage(String url, File localFile) async {
    try {
      await Dio().download(url, localFile.path);
      print("Kép sikeresen letöltve és mentve a helyi tárolóba.");
    } catch (e) {
      print("Hiba történt a kép letöltésekor: $e");
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: '533680516754-tarc1mubk9q7eu5qk84si0qv6d1hgd8g.apps.googleusercontent.com',
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

        if (userCredential.user != null) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'SmartPantri',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _localImageFile != null
                  ? Image.file(
                      _localImageFile!,
                      width: 200,
                      height: 220,
                      fit: BoxFit.cover,
                    )
                  : CachedNetworkImage(
                      imageUrl: _imageUrl,
                      width: 200,
                      height: 220,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Log In'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/register');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Register'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => signInWithGoogle(context),
              icon: const Icon(Icons.login, color: Colors.white),
              label: const Text('Continue with Google'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                widget.setGuestMode(true);
                Navigator.of(context).pushReplacementNamed('/home');
              },
              child: const Text(
                'Continue as Guest',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}