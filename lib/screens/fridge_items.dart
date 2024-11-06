import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FridgeItemsScreen extends StatefulWidget {
  final bool isGuest;
  final String groupId;

  const FridgeItemsScreen({super.key, required this.isGuest, required this.groupId});

  @override
  _FridgeItemsScreenState createState() => _FridgeItemsScreenState();
}

class _FridgeItemsScreenState extends State<FridgeItemsScreen> {
  bool _hasAccess(String groupId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    FirebaseFirestore.instance.collection('groups').doc(groupId).get().then((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['userId'] == user.uid || (data['sharedWith'] as List<dynamic>).contains(user.uid)) {
          setState(() {
            hasAccess = true;
          });
        } else {
          setState(() {
            hasAccess = false;
          });
        }
      }
    });

    return hasAccess;
  }

  bool hasAccess = false;

  @override
  void initState() {
    super.initState();
    hasAccess = _hasAccess(widget.groupId);
  }

  @override
  Widget build(BuildContext context) {
    if (!hasAccess) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text('You do not have access to this group.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("What's in the Fridge?"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('fridge_items')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No items found in the fridge.'));
          }
          final documents = snapshot.data!.docs;
          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              var data = documents[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['name'] ?? 'No name'),
                subtitle: Text(data['quantity'] ?? 'No quantity'),
                trailing: widget.isGuest
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('groups')
                              .doc(widget.groupId)
                              .collection('fridge_items')
                              .doc(documents[index].id)
                              .delete();
                        },
                      ),
              );
            },
          );
        },
      ),
      floatingActionButton: widget.isGuest
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/add-fridge-item',
                  arguments: {'groupId': widget.groupId},
                );
              },
              child: const Icon(Icons.add),
            ),
    );
  }
}
