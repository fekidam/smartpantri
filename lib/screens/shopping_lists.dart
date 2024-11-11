import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  void addItemToCart(Map<String, dynamic> item) {
    setState(() {
      cartItems.add({...item, 'quantity': 1, 'unit': selectedUnit});
    });
    saveCartItems();
  }

  void toggleItemSelection(Map<String, dynamic> item) {
    setState(() {
      if (selectedItems.contains(item)) {
        selectedItems.remove(item);
      } else {
        selectedItems.add(item);
      }
    });
    saveSelectedItems();
  }

  void editCartItem(int index, int newQuantity, String newUnit) {
    setState(() {
      cartItems[index]['quantity'] = newQuantity;
      cartItems[index]['unit'] = newUnit;
    });
    saveCartItems();
  }

  void removeCartItem(int index) {
    setState(() {
      cartItems.removeAt(index);
    });
    saveCartItems();
  }

  Future<void> saveCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final cartItemsJson = jsonEncode(cartItems);
    await prefs.setString('cartItems_${widget.groupId}', cartItemsJson);
  }

  Future<void> loadCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final cartItemsJson = prefs.getString('cartItems_${widget.groupId}');
    if (cartItemsJson != null) {
      setState(() {
        cartItems = List<Map<String, dynamic>>.from(jsonDecode(cartItemsJson));
      });
    }
  }

  Future<void> saveSelectedItems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docRef = FirebaseFirestore.instance.collection('user_shopping_lists').doc(user.uid);

      await docRef.set({
        'items': selectedItems.map((item) => {'name': item['name'], 'quantity': item['quantity'], 'unit': item['unit']}).toList()
      }, SetOptions(merge: true));
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

  Future<void> addCustomProduct(String name) async {
    final newItem = {'name': name, 'unit': selectedUnit};
    setState(() {
      availableProducts.add(newItem);
      addItemToCart(newItem);
    });
    await FirebaseFirestore.instance.collection('products').add(newItem);
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
          if (filteredProducts.isEmpty && searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  final newProductName = searchController.text.trim();
                  if (newProductName.isNotEmpty) {
                    addCustomProduct(newProductName);
                    searchController.clear();
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(100, 40),
                  textStyle: const TextStyle(fontSize: 14),
                ),
                child: const Text('Add New Item'),
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
                bool isSelected = selectedItems.contains(cartItem);

                return Dismissible(
                  key: Key(cartItem['name']),
                  onDismissed: (direction) {
                    removeCartItem(index);
                  },
                  background: Container(color: Colors.red),
                  child: ListTile(
                    title: Text(cartItem['name']),
                    subtitle: Text('Quantity: ${cartItem['quantity']} ${cartItem['unit']}'),
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: (bool? value) {
                        toggleItemSelection(cartItem);
                      },
                    ),
                    onTap: () {
                      _showEditDialog(index, cartItem);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(int index, Map<String, dynamic> cartItem) async {
    int quantity = cartItem['quantity'];
    String unit = cartItem['unit'];

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit ${cartItem['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: quantity.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity'),
                onChanged: (value) {
                  quantity = int.tryParse(value) ?? quantity;
                },
              ),
              DropdownButtonFormField<String>(
                value: unit,
                decoration: const InputDecoration(labelText: 'Unit'),
                items: units
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (value) {
                  unit = value ?? unit;
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
              onPressed: () {
                editCartItem(index, quantity, unit);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
