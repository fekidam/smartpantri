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
  bool hasAccess = false;

  bool _hasAccess(String groupId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    FirebaseFirestore.instance.collection('groups').doc(groupId).get().then((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          hasAccess = data['userId'] == user.uid || (data['sharedWith'] as List<dynamic>).contains(user.uid);
        });
      }
    });

    return hasAccess;
  }

  @override
  void initState() {
    super.initState();
    hasAccess = _hasAccess(widget.groupId);
  }

  void _addItem(String name, String quantity, String unit) async {
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('fridge_items')
        .add({
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'createdAt': FieldValue.serverTimestamp(),
    });
    setState(() {}); // Frissíti a képernyőt
  }

  void _editItem(BuildContext context, Map<String, dynamic> item, String docId) {
    final TextEditingController quantityController = TextEditingController(text: item['quantity']);
    String selectedUnit = item['unit'] ?? 'kg';

    showDialog(
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
              DropdownButtonFormField(
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('groups')
                    .doc(widget.groupId)
                    .collection('fridge_items')
                    .doc(docId)
                    .update({
                  'quantity': quantityController.text,
                  'unit': selectedUnit,
                });
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
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
          return SingleChildScrollView( // Görgethető tartalom
            child: Column(
              children: documents.map((doc) {
                var data = doc.data() as Map<String, dynamic>;
                return ListTile(
                  title: Text(data['name'] ?? 'No name'),
                  subtitle: Text('${data['quantity']} ${data['unit'] ?? ''}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!widget.isGuest)
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            _editItem(context, data, doc.id);
                          },
                        ),
                      if (!widget.isGuest)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('groups')
                                .doc(widget.groupId)
                                .collection('fridge_items')
                                .doc(doc.id)
                                .delete();
                          },
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
      floatingActionButton: widget.isGuest
          ? null
          : FloatingActionButton(
        onPressed: () {
          _showAddItemDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }


  void _showAddItemDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController quantityController = TextEditingController();
    String selectedUnit = 'kg';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Item Name'),
                ),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                ),
                DropdownButtonFormField(
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text;
                final quantity = quantityController.text;
                if (name.isNotEmpty && quantity.isNotEmpty) {
                  _addItem(name, quantity, selectedUnit);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

}
