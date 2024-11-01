import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartpantri/data.dart';
import 'groups.dart';
import 'group_detail.dart';

class HomeScreen extends StatefulWidget {
  final bool isGuest;

  const HomeScreen({Key? key, required this.isGuest}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  Stream<List<Group>> _fetchGroups() {
    return FirebaseFirestore.instance
        .collection('groups')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Group.fromJson(doc.id, doc.data() as Map<String, dynamic>);
          }).toList();
        });
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
