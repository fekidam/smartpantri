import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../services/theme_provider.dart';
import 'package:smartpantri/generated/l10n.dart'; // <<< Fontos: lokalizáció import!

class ExpenseTrackerScreen extends StatefulWidget {
  final bool isGuest;
  final String groupId;

  const ExpenseTrackerScreen({super.key, required this.isGuest, required this.groupId});

  @override
  _ExpenseTrackerScreenState createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  Future<Map<String, dynamic>>? _monthlyExpensesFuture;

  @override
  void initState() {
    super.initState();
    _monthlyExpensesFuture = calculateMonthlyExpenses();
  }

  Future<Map<String, dynamic>> calculateMonthlyExpenses() async {
    if (widget.isGuest) {
      return {
        'totalExpenses': 0.0,
        'userExpenses': {'Guest': 0.0},
      };
    }

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
    try {
      if (userId == 'guest') return 'Guest';
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get(const GetOptions(source: Source.server));
      if (userDoc.exists) {
        return userDoc.data()?['email'] ?? 'Unknown';
      } else {
        return 'Unknown';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  void _showMonthlySummary() async {
    final stats = await calculateMonthlyExpenses();
    final totalExpenses = stats['totalExpenses'];
    final userExpenses = stats['userExpenses'] as Map<String, double>;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.monthlySummary),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${AppLocalizations.of(context)!.totalExpense}: ${totalExpenses.toStringAsFixed(2)} Ft'),
                const SizedBox(height: 10),
                Text(AppLocalizations.of(context)!.byUsers),
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
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.expenseTracker),
        backgroundColor: themeProvider.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _showMonthlySummary,
          ),
        ],
      ),
      body: widget.isGuest
          ? Center(child: Text(AppLocalizations.of(context)!.noExpensesInGuestMode))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('expense_tracker')
            .where('groupId', isEqualTo: widget.groupId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text(AppLocalizations.of(context)!.noExpensesFound));
          }

          final data = snapshot.data!.docs;

          return ListView(
            children: data.map((doc) {
              final item = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(item['category'] ?? AppLocalizations.of(context)!.unknownItem),
                subtitle: Text('${item['amount']?.toDouble()?.toStringAsFixed(2) ?? '0.00'} Ft'),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
