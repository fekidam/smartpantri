import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Új elem hozzáadására szolgáló képernyő (pl. bevásárlólista vagy költségkövetés)
class AddItemScreen extends StatelessWidget {
  final String collectionName; // pl. "shopping_list" vagy "expense_tracker"
  final String groupId; // Az aktuális csoport azonosítója

  const AddItemScreen({
    super.key,
    required this.collectionName,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    // Vezérlők az űrlap mezőkhöz
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
            // Első szövegmező: elem neve vagy kategória
            TextField(
              controller: itemController,
              decoration: InputDecoration(
                hintText: collectionName == 'expense_tracker' ? 'Category' : 'Item Name',
              ),
            ),
            const SizedBox(height: 20),

            // Második szövegmező: mennyiség vagy összeg
            TextField(
              controller: quantityController,
              decoration: InputDecoration(
                hintText: collectionName == 'expense_tracker' ? 'Amount' : 'Quantity',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),

            // Hozzáadás gomb
            ElevatedButton(
              onPressed: () async {
                // Csak akkor menti el, ha mindkét mező ki van töltve
                if (itemController.text.isNotEmpty && quantityController.text.isNotEmpty) {
                  Map<String, dynamic> data = {};

                  // Különböző mezők expense trackerhez vagy más gyűjteményhez
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

                  // Adat hozzáadása Firestore-hoz
                  await FirebaseFirestore.instance
                      .collection('groups')
                      .doc(groupId)
                      .collection(collectionName)
                      .add(data);

                  // Visszatérés az előző képernyőre
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
