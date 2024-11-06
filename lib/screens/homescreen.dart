import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartpantri/groups/group_detail.dart';
import 'package:smartpantri/groups/groups.dart';
import 'package:smartpantri/groups/share_group.dart';
import '../models/data.dart';

class HomeScreen extends StatefulWidget {
  final bool isGuest;

  const HomeScreen({super.key, required this.isGuest});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  Stream<List<Group>> _fetchGroups() {
    if (user == null) {
      return Stream.value([]);
    }
    return FirebaseFirestore.instance
        .collection('groups')
        .where('sharedWith', arrayContains: user!.uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Group.fromJson(doc.id, doc.data());
      }).toList();
    });
  }

  Future<void> _showEditGroupDialog(Group group) async {
    TextEditingController nameController = TextEditingController(text: group.name);
    Color selectedColor = Color(int.parse('0xFF${group.color}'));
    final List<Color> colorOptions = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.yellow,
      Colors.pink,
    ];

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Group Name'),
              ),
              const SizedBox(height: 10),
              const Text('Select Color'),
              Wrap(
                spacing: 10,
                children: colorOptions.map((color) {
                  bool isSelected = selectedColor == color;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedColor = color;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        backgroundColor: color,
                        radius: 20,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
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
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteGroup(Group group) async {
    await FirebaseFirestore.instance.collection('groups').doc(group.id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your Groups")),
      body: StreamBuilder<List<Group>>(
        stream: _fetchGroups(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No groups found"));
          }
          List<Group> groups = snapshot.data!;
          return ListView(
            children: groups.map((group) {
              return ListTile(
                title: Text(group.name),
                leading: CircleAvatar(
                  backgroundColor: Color(int.parse('0xFF${group.color}')),
                ),
                subtitle: group.sharedWith.length > 1 ? const Text('Shared') : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.person_add, color: Colors.green),
                      onPressed: () {
                        Navigator.push(
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
                      builder: (context) => GroupDetailScreen(group: group),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
