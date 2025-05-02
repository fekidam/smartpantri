import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartpantri/groups/group_detail.dart';
import 'package:smartpantri/groups/share_group.dart';
import '../models/data.dart';
import 'groups.dart';
import 'your_groups.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:smartpantri/generated/l10n.dart'; // AppLocalizations import

class HomeScreen extends StatefulWidget {
  final bool isGuest;

  const HomeScreen({super.key, required this.isGuest});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  StreamSubscription<QuerySnapshot>? _groupsSubscription;

  @override
  void initState() {
    super.initState();
    _setupGroupsListener();
  }

  @override
  void dispose() {
    _groupsSubscription?.cancel();
    super.dispose();
  }

  void _setupGroupsListener() {
    if (widget.isGuest || user == null) return;

    _groupsSubscription = FirebaseFirestore.instance
        .collection('groups')
        .where('sharedWith', arrayContains: user!.uid)
        .snapshots()
        .listen((snapshot) {
      // A StreamBuilder automatikusan kezeli a frissítéseket
    }, onError: (error) {
      print('Error fetching groups: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorFetchingGroups(error.toString()))),
      );
    });

    // Kijelentkezés figyelése
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        _groupsSubscription?.cancel();
        setState(() {});
      }
    });
  }

  Stream<List<Map<String, dynamic>>> _fetchGroups() {
    if (widget.isGuest) {
      return Stream.value([
        {
          'group': Group(
            id: 'demo_group_id',
            name: AppLocalizations.of(context)!.demoGroup,
            color: '00FF00',
            sharedWith: ['guest'],
          ),
          'isShared': false,
        }
      ]);
    }

    if (user == null) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('groups')
        .where('sharedWith', arrayContains: user!.uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final group = Group.fromJson(doc.id, doc.data());
        final isShared = group.sharedWith.length > 1;
        return {
          'group': group,
          'isShared': isShared,
        };
      }).toList();
    });
  }

  Future<void> _showEditGroupDialog(Group group) async {
    TextEditingController nameController = TextEditingController(text: group.name);
    Color selectedColor = Color(int.parse('0xFF${group.color}'));

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.editGroup),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: AppLocalizations.of(context)!.groupName),
                    ),
                    const SizedBox(height: 10),
                    Text(AppLocalizations.of(context)!.groupTagColor),
                    const SizedBox(height: 10),
                    BlockPicker(
                      pickerColor: selectedColor,
                      onColorChanged: (color) {
                        setState(() {
                          selectedColor = color;
                        });
                      },
                      availableColors: const [
                        Colors.blue,
                        Colors.green,
                        Colors.orange,
                        Colors.purple,
                        Colors.red,
                        Colors.teal,
                        Colors.yellow,
                        Colors.pink,
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      String colorHex = selectedColor.value.toRadixString(16).substring(2);
                      await FirebaseFirestore.instance.collection('groups').doc(group.id).update({
                        'name': nameController.text,
                        'color': colorHex,
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.groupUpdatedSuccessfully)),
                      );
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteGroup(Group group) async {
    await FirebaseFirestore.instance.collection('groups').doc(group.id).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.groupDeleted)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.yourGroups),
        backgroundColor: Colors.grey[800], // Fixed dark grey color
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _fetchGroups(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text(AppLocalizations.of(context)!.noGroupsFound));
                }
                List<Map<String, dynamic>> groupData = snapshot.data!;
                return ListView(
                  children: groupData.map((data) {
                    final group = data['group'] as Group;
                    final isShared = data['isShared'] as bool;
                    return ListTile(
                      title: Text(group.name),
                      leading: CircleAvatar(
                        backgroundColor: Color(int.parse('0xFF${group.color}')),
                      ),
                      subtitle: isShared ? Text(AppLocalizations.of(context)!.shared) : null,
                      trailing: widget.isGuest
                          ? null
                          : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.person_add, color: Colors.green),
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ShareGroupScreen(groupId: group.id),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showEditGroupDialog(group),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteGroup(group),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GroupDetailScreen(
                              group: group,
                              isGuest: widget.isGuest,
                              isShared: isShared,
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => YourGroupsScreen(isGuest: widget.isGuest)),
                );
              },
              icon: const Icon(Icons.list),
              label: Text(AppLocalizations.of(context)!.viewYourGroups),
            ),
          ),
        ],
      ),
      floatingActionButton: widget.isGuest
          ? null
          : FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateGroupScreen(isGuest: widget.isGuest),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}