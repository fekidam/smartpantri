import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  String? errorMessage;
  bool _obscurePassword = true;

  Future<void> _login() async {
    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        setState(() {
          errorMessage = 'Please fill in both fields!';
        });
        return;
      }

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;

      if (user != null && user.emailVerified) {
        String? token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'fcmToken': token,
          });
          print("FCM token updated successfully: $token");
        }

        Navigator.pushReplacementNamed(context, '/home');
      } else if (user != null && !user.emailVerified) {
        setState(() {
          errorMessage = 'Please verify your email address to log in.';
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'User not found.';
            break;
          case 'wrong-password':
            errorMessage = 'Invalid password.';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address.';
            break;
          default:
            errorMessage = 'Login error: ${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Login error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Log In',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Enter your email',
                hintStyle: TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
              ),
              onFieldSubmitted: (_) => _login(),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Password',
                hintStyle: const TextStyle(color: Colors.white70),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green, width: 1),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green, width: 2),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              onFieldSubmitted: (_) => _login(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Log in'),
            ),
            const SizedBox(height: 10),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child: const Text(
                'Don\'t have an account? Register',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
