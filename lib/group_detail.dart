import 'package:flutter/material.dart';
import 'package:smartpantri/data.dart';
import 'expense_tracker.dart';
import 'fridge_items.dart';
import 'shopping_lists.dart';

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
            title: const Text("Expense Tracker"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExpenseTrackerScreen(
                    isGuest: false,
                    groupId: group.id,
                  ),
                ),
              );
            },
          ),
          ListTile(
            title: const Text("What's in the Fridge"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FridgeItemsScreen(
                    isGuest: false,
                    groupId: group.id,
                  ),
                ),
              );
            },
          ),
          ListTile(
            title: const Text("Shopping List"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShoppingListScreen(
                    isGuest: false,
                    groupId: group.id,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
