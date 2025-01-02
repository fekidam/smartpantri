import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class YourGroupsScreen extends StatefulWidget {
  const YourGroupsScreen({super.key});

  @override
  _YourGroupsScreenState createState() => _YourGroupsScreenState();
}

class _YourGroupsScreenState extends State<YourGroupsScreen> {
  Future<String?> fetchGroupId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .where('sharedWith', arrayContains: user.uid)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchUserItems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('user_shopping_lists')
          .doc(user.uid)
          .get();
      final data = doc.data();
      if (data != null && data.containsKey('items')) {
        return List<Map<String, dynamic>>.from(data['items']);
      }
    }
    return [];
  }

  Map<String, dynamic> normalizeItem(Map<String, dynamic> item) {
    return {
      'name': item['name'] ?? 'Unknown',
      'quantity': item['quantity'] ?? 0,
      'price': item['price'] ?? 0.0,
      'unit': item['unit'] ?? 'pcs',
      'isChecked': item['isChecked'] ?? false,
      'category': item['category'] ?? 'General',
      'defaultUnit': item['defaultUnit'] ?? 'pcs',
      'selectedBy': item['selectedBy'] ?? FirebaseAuth.instance.currentUser?.email ?? 'unknown',
    };
  }

  Future<void> toggleItemStatus(Map<String, dynamic> item) async {
    final user = FirebaseAuth.instance.currentUser;
    final groupId = await fetchGroupId();

    if (user != null && groupId != null) {
      final userDocRef = FirebaseFirestore.instance
          .collection('user_shopping_lists')
          .doc(user.uid);
      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null && userData.containsKey('items')) {
          final userItems = List<Map<String, dynamic>>.from(userData['items']);
          final index = userItems.indexWhere(
                  (existingItem) => existingItem['name'] == item['name']);

          if (index != -1) {
            userItems[index]['isChecked'] = !(userItems[index]['isChecked'] ?? false);
            userItems[index] = normalizeItem(userItems[index]);
            await userDocRef.set({'items': userItems}, SetOptions(merge: true));

            if (userItems[index]['isChecked'] == true) {
              await FirebaseFirestore.instance.collection('expense_tracker').add({
                'category': item['name'],
                'amount': item['price'],
                'userId': user.uid,
                'groupId': groupId,
                'createdAt': FieldValue.serverTimestamp(),
              });
            } else {
              final query = await FirebaseFirestore.instance
                  .collection('expense_tracker')
                  .where('userId', isEqualTo: user.uid)
                  .where('category', isEqualTo: item['name'])
                  .where('groupId', isEqualTo: groupId)
                  .get();

              for (var doc in query.docs) {
                await doc.reference.delete();
              }
            }
          }
        }
      }
    }
    setState(() {});
  }

  Future<void> editItem(BuildContext context, Map<String, dynamic> item, int index) async {
    final TextEditingController quantityController =
    TextEditingController(text: item['quantity'].toString());
    final TextEditingController priceController =
    TextEditingController(text: item['price']?.toString() ?? '');
    String selectedUnit = item['unit'];

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit: ${item['name'] ?? 'Unknown'}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                ),
                TextFormField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price'),
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final updatedItem = normalizeItem({
                    'name': item['name'],
                    'quantity': int.tryParse(quantityController.text) ?? item['quantity'],
                    'price': double.tryParse(priceController.text) ?? item['price'],
                    'unit': selectedUnit,
                    'isChecked': item['isChecked'] ?? false,
                  });

                  final doc = await FirebaseFirestore.instance
                      .collection('user_shopping_lists')
                      .doc(user.uid)
                      .get();

                  if (doc.exists) {
                    final items = List<Map<String, dynamic>>.from(doc['items']);
                    items[index] = updatedItem;
                    await FirebaseFirestore.instance
                        .collection('user_shopping_lists')
                        .doc(user.uid)
                        .set({'items': items}, SetOptions(merge: true));
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

  Future<void> removeItem(Map<String, dynamic> item) async {
    final user = FirebaseAuth.instance.currentUser;
    final groupId = await fetchGroupId();

    if (user != null && groupId != null) {
      final userDocRef = FirebaseFirestore.instance
          .collection('user_shopping_lists')
          .doc(user.uid);
      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null && userData.containsKey('items')) {
          final userItems = List<Map<String, dynamic>>.from(userData['items']);
          userItems.removeWhere((existingItem) => existingItem['name'] == item['name']);
          await userDocRef.set({'items': userItems}, SetOptions(merge: true));

          final query = await FirebaseFirestore.instance
              .collection('expense_tracker')
              .where('userId', isEqualTo: user.uid)
              .where('category', isEqualTo: item['name'])
              .where('groupId', isEqualTo: groupId)
              .get();

          for (var doc in query.docs) {
            await doc.reference.delete();
          }
        }
      }

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aggregated Shopping List'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchUserItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No items in the consolidated list."));
          }

          final items = snapshot.data!;

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = normalizeItem(items[index]);
              final isChecked = item['isChecked'] ?? false;

              return ListTile(
                title: Text(item['name']),
                subtitle: Text(
                  'Quantity: ${item['quantity']} ${item['unit']}\nPrice: ${item['price'] ?? 'N/A'} Ft',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        isChecked ? Icons.shopping_cart : Icons.shopping_cart_outlined,
                        color: isChecked ? Colors.green : Colors.grey,
                      ),
                      onPressed: () async {
                        await toggleItemStatus(item);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        editItem(context, item, index);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await removeItem(item);
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
