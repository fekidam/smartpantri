import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationsScreen extends StatefulWidget {
  final String groupId;

  const NotificationsScreen({super.key, required this.groupId});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _sendNotification(String message) async {
    User? user = _auth.currentUser;
    if (user != null && widget.groupId.isNotEmpty) {
      await FirebaseFirestore.instance.collection('notifications').add({
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'sender': user.email,
        'groupId': widget.groupId,
      });

      DocumentSnapshot groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (groupDoc.exists && groupDoc.data() != null) {
        List<dynamic> sharedWith = groupDoc['sharedWith'] ?? [];

        for (String userId in sharedWith) {
          if (userId != user.uid) {
            DocumentSnapshot userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .get();

            if (userDoc.exists && userDoc['fcmToken'] != null) {
              String fcmToken = userDoc['fcmToken'];
              await _sendPushNotification(fcmToken, message);
            }
          }
        }
      }
    }
  }

  Future<void> _sendPushNotification(String token, String message) async {
    try {
      final Uri uri = Uri.parse('https://fcm.googleapis.com/fcm/send');
      await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=${dotenv.env['FIREBASE_SERVER_KEY']}',
        },
        body: jsonEncode({
          'to': token,
          'notification': {
            'title': 'New Notification',
            'body': message,
          },
        }),
      );
    } catch (e) {
      print('Failed to send notification: $e');
    }
  }

  void _showNotificationOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Going Shopping'),
              onTap: () {
                _sendNotification('I am going shopping today.');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('What\'s Missing?'),
              onTap: () {
                _sendNotification('What\'s missing from the shopping list?');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Who\'s Going Shopping?'),
              onTap: () {
                _sendNotification('Who\'s going shopping today?');
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('groupId', isEqualTo: widget.groupId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          if (snapshot.data?.docs.isEmpty ?? true) {
            return const Center(child: Text('No notifications found.'));
          }
          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data() as Map<String, dynamic>;

              DateTime? timestamp = (data['timestamp'] != null)
                  ? (data['timestamp'] as Timestamp).toDate()
                  : null;

              return ListTile(
                title: Text(data['message'] ?? 'No message'),
                subtitle: Text(timestamp != null
                    ? '${timestamp.day}/${timestamp.month}/${timestamp.year}'
                    : 'No timestamp available'),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNotificationOptions,
        child: const Icon(Icons.add),
      ),
    );
  }
}
