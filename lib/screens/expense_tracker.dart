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
  Future<Map<String, dynamic>> calculateMonthlyExpenses() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final querySnapshot = await FirebaseFirestore.instance
        .collection('expense_tracker')
        .where('groupId', isEqualTo: widget.groupId)
        .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
        .get();

    double totalExpenses = 0.0;
    Map<String, double> userExpenses = {};

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final amount = data['amount']?.toDouble() ?? 0.0;
      final userId = data['userId'] ?? 'guest';

      final userEmail = widget.isGuest ? 'Guest' : await getUserEmail(userId);
      totalExpenses += amount;
      userExpenses[userEmail] = (userExpenses[userEmail] ?? 0.0) + amount;
    }

    return {
      'totalExpenses': totalExpenses,
      'userExpenses': userExpenses,
    };
  }

  Future<String> getUserEmail(String userId) async {
    if (userId == 'guest') return 'Guest';
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.data()?['email'] ?? 'Unknown';
  }

  Future<Map<String, Map<String, List<Map<String, dynamic>>>>> fetchGroupedData(
      AsyncSnapshot<QuerySnapshot> snapshot) async {
    final Map<String, Map<String, List<Map<String, dynamic>>>> groupedData = {};

    for (var doc in snapshot.data!.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final userId = data['userId'] ?? 'guest';
      final userEmail = widget.isGuest ? 'Guest' : await getUserEmail(userId);
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final dateKey =
          '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';

      if (!groupedData.containsKey(userEmail)) {
        groupedData[userEmail] = {};
      }
      if (!groupedData[userEmail]!.containsKey(dateKey)) {
        groupedData[userEmail]![dateKey] = [];
      }
      groupedData[userEmail]![dateKey]!.add(data);
    }

    return groupedData;
  }

  void _showMonthlySummary() async {
    final stats = await calculateMonthlyExpenses();
    final totalExpenses = stats['totalExpenses'];
    final userExpenses = stats['userExpenses'] as Map<String, double>;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Monthly Summary'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Expense: ${totalExpenses.toStringAsFixed(2)} Ft'),
                const SizedBox(height: 10),
                const Text('By Users:'),
                ...userExpenses.entries.map((entry) {
                  return Text(
                    '${entry.key}: ${entry.value.toStringAsFixed(2)} Ft',
                    style: const TextStyle(fontSize: 14),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _showMonthlySummary,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('expense_tracker')
            .where('groupId', isEqualTo: widget.groupId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No expenses found.'));
          }

          return FutureBuilder<Map<String, Map<String, List<Map<String, dynamic>>>>>(
            future: fetchGroupedData(snapshot),
            builder: (context, futureSnapshot) {
              if (futureSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (futureSnapshot.hasError) {
                return Text('Error: ${futureSnapshot.error}');
              }
              if (!futureSnapshot.hasData) {
                return const Center(child: Text('No data found.'));
              }

              final groupedData = futureSnapshot.data!;

              return ListView(
                children: groupedData.entries.map((userEntry) {
                  final userEmail = userEntry.key;
                  final dateEntries = userEntry.value;

                  return ExpansionTile(
                    title: Text(userEmail),
                    children: dateEntries.entries.map((dateEntry) {
                      final date = dateEntry.key;
                      final items = dateEntry.value;

                      final dailyTotal = items.fold<double>(
                          0.0, (sum, item) => sum + (item['amount']?.toDouble() ?? 0.0));

                      return ExpansionTile(
                        title: Text(
                          '$date - Total: ${dailyTotal.toStringAsFixed(2)} Ft',
                        ),
                        children: items.map((item) {
                          return ListTile(
                            title: Text(item['category'] ?? 'Unknown'),
                            subtitle: Text(
                              'Price: ${(item['amount']?.toDouble() ?? 0.0).toStringAsFixed(2)} Ft',
                            ),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}