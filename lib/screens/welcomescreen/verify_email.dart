
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../generated/l10n.dart';

// Ez a képernyő jelenik meg regisztráció után, amíg nem igazolta vissza az emailjét a felhasználó
class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({Key? key}) : super(key: key);

  // Szín sötétítése
  Color _darken(Color color, [double amount = .2]) {
    final hsl = HSLColor.fromColor(color);
    final l = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(l).toColor();
  }

  // Email státusz frissítése, ha megerősítette akkor tovább enged a bejelentkezéshez
  Future<void> _refreshStatus(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    if (FirebaseAuth.instance.currentUser?.emailVerified ?? false) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseVerifyYourEmailFirst)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Automatikusan egyszer elküldi a megerősítő emailt
    FirebaseAuth.instance.currentUser?.sendEmailVerification();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade300, Colors.grey.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.email,
                    size: 72,
                    color: _darken(theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 24),

                  // Üzenet a felhasználónak
                  Text(
                    AppLocalizations.of(context)!.verificationEmailSent,
                    style: theme.textTheme.bodyLarge?.copyWith(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Gomb: "Megerősítettem az email címemet"
                  ElevatedButton(
                    onPressed: () => _refreshStatus(context),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: _darken(theme.colorScheme.primary),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 4,
                    ),
                    child: Text(AppLocalizations.of(context)!.iHaveVerifiedMyEmail),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
