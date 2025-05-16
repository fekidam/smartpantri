// lib/screens/welcome_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:smartpantri/services/storage_service.dart';
import '../../generated/l10n.dart';

class WelcomeScreen extends StatefulWidget {
  final Function(bool)? setGuestMode;
  const WelcomeScreen({Key? key, this.setGuestMode}) : super(key: key);

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
      final url = await _storageService.getHomePageImageUrl();
      setState(() => _imageUrl = url);
    } catch (e) {
      debugPrint('Error loading homepage image: $e');
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final googleSignIn = GoogleSignIn(serverClientId: dotenv.env['GOOGLE_CLIENT_ID']);
      await googleSignIn.signOut();
      final user = await googleSignIn.signIn();
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.googleSignInCancelled)),
        );
        return;
      }
      final auth = await user.authentication;
      final cred = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      final userCred = await FirebaseAuth.instance.signInWithCredential(cred);
      final firebaseUser = userCred.user;
      if (firebaseUser != null) {
        await _firestore.collection('users').doc(firebaseUser.uid).set({
          'email': firebaseUser.email ?? '',
          'firstName': firebaseUser.displayName?.split(' ').first ?? '',
          'lastName': firebaseUser.displayName?.split(' ').last ?? '',
          'profilePictureUrl': firebaseUser.photoURL ?? '',
        }, SetOptions(merge: true));
        widget.setGuestMode?.call(false);
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.googleSignInError} $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _darken(Color color, [double amount = .2]) {
    final hsl = HSLColor.fromColor(color);
    final l = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(l).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade300,
                  Colors.grey.shade500,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.appTitle,
                        style: theme.textTheme.headlineSmall!
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 32),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FadeInImage.assetNetwork(
                          placeholder: 'assets/family_shopping_image.png',
                          image: _imageUrl.isNotEmpty
                              ? _imageUrl
                              : 'assets/family_shopping_image.png',
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                          imageErrorBuilder: (_, __, ___) => Image.asset(
                            'assets/family_shopping_image.png',
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildButton(
                        text: AppLocalizations.of(context)!.logIn,
                        icon: null,
                        color: _darken(theme.colorScheme.primary),
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/login'),
                      ),
                      const SizedBox(height: 16),
                      _buildButton(
                        text: AppLocalizations.of(context)!.register,
                        icon: null,
                        color: _darken(theme.colorScheme.primary),
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/register'),
                      ),
                      const SizedBox(height: 24),
                      _buildButton(
                        text: AppLocalizations.of(context)!.continueWithGoogle,
                        icon: Icons.login,
                        color: _darken(Colors.redAccent),
                        onPressed: _isLoading ? null : _signInWithGoogle,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          widget.setGuestMode?.call(true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context)!.continuingAsGuest,
                              ),
                            ),
                          );
                          Navigator.pushReplacementNamed(context, '/home');
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 14),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.continueAsGuest,
                          style: theme.textTheme.labelLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildButton({
    required String text,
    IconData? icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon != null
          ? Icon(icon, size: 20, color: Colors.white)
          : const SizedBox.shrink(),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 4,
      ),
    );
  }
}
