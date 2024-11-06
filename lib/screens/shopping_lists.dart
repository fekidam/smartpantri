import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
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

  List<Map<String, dynamic>> availableProducts = [
    {'name': 'Apples'}, {'name': 'Bananas'}, {'name': 'Strawberries'},
    {'name': 'Avocados'}, {'name': 'Bell Peppers'}, {'name': 'Carrots'},
    {'name': 'Broccoli'}, {'name': 'Garlic'}, {'name': 'Lemons/Limes'},
    {'name': 'Onion'}, {'name': 'Parsley'}, {'name': 'Cilantro'},
    {'name': 'Basil'}, {'name': 'Potatoes'}, {'name': 'Spinach'},
    {'name': 'Tomatoes'}, {'name': 'Breadcrumbs'}, {'name': 'Pasta'},
    {'name': 'Quinoa'}, {'name': 'Rice'}, {'name': 'Sandwich Bread'},
    {'name': 'Tortillas'}, {'name': 'Chicken'}, {'name': 'Eggs'},
    {'name': 'Ground Beef'}, {'name': 'Sliced Turkey'}, {'name': 'Lunch Meat'},
    {'name': 'Butter'}, {'name': 'Sliced Cheese'}, {'name': 'Shredded Cheese'},
    {'name': 'Milk'}, {'name': 'Sour Cream'}, {'name': 'Greek Yogurt'},
  ];

  List<Map<String, dynamic>> cartItems = [];
  bool showSearchBar = false;

  @override
  void initState() {
    super.initState();
    loadCartItems(); // Betöltjük a mentett elemeket
  }

  void addItemToCart(Map<String, dynamic> item) {
    setState(() {
      cartItems.add({...item, 'quantity': 1, 'unit': selectedUnit});
    });
    saveCartItems(); // Mentjük az új bevásárlólistát
  }

  void editCartItem(int index, int newQuantity, String newUnit) {
    setState(() {
      cartItems[index]['quantity'] = newQuantity;
      cartItems[index]['unit'] = newUnit;
    });
    saveCartItems(); // Mentjük a módosított bevásárlólistát
  }

  void removeCartItem(int index) {
    setState(() {
      cartItems.removeAt(index);
    });
    saveCartItems(); // Mentjük a frissített bevásárlólistát
  }

  Future<void> saveCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final cartItemsJson = jsonEncode(cartItems);
    await prefs.setString('cartItems', cartItemsJson);
  }

  Future<void> loadCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final cartItemsJson = prefs.getString('cartItems');
    if (cartItemsJson != null) {
      setState(() {
        cartItems = List<Map<String, dynamic>>.from(jsonDecode(cartItemsJson));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              itemCount: availableProducts.length,
              itemBuilder: (context, index) {
                var product = availableProducts[index];
                if (searchController.text.isNotEmpty &&
                    !product['name']
                        .toLowerCase()
                        .startsWith(searchController.text.toLowerCase())) {
                  return Container(); // Csak azokat mutatja, amelyek az első betűre egyeznek
                }
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
                return Dismissible(
                  key: Key(cartItem['name']),
                  onDismissed: (direction) {
                    removeCartItem(index);
                  },
                  background: Container(color: Colors.red),
                  child: ListTile(
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
