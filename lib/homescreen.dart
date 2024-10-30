import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'groups.dart';
import 'data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key, required bool isGuest}) : super(key: key);

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
        .where('userId', isEqualTo: user!.uid)
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
                  // Navigate to Group details
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
