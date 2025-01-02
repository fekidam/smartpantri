import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'group_home.dart';

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
        message = 'Please enter an email.';
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
          message = 'User not found.';
        });
        return;
      }

      final userId = userSnapshot.docs.first.id;
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .update({
        'sharedWith': FieldValue.arrayUnion([userId])
      });

      setState(() {
        message = 'Group shared successfully!';
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
      appBar: AppBar(
        title: const Text('Share Group'),
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
