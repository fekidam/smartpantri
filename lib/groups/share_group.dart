import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'group_home.dart';
import 'package:smartpantri/generated/l10n.dart'; // AppLocalizations import

class ShareGroupScreen extends StatefulWidget {
  final String groupId;

  const ShareGroupScreen({super.key, required this.groupId});

  @override
  _ShareGroupScreenState createState() => _ShareGroupScreenState();
}

class _ShareGroupScreenState extends State<ShareGroupScreen> {
  final TextEditingController emailController = TextEditingController();
  String? message;

  Future<void> _shareGroup() async {
    final email = emailController.text.trim().toLowerCase();

    if (email.isEmpty) {
      setState(() {
        message = AppLocalizations.of(context)!.pleaseEnterEmailAddress;
      });
      return;
    }

    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userSnapshot.docs.isEmpty) {
        setState(() {
          message = AppLocalizations.of(context)!.userNotFound;
        });
        return;
      }

      final userId = userSnapshot.docs.first.id;
      final groupRef = FirebaseFirestore.instance.collection('groups').doc(widget.groupId);

      await groupRef.update({
        'sharedWith': FieldValue.arrayUnion([userId])
      });

      setState(() {
        message = AppLocalizations.of(context)!.groupSharedSuccessfully;
      });

      // Clear the email input after successful sharing
      emailController.clear();
    } catch (e) {
      setState(() {
        message = AppLocalizations.of(context)!.errorSharingGroup(e.toString());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.shareGroup),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(isGuest: false),
              ),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.enterEmailToShareWith,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _shareGroup,
              child: Text(AppLocalizations.of(context)!.shareGroup),
            ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  message!,
                  style: TextStyle(
                    color: message!.contains(AppLocalizations.of(context)!.groupSharedSuccessfully)
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}