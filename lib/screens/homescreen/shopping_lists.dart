import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartpantri/generated/l10n.dart';
import '../../Providers/theme_provider.dart';
import '../../Providers/language_provider.dart';

// Product model
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
  final Color groupColor; // Új paraméter a csoport színének

  const ShoppingListScreen({
    Key? key,
    required this.isGuest,
    required this.groupId,
    required this.groupColor, // Kötelező paraméter
  }) : super(key: key);

  @override
  _ShoppingListScreenState createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final TextEditingController searchController = TextEditingController();
  final List<String> units = ['kg', 'g', 'pcs', 'liters'];
  List<Product> products = [];
  List<Map<String, dynamic>> availableProducts = [];
  List<Map<String, dynamic>> cartItems = [];
  List<Map<String, dynamic>> selectedItems = [];
  bool showSearchBar = false;
  final int guestCartLimit = 3;
  bool _initialized = false;
  late LanguageProvider _languageProvider;
  static List<Map<String, dynamic>> guestCartItems = [];

  @override
  void initState() {
    super.initState();
    if (widget.isGuest) _loadGuestCart();
    _loadCartItems();
    if (!widget.isGuest) _loadSelectedItems();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _languageProvider =
          Provider.of<LanguageProvider>(context, listen: false);
      _languageProvider.addListener(_onLanguageChange);
      _fetchProducts();
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _languageProvider.removeListener(_onLanguageChange);
    super.dispose();
  }

  void _onLanguageChange() {
    _fetchProducts();
    _loadCartItems();
    if (!widget.isGuest) _loadSelectedItems();
  }

  Future<void> _fetchProducts() async {
    final localeCode = Localizations.localeOf(context).languageCode;
    final isHu = localeCode == 'hu';
    final snap = await FirebaseFirestore.instance
        .collection('products')
        .where(isHu ? 'name.hu' : 'name.en', isNotEqualTo: '')
        .get();

    final fetched = <Product>[];
    final avail = <Map<String, dynamic>>[];

    for (var doc in snap.docs) {
      final d = doc.data();
      // name
      Map<String, dynamic> nameMap;
      if (d['name'] is Map) {
        nameMap = Map<String, dynamic>.from(d['name']);
      } else {
        final raw = d['name']?.toString() ?? '';
        nameMap = {'en': raw, 'hu': raw};
      }
      // category
      Map<String, dynamic> catMap;
      if (d['category'] is Map) {
        catMap = Map<String, dynamic>.from(d['category']);
      } else {
        final raw = d['category']?.toString() ?? '';
        catMap = {'en': raw, 'hu': raw};
      }
      // defaultUnit
      Map<String, dynamic> unitMap;
      if (d['defaultUnit'] is Map) {
        unitMap = Map<String, dynamic>.from(d['defaultUnit']);
      } else {
        final raw = d['defaultUnit']?.toString() ?? 'kg';
        unitMap = {'en': raw, 'hu': raw};
      }

      fetched.add(Product(
        id: doc.id,
        name: isHu ? (nameMap['hu'] ?? '') : (nameMap['en'] ?? ''),
        category: isHu ? (catMap['hu'] ?? '') : (catMap['en'] ?? ''),
        defaultUnit: (unitMap['en'] ?? 'kg').toLowerCase(),
      ));
      avail.add({
        'id': doc.id,
        'name': nameMap,
        'category': catMap,
        'defaultUnit': unitMap,
      });
    }

    setState(() {
      products = fetched;
      availableProducts = avail;
    });
  }

  Future<void> _loadGuestCart() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('guestCartItems');
    if (s != null) {
      guestCartItems = List<Map<String, dynamic>>.from(jsonDecode(s));
      cartItems = [...guestCartItems];
    }
  }

  Future<void> _saveGuestCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('guestCartItems', jsonEncode(guestCartItems));
  }

  Future<void> _loadCartItems() async {
    if (widget.isGuest) return;
    final doc = await FirebaseFirestore.instance
        .collection('shopping_lists')
        .doc(widget.groupId)
        .get();
    if (doc.exists && doc.data()!.containsKey('items')) {
      cartItems = List<Map<String, dynamic>>.from(doc.data()!['items']);
    }
    setState(() {});
  }

  Future<void> _loadSelectedItems() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('user_shopping_lists')
        .doc(u.uid)
        .get();
    if (doc.exists && doc.data()!.containsKey('items')) {
      selectedItems = List<Map<String, dynamic>>.from(doc.data()!['items']);
    }
  }

  Future<void> addNewProduct() async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final fontSizeScale = theme.fontSizeScale;
    final unitsTranslated = {
      'kg': l10n.unitKg,
      'g': l10n.unitG,
      'pcs': l10n.unitPcs,
      'liters': l10n.unitLiters,
    };
    final nameEnCtrl = TextEditingController();
    final nameHuCtrl = TextEditingController();
    final catEnCtrl = TextEditingController();
    final catHuCtrl = TextEditingController();
    String selectedUnit = 'kg';

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          l10n.addNewProduct,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20 * fontSizeScale,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameHuCtrl,
                decoration: InputDecoration(
                  labelText: l10n.nameLabelHu,
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  labelStyle: TextStyle(
                    fontSize: 16 * fontSizeScale,
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16 * fontSizeScale,
                ),
              ),
              TextField(
                controller: nameEnCtrl,
                decoration: InputDecoration(
                  labelText: l10n.nameLabelEn,
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  labelStyle: TextStyle(
                    fontSize: 16 * fontSizeScale,
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16 * fontSizeScale,
                ),
              ),
              TextField(
                controller: catHuCtrl,
                decoration: InputDecoration(
                  labelText: l10n.categoryLabelHu,
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  labelStyle: TextStyle(
                    fontSize: 16 * fontSizeScale,
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16 * fontSizeScale,
                ),
              ),
              TextField(
                controller: catEnCtrl,
                decoration: InputDecoration(
                  labelText: l10n.categoryLabelEn,
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  labelStyle: TextStyle(
                    fontSize: 16 * fontSizeScale,
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16 * fontSizeScale,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedUnit,
                decoration: InputDecoration(
                  labelText: l10n.unitLabel,
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  labelStyle: TextStyle(
                    fontSize: 16 * fontSizeScale,
                  ),
                ),
                items: units
                    .map((u) => DropdownMenuItem(
                  value: u,
                  child: Text(
                    unitsTranslated[u] ?? u,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16 * fontSizeScale,
                    ),
                  ),
                ))
                    .toList(),
                onChanged: (v) => selectedUnit = v ?? 'kg',
                dropdownColor: Theme.of(context).cardColor,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16 * fontSizeScale,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14 * fontSizeScale,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                      l10n.userNotLoggedIn,
                      style: TextStyle(fontSize: 14 * fontSizeScale),
                    )));
                return;
              }
              final newProd = {
                'name': {'en': nameEnCtrl.text, 'hu': nameHuCtrl.text},
                'category': {'en': catEnCtrl.text, 'hu': catHuCtrl.text},
                'defaultUnit': {'en': selectedUnit, 'hu': selectedUnit},
                'createdBy': user.uid,
              };
              await FirebaseFirestore.instance
                  .collection('products')
                  .add(newProd);
              Navigator.pop(context);
              _fetchProducts();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                    l10n.productAdded,
                    style: TextStyle(fontSize: 14 * fontSizeScale),
                  )));
            },
            child: Text(
              l10n.save,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 14 * fontSizeScale,
              ),
            ),
            style: ElevatedButton.styleFrom(backgroundColor: widget.groupColor),
          ),
        ],
      ),
    );
  }

  Future<void> addItemToCart(Map<String, dynamic> item) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final fontSizeScale = theme.fontSizeScale;
    final locale = Localizations.localeOf(context).languageCode;
    final nameMap = Map<String, dynamic>.from(item['name']);
    final itemName = nameMap[locale] ?? nameMap['en'] ?? l10n.unknownItem;
    final qtyCtrl = TextEditingController(text: '1');
    String selectedUnit =
        (item['defaultUnit'] as Map)['en']?.toString().toLowerCase() ?? 'kg';

    final should = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          l10n.addToCart(itemName),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20 * fontSizeScale,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.quantityLabel,
                filled: true,
                fillColor: Theme.of(context).cardColor,
                labelStyle: TextStyle(
                  fontSize: 16 * fontSizeScale,
                ),
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16 * fontSizeScale,
              ),
            ),
            DropdownButtonFormField<String>(
              value: selectedUnit,
              decoration: InputDecoration(
                labelText: l10n.unitLabel,
                filled: true,
                fillColor: Theme.of(context).cardColor,
                labelStyle: TextStyle(
                  fontSize: 16 * fontSizeScale,
                ),
              ),
              items: units
                  .map((u) => DropdownMenuItem(
                value: u,
                child: Text(
                  u,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16 * fontSizeScale,
                  ),
                ),
              ))
                  .toList(),
              onChanged: (v) => selectedUnit = v ?? selectedUnit,
              dropdownColor: Theme.of(context).cardColor,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16 * fontSizeScale,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.cancel,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14 * fontSizeScale,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.save,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 14 * fontSizeScale,
              ),
            ),
            style: ElevatedButton.styleFrom(backgroundColor: widget.groupColor),
          ),
        ],
      ),
    );
    if (should != true) return;

    final user = FirebaseAuth.instance.currentUser;
    final createdBy = widget.isGuest ? 'guest' : user?.email;
    final cartItem = {
      ...item,
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'quantity': int.tryParse(qtyCtrl.text) ?? 1,
      'unit': selectedUnit,
      'isChecked': false,
      'isPurchased': false,
      'addedBy': createdBy,
    };

    setState(() => cartItems.add(cartItem));

    if (widget.isGuest) {
      guestCartItems = List.from(cartItems);
      _saveGuestCart();
    } else {
      final groupRef =
      FirebaseFirestore.instance.collection('shopping_lists').doc(widget.groupId);
      final snap = await groupRef.get();
      final items = snap.exists && snap.data()!.containsKey('items')
          ? List<Map<String, dynamic>>.from(snap.data()!['items'])
          : <Map<String, dynamic>>[];
      items.add(cartItem);
      await groupRef.set({'items': items}, SetOptions(merge: true));
    }
  }

  Future<void> toggleItemSelection(Map<String, dynamic> item) async {
    final user = FirebaseAuth.instance.currentUser!;
    final l10n = AppLocalizations.of(context)!;
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final fontSizeScale = theme.fontSizeScale;

    // block if someone else already checked it
    if (item['isChecked'] == true && item['selectedBy'] != user.email) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.itemAlreadySelectedBy(item['selectedBy']),
            style: TextStyle(fontSize: 14 * fontSizeScale),
          ),
        ),
      );
      return;
    }

    final groupRef =
    FirebaseFirestore.instance.collection('shopping_lists').doc(widget.groupId);
    final userRef =
    FirebaseFirestore.instance.collection('user_shopping_lists').doc(user.uid);

    setState(() {
      final was = item['isChecked'] == true;
      item['isChecked'] = !was;
      item['isPurchased'] = !was;
      if (!was) {
        item['selectedBy'] = user.email;
        selectedItems.add(item);
      } else {
        item.remove('selectedBy');
        selectedItems.removeWhere((i) => i['id'] == item['id']);
      }
    });

    // Update group
    final gSnap = await groupRef.get();
    final gItems = gSnap.exists
        ? List<Map<String, dynamic>>.from(gSnap.data()!['items'] ?? [])
        : <Map<String, dynamic>>[];
    final gIdx = gItems.indexWhere((i) => i['id'] == item['id']);
    if (gIdx != -1) {
      gItems[gIdx] = item;
    } else {
      gItems.add(item);
    }
    await groupRef.set({'items': gItems}, SetOptions(merge: true));

    // Update this user's personal list
    final uSnap = await userRef.get();
    final uItems = uSnap.exists
        ? List<Map<String, dynamic>>.from(uSnap.data()!['items'] ?? [])
        : <Map<String, dynamic>>[];
    final uIdx = uItems.indexWhere((i) => i['id'] == item['id']);
    if (item['isPurchased'] == true) {
      if (uIdx != -1) {
        uItems[uIdx] = item;
      } else {
        uItems.add(item);
      }
    } else {
      if (uIdx != -1) uItems.removeAt(uIdx);
    }
    await userRef.set({'items': uItems}, SetOptions(merge: true));
  }

  Future<void> removeItem(Map<String, dynamic> item) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final fontSizeScale = theme.fontSizeScale;
    final user = FirebaseAuth.instance.currentUser;
    final addedBy = item['addedBy'] ?? '';
    final locale = Localizations.localeOf(context).languageCode;
    final nameMap = Map<String, dynamic>.from(item['name']);
    final itemName = nameMap[locale] ?? nameMap['en'] ?? '';

    // only owner may delete
    if (widget.isGuest && addedBy != 'guest' ||
        (!widget.isGuest && (user == null || addedBy != user.email))) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(
        content: Text(
          l10n.onlyDeleteOwnItems,
          style: TextStyle(fontSize: 14 * fontSizeScale),
        ),
      ));
      return;
    }

    setState(() {
      cartItems.removeWhere((i) => i['id'] == item['id']);
      selectedItems.removeWhere((i) => i['id'] == item['id']);
    });

    if (widget.isGuest) {
      guestCartItems = List.from(cartItems);
      _saveGuestCart();
    } else {
      final groupRef =
      FirebaseFirestore.instance.collection('shopping_lists').doc(widget.groupId);
      final gSnap = await groupRef.get();
      if (gSnap.exists) {
        final gItems = List<Map<String, dynamic>>.from(gSnap.data()!['items'] ?? []);
        gItems.removeWhere((i) => i['id'] == item['id']);
        await groupRef.set({'items': gItems}, SetOptions(merge: true));
      }
      final userRef = FirebaseFirestore.instance
          .collection('user_shopping_lists')
          .doc(user!.uid);
      final uSnap = await userRef.get();
      if (uSnap.exists) {
        final uItems = List<Map<String, dynamic>>.from(uSnap.data()!['items'] ?? []);
        uItems.removeWhere((i) => i['id'] == item['id']);
        await userRef.set({'items': uItems}, SetOptions(merge: true));
      }
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(
      content: Text(
        l10n.itemRemoved(itemName),
        style: TextStyle(fontSize: 14 * fontSizeScale),
      ),
    ));
  }

  Future<void> editCartItem(BuildContext context, Map<String, dynamic> item) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final fontSizeScale = theme.fontSizeScale;
    final user = FirebaseAuth.instance.currentUser;
    final addedBy = item['addedBy'] ?? '';
    final locale = Localizations.localeOf(context).languageCode;
    final nameMap = Map<String, dynamic>.from(item['name']);
    final itemName = nameMap[locale] ?? nameMap['en'] ?? '';

    // only owner may edit
    if (widget.isGuest && addedBy != 'guest' ||
        (!widget.isGuest && (user == null || addedBy != user.email))) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(
        content: Text(
          l10n.onlyEditOwnItems,
          style: TextStyle(fontSize: 14 * fontSizeScale),
        ),
      ));
      return;
    }

    final qtyCtrl = TextEditingController(text: item['quantity'].toString());
    String selectedUnit = item['unit']?.toString().toLowerCase() ?? 'kg';

    final should = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          l10n.editItem(itemName),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20 * fontSizeScale,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.quantityLabel,
                filled: true,
                fillColor: Theme.of(context).cardColor,
                labelStyle: TextStyle(
                  fontSize: 16 * fontSizeScale,
                ),
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16 * fontSizeScale,
              ),
            ),
            DropdownButtonFormField<String>(
              value: selectedUnit,
              decoration: InputDecoration(
                labelText: l10n.unitLabel,
                filled: true,
                fillColor: Theme.of(context).cardColor,
                labelStyle: TextStyle(
                  fontSize: 16 * fontSizeScale,
                ),
              ),
              items: units
                  .map((u) => DropdownMenuItem(
                value: u,
                child: Text(
                  u,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16 * fontSizeScale,
                  ),
                ),
              ))
                  .toList(),
              onChanged: (v) => selectedUnit = v ?? selectedUnit,
              dropdownColor: Theme.of(context).cardColor,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16 * fontSizeScale,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.cancel,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14 * fontSizeScale,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.save,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 14 * fontSizeScale,
              ),
            ),
            style: ElevatedButton.styleFrom(backgroundColor: widget.groupColor),
          ),
        ],
      ),
    );
    if (should != true) return;

    final updated = {
      ...item,
      'quantity': int.tryParse(qtyCtrl.text) ?? item['quantity'],
      'unit': selectedUnit,
    };

    setState(() {
      final idx = cartItems.indexWhere((i) => i['id'] == item['id']);
      if (idx != -1) cartItems[idx] = updated;
      final sidx = selectedItems.indexWhere((i) => i['id'] == item['id']);
      if (sidx != -1) selectedItems[sidx] = updated;
    });

    if (widget.isGuest) {
      guestCartItems = List.from(cartItems);
      _saveGuestCart();
    } else {
      final groupRef =
      FirebaseFirestore.instance.collection('shopping_lists').doc(widget.groupId);
      final gSnap = await groupRef.get();
      if (gSnap.exists) {
        final gItems = List<Map<String, dynamic>>.from(gSnap.data()!['items'] ?? []);
        final gIdx = gItems.indexWhere((i) => i['id'] == updated['id']);
        if (gIdx != -1) gItems[gIdx] = updated;
        await groupRef.set({'items': gItems}, SetOptions(merge: true));
      }
      final userRef = FirebaseFirestore.instance
          .collection('user_shopping_lists')
          .doc(user!.uid);
      final uSnap = await userRef.get();
      if (uSnap.exists) {
        final uItems = List<Map<String, dynamic>>.from(uSnap.data()!['items'] ?? []);
        final uIdx = uItems.indexWhere((i) => i['id'] == updated['id']);
        if (uIdx != -1) uItems[uIdx] = updated;
        await userRef.set({'items': uItems}, SetOptions(merge: true));
      }
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(
      content: Text(
        l10n.itemEdited(itemName),
        style: TextStyle(fontSize: 14 * fontSizeScale),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final fontSizeScale = theme.fontSizeScale;
    final gradientOpacity = theme.gradientOpacity;
    final iconStyle = theme.iconStyle;
    final locale = Localizations.localeOf(context).languageCode;
    final effectiveColor = theme.useGlobalTheme ? theme.primaryColor : widget.groupColor;

    final filtered = availableProducts.where((p) {
      final nameMap = Map<String, dynamic>.from(p['name']);
      final name = nameMap[locale] ?? nameMap['en'] ?? '';
      return name.toLowerCase().contains(searchController.text.toLowerCase());
    }).toList();

    return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
        title: Text(
        l10n.shoppingList,
        style: TextStyle(
        color: Theme.of(context).colorScheme.onPrimary,
    fontSize: 20 * fontSizeScale,
    ),
    ),
    backgroundColor: effectiveColor,
    iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
    actions: [
    if (!widget.isGuest)
    IconButton(
    icon: Icon(
    showSearchBar
    ? (iconStyle == 'filled' ? Icons.close : Icons.close_outlined)
        : (iconStyle == 'filled' ? Icons.search : Icons.search_outlined),
    color: Theme.of(context).colorScheme.onPrimary,
    ),
    onPressed: () => setState(() {
    showSearchBar = !showSearchBar;
    searchController.clear();
    }),
    ),
    ],
    ),
    body: Container(
    decoration: BoxDecoration(
    gradient: LinearGradient(
    colors: [
    effectiveColor.withOpacity(gradientOpacity),
    Theme.of(context).brightness == Brightness.dark ? Colors.grey[900]! : Colors.grey[200]!,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    ),
    ),
    child: Column(
    children: [
    if (showSearchBar && !widget.isGuest)
    Padding(
    padding: const EdgeInsets.all(8),
    child: TextField(
    controller: searchController,
    style: TextStyle(
    color: Theme.of(context).colorScheme.onSurface,
    fontSize: 16 * fontSizeScale,
    ),
      decoration: InputDecoration(
        hintText: l10n.searchForProducts,
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          fontSize: 16 * fontSizeScale,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        fillColor: Theme.of(context).cardColor,
        filled: true,
      ),
      onChanged: (_) => setState(() {}),
    ),
    ),

// Products grid
      Expanded(
        flex: 2,
        child: GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final p = filtered[i];
            final nameMap = Map<String, dynamic>.from(p['name']);
            final display = nameMap[locale] ?? nameMap['en'] ?? '';
            return GestureDetector(
              onTap: () => addItemToCart(p),
              child: Card(
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Center(
                  child: Text(
                    display,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 16 * fontSizeScale,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          },
        ),
      ),

      const Divider(color: Colors.white70, height: 1),

// Cart / checked items list
      Expanded(
        flex: 3,
        child: cartItems.isEmpty
            ? Center(
          child: Text(
            l10n.noItemsInConsolidatedList,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 16 * fontSizeScale,
            ),
          ),
        )
        :ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: cartItems.length,
          itemBuilder: (BuildContext context, int idx) {
            final item = cartItems[idx];
            final nameMap = Map<String, dynamic>.from(item['name']);
            final display = nameMap[locale] ?? nameMap['en'] ?? '';
            final qty = item['quantity'];
            final unit = item['unit'];
            final checked = item['isChecked'] == true;
            final by = item['selectedBy'];
            return Dismissible(
              key: Key(item['id']),
              background: Container(
                color: Theme.of(context).colorScheme.error,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: Icon(
                  iconStyle == 'filled' ? Icons.delete : Icons.delete_outlined,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              direction: (widget.isGuest && item['addedBy'] != 'guest') ||
                  (!widget.isGuest &&
                      item['addedBy'] !=
                          FirebaseAuth.instance.currentUser?.email)
                  ? DismissDirection.none
                  : DismissDirection.endToStart,
              onDismissed: (DismissDirection direction) {
                removeItem(item);
              },
              child: ListTile(
                title: Text(
                  display,
                  style: TextStyle(
                    color: checked
                        ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                        : Theme.of(context).colorScheme.onSurface,
                    decoration: checked ? TextDecoration.lineThrough : null,
                    fontSize: 16 * fontSizeScale,
                  ),
                ),
                subtitle: Text(
                  '${l10n.quantityLabel}: $qty $unit${checked && by != null ? '\n${l10n.selectedBy(by)}' : ''}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 14 * fontSizeScale,
                  ),
                ),
                onTap: () => editCartItem(context, item),
                trailing: widget.isGuest
                    ? null
                    : Checkbox(
                  value: checked,
                  onChanged: (_) => toggleItemSelection(item),
                  checkColor: Theme.of(context).colorScheme.onPrimary,
                  activeColor: effectiveColor,
                ),
              ),
            );
          },
        ),
      ),
    ],
    ),
    ),
      floatingActionButton: !widget.isGuest
          ? FloatingActionButton(
        backgroundColor: effectiveColor,
        onPressed: addNewProduct,
        child: Icon(
          iconStyle == 'filled' ? Icons.add : Icons.add_outlined,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      )
          : null,
    );
  }
}