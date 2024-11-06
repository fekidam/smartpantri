import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/data.dart';
import 'group_detail.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _nameController = TextEditingController();
  Color _selectedColor = Colors.blue;
  final List<Color> _colorOptions = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.yellow,
    Colors.pink,
  ];

  Future<void> _saveGroup() async {
    if (_nameController.text.isNotEmpty) {
      String colorHex = _selectedColor.value.toRadixString(16).substring(2);
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        Group newGroup = Group(
          id: '',
          name: _nameController.text,
          color: colorHex,
          userId: user.uid,
          sharedWith: [user.uid],
        );

        try {
          DocumentReference docRef = await FirebaseFirestore.instance.collection('groups').add(newGroup.toJson());
          String groupId = docRef.id;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GroupDetailScreen(
                group: Group(
                  id: groupId,
                  name: _nameController.text,
                  color: colorHex,
                  userId: user.uid,
                  sharedWith: [user.uid],
                ),
              ),
            ),
          );
        } catch (e) {
          print('Error creating group: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to create group. Please try again.")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a group name.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create New Group")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Group Name"),
            ),
            const SizedBox(height: 20),
            const Text("Select Color"),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: _colorOptions.map((color) {
                bool isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    padding: isSelected ? const EdgeInsets.all(3) : null,
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
            const Spacer(),
            ElevatedButton(
              onPressed: _saveGroup,
              child: const Text("Save Group"),
            ),
          ],
        ),
      ),
    );
  }
}
