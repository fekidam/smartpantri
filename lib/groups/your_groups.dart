import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class YourGroupsScreen extends StatelessWidget {
  const YourGroupsScreen({super.key});

  Future<List<Map<String, dynamic>>> fetchUserItems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('user_shopping_lists').doc(user.uid).get();
      final data = doc.data();
      if (data != null && data.containsKey('items')) {
        return List<Map<String, dynamic>>.from(data['items']);
      }
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Consolidated Shopping List'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchUserItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No items in your consolidated shopping list."));
          }

          final items = snapshot.data!;

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item['name']),
                subtitle: Text('Quantity: ${item['quantity']} ${item['unit']}'),
              );
            },
          );
        },
      ),
    );
  }
}
