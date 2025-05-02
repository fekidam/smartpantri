import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';
import 'expense_tracker.dart';
import 'fridge_items.dart';
import 'shopping_lists.dart';
import 'package:smartpantri/generated/l10n.dart'; // AppLocalizations import

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
            title: Text(AppLocalizations.of(context)!.homeTitle),
            backgroundColor: themeProvider.primaryColor, // Use theme's primaryColor
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
          ),
          body: ListView(
            children: [
              ListTile(
                title: Text(AppLocalizations.of(context)!.expenseTracker),
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
                title: Text(AppLocalizations.of(context)!.whatsInTheFridge),
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
                title: Text(AppLocalizations.of(context)!.shoppingList),
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
