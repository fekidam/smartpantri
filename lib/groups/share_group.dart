import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartpantri/services/email_service.dart';

class ShareGroupScreen extends StatefulWidget {
  final String groupId;

  const ShareGroupScreen({super.key, required this.groupId});

  @override
  _ShareGroupScreenState createState() => _ShareGroupScreenState();
}

class _ShareGroupScreenState extends State<ShareGroupScreen> {
  final TextEditingController emailController = TextEditingController();
  String? message;

  final EmailService emailService = EmailService(); // Initialize EmailService

  Future<void> _shareGroup() async {
    final email = emailController.text.trim().toLowerCase();

    if (email.isEmpty) {
      setState(() {
        message = 'Please enter an email.';
      });
      return;
    }

    try {
      // Look up the user by email in Firestore
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userSnapshot.docs.isEmpty) {
        setState(() {
          message = 'User not found.';
        });
        return;
      }

      // Add the user to the group's 'sharedWith' array
      final userId = userSnapshot.docs.first.id;
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .update({
        'sharedWith': FieldValue.arrayUnion([userId])
      });

      // Send the invite email
      await emailService.sendInviteEmail(email, 'Your Group Name');

      setState(() {
        message = 'Group shared and email invitation sent!';
      });
    } catch (e) {
      setState(() {
        message = 'Error sharing group: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share Group')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Enter email to share with',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _shareGroup,
              child: const Text('Share Group'),
            ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  message!,
                  style: TextStyle(
                    color: message!.contains('successfully') ? Colors.green : Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
