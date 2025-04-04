import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  Future<void> refreshUserStatus(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    user = FirebaseAuth.instance.currentUser;

    if (user?.emailVerified ?? false) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      const snackBar = SnackBar(content: Text('Please verify your email first.'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    user?.sendEmailVerification();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'A verification email has been sent to your email address.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await refreshUserStatus(context);
              },
              child: const Text('I have verified my email'),
            ),
          ],
        ),
      ),
    );
  }
}
