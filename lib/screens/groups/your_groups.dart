import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../generated/l10n.dart';
import 'info_dialog.dart';
import '../../Providers/theme_provider.dart';

class YourGroupsScreen extends StatefulWidget {
  final bool isGuest;

  const YourGroupsScreen({Key? key, required this.isGuest}) : super(key: key);

  @override
  _YourGroupsScreenState createState() => _YourGroupsScreenState();
}

class _YourGroupsScreenState extends State<YourGroupsScreen> {
  List<Map<String, dynamic>> _guestItems = [];
  List<Map<String, dynamic>> _userItems = [];

  // Konstans átváltási ráta: 1 USD = 360 HUF
  static const double usdToHufRate = 360.0;

  @override
  void initState() {
    super.initState();
    if (widget.isGuest) {
      _loadGuestCart();
    } else {
      _fetchAndSetUserItems();
    }
    _showInfoDialogIfFirstLaunch();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handleLanguageChange();
  }

  Future<void> _showInfoDialogIfFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('hasSeenGroupsInfo') ?? false;
    if (!seen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => InfoDialog(
            title: AppLocalizations.of(context)!.yourGroupsInfoTitle,
            message: AppLocalizations.of(context)!.aggregatedListInfoMessage,
            onDismiss: () async {
              await prefs.setBool('hasSeenGroupsInfo', true);
            },
          ),
        );
      });
    }
  }

  Future<void> _loadGuestCart() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('guestCartItems');
    if (data != null) {
      final list = jsonDecode(data) as List;
      setState(() {
        _guestItems = list.map((e) => Map<String, dynamic>.from(e)).toList();
      });
      await _handleLanguageChangeForGuest();
    }
  }

  Future<List<String>> _fetchGroupIds() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    // 1. Csoportok, ahol meg van hívva (sharedWith)
    final snapShared = await FirebaseFirestore.instance
        .collection('groups')
        .where('sharedWith', arrayContains: user.uid)
        .get();
    // 2. Csoportok, ahol ő a tulajdonos
    final snapOwn = await FirebaseFirestore.instance
        .collection('groups')
        .where('userId', isEqualTo: user.uid)
        .get();
    // Mindkét listából szedjük össze az id-kat, duplikáció nélkül
    final ids = {...snapShared.docs.map((d) => d.id), ...snapOwn.docs.map((d) => d.id)};
    return ids.toList();
  }


  Future<void> _fetchAndSetUserItems() async {
    final ids = await _fetchGroupIds();
    if (ids.isEmpty) return;
    final currentEmail = FirebaseAuth.instance.currentUser?.email;
    List<Map<String, dynamic>> all = [];
    for (var gid in ids) {
      final doc = await FirebaseFirestore.instance.collection('shopping_lists').doc(gid).get();
      if (doc.exists && doc.data()!.containsKey('items')) {
        final items = List<Map<String, dynamic>>.from(doc['items']);
        for (var raw in items) {
          if (raw['selectedBy'] == currentEmail) { // Csak a felhasználóhoz rendelt elemeket veszi fel
            final m = Map<String, dynamic>.from(raw)..['groupId'] = gid;
            all.add(m);
          }
        }
      }
    }
    setState(() {
      _userItems = all;
    });
    await _handleLanguageChange();
  }

  Future<void> _handleLanguageChange() async {
    final locale = Localizations.localeOf(context).languageCode;
    final currentCurrency = locale == 'hu' ? 'HUF' : 'USD';
    final itemsToUpdate = widget.isGuest ? _guestItems : _userItems;
    final needsUpdate = itemsToUpdate.any((item) => (item['currency'] as String? ?? 'USD') != currentCurrency);

    if (needsUpdate) {
      for (var item in itemsToUpdate) {
        final currentPrice = item['price'] as double;
        final storedCurrency = item['currency'] as String? ?? 'USD';
        final newPrice = storedCurrency == 'HUF' && locale != 'hu'
            ? currentPrice / usdToHufRate
            : storedCurrency == 'USD' && locale == 'hu'
            ? currentPrice * usdToHufRate
            : currentPrice;
        item['price'] = newPrice;
        item['currency'] = currentCurrency;
      }
      setState(() {});
      if (!widget.isGuest) {
        await _updateFirestoreItems();
      } else {
        await _saveGuestCart();
      }
    }
  }

  Future<void> _handleLanguageChangeForGuest() async {
    final locale = Localizations.localeOf(context).languageCode;
    final currentCurrency = locale == 'hu' ? 'HUF' : 'USD';
    final needsUpdate = _guestItems.any((item) => (item['currency'] as String? ?? 'USD') != currentCurrency);

    if (needsUpdate) {
      for (var item in _guestItems) {
        final currentPrice = item['price'] as double;
        final storedCurrency = item['currency'] as String? ?? 'USD';
        final newPrice = storedCurrency == 'HUF' && locale != 'hu'
            ? currentPrice / usdToHufRate
            : storedCurrency == 'USD' && locale == 'hu'
            ? currentPrice * usdToHufRate
            : currentPrice;
        item['price'] = newPrice;
        item['currency'] = currentCurrency;
      }
      setState(() {});
      await _saveGuestCart();
    }
  }

  Future<void> _saveGuestCart() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_guestItems);
    await prefs.setString('guestCartItems', data);
  }

  Future<void> _updateFirestoreItems() async {
    final ids = await _fetchGroupIds();
    if (ids.isEmpty) return;
    final currentEmail = FirebaseAuth.instance.currentUser?.email;
    for (var gid in ids) {
      final doc = await FirebaseFirestore.instance.collection('shopping_lists').doc(gid).get();
      if (doc.exists && doc.data()!.containsKey('items')) {
        final items = List<Map<String, dynamic>>.from(doc['items']);
        final updatedItems = items.map((item) {
          final match = _userItems.firstWhere(
                (ui) => ui['id'] == item['id'] && ui['selectedBy'] == currentEmail,
            orElse: () => {},
          );
          return match.isNotEmpty ? match : item;
        }).toList();
        await FirebaseFirestore.instance.collection('shopping_lists').doc(gid).set(
          {'items': updatedItems},
          SetOptions(merge: true),
        );
      }
    }
  }

  Future<void> _togglePurchased(Map<String, dynamic> item) async {
    final user = FirebaseAuth.instance.currentUser!;
    final gid = item['groupId'] as String;
    final now = !item['isPurchased'] as bool? ?? false;
    setState(() {
      item['isPurchased'] = now;
    });
    final groupRef = FirebaseFirestore.instance.collection('shopping_lists').doc(gid);
    final gSnap = await groupRef.get();
    if (gSnap.exists) {
      final gItems = List<Map<String, dynamic>>.from(gSnap.data()!['items'] ?? []);
      final idx = gItems.indexWhere((i) => i['id'] == item['id']);
      if (idx != -1) {
        gItems[idx] = item;
        await groupRef.set({'items': gItems}, SetOptions(merge: true));
      }
    }
    if (!widget.isGuest) {
      final userRef = FirebaseFirestore.instance.collection('user_shopping_lists').doc(user.uid);
      final uSnap = await userRef.get();
      List<Map<String, dynamic>> uItems = [];
      if (uSnap.exists) {
        uItems = List<Map<String, dynamic>>.from(uSnap.data()!['items'] ?? []);
      }
      final uidx = uItems.indexWhere((i) => i['id'] == item['id']);
      if (uidx != -1) {
        uItems[uidx] = item;
      } else if (now) {
        uItems.add(item); // Ha bepipáljuk, és még nincs a listában, hozzáadjuk
      }
      await userRef.set({'items': uItems}, SetOptions(merge: true));
    }
  }

  Future<void> _editItem(BuildContext context, Map<String, dynamic> item) async {
    final l10n = AppLocalizations.of(context)!;
    final qtyCtrl = TextEditingController(text: '${item['quantity']}');
    final unitCtrl = TextEditingController(text: item['unit'] as String? ?? '');
    final priceCtrl = TextEditingController(text: '${item['price']?.toStringAsFixed(2) ?? '0.00'}');
    final locale = Localizations.localeOf(context).languageCode;
    final nameMap = item['name'] as Map;
    final itemName = nameMap[locale] ?? nameMap['en'] ?? '';
    final save = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.editItem(itemName)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyCtrl,
              decoration: InputDecoration(labelText: l10n.quantityLabel),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: unitCtrl,
              decoration: InputDecoration(labelText: l10n.unitLabel),
            ),
            TextField(
              controller: priceCtrl,
              decoration: InputDecoration(labelText: '${l10n.priceLabel} (${locale == 'hu' ? 'HUF' : 'USD'})'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.save)),
        ],
      ),
    );
    if (save != true) return;
    final newQty = int.tryParse(qtyCtrl.text) ?? item['quantity'];
    final newUnit = unitCtrl.text;
    final newPrice = double.tryParse(priceCtrl.text) ?? item['price'] ?? 0.0;
    final currency = locale == 'hu' ? 'HUF' : 'USD';
    setState(() {
      item['quantity'] = newQty;
      item['unit'] = newUnit;
      item['price'] = newPrice;
      item['currency'] = currency;
    });
    final user = FirebaseAuth.instance.currentUser!;
    final gid = item['groupId'] as String;
    final groupRef = FirebaseFirestore.instance.collection('shopping_lists').doc(gid);
    final gSnap = await groupRef.get();
    if (gSnap.exists) {
      final gItems = List<Map<String, dynamic>>.from(gSnap.data()!['items'] ?? []);
      final idx = gItems.indexWhere((i) => i['id'] == item['id']);
      if (idx != -1) {
        gItems[idx] = item;
        await groupRef.set({'items': gItems}, SetOptions(merge: true));
      }
    }
    final userRef = FirebaseFirestore.instance.collection('user_shopping_lists').doc(user.uid);
    final uSnap = await userRef.get();
    if (uSnap.exists) {
      final uItems = List<Map<String, dynamic>>.from(uSnap.data()!['items'] ?? []);
      final uidx = uItems.indexWhere((i) => i['id'] == item['id']);
      if (uidx != -1) {
        uItems[uidx] = item;
        await userRef.set({'items': uItems}, SetOptions(merge: true));
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.itemEdited(itemName))));
  }

  Future<void> _removeItem(Map<String, dynamic> item) async {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser!;
    final locale = Localizations.localeOf(context).languageCode;
    final nameMap = item['name'] as Map;
    final itemName = nameMap[locale] ?? nameMap['en'] ?? '';
    final gid = item['groupId'] as String;
    final wasPurchased = item['isPurchased'] as bool? ?? false;
    final price = item['price'] as double? ?? 0.0;
    final category = item['category'];
    final name = item['name'];

    setState(() {
      if (widget.isGuest) {
        _guestItems.removeWhere((i) => i['id'] == item['id']);
      } else {
        _userItems.removeWhere((i) => i['id'] == item['id']);
      }
    });

    final groupRef = FirebaseFirestore.instance.collection('shopping_lists').doc(gid);
    final gSnap = await groupRef.get();
    if (gSnap.exists) {
      final gItems = List<Map<String, dynamic>>.from(gSnap.data()!['items'] ?? []);
      gItems.removeWhere((i) => i['id'] == item['id']);
      await groupRef.set({'items': gItems}, SetOptions(merge: true));
    }

    if (!widget.isGuest) {
      final userRef = FirebaseFirestore.instance.collection('user_shopping_lists').doc(user.uid);
      final uSnap = await userRef.get();
      if (uSnap.exists) {
        final uItems = List<Map<String, dynamic>>.from(uSnap.data()!['items'] ?? []);
        uItems.removeWhere((i) => i['id'] == item['id']);
        await userRef.set({'items': uItems}, SetOptions(merge: true));
      }
    }

    if (wasPurchased && !widget.isGuest) {
      await FirebaseFirestore.instance.collection('expense_tracker').add({
        'groupId': gid,
        'userId': user.uid,
        'amount': price,
        'currency': item['currency'],
        'createdAt': FieldValue.serverTimestamp(),
        'category': category,
        'name': name,
      });
      await FirebaseFirestore.instance.collection('groups').doc(gid).collection('fridge_items').add({
        'name': item['name'],
        'quantity': item['quantity'],
        'unit': item['unit'],
        'price': price,
        'currency': item['currency'],
        'expirationDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)),
        ),
        'addedBy': user.uid,
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.itemRemoved(itemName))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final fontSizeScale = theme.fontSizeScale.toDouble();
    final gradientOpacity = theme.gradientOpacity;
    final iconStyle = theme.iconStyle;
    final currencySymbol = locale == 'hu' ? 'HUF' : 'USD';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            iconStyle == 'filled' ? Icons.arrow_back : Icons.arrow_back_outlined,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            l10n.viewYourGroups,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20 * fontSizeScale,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.primaryColor.withOpacity(gradientOpacity),
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]!
                  : Colors.grey[200]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _fetchUserItemsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              final items = snapshot.data ?? [];
              return items.isEmpty
                  ? Center(
                child: Text(
                  l10n.noItemsInConsolidatedList,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 14 * fontSizeScale,
                  ),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  final nameMap = item['name'] as Map;
                  final name = nameMap[locale] ?? nameMap['en'] ?? '';
                  final qty = item['quantity'];
                  final unit = item['unit'] as String? ?? '';
                  final price = item['price']?.toStringAsFixed(2) ?? '0.00';
                  final checked = item['isPurchased'] as bool? ?? false;

                  return Card(
                    color: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                    child: ListTile(
                      title: Text(
                        name,
                        style: TextStyle(
                          color: checked
                              ? Theme.of(context).disabledColor
                              : Theme.of(context).colorScheme.onSurface,
                          decoration: checked ? TextDecoration.lineThrough : null,
                          fontSize: 16 * fontSizeScale,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: checked,
                            onChanged: (_) => _togglePurchased(item),
                            activeColor: Theme.of(context).colorScheme.onSurface,
                            checkColor: Theme.of(context).cardColor,
                          ),
                          IconButton(
                            icon: Icon(
                              iconStyle == 'filled' ? Icons.edit : Icons.edit_outlined,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            onPressed: () => _editItem(context, item),
                          ),
                          IconButton(
                            icon: Icon(
                              iconStyle == 'filled' ? Icons.delete : Icons.delete_outlined,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            onPressed: () => _removeItem(item),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${l10n.quantityLabel}: $qty $unit',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              fontSize: 14 * fontSizeScale,
                            ),
                          ),
                          Text(
                            '${l10n.priceLabel}: $price $currencySymbol',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              fontSize: 14 * fontSizeScale,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> _fetchUserItemsStream() async* {
    final ids = await _fetchGroupIds();
    if (ids.isEmpty) yield [];
    final currentEmail = FirebaseAuth.instance.currentUser?.email;
    for (var gid in ids) {
      yield* FirebaseFirestore.instance
          .collection('shopping_lists')
          .doc(gid)
          .snapshots()
          .map((doc) {
        if (!doc.exists || !doc.data()!.containsKey('items')) return [];
        final items = List<Map<String, dynamic>>.from(doc['items']);
        return items
            .where((raw) => raw['selectedBy'] == currentEmail)
            .map((raw) => Map<String, dynamic>.from(raw)..['groupId'] = gid)
            .toList();
      });
    }
  }
}