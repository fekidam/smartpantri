import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class YourGroupsScreen extends StatefulWidget {
  const YourGroupsScreen({super.key});

  @override
  _YourGroupsScreenState createState() => _YourGroupsScreenState();
}

class _YourGroupsScreenState extends State<YourGroupsScreen> {
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

  Future<void> removeItem(Map<String, dynamic> item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Törlés a user_shopping_lists kollekcióból
      final userDocRef = FirebaseFirestore.instance.collection('user_shopping_lists').doc(user.uid);
      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null && userData.containsKey('items')) {
          final userItems = List<Map<String, dynamic>>.from(userData['items']);
          userItems.removeWhere((existingItem) => existingItem['name'] == item['name']);
          await userDocRef.set({'items': userItems}, SetOptions(merge: true));
        }
      }

      // Törlés a shopping_lists kollekcióból
      final groupDocRef = FirebaseFirestore.instance.collection('shopping_lists').doc(item['groupId']);
      final groupDoc = await groupDocRef.get();

      if (groupDoc.exists) {
        final groupData = groupDoc.data();
        if (groupData != null && groupData.containsKey('items')) {
          final groupItems = List<Map<String, dynamic>>.from(groupData['items']);
          groupItems.removeWhere((groupItem) => groupItem['name'] == item['name']);
          await groupDocRef.set({'items': groupItems}, SetOptions(merge: true));
        }
      }
    }
  }

  Future<void> editItem(BuildContext context, Map<String, dynamic> item) async {
    final TextEditingController quantityController =
        TextEditingController(text: item['quantity'].toString());
    String selectedUnit = item['unit'];

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit ${item['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity'),
              ),
              DropdownButtonFormField<String>(
                value: selectedUnit,
                decoration: const InputDecoration(labelText: 'Unit'),
                items: ['kg', 'g', 'pcs', 'liters']
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (value) {
                  selectedUnit = value!;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final docRef = FirebaseFirestore.instance.collection('user_shopping_lists').doc(user.uid);
                  final doc = await docRef.get();

                  if (doc.exists) {
                    final data = doc.data();
                    if (data != null && data.containsKey('items')) {
                      final items = List<Map<String, dynamic>>.from(data['items']);
                      final index = items.indexWhere((existingItem) => existingItem['name'] == item['name']);
                      if (index != -1) {
                        items[index]['quantity'] = int.parse(quantityController.text);
                        items[index]['unit'] = selectedUnit;
                      }
                      await docRef.set({'items': items}, SetOptions(merge: true));
                    }
                  }
                }
                Navigator.of(context).pop();
                setState(() {});
              },
              child: const Text('Save'),
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        editItem(context, item);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await removeItem(item);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
