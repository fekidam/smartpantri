import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseTrackerScreen extends StatefulWidget {
  final bool isGuest;
  final String groupId;

  const ExpenseTrackerScreen({super.key, required this.isGuest, required this.groupId});

  @override
  _ExpenseTrackerScreenState createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  Future<void> _addExpense(String category, int amount) async {
    if (!widget.isGuest) {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('expenses')
          .add({'category': category, 'amount': amount});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('expenses')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          if (snapshot.data?.docs.isEmpty ?? true) {
            return const Center(child: Text('No expenses found.'));
          }
          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data() as Map<String, dynamic>;
              String category = data['category'] ?? 'Unknown';
              int amount = data['amount'] ?? 0;
              return ListTile(
                title: Text(category),
                subtitle: Text('\$$amount'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    if (!widget.isGuest) {
                      FirebaseFirestore.instance
                          .collection('groups')
                          .doc(widget.groupId)
                          .collection('expenses')
                          .doc(document.id)
                          .delete();
                    }
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: widget.isGuest
          ? null
          : FloatingActionButton(
              onPressed: () {
                _showAddExpenseDialog(context);
              },
              child: const Icon(Icons.add),
            ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final TextEditingController categoryController = TextEditingController();
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Expense'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final category = categoryController.text;
                final amount = int.tryParse(amountController.text) ?? 0;
                if (category.isNotEmpty && amount > 0) {
                  _addExpense(category, amount);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
