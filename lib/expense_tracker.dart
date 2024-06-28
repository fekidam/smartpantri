import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpenseTrackerScreen extends StatefulWidget {
  final bool isGuest;

  const ExpenseTrackerScreen({Key? key, required this.isGuest}) : super(key: key);

  @override
  _ExpenseTrackerScreenState createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('expense_tracker').snapshots(),
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
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    if (!widget.isGuest) {
                      FirebaseFirestore.instance.collection('expense_tracker').doc(document.id).delete();
                    }
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: widget.isGuest ? null : FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add-expense');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
