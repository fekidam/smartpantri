import 'package:flutter/material.dart';
import 'package:smartpantri/generated/l10n.dart';

// Egy egyszerű dialógus ablak tájékoztató vagy bemutató üzenethez
class InfoDialog extends StatelessWidget {
  final String title;           // Dialógus címe
  final String message;         // A megjelenítendő szöveg
  final VoidCallback onDismiss; // Callback, ha a felhasználó bezárja

  const InfoDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title), // Fejléc
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 16), // Szöveg formázása
            ),
          ],
        ),
      ),
      actions: [
        // Gomb: "Értettem"
        TextButton(
          onPressed: () {
            onDismiss();          // Callback hívás
            Navigator.pop(context); // Dialógus bezárása
          },
          child: Text(AppLocalizations.of(context)!.gotIt),
        ),
      ],
    );
  }
}
