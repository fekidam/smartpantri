import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';
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

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Home'),
            backgroundColor: themeProvider.primaryColor, // Use theme's primaryColor
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
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
          ),
        );
      },
    );
  }
}