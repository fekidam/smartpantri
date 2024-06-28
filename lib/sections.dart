import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final VoidCallback onAdd;
  final String title;

  const SectionTitle({super.key, required this.title, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: onAdd,
        ),
      ],
    );
  }
}

class ShoppingListsSection extends StatelessWidget {
  final VoidCallback onAdd;
  final List<String> items;  // This will hold the list items

  const ShoppingListsSection({super.key, required this.onAdd, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SectionTitle(title: "Shopping Lists", onAdd: onAdd),
        ListView.builder(
          shrinkWrap: true,  // Needed to build a list view within a column
          physics: const NeverScrollableScrollPhysics(), // Disable scrolling within the list view
          itemCount: items.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(items[index], style: const TextStyle(color: Colors.white)),
            );
          },
        ),
      ],
    );
  }
}

class ExpenseTrackingSection extends StatelessWidget {
  final VoidCallback onAdd;

  const ExpenseTrackingSection({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SectionTitle(title: "Expense Tracking", onAdd: onAdd),
        const ListTile(title: Text("Total Spent - \$150", style: TextStyle(color: Colors.white))),
        const ListTile(title: Text("Budget - \$200", style: TextStyle(color: Colors.white))),
      ],
    );
  }
}

class WhatsInTheFridgeSection extends StatelessWidget {
  final VoidCallback onAdd;

  const WhatsInTheFridgeSection({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SectionTitle(title: "What's in the fridge?", onAdd: onAdd),
        const ListTile(title: Text("Milk - 2 liters", style: TextStyle(color: Colors.white))),
        const ListTile(title: Text("Eggs - 12 pieces", style: TextStyle(color: Colors.white))),
        const ListTile(title: Text("Butter - 200 grams", style: TextStyle(color: Colors.white))),
      ],
    );
  }
}
