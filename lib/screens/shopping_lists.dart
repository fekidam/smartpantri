import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final int guestCartLimit = 3;

  static List<Map<String, dynamic>> guestCartItems = [];

  @override
  void initState() {
    super.initState();
    if (widget.isGuest) {
      _loadGuestCart();
    }
    loadCartItems();
    fetchProductsFromFirestore();
    if (!widget.isGuest) {
      loadSelectedItems();
    }
  }

  Future<void> _loadGuestCart() async {
    final prefs = await SharedPreferences.getInstance();
    final guestCartString = prefs.getString('guestCartItems');
    if (guestCartString != null) {
      final List<dynamic> guestCartJson = jsonDecode(guestCartString);
      setState(() {
        guestCartItems = guestCartJson.map((item) => Map<String, dynamic>.from(item)).toList();
        cartItems = List.from(guestCartItems);
      });
    }
  }

  Future<void> _saveGuestCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('guestCartItems', jsonEncode(guestCartItems));
  }

  Future<void> fetchProductsFromFirestore() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('products').get();
    final List<Map<String, dynamic>> products = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

    setState(() {
      availableProducts = products;
    });
  }

  void addItemToCart(Map<String, dynamic> item) async {
    if (widget.isGuest) {
      if (cartItems.length >= guestCartLimit) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Guest users can only add up to $guestCartLimit items. Please log in to add more.'),
          ),
        );
        return;
      }

      final String itemId = DateTime.now().millisecondsSinceEpoch.toString();
      final cartItem = {
        ...item,
        'id': itemId,
        'quantity': 1,
        'unit': selectedUnit,
        'isChecked': false,
        'addedBy': 'guest',
      };
      setState(() {
        cartItems.add(cartItem);
        guestCartItems = List.from(cartItems);
      });
      await _saveGuestCart();
    } else {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final String itemId = DateTime.now().millisecondsSinceEpoch.toString();
        final cartItem = {
          ...item,
          'id': itemId,
          'quantity': 1,
          'unit': selectedUnit,
          'isChecked': false,
          'addedBy': user.email,
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
  }

  void toggleItemSelection(Map<String, dynamic> item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (item['isChecked'] == true && item['selectedBy'] != user.email) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('This item is already selected by ${item['selectedBy']}.'),
        ),
      );
      return;
    }

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

  Future<void> removeItem(Map<String, dynamic> item) async {
    final user = FirebaseAuth.instance.currentUser;
    final String? addedBy = item['addedBy'] ?? 'unknown';

    if (widget.isGuest) {
      if (addedBy != 'guest') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You can only delete items you added.'),
          ),
        );
        return;
      }
    } else {
      if (user == null || addedBy != user.email) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You can only delete items you added.'),
          ),
        );
        return;
      }
    }

    if (widget.isGuest) {
      setState(() {
        cartItems.removeWhere((cartItem) => cartItem['id'] == item['id']);
        selectedItems.removeWhere((selectedItem) => selectedItem['id'] == item['id']);
        guestCartItems = List.from(cartItems);
      });
      await _saveGuestCart();
    } else {
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
  }

  Future<void> editCartItem(BuildContext context, Map<String, dynamic> item) async {
    final user = FirebaseAuth.instance.currentUser;
    final String? addedBy = item['addedBy'] ?? 'unknown';

    if (widget.isGuest) {
      if (addedBy != 'guest') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You can only edit items you added.'),
          ),
        );
        return;
      }
    } else {
      if (user == null || addedBy != user.email) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You can only edit items you added.'),
          ),
        );
        return;
      }
    }

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
                if (widget.isGuest) {
                  setState(() {
                    final cartIndex = cartItems.indexWhere((cartItem) => cartItem['id'] == item['id']);
                    if (cartIndex != -1) {
                      cartItems[cartIndex] = {
                        ...item,
                        'quantity': int.parse(quantityController.text),
                        'unit': selectedUnit,
                      };
                      guestCartItems = List.from(cartItems);
                    }
                  });
                  await _saveGuestCart();
                } else {
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
    if (widget.isGuest) {
      await _loadGuestCart();
      setState(() {
        cartItems = List.from(guestCartItems);
      });
      return;
    }

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
          if (!widget.isGuest)
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
          if (showSearchBar && !widget.isGuest)
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
                final user = FirebaseAuth.instance.currentUser;
                final String? addedBy = cartItem['addedBy'];

                bool isEditable = !isSelected || (selectedBy == user?.email);
                bool canEditItem = widget.isGuest ? (addedBy == 'guest') : (user != null && addedBy == user?.email);

                return widget.isGuest
                    ? ListTile(
                  title: Text(cartItem['name']),
                  subtitle: Text(
                    'Quantity: ${cartItem['quantity']} ${cartItem['unit']}' '${isSelected && selectedBy != null ? '\nSelected by: $selectedBy' : ''}',
                  ),
                  trailing: canEditItem
                      ? IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => editCartItem(context, cartItem),
                  )
                      : null,
                )
                    : canEditItem
                    ? Dismissible(
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
                      'Quantity: ${cartItem['quantity']} ${cartItem['unit']}' '${isSelected && selectedBy != null ? '\nSelected by: $selectedBy' : ''}',
                    ),
                    onTap: canEditItem ? () => editCartItem(context, cartItem) : null,
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: isEditable
                          ? (bool? value) {
                        toggleItemSelection(cartItem);
                      }
                          : null,
                    ),
                  ),
                )
                    : ListTile(
                  title: Text(cartItem['name']),
                  subtitle: Text(
                    'Quantity: ${cartItem['quantity']} ${cartItem['unit']}' '${isSelected && selectedBy != null ? '\nSelected by: $selectedBy' : ''}',
                  ),
                  onTap: canEditItem ? () => editCartItem(context, cartItem) : null,
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: isEditable
                        ? (bool? value) {
                      toggleItemSelection(cartItem);
                    }
                        : null,
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