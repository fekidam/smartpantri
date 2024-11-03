import 'package:flutter/material.dart';
import 'expense_tracker.dart';
import 'fridge_items.dart';
import 'shopping_lists.dart';

class GroupHomeScreen extends StatelessWidget {
  final String groupId;

  const GroupHomeScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: const Text("Expense Tracker"),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExpenseTrackerScreen(
                  isGuest: false,
                  groupId: groupId,
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
                  groupId: groupId,
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
                  groupId: groupId,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
