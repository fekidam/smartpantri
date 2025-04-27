import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import '../services/app_state_provider.dart';
import '../services/theme_provider.dart';

class FridgeItemsScreen extends StatefulWidget {
  final bool isGuest;
  final String groupId;

  const FridgeItemsScreen({super.key, required this.isGuest, required this.groupId});

  @override
  _FridgeItemsScreenState createState() => _FridgeItemsScreenState();
}

class _FridgeItemsScreenState extends State<FridgeItemsScreen> {
  bool hasAccess = false;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  final Set<int> scheduledNotifications = {};

  @override
  void initState() {
    super.initState();
    _checkAccess();
    if (!widget.isGuest) {
      _initializeTestData();
    }
  }

  Future<bool> _hasAccess(String groupId) async {
    if (widget.isGuest) {
      return groupId == 'demo_group_id';
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final doc = await FirebaseFirestore.instance.collection('groups').doc(groupId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return data['userId'] == user.uid || (data['sharedWith'] as List<dynamic>).contains(user.uid);
    }
    return false;
  }

  Future<void> _checkAccess() async {
    bool access = await _hasAccess(widget.groupId);
    setState(() {
      hasAccess = access;
    });
  }

  Future<void> _initializeTestData() async {
    final groupRef = FirebaseFirestore.instance.collection('groups').doc(widget.groupId);
    final groupDoc = await groupRef.get();

    if (!groupDoc.exists) {
      await groupRef.set({
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'test_user',
        'sharedWith': [],
      });

      await groupRef.collection('fridge_items').add({
        'name': 'Tej',
        'quantity': '1',
        'unit': 'liter',
        'createdAt': FieldValue.serverTimestamp(),
        'expirationDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 3))),
      });

      await groupRef.collection('fridge_items').add({
        'name': 'Tojás',
        'quantity': '10',
        'unit': 'pcs',
        'createdAt': FieldValue.serverTimestamp(),
        'expirationDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 7))),
      });
    }
  }

  Future<void> _showNotification(String itemName, DateTime expirationDate) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'fridge_channel_id',
      'Fridge Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.show(
      itemName.hashCode,
      'Item Expiring Soon',
      '$itemName is expiring on ${DateFormat('yyyy-MM-dd HH:mm').format(expirationDate)}!',
      notificationDetails,
    );
  }

  void _addItem(String name, String quantity, String unit, DateTime? expirationDate) async {
    final itemData = {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'createdAt': FieldValue.serverTimestamp(),
      'expirationDate': expirationDate != null ? Timestamp.fromDate(expirationDate) : null,
    };

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('fridge_items')
        .add(itemData);
  }

  void _editItem(BuildContext context, Map<String, dynamic> item, String docId) {
    final TextEditingController quantityController = TextEditingController(text: item['quantity']);
    String selectedUnit = item['unit'] ?? 'kg';
    DateTime? expirationDate = item['expirationDate'] != null
        ? (item['expirationDate'] as Timestamp).toDate()
        : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit ${item['name']}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                    ),
                    DropdownButtonFormField(
                      value: selectedUnit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: ['kg', 'g', 'pcs', 'liters']
                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedUnit = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: expirationDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );

                        if (pickedDate != null) {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(
                                expirationDate ?? DateTime.now()),
                          );

                          if (pickedTime != null) {
                            setDialogState(() {
                              expirationDate = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            });
                          }
                        }
                      },
                      child: Text(
                        expirationDate != null
                            ? 'Expiration: ${DateFormat('yyyy-MM-dd HH:mm').format(expirationDate!)}'
                            : 'Set Expiration Date and Time',
                      ),
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
                    try {
                      final updatedData = {
                        'quantity': quantityController.text,
                        'unit': selectedUnit,
                        'expirationDate': expirationDate != null ? Timestamp.fromDate(expirationDate!) : null,
                      };

                      await FirebaseFirestore.instance
                          .collection('groups')
                          .doc(widget.groupId)
                          .collection('fridge_items')
                          .doc(docId)
                          .update(updatedData);
                    } catch (e) {
                      print("Error saving item: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error saving item: $e')),
                      );
                    } finally {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    if (!hasAccess) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        backgroundColor: themeProvider.primaryColor,
        body: const Center(
          child: Text('You do not have access to this group.'),
        ),
      );
    }

    final appStateProvider = Provider.of<AppStateProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("What's in the Fridge?"),
        backgroundColor: themeProvider.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('fridge_items')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No items found in the fridge.'));
          }
          final documents = snapshot.data!.docs;

          if (!widget.isGuest) {
            for (var doc in documents) {
              var data = doc.data() as Map<String, dynamic>;
              if (data['expirationDate'] != null) {
                final expirationDate = (data['expirationDate'] as Timestamp).toDate();
                final notificationTime = expirationDate.subtract(const Duration(days: 1));
                final now = DateTime.now();

                if (notificationTime.isBefore(now) &&
                    !scheduledNotifications.contains(data['name'].hashCode) &&
                    !appStateProvider.isAppInForeground) { // Itt használjuk az AppStateProvider-t
                  _showNotification(data['name'], expirationDate);
                  scheduledNotifications.add(data['name'].hashCode);
                }
              }
            }
          }

          return SingleChildScrollView(
            child: Column(
              children: documents.map((doc) {
                var data = doc.data() as Map<String, dynamic>;
                final expirationDate = data['expirationDate'] != null
                    ? (data['expirationDate'] as Timestamp).toDate()
                    : null;

                Color backgroundColor = Colors.transparent;
                if (expirationDate != null) {
                  final now = DateTime.now();
                  final diff = expirationDate.difference(now).inHours;
                  if (diff <= 0) {
                    backgroundColor = Colors.red.withOpacity(0.2);
                  } else if (diff <= 48) {
                    backgroundColor = Colors.red.withOpacity(0.2);
                  } else if (diff <= 7 * 24) {
                    backgroundColor = Colors.yellow.withOpacity(0.2);
                  } else {
                    backgroundColor = Colors.green.withOpacity(0.2);
                  }
                }

                return Container(
                  color: backgroundColor,
                  child: ListTile(
                    title: Text(data['name'] ?? 'No name'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${data['quantity']} ${data['unit'] ?? ''}'),
                        if (expirationDate != null)
                          Text(
                            'Expires: ${DateFormat('yyyy-MM-dd HH:mm').format(expirationDate)}',
                            style: TextStyle(
                              color: expirationDate.difference(DateTime.now()).inHours <= 0
                                  ? Colors.red
                                  : null,
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!widget.isGuest)
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              _editItem(context, data, doc.id);
                            },
                          ),
                        if (!widget.isGuest)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('groups')
                                  .doc(widget.groupId)
                                  .collection('fridge_items')
                                  .doc(doc.id)
                                  .delete();
                            },
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
      floatingActionButton: widget.isGuest
          ? null
          : FloatingActionButton(
        onPressed: () {
          _showAddItemDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController quantityController = TextEditingController();
    String selectedUnit = 'kg';
    DateTime? expirationDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Item Name'),
                    ),
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                    ),
                    DropdownButtonFormField(
                      value: selectedUnit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: ['kg', 'g', 'pcs', 'liters']
                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedUnit = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: expirationDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );

                        if (pickedDate != null) {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(
                                expirationDate ?? DateTime.now()),
                          );

                          if (pickedTime != null) {
                            setDialogState(() {
                              expirationDate = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            });
                          }
                        }
                      },
                      child: Text(
                        expirationDate != null
                            ? 'Expiration: ${DateFormat('yyyy-MM-dd HH:mm').format(expirationDate!)}'
                            : 'Set Expiration Date and Time',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text;
                    final quantity = quantityController.text;
                    if (name.isNotEmpty && quantity.isNotEmpty) {
                      _addItem(name, quantity, selectedUnit, expirationDate);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}