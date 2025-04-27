import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class YourGroupsScreen extends StatefulWidget {
  final bool isGuest;

  const YourGroupsScreen({super.key, required this.isGuest});

  @override
  _YourGroupsScreenState createState() => _YourGroupsScreenState();
}

class _YourGroupsScreenState extends State<YourGroupsScreen> {
  List<Map<String, dynamic>> guestCartItems = [];

  @override
  void initState() {
    super.initState();
    if (widget.isGuest) {
      _loadGuestCart();
    }
  }

  Future<void> _loadGuestCart() async {
    final prefs = await SharedPreferences.getInstance();
    final guestCartString = prefs.getString('guestCartItems');
    if (guestCartString != null) {
      final List<dynamic> guestCartJson = jsonDecode(guestCartString);
      setState(() {
        guestCartItems = guestCartJson.map((item) => Map<String, dynamic>.from(item)).toList();
      });
    }
  }

  Future<void> _saveGuestCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('guestCartItems', jsonEncode(guestCartItems));
  }

  Future<List<String>> fetchGroupIds() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .where('sharedWith', arrayContains: user.uid)
          .get();

      return querySnapshot.docs.map((doc) => doc.id).toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchUserItems() async {
    if (widget.isGuest) {
      return guestCartItems;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final groupIds = await fetchGroupIds();
    List<Map<String, dynamic>> userSelectedItems = [];

    // Gyűjtsük össze az összes olyan elemet, amelyet a felhasználó kiválasztott
    for (String groupId in groupIds) {
      final groupDoc = await FirebaseFirestore.instance
          .collection('shopping_lists')
          .doc(groupId)
          .get();

      if (groupDoc.exists) {
        final data = groupDoc.data();
        if (data != null && data.containsKey('items')) {
          final items = List<Map<String, dynamic>>.from(data['items']);
          // Csak azokat az elemeket vesszük fel, amelyeket a felhasználó kiválasztott
          final selectedItems = items.where((item) {
            return item['isChecked'] == true &&
                item['selectedBy'] == user.email;
          }).toList();
          userSelectedItems.addAll(selectedItems);
        }
      }
    }

    // Mentsük a felhasználó kiválasztott elemeit a user_shopping_lists kollekcióba
    final userDocRef = FirebaseFirestore.instance
        .collection('user_shopping_lists')
        .doc(user.uid);
    await userDocRef.set({'items': userSelectedItems}, SetOptions(merge: true));

    return userSelectedItems;
  }

  // Helper method to convert hex string to Color
  Color _hexToColor(String hexColor) {
    try {
      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor'; // Add alpha channel if not present
      }
      return Color(int.parse('0x$hexColor'));
    } catch (e) {
      print('Error parsing color: $hexColor, defaulting to blue');
      return Colors.blue; // Fallback color in case of parsing error
    }
  }

  Future<Color> _getGroupColor() async {
    final groupIds = await fetchGroupIds();
    if (groupIds.isNotEmpty) {
      final groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupIds.first)
          .get();
      if (groupDoc.exists) {
        final groupData = groupDoc.data() as Map<String, dynamic>;
        return _hexToColor(groupData['color'] ?? '0000FF');
      }
    }
    return Colors.blue; // Fallback color
  }

  Map<String, dynamic> normalizeItem(Map<String, dynamic> item) {
    return {
      'id': item['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'name': item['name'] ?? 'Unknown',
      'quantity': item['quantity'] ?? 0,
      'price': item['price'] ?? 0.0,
      'unit': item['unit'] ?? 'pcs',
      'isChecked': item['isChecked'] ?? false,
      'isPurchased': item['isPurchased'] ?? false,
      'category': item['category'] ?? 'General',
      'defaultUnit': item['defaultUnit'] ?? 'pcs',
      'selectedBy': item['selectedBy'] ?? FirebaseAuth.instance.currentUser?.email ?? 'unknown',
    };
  }

  Future<void> toggleItemStatus(Map<String, dynamic> item) async {
    if (widget.isGuest) {
      setState(() {
        final index = guestCartItems.indexWhere((i) => i['id'] == item['id']);
        if (index != -1) {
          guestCartItems[index]['isPurchased'] = !(guestCartItems[index]['isPurchased'] ?? false);
        }
      });
      await _saveGuestCart();
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final groupId = (await fetchGroupIds()).isNotEmpty ? (await fetchGroupIds()).first : null;

    if (user != null && groupId != null) {
      final userDocRef = FirebaseFirestore.instance.collection('user_shopping_lists').doc(user.uid);
      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null && userData.containsKey('items')) {
          final userItems = List<Map<String, dynamic>>.from(userData['items']);
          final index = userItems.indexWhere((existingItem) => existingItem['id'] == item['id']);

          if (index != -1) {
            userItems[index]['isPurchased'] = !(userItems[index]['isPurchased'] ?? false);
            userItems[index] = normalizeItem(userItems[index]);
            await userDocRef.set({'items': userItems}, SetOptions(merge: true));

            final groupDocRef = FirebaseFirestore.instance.collection('shopping_lists').doc(groupId);
            final groupDoc = await groupDocRef.get();
            if (groupDoc.exists) {
              final groupData = groupDoc.data();
              if (groupData != null && groupData.containsKey('items')) {
                final groupItems = List<Map<String, dynamic>>.from(groupData['items']);
                final groupItemIndex = groupItems.indexWhere((existingItem) => existingItem['id'] == item['id']);
                if (groupItemIndex != -1) {
                  groupItems[groupItemIndex]['isPurchased'] = userItems[index]['isPurchased'];
                  await groupDocRef.set({'items': groupItems}, SetOptions(merge: true));
                }
              }
            }

            if (userItems[index]['isPurchased'] == true) {
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
                if (widget.isGuest) {
                  setState(() {
                    final updatedItem = normalizeItem({
                      'id': item['id'],
                      'name': item['name'],
                      'quantity': int.tryParse(quantityController.text) ?? item['quantity'],
                      'price': double.tryParse(priceController.text) ?? item['price'],
                      'unit': selectedUnit,
                      'isChecked': item['isChecked'] ?? false,
                      'isPurchased': item['isPurchased'] ?? false,
                    });
                    final cartIndex = guestCartItems.indexWhere((i) => i['id'] == item['id']);
                    if (cartIndex != -1) {
                      guestCartItems[cartIndex] = updatedItem;
                    }
                  });
                  await _saveGuestCart();
                } else {
                  final user = FirebaseAuth.instance.currentUser;
                  final groupId = (await fetchGroupIds()).isNotEmpty ? (await fetchGroupIds()).first : null;
                  if (user != null && groupId != null) {
                    final updatedItem = normalizeItem({
                      'id': item['id'],
                      'name': item['name'],
                      'quantity': int.tryParse(quantityController.text) ?? item['quantity'],
                      'price': double.tryParse(priceController.text) ?? item['price'],
                      'unit': selectedUnit,
                      'isChecked': item['isChecked'] ?? false,
                      'isPurchased': item['isPurchased'] ?? false,
                    });

                    final userDoc = await FirebaseFirestore.instance
                        .collection('user_shopping_lists')
                        .doc(user.uid)
                        .get();

                    if (userDoc.exists) {
                      final userItems = List<Map<String, dynamic>>.from(userDoc['items']);
                      userItems[index] = updatedItem;
                      await FirebaseFirestore.instance
                          .collection('user_shopping_lists')
                          .doc(user.uid)
                          .set({'items': userItems}, SetOptions(merge: true));
                    }

                    final groupDocRef = FirebaseFirestore.instance.collection('shopping_lists').doc(groupId);
                    final groupDoc = await groupDocRef.get();
                    if (groupDoc.exists) {
                      final groupData = groupDoc.data();
                      if (groupData != null && groupData.containsKey('items')) {
                        final groupItems = List<Map<String, dynamic>>.from(groupData['items']);
                        final groupItemIndex = groupItems.indexWhere((existingItem) => existingItem['id'] == item['id']);
                        if (groupItemIndex != -1) {
                          groupItems[groupItemIndex] = updatedItem;
                          await groupDocRef.set({'items': groupItems}, SetOptions(merge: true));
                        }
                      }
                    }

                    if (updatedItem['isPurchased'] == true) {
                      final query = await FirebaseFirestore.instance
                          .collection('expense_tracker')
                          .where('userId', isEqualTo: user.uid)
                          .where('category', isEqualTo: item['name'])
                          .where('groupId', isEqualTo: groupId)
                          .get();

                      for (var doc in query.docs) {
                        await doc.reference.update({
                          'amount': updatedItem['price'],
                        });
                      }
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

  Future<void> removeItem(Map<String, dynamic> item) async {
    if (widget.isGuest) {
      setState(() {
        guestCartItems.removeWhere((i) => i['id'] == item['id']);
      });
      await _saveGuestCart();
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final groupId = (await fetchGroupIds()).isNotEmpty ? (await fetchGroupIds()).first : null;

    if (user != null && groupId != null) {
      final userDocRef = FirebaseFirestore.instance.collection('user_shopping_lists').doc(user.uid);
      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null && userData.containsKey('items')) {
          final userItems = List<Map<String, dynamic>>.from(userData['items']);
          userItems.removeWhere((existingItem) => existingItem['id'] == item['id']);
          await userDocRef.set({'items': userItems}, SetOptions(merge: true));
        }
      }

      final groupDocRef = FirebaseFirestore.instance.collection('shopping_lists').doc(groupId);
      final groupDoc = await groupDocRef.get();

      if (groupDoc.exists) {
        final groupData = groupDoc.data();
        if (groupData != null && groupData.containsKey('items')) {
          final groupItems = List<Map<String, dynamic>>.from(groupData['items']);
          groupItems.removeWhere((groupItem) => groupItem['id'] == item['id']);
          await groupDocRef.set({'items': groupItems}, SetOptions(merge: true));
        }
      }
      if (item['isPurchased'] != true) {
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

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Color>(
      future: _getGroupColor(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final groupColor = snapshot.data ?? Colors.blue;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Aggregated Shopping List'),
            backgroundColor: groupColor, // Use group's color
            foregroundColor: Colors.white,
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
                  final isPurchased = item['isPurchased'] ?? false;

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
                            isPurchased ? Icons.check : Icons.check_box_outline_blank,
                            color: isPurchased ? Colors.green : Colors.grey,
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
      },
    );
  }
}