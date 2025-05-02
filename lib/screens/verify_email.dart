import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartpantri/generated/l10n.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  Future<void> refreshUserStatus(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    user = FirebaseAuth.instance.currentUser;

    if (user?.emailVerified ?? false) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      final snackBar = SnackBar(content: Text(AppLocalizations.of(context)!.pleaseVerifyYourEmailFirst));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    user?.sendEmailVerification();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.verifyEmail),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              AppLocalizations.of(context)!.verificationEmailSent,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await refreshUserStatus(context);
              },
              child: Text(AppLocalizations.of(context)!.iHaveVerifiedMyEmail),
            ),
          ],
        ),
      ),
    );
  }
}