import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartpantri/generated/l10n.dart'; // AppLocalizations import
import '../services/theme_provider.dart';
import '../services/language_provider.dart';

// Product osztály definiálása
class Product {
  final String id;
  final String name;
  final String category;
  final String defaultUnit;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.defaultUnit,
  });
}

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
  List<Product> products = []; // A Product osztály használata
  List<Map<String, dynamic>> availableProducts = [];
  List<Map<String, dynamic>> cartItems = [];
  List<Map<String, dynamic>> selectedItems = [];
  bool showSearchBar = false;
  final int guestCartLimit = 3;
  bool _isInitialized = false; // Flag az inicializálás nyomon követésére

  static List<Map<String, dynamic>> guestCartItems = [];

  @override
  void initState() {
    super.initState();
    if (widget.isGuest) {
      _loadGuestCart();
    }
    loadCartItems();
    if (!widget.isGuest) {
      loadSelectedItems();
    }
    // Nyelvváltás figyelése
    Provider.of<LanguageProvider>(context, listen: false).addListener(_onLanguageChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Csak akkor inicializálunk, ha még nem történt meg, vagy ha a lokalizáció változik
    if (!_isInitialized) {
      fetchProductsFromFirestore();
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    // Listener eltávolítása
    Provider.of<LanguageProvider>(context, listen: false).removeListener(_onLanguageChanged);
    super.dispose();
  }

  // Nyelvváltás kezelése
  void _onLanguageChanged() {
    fetchProductsFromFirestore();
    loadCartItems();
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
    final locale = Localizations.localeOf(context);
    final isHungarian = locale.languageCode == 'hu';

    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .where(isHungarian ? 'name.hu' : 'name.en', isNotEqualTo: '')
        .get();

    setState(() {
      products = snapshot.docs.map((doc) {
        final data = doc.data();

        // Ellenőrizzük, hogy a 'name' mező Map-e, ha nem, alapértelmezett értéket adunk
        final nameMap = data['name'] is Map<String, dynamic>
            ? data['name'] as Map<String, dynamic>
            : {'en': data['name']?.toString() ?? 'Unknown', 'hu': data['name']?.toString() ?? 'Ismeretlen'};

        // Ellenőrizzük, hogy a 'category' mező Map-e, ha nem, alapértelmezett értéket adunk
        final categoryMap = data['category'] is Map<String, dynamic>
            ? data['category'] as Map<String, dynamic>
            : {'en': data['category']?.toString() ?? 'Unknown', 'hu': data['category']?.toString() ?? 'Ismeretlen'};

        // Ellenőrizzük, hogy a 'defaultUnit' mező Map-e, ha nem, alapértelmezett értéket adunk
        final defaultUnitMap = data['defaultUnit'] is Map<String, dynamic>
            ? data['defaultUnit'] as Map<String, dynamic>
            : {'en': data['defaultUnit']?.toString() ?? 'kg', 'hu': data['defaultUnit']?.toString() ?? 'kg'};

        return Product(
          id: doc.id,
          name: isHungarian ? nameMap['hu'] ?? 'Ismeretlen' : nameMap['en'] ?? 'Unknown',
          category: isHungarian ? categoryMap['hu'] ?? 'Ismeretlen' : categoryMap['en'] ?? 'Unknown',
          defaultUnit: defaultUnitMap['en'] ?? 'kg',
        );
      }).toList();

      // availableProducts feltöltése az eredeti Firestore struktúrával
      availableProducts = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] is Map<String, dynamic>
              ? data['name']
              : {'en': data['name']?.toString() ?? 'Unknown', 'hu': data['name']?.toString() ?? 'Ismeretlen'},
          'category': data['category'] is Map<String, dynamic>
              ? data['category']
              : {'en': data['category']?.toString() ?? 'Unknown', 'hu': data['category']?.toString() ?? 'Ismeretlen'},
          'defaultUnit': data['defaultUnit'] is Map<String, dynamic>
              ? data['defaultUnit']
              : {'en': data['defaultUnit']?.toString() ?? 'kg', 'hu': data['defaultUnit']?.toString() ?? 'kg'},
        };
      }).toList();
    });
  }

  Future<void> addNewProduct() async {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final isHungarian = locale.languageCode == 'hu';

    final TextEditingController nameEnController = TextEditingController();
    final TextEditingController nameHuController = TextEditingController();
    final TextEditingController categoryEnController = TextEditingController();
    final TextEditingController categoryHuController = TextEditingController();
    String selectedDefaultUnit = 'kg';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.addNewProduct),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameHuController,
                  decoration: InputDecoration(labelText: l10n.nameLabelHu),
                ),
                TextFormField(
                  controller: nameEnController,
                  decoration: InputDecoration(labelText: l10n.nameLabelEn),
                ),
                TextFormField(
                  controller: categoryHuController,
                  decoration: InputDecoration(labelText: l10n.categoryLabelHu),
                ),
                TextFormField(
                  controller: categoryEnController,
                  decoration: InputDecoration(labelText: l10n.categoryLabelEn),
                ),
                DropdownButtonFormField<String>(
                  value: selectedDefaultUnit,
                  decoration: InputDecoration(labelText: l10n.unitLabel),
                  items: units.map((unit) {
                    final translatedUnit = unit == 'kg'
                        ? l10n.unitKg
                        : unit == 'g'
                        ? l10n.unitG
                        : unit == 'pcs'
                        ? l10n.unitPcs
                        : unit == 'liters'
                        ? l10n.unitLiters
                        : unit;
                    return DropdownMenuItem(value: unit, child: Text(translatedUnit));
                  }).toList(),
                  onChanged: (value) {
                    selectedDefaultUnit = value!;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                // Ellenőrizzük a mezőket a nyelvi beállítás alapján
                bool isValid = true;
                String errorMessage = '';

                // Legalább az egyik nyelvi mező kitöltött kell legyen (Firestore szabály miatt)
                if (nameHuController.text.isEmpty && nameEnController.text.isEmpty) {
                  isValid = false;
                  errorMessage = l10n.fillAtLeastOneName;
                } else if (categoryHuController.text.isEmpty && categoryEnController.text.isEmpty) {
                  isValid = false;
                  errorMessage = l10n.fillAtLeastOneCategory;
                } else {
                  // Ha magyar nyelv van, a magyar mezők kötelezőek
                  if (isHungarian) {
                    if (nameHuController.text.isEmpty) {
                      isValid = false;
                      errorMessage = l10n.fillHungarianName;
                    }
                    if (categoryHuController.text.isEmpty) {
                      isValid = false;
                      errorMessage = errorMessage.isEmpty ? l10n.fillHungarianCategory : '$errorMessage\n${l10n.fillHungarianCategory}';
                    }
                  }
                  // Ha angol nyelv van, az angol mezők kötelezőek
                  else {
                    if (nameEnController.text.isEmpty) {
                      isValid = false;
                      errorMessage = l10n.fillEnglishName;
                    }
                    if (categoryEnController.text.isEmpty) {
                      isValid = false;
                      errorMessage = errorMessage.isEmpty ? l10n.fillEnglishCategory : '$errorMessage\n${l10n.fillEnglishCategory}';
                    }
                  }
                }

                if (!isValid) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errorMessage)),
                  );
                  return;
                }

                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.userNotLoggedIn)),
                  );
                  return;
                }

                final newProduct = {
                  'name': {
                    'en': nameEnController.text.isNotEmpty ? nameEnController.text : '', // Üres string, ha nincs kitöltve
                    'hu': nameHuController.text.isNotEmpty ? nameHuController.text : '',
                  },
                  'category': {
                    'en': categoryEnController.text.isNotEmpty ? categoryEnController.text : '',
                    'hu': categoryHuController.text.isNotEmpty ? categoryHuController.text : '',
                  },
                  'defaultUnit': {
                    'en': selectedDefaultUnit,
                    'hu': selectedDefaultUnit,
                  },
                  'createdBy': user.uid,
                };

                await FirebaseFirestore.instance.collection('products').add(newProduct);
                Navigator.of(context).pop();
                await fetchProductsFromFirestore();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.productAdded)),
                );
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
  }

  void addItemToCart(Map<String, dynamic> item) async {
    final l10n = AppLocalizations.of(context)!;
    if (widget.isGuest) {
      if (cartItems.length >= guestCartLimit) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.guestCartLimitMessage(guestCartLimit)),
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
    final l10n = AppLocalizations.of(context)!;
    if (user == null) return;

    if (item['isChecked'] == true && item['selectedBy'] != user.email) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.itemAlreadySelectedBy(item['selectedBy'])),
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
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context).languageCode;
    final itemName = item['name'] is Map<String, dynamic>
        ? item['name'][currentLocale] ?? item['name']['en']
        : item['name'];

    if (widget.isGuest) {
      if (addedBy != 'guest') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.onlyDeleteOwnItems),
          ),
        );
        return;
      }
    } else {
      if (user == null || addedBy != user.email) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.onlyDeleteOwnItems),
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.itemRemoved(itemName))),
    );
  }

  Future<void> editCartItem(BuildContext context, Map<String, dynamic> item) async {
    final user = FirebaseAuth.instance.currentUser;
    final String? addedBy = item['addedBy'] ?? 'unknown';
    final l10n = AppLocalizations.of(context)!;

    if (widget.isGuest) {
      if (addedBy != 'guest') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.onlyEditOwnItems),
          ),
        );
        return;
      }
    } else {
      if (user == null || addedBy != user.email) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.onlyEditOwnItems),
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
        final l10n = AppLocalizations.of(context)!;
        final currentLocale = Localizations.localeOf(context).languageCode;
        final itemName = item['name'] is Map<String, dynamic>
            ? item['name'][currentLocale] ?? item['name']['en']
            : item['name'];

        return AlertDialog(
          title: Text(l10n.editItem(itemName)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.quantityLabel),
              ),
              DropdownButtonFormField<String>(
                value: selectedUnit,
                decoration: InputDecoration(labelText: l10n.unitLabel),
                items: units.map((unit) {
                  final translatedUnit = unit == 'kg'
                      ? l10n.unitKg
                      : unit == 'g'
                      ? l10n.unitG
                      : unit == 'pcs'
                      ? l10n.unitPcs
                      : unit == 'liters'
                      ? l10n.unitLiters
                      : unit;
                  return DropdownMenuItem(value: unit, child: Text(translatedUnit));
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
              child: Text(l10n.cancel),
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
                      if (userData != null && userData.containsKey('items')) { // Fixed: Changed 'data' to 'userData'
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
              child: Text(l10n.save),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context).languageCode;

    final filteredProducts = availableProducts.where((product) {
      final productName = product['name'] is Map<String, dynamic>
          ? product['name'][currentLocale] ?? ''
          : product['name'];
      return productName.isNotEmpty &&
          (searchController.text.isEmpty ||
              productName.toLowerCase().startsWith(searchController.text.toLowerCase()));
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.shoppingList),
        backgroundColor: themeProvider.primaryColor,
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
                  hintText: l10n.searchForProducts,
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
            child: filteredProducts.isEmpty
                ? Center(
              child: Text(
                currentLocale == 'hu'
                    ? "Nincsenek magyar nyelven elérhető termékek."
                    : "No products available in English.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : GridView.builder(
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
                final productName = product['name'] is Map<String, dynamic>
                    ? product['name'][currentLocale] ?? ''
                    : product['name'];
                return GestureDetector(
                  onTap: () => addItemToCart(product),
                  child: Card(
                    color: Colors.lightBlueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Center(
                      child: Text(
                        productName,
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
          Text(
            l10n.shoppingCart,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: cartItems.isEmpty
                ? Center(
              child: Text(
                l10n.noItemsInConsolidatedList,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                var cartItem = cartItems[index];
                final cartItemName = cartItem['name'] is Map<String, dynamic>
                    ? cartItem['name'][currentLocale] ?? cartItem['name']['en'] ?? l10n.unknownItem
                    : cartItem['name'];
                final cartItemUnit = cartItem['unit'];
                final translatedUnit = cartItemUnit == 'kg'
                    ? l10n.unitKg
                    : cartItemUnit == 'g'
                    ? l10n.unitG
                    : cartItemUnit == 'pcs'
                    ? l10n.unitPcs
                    : cartItemUnit == 'liters'
                    ? l10n.unitLiters
                    : cartItemUnit;
                bool isSelected = cartItem['isChecked'] ?? false;
                String? selectedBy = cartItem['selectedBy'];
                final user = FirebaseAuth.instance.currentUser;
                final String? addedBy = cartItem['addedBy'];

                bool isEditable = !isSelected || (selectedBy == user?.email);
                bool canEditItem =
                widget.isGuest ? (addedBy == 'guest') : (user != null && addedBy == user?.email);

                return widget.isGuest
                    ? ListTile(
                  title: Text(cartItemName),
                  subtitle: Text(
                    '${l10n.quantityLabel}: ${cartItem['quantity']} $translatedUnit${isSelected && selectedBy != null ? '\n${l10n.selectedBy(selectedBy)}' : ''}',
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
                  },
                  background: Container(color: Colors.red),
                  child: ListTile(
                    title: Text(cartItemName),
                    subtitle: Text(
                      '${l10n.quantityLabel}: ${cartItem['quantity']} $translatedUnit${isSelected && selectedBy != null ? '\n${l10n.selectedBy(selectedBy)}' : ''}',
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
                  title: Text(cartItemName),
                  subtitle: Text(
                    '${l10n.quantityLabel}: ${cartItem['quantity']} $translatedUnit${isSelected && selectedBy != null ? '\n${l10n.selectedBy(selectedBy)}' : ''}',
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
      floatingActionButton: !widget.isGuest
          ? FloatingActionButton(
        onPressed: addNewProduct,
        child: const Icon(Icons.add),
        tooltip: l10n.addNewProduct,
      )
          : null,
    );
  }
}