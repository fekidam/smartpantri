import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FridgeItemsScreen extends StatefulWidget {
  final bool isGuest;

  const FridgeItemsScreen({Key? key, required this.isGuest}) : super(key: key);

  @override
  _FridgeItemsScreenState createState() => _FridgeItemsScreenState();
}

class _FridgeItemsScreenState extends State<FridgeItemsScreen> {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    if (!widget.isGuest && user == null) {
      return const Center(child: Text('Please log in to view what\'s in the fridge.'));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('What\'s in the Fridge?'),
        actions: widget.isGuest
            ? []
            : [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushReplacementNamed(context, '/');
                  },
                ),
              ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('fridge_items').snapshots(),
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
                          await FirebaseFirestore.instance.collection('fridge_items').doc(documents[index].id).delete();
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
                Navigator.pushNamed(context, '/add-fridge-item');
              },
              child: const Icon(Icons.add),
            ),
    );
  }
}
