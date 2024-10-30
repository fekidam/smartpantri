import 'package:flutter/material.dart';
import 'data.dart';

class GroupDetailScreen extends StatelessWidget {
  final Group group;

  const GroupDetailScreen({Key? key, required this.group}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        backgroundColor: Color(int.parse('0xFF${group.color}')),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Shopping Lists'),
            onTap: () {
              Navigator.pushNamed(context, '/shopping-lists');
            },
          ),
          ListTile(
            title: const Text('Expenses'),
            onTap: () {
              Navigator.pushNamed(context, '/expenses');
            },
          ),
          ListTile(
            title: const Text('What\'s in the Fridge'),
            onTap: () {
              Navigator.pushNamed(context, '/fridge-items');
            },
          ),
        ],
      ),
    );
  }
}
