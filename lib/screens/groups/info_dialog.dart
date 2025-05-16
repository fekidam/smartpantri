import 'package:flutter/material.dart';
import 'package:smartpantri/generated/l10n.dart';

class InfoDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onDismiss;

  const InfoDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            onDismiss();
            Navigator.pop(context);
          },
          child: Text(AppLocalizations.of(context)!.gotIt),
        ),
      ],
    );
  }
}