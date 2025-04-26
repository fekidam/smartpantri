import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smartpantri/services/storage_service.dart';

class WelcomeScreen extends StatefulWidget {
  final Function(bool)? setGuestMode;
  const WelcomeScreen({super.key, required this.setGuestMode});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final StorageService _storageService = StorageService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _imageUrl = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHomePageImage();
  }

  Future<void> _loadHomePageImage() async {
    try {
      String imageUrl = await _storageService.getHomePageImageUrl();
      setState(() {
        _imageUrl = imageUrl;
      });
    } catch (e) {
      print('Error loading homepage image: $e');
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: dotenv.env['GOOGLE_CLIENT_ID'],
      );

      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-in cancelled.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // Mentsük el a felhasználó adatait a Firestore-ban, de ne mentsük az FCM tokent
        await _firestore.collection('users').doc(user.uid).set({
          'birthDate': '',
          'email': user.email ?? '',
          'firstName': user.displayName?.split(' ').first ?? '',
          'lastName': (user.displayName != null && user.displayName!.split(' ').length > 1)
              ? user.displayName?.split(' ').last ?? ''
              : '',
          'profilePictureUrl': user.photoURL ?? '',
        }, SetOptions(merge: true));

        if (widget.setGuestMode != null) {
          widget.setGuestMode!(false);
        }

        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
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
                  child: _imageUrl.isNotEmpty
                      ? Image.network(
                    _imageUrl,
                    fit: BoxFit.cover,
                    width: 200,
                    height: 220,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              (loadingProgress.expectedTotalBytes ?? 1)
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/family_shopping_image.png',
                      fit: BoxFit.cover,
                      width: 200,
                      height: 220,
                    ),
                  )
                      : Image.asset(
                    'assets/family_shopping_image.png',
                    fit: BoxFit.cover,
                    width: 200,
                    height: 220,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
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
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Register'),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => signInWithGoogle(context),
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: const Text('Continue with Google'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    if (widget.setGuestMode != null) {
                      widget.setGuestMode!(true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Continuing as Guest')),
                      );
                    }
                    Navigator.of(context).pushReplacementNamed('/home');
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
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
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}