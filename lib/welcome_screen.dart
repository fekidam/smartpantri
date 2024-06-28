import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  final Function(bool) setGuestMode;
  const WelcomeScreen({super.key, required this.setGuestMode});

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
              child: Image.asset(
                "assets/images/family_shopping_image.png",
                width: 200,
                height: 220,
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Log In'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/register');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Register'),
            ),
            TextButton(
              onPressed: () {
                setGuestMode(true);
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
