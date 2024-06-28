import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShoppingListsScreen extends StatefulWidget {
  final bool isGuest;

  const ShoppingListsScreen({Key? key, required this.isGuest}) : super(key: key);

  @override
  _ShoppingListsScreenState createState() => _ShoppingListsScreenState();
}

class _ShoppingListsScreenState extends State<ShoppingListsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Lists'),
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
        stream: FirebaseFirestore.instance.collection('shopping_list').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          if (snapshot.data?.docs.isEmpty ?? true) {
            return const Center(child: Text('No items found.'));
          }
          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['name']),
                subtitle: Text(data['quantity'] ?? ''),
                trailing: widget.isGuest
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          FirebaseFirestore.instance.collection('shopping_list').doc(document.id).delete();
                        },
                      ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: widget.isGuest
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/add-item');
              },
              child: const Icon(Icons.add),
            ),
    );
  }
}
