import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddItemScreen extends StatelessWidget {
  final String collectionName;
  final String groupId;

  const AddItemScreen({
    super.key,
    required this.collectionName,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    TextEditingController itemController = TextEditingController();
    TextEditingController quantityController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            TextField(
              controller: itemController,
              decoration: InputDecoration(
                hintText: collectionName == 'expense_tracker' ? 'Category' : 'Item Name',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: quantityController,
              decoration: InputDecoration(
                hintText: collectionName == 'expense_tracker' ? 'Amount' : 'Quantity',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (itemController.text.isNotEmpty && quantityController.text.isNotEmpty) {
                  Map<String, dynamic> data = {};
                  if (collectionName == 'expense_tracker') {
                    data = {
                      'category': itemController.text,
                      'amount': int.parse(quantityController.text),
                    };
                  } else {
                    data = {
                      'name': itemController.text,
                      'quantity': quantityController.text,
                    };
                  }
                  await FirebaseFirestore.instance
                      .collection('groups')
                      .doc(groupId)
                      .collection(collectionName)
                      .add(data);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
