import 'package:flutter/material.dart';
import 'expense_tracker.dart';
import 'fridge_items.dart';
import 'shopping_lists.dart';

class GroupHomeScreen extends StatelessWidget {
  final String groupId;
  final bool isGuest;

  const GroupHomeScreen({super.key, required this.groupId, required this.isGuest});

  @override
  Widget build(BuildContext context) {
    final effectiveGroupId = isGuest ? 'demo_group_id' : groupId;

    return ListView(
      children: [
        ListTile(
          title: const Text("Expense Tracker"),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExpenseTrackerScreen(
                  isGuest: isGuest,
                  groupId: effectiveGroupId,
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
                  isGuest: isGuest,
                  groupId: effectiveGroupId,
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
                  isGuest: isGuest,
                  groupId: effectiveGroupId,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}