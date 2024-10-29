import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ShoppingListScreen extends StatefulWidget {
  final bool isGuest;

  const ShoppingListScreen({super.key, required this.isGuest});

  @override
  _ShoppingListScreenState createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> availableProducts = [
    {'name': 'Apples', 'image': 'assets/images/apple.png'},
    {'name': 'Bananas', 'image': 'assets/images/banana.png'},
    {'name': 'Carrots', 'image': 'assets/images/carrot.png'},
  ];
  List<Map<String, dynamic>> cartItems = [];
  bool showSearchBar = false;

  final List<String> units = ['kg', 'g', 'pcs', 'liters'];
  String selectedUnit = 'kg';

  void addItemToCart(Map<String, dynamic> item) {
    setState(() {
      cartItems.add({...item, 'quantity': 1, 'unit': selectedUnit});
    });
  }

  void editCartItem(int index, int newQuantity, String newUnit) {
    setState(() {
      cartItems[index]['quantity'] = newQuantity;
      cartItems[index]['unit'] = newUnit;
    });
  }

  void removeCartItem(int index) {
    setState(() {
      cartItems.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        actions: [
          IconButton(
            icon: Icon(showSearchBar ? Icons.close : Icons.add),
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
            child: ListView.builder(
              itemCount: availableProducts.length,
              itemBuilder: (context, index) {
                var product = availableProducts[index];
                if (searchController.text.isNotEmpty &&
                    !product['name']
                        .toLowerCase()
                        .contains(searchController.text.toLowerCase())) {
                  return Container();
                }
                return ListTile(
                  leading: Image.asset(product['image'], width: 50, height: 50),
                  title: Text(product['name']),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_shopping_cart),
                    onPressed: () {
                      addItemToCart(product);
                    },
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
                return Dismissible(
                  key: Key(cartItem['name']),
                  onDismissed: (direction) {
                    removeCartItem(index);
                  },
                  background: Container(color: Colors.red),
                  child: ListTile(
                    leading: Image.asset(cartItem['image'], width: 50, height: 50),
                    title: Text(cartItem['name']),
                    subtitle: Text(
                        'Quantity: ${cartItem['quantity']} ${cartItem['unit']}'),
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
