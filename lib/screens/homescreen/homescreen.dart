import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Providers/theme_provider.dart';
import 'expense_tracker.dart';
import 'fridge_items.dart';
import 'shopping_lists.dart';
import 'package:smartpantri/generated/l10n.dart';

class GroupHomeScreen extends StatelessWidget {
  final String groupId;
  final bool isGuest;
  final Color groupColor;

  const GroupHomeScreen({
    Key? key,
    required this.groupId,
    required this.isGuest,
    required this.groupColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveGroupId = isGuest ? 'demo_group_id' : groupId;
    final theme = Provider.of<ThemeProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final effectiveColor = theme.useGlobalTheme ? theme.primaryColor : groupColor;
    final fontSizeScale = theme.fontSizeScale;
    final gradientOpacity = theme.gradientOpacity;
    final iconStyle = theme.iconStyle;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: effectiveColor.withOpacity(0.3), // Világosabb háttér a címhez
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            l10n.homeTitle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 20 * fontSizeScale,
              fontWeight: FontWeight.bold, // Vastagabb betűtípus
            ),
          ),
        ),
        backgroundColor: effectiveColor,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              effectiveColor.withOpacity(gradientOpacity),
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]!
                  : Colors.grey[200]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: Theme.of(context).cardColor,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(
                  iconStyle == 'filled' ? Icons.pie_chart : Icons.pie_chart_outline,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                title: Text(
                  l10n.expenseTracker,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16 * fontSizeScale,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExpenseTrackerScreen(
                        isGuest: isGuest,
                        groupId: effectiveGroupId,
                        groupColor: groupColor,
                      ),
                    ),
                  );
                },
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: Theme.of(context).cardColor,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(
                  iconStyle == 'filled' ? Icons.kitchen : Icons.kitchen_outlined,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                title: Text(
                  l10n.whatsInTheFridge,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16 * fontSizeScale,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FridgeItemsScreen(
                        isGuest: isGuest,
                        groupId: effectiveGroupId,
                        groupColor: groupColor,
                      ),
                    ),
                  );
                },
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: Theme.of(context).cardColor,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(
                  iconStyle == 'filled' ? Icons.list_alt : Icons.list_alt_outlined,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                title: Text(
                  l10n.shoppingList,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16 * fontSizeScale,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShoppingListScreen(
                        isGuest: isGuest,
                        groupId: effectiveGroupId,
                        groupColor: groupColor,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}