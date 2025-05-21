import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../Providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:smartpantri/generated/l10n.dart';

// Segítő függvény a hex szín konvertálására
Color hexToColor(String hexColor) {
  hexColor = hexColor.replaceAll('#', '');
  if (hexColor.length == 6) {
    hexColor = 'FF$hexColor';
  }
  return Color(int.parse(hexColor, radix: 16));
}

class FridgeItemsScreen extends StatefulWidget {
  final bool isGuest;
  final String groupId;
  final Color groupColor; // Új paraméter a csoport színének

  const FridgeItemsScreen({
    Key? key,
    required this.isGuest,
    required this.groupId,
    required this.groupColor, // Kötelező paraméter
  }) : super(key: key);

  @override
  _FridgeItemsScreenState createState() => _FridgeItemsScreenState();
}

class _FridgeItemsScreenState extends State<FridgeItemsScreen> {
  bool hasAccess = false;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    if (widget.isGuest) {
      setState(() => hasAccess = false); // Vendég mód esetén tiltjuk a hűtőt
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => hasAccess = false);
      return;
    }
    final doc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final ok = data['userId'] == user.uid ||
          (data['sharedWith'] as List).contains(user.uid);
      setState(() => hasAccess = ok);
    }
  }

  Future<void> _editFridgeItem(BuildContext context, Map<String, dynamic> item, String docId) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final fontSizeScale = theme.fontSizeScale;
    final qtyCtrl = TextEditingController(text: '${item['quantity']}');
    final unitCtrl = TextEditingController(text: item['unit'] as String? ?? '');
    final priceCtrl = TextEditingController(text: '${item['price']?.toStringAsFixed(2) ?? '0.00'}');
    final expDateCtrl = TextEditingController(
      text: item['expirationDate'] != null
          ? DateFormat('yyyy-MM-dd HH:mm').format((item['expirationDate'] as Timestamp).toDate())
          : '',
    );
    final locale = Localizations.localeOf(context).languageCode;
    final nameMap = item['name'] as Map<String, dynamic>;
    final itemName = nameMap[locale] ?? nameMap['en'] ?? '';

    final save = await showDialog<bool>(
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
              decoration: InputDecoration(
                labelText: l10n.quantityLabel,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 16 * fontSizeScale,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16 * fontSizeScale,
              ),
            ),
            TextField(
              controller: unitCtrl,
              decoration: InputDecoration(
                labelText: l10n.unitLabel,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 16 * fontSizeScale,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16 * fontSizeScale,
              ),
            ),
            TextField(
              controller: priceCtrl,
              decoration: InputDecoration(
                labelText: l10n.priceLabel,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 16 * fontSizeScale,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16 * fontSizeScale,
              ),
            ),
            TextField(
              controller: expDateCtrl,
              readOnly: true, // Csak a dátumválasztóval módosítható
              decoration: InputDecoration(
                labelText: l10n.expires,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 16 * fontSizeScale,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                suffixIcon: Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16 * fontSizeScale,
              ),
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: item['expirationDate'] != null
                      ? (item['expirationDate'] as Timestamp).toDate()
                      : DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(
                      item['expirationDate'] != null
                          ? (item['expirationDate'] as Timestamp).toDate()
                          : DateTime.now(),
                    ),
                  );
                  if (pickedTime != null) {
                    final finalDateTime = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      pickedTime.hour,
                      pickedTime.minute,
                    );
                    expDateCtrl.text = DateFormat('yyyy-MM-dd HH:mm').format(finalDateTime);
                  }
                }
              },
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
            style: ElevatedButton.styleFrom(backgroundColor: widget.groupColor),
            child: Text(
              l10n.save,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 14 * fontSizeScale,
              ),
            ),
          ),
        ],
      ),
    );
    if (save != true) return;

    final newQty = int.tryParse(qtyCtrl.text) ?? item['quantity'];
    final newUnit = unitCtrl.text;
    final newPrice = double.tryParse(priceCtrl.text) ?? item['price'] ?? 0.0;
    final newExpDate = expDateCtrl.text.isNotEmpty
        ? Timestamp.fromDate(DateFormat('yyyy-MM-dd HH:mm').parse(expDateCtrl.text))
        : item['expirationDate'];

    final updatedItem = {
      'name': item['name'],
      'quantity': newQty,
      'unit': newUnit,
      'price': newPrice,
      'expirationDate': newExpDate,
      'addedBy': item['addedBy'],
    };

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('fridge_items')
        .doc(docId)
        .set(updatedItem, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.itemEdited(itemName),
          style: TextStyle(fontSize: 14 * fontSizeScale),
        ),
      ),
    );
  }

  Future<void> _removeFridgeItem(String docId, Map<String, dynamic> item) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final fontSizeScale = theme.fontSizeScale;
    final user = FirebaseAuth.instance.currentUser!;
    final locale = Localizations.localeOf(context).languageCode;
    final nameMap = item['name'] as Map<String, dynamic>;
    final itemName = nameMap[locale] ?? nameMap['en'] ?? '';
    final purchased = item['isPurchased'] as bool? ?? false;
    final price = item['price'] as double? ?? 0.0;

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('fridge_items')
        .doc(docId)
        .delete();

    if (purchased && !widget.isGuest) {
      await FirebaseFirestore.instance.collection('expense_tracker').add({
        'groupId': widget.groupId,
        'userId': user.uid,
        'amount': price,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('fridge_items')
          .add({
        'name': item['name'],
        'quantity': item['quantity'],
        'unit': item['unit'],
        'price': price,
        'expirationDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)),
        ),
        'addedBy': user.uid,
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.itemRemoved(itemName),
          style: TextStyle(fontSize: 14 * fontSizeScale),
        ),
      ),
    );
  }

  Future<void> _addToShoppingList(Map<String, dynamic> item, String docId) async {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser!;
    final gid = widget.groupId;
    final locale = Localizations.localeOf(context).languageCode;
    final nameMap = item['name'] as Map;
    final itemName = nameMap[locale] ?? nameMap['en'] ?? '';

    try {
      // Az új elem létrehozása
      final newItem = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': item['name'],
        'quantity': item['quantity'],
        'unit': item['unit'],
        'price': item['price'],
        'currency': item['currency'] ?? (locale == 'hu' ? 'HUF' : 'USD'),
        'category': item['category'] ?? 'unknown',
        'isPurchased': false,
        'isChecked': false,
        'selectedBy': user.email, // A selectedBy mezőt a jelenlegi felhasználó emailjére állítom
        'groupId': gid,
        'addedBy': user.email,
      };

      // 1. Hozzáadom az elemet a shopping_lists gyűjteményhez (ShoppingListScreen)
      final groupRef = FirebaseFirestore.instance.collection('shopping_lists').doc(gid);
      final gSnap = await groupRef.get();
      List<Map<String, dynamic>> gItems = [];
      if (gSnap.exists && gSnap.data() != null && gSnap.data()!['items'] != null) {
        gItems = List<Map<String, dynamic>>.from(gSnap.data()!['items']);
      }
      gItems.add(newItem);
      await groupRef.set({'items': gItems}, SetOptions(merge: true));

      // 2. Hozzáadom az elemet a user_shopping_lists-hez (YourGroupsScreen)
      final userRef = FirebaseFirestore.instance.collection('user_shopping_lists').doc(user.uid);
      final uSnap = await userRef.get();
      List<Map<String, dynamic>> uItems = [];
      if (uSnap.exists && uSnap.data() != null && uSnap.data()!['items'] != null) {
        uItems = List<Map<String, dynamic>>.from(uSnap.data()!['items']);
      }
      uItems.add(newItem);
      await userRef.set({'items': uItems}, SetOptions(merge: true));

      // 3. Törlöm az elemet a hűtőből
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('fridge_items')
          .doc(docId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.itemAddedToShoppingList(itemName))),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hiba történt: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final fontSizeScale = theme.fontSizeScale;
    final gradientOpacity = theme.gradientOpacity;
    final iconStyle = theme.iconStyle;
    final effectiveColor = theme.useGlobalTheme ? theme.primaryColor : widget.groupColor;

    if (!hasAccess) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            l10n.accessDenied,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 20 * fontSizeScale,
            ),
          ),
          backgroundColor: effectiveColor,
          iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
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
          child: Center(
            child: Text(
              l10n.noAccessToGroup,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16 * fontSizeScale,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          l10n.whatsInTheFridge,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 20 * fontSizeScale,
          ),
        ),
        backgroundColor: effectiveColor,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
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
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('groups')
              .doc(widget.groupId)
              .collection('fridge_items')
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: effectiveColor));
            }
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(
                child: Text(
                  l10n.noItemsFoundInFridge,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16 * fontSizeScale,
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final data = docs[i].data() as Map<String, dynamic>;
                final docId = docs[i].id;
                final nameMap = data['name'] as Map<String, dynamic>;
                final locale = Localizations.localeOf(context).languageCode;
                final displayName = nameMap[locale] ?? nameMap['en'] ?? '';
                final quantity = data['quantity']?.toString() ?? '';
                final unit = data['unit']?.toString() ?? '';
                final price = data['price']?.toStringAsFixed(2) ?? '0.00';
                final ts = data['expirationDate'] as Timestamp?;
                final expDate = ts?.toDate();
                Color bg = Colors.transparent;
                int diff = 0;
                if (expDate != null) {
                  diff = expDate.difference(DateTime.now()).inHours;
                  if (diff <= 0) bg = Colors.red.withOpacity(0.2);
                  else if (diff <= 48) bg = Colors.red.withOpacity(0.2);
                  else if (diff <= 168) bg = Colors.yellow.withOpacity(0.2);
                  else bg = Colors.green.withOpacity(0.2);
                }

                // Ellenőrzöm, hogy az elem hamarosan lejár-e (3 napon belül, de még nem járt le)
                bool isExpiringSoon = expDate != null &&
                    expDate.isBefore(DateTime.now().add(const Duration(days: 3))) &&
                    !expDate.isBefore(DateTime.now());

                return Container(
                  color: bg,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(
                      displayName,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16 * fontSizeScale,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$quantity $unit',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 14 * fontSizeScale,
                          ),
                        ),
                        Text(
                          '${l10n.priceLabel}: $price ${l10n.currencySymbol}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 14 * fontSizeScale,
                          ),
                        ),
                        if (expDate != null)
                          Text(
                            '${l10n.expires}: '
                                '${DateFormat('yyyy-MM-dd HH:mm').format(expDate)}',
                            style: TextStyle(
                              color: diff <= 0
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              fontSize: 14 * fontSizeScale,
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            iconStyle == 'filled' ? Icons.edit : Icons.edit_outlined,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          onPressed: () => _editFridgeItem(context, data, docId),
                        ),
                        IconButton(
                          icon: Icon(
                            iconStyle == 'filled' ? Icons.delete : Icons.delete_outlined,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          onPressed: () => _removeFridgeItem(docId, data),
                        ),
                        if (isExpiringSoon)
                          IconButton(
                            icon: Icon(
                              iconStyle == 'filled' ? Icons.shopping_cart : Icons.shopping_cart_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            onPressed: () => _addToShoppingList(data, docId),
                            tooltip: l10n.addToShoppingList,
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
    );
  }
}