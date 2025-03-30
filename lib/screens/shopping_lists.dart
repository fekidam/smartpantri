import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShoppingListScreen extends StatefulWidget {
  final bool isGuest;
  final String groupId;

  const ShoppingListScreen({super.key, required this.isGuest, required this.groupId});

  @override
  _ShoppingListScreenState createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final TextEditingController searchController = TextEditingController();
  final List<String> units = ['kg', 'g', 'pcs', 'liters'];
  String selectedUnit = 'kg';
  List<Map<String, dynamic>> availableProducts = [];
  List<Map<String, dynamic>> cartItems = [];
  List<Map<String, dynamic>> selectedItems = [];
  bool showSearchBar = false;

  @override
  void initState() {
    super.initState();
    loadCartItems();
    fetchProductsFromFirestore();
    loadSelectedItems();
  }

  Future<void> fetchProductsFromFirestore() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('products').get();
    final List<Map<String, dynamic>> products = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

    setState(() {
      availableProducts = products;
    });
  }

  void addItemToCart(Map<String, dynamic> item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final String itemId = DateTime.now().millisecondsSinceEpoch.toString();
      final cartItem = {
        ...item,
        'id': itemId,
        'quantity': 1,
        'unit': selectedUnit,
        'isChecked': false,
      };
      setState(() {
        cartItems.add(cartItem);
      });

      final groupRef = FirebaseFirestore.instance.collection('shopping_lists').doc(widget.groupId);
      final groupDoc = await groupRef.get();

      if (groupDoc.exists) {
        final data = groupDoc.data();
        if (data != null && data.containsKey('items')) {
          final items = List<Map<String, dynamic>>.from(data['items']);
          items.add(cartItem);
          await groupRef.set({'items': items}, SetOptions(merge: true));
        }
      } else {
        await groupRef.set({
          'items': [cartItem]
        });
      }
    }
  }

  void toggleItemSelection(Map<String, dynamic> item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final groupDocRef = FirebaseFirestore.instance.collection('shopping_lists').doc(widget.groupId);
      final userDocRef = FirebaseFirestore.instance.collection('user_shopping_lists').doc(user.uid);

      setState(() {
        if (item['isChecked'] == true) {
          item['isChecked'] = false;
          item.remove('selectedBy');
          selectedItems.removeWhere((selectedItem) => selectedItem['id'] == item['id']);
        } else {
          item['isChecked'] = true;
          item['selectedBy'] = user.email;
          selectedItems.add(item);
        }
      });

      final groupDoc = await groupDocRef.get();
      if (groupDoc.exists) {
        final data = groupDoc.data();
        if (data != null && data.containsKey('items')) {
          final items = List<Map<String, dynamic>>.from(data['items']);
          final itemIndex = items.indexWhere((existingItem) => existingItem['id'] == item['id']);

          if (itemIndex != -1) {
            items[itemIndex] = item;
          } else {
            items.add(item);
          }

          await groupDocRef.set({'items': items}, SetOptions(merge: true));
        }
      }

      final userDoc = await userDocRef.get();
      if (item['isChecked'] == true) {
        if (userDoc.exists) {
          final data = userDoc.data();
          if (data != null && data.containsKey('items')) {
            final userItems = List<Map<String, dynamic>>.from(data['items']);
            final userItemIndex = userItems.indexWhere((existingItem) => existingItem['id'] == item['id']);

            if (userItemIndex != -1) {
              userItems[userItemIndex] = item;
            } else {
              userItems.add(item);
            }

            await userDocRef.set({'items': userItems}, SetOptions(merge: true));
          }
        } else {
          await userDocRef.set({
            'items': [item]
          });
        }
      } else {
        if (userDoc.exists) {
          final data = userDoc.data();
          if (data != null && data.containsKey('items')) {
            final userItems = List<Map<String, dynamic>>.from(data['items']);
            userItems.removeWhere((existingItem) => existingItem['id'] == item['id']);
            await userDocRef.set({'items': userItems}, SetOptions(merge: true));
          }
        }
      }
    }
  }

  Future<void> removeItem(Map<String, dynamic> item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
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

      final groupDocRef = FirebaseFirestore.instance.collection('shopping_lists').doc(widget.groupId);
      final groupDoc = await groupDocRef.get();

      if (groupDoc.exists) {
        final groupData = groupDoc.data();
        if (groupData != null && groupData.containsKey('items')) {
          final groupItems = List<Map<String, dynamic>>.from(groupData['items']);
          groupItems.removeWhere((groupItem) => groupItem['id'] == item['id']);
          await groupDocRef.set({'items': groupItems}, SetOptions(merge: true));
        }
      }

      setState(() {
        cartItems.removeWhere((cartItem) => cartItem['id'] == item['id']);
        selectedItems.removeWhere((selectedItem) => selectedItem['id'] == item['id']);
      });
    }
  }

  Future<void> editCartItem(BuildContext context, Map<String, dynamic> item) async {
    final TextEditingController quantityController = TextEditingController(text: item['quantity'].toString());
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
                items: units.map((unit) {
                  return DropdownMenuItem(value: unit, child: Text(unit));
                }).toList(),
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
                  final updatedItem = {
                    ...item,
                    'quantity': int.parse(quantityController.text),
                    'unit': selectedUnit,
                  };

                  setState(() {
                    final cartIndex = cartItems.indexWhere((cartItem) => cartItem['id'] == item['id']);
                    if (cartIndex != -1) {
                      cartItems[cartIndex] = updatedItem;
                    }
                  });

                  final groupDocRef =
                  FirebaseFirestore.instance.collection('shopping_lists').doc(widget.groupId);
                  final groupDoc = await groupDocRef.get();
                  if (groupDoc.exists) {
                    final data = groupDoc.data();
                    if (data != null && data.containsKey('items')) {
                      final items = List<Map<String, dynamic>>.from(data['items']);
                      final itemIndex = items.indexWhere((existingItem) => existingItem['id'] == item['id']);
                      if (itemIndex != -1) {
                        items[itemIndex] = updatedItem;
                      }
                      await groupDocRef.set({'items': items}, SetOptions(merge: true));
                    }
                  }

                  final userDocRef = FirebaseFirestore.instance.collection('user_shopping_lists').doc(user.uid);
                  final userDoc = await userDocRef.get();
                  if (userDoc.exists) {
                    final userData = userDoc.data();
                    if (userData != null && userData.containsKey('items')) {
                      final userItems = List<Map<String, dynamic>>.from(userData['items']);
                      final userItemIndex =
                      userItems.indexWhere((existingItem) => existingItem['id'] == item['id']);
                      if (userItemIndex != -1) {
                        userItems[userItemIndex] = updatedItem;
                      }
                      await userDocRef.set({'items': userItems}, SetOptions(merge: true));
                    }
                  }
                }

                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> loadCartItems() async {
    final docRef = FirebaseFirestore.instance.collection('shopping_lists').doc(widget.groupId);
    final doc = await docRef.get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null && data.containsKey('items')) {
        setState(() {
          cartItems = List<Map<String, dynamic>>.from(data['items']);
          selectedItems = cartItems.where((item) => item['isChecked'] == true).toList();
        });
      }
    }
  }

  Future<void> loadSelectedItems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docRef = await FirebaseFirestore.instance.collection('user_shopping_lists').doc(user.uid).get();
      final data = docRef.data();
      if (data != null && data.containsKey('items')) {
        setState(() {
          selectedItems = List<Map<String, dynamic>>.from(data['items']);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = availableProducts.where((product) {
      return searchController.text.isEmpty ||
          product['name'].toLowerCase().startsWith(searchController.text.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        actions: [
          IconButton(
            icon: Icon(showSearchBar ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                showSearchBar = !showSearchBar;
                searchController.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (showSearchBar)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search for products',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                var product = filteredProducts[index];
                return GestureDetector(
                  onTap: () => addItemToCart(product),
                  child: Card(
                    color: Colors.lightBlueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Center(
                      child: Text(
                        product['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          const Text(
            'Shopping Cart',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                var cartItem = cartItems[index];
                bool isSelected = cartItem['isChecked'] ?? false;
                String? selectedBy = cartItem['selectedBy'];

                return Dismissible(
                  key: Key(cartItem['id'].toString()),
                  onDismissed: (direction) {
                    setState(() {
                      cartItems.removeAt(index);
                    });
                    removeItem(cartItem);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${cartItem['name']} removed')),
                    );
                  },
                  background: Container(color: Colors.red),
                  child: ListTile(
                    title: Text(cartItem['name']),
                    subtitle: Text(
                      'Quantity: ${cartItem['quantity']} ${cartItem['unit']}'
                          '${isSelected && selectedBy != null ? '\nSelected by: $selectedBy' : ''}',
                    ),
                    onTap: () => editCartItem(context, cartItem),
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: (bool? value) {
                        toggleItemSelection(cartItem);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}