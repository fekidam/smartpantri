import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart'; // fl_chart csomag

class ExpenseTrackerScreen extends StatefulWidget {
  final bool isGuest;
  final String groupId;

  const ExpenseTrackerScreen({super.key, required this.isGuest, required this.groupId});

  @override
  _ExpenseTrackerScreenState createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  Future<Map<String, dynamic>>? _monthlyExpensesFuture; // Nullable típusú

  @override
  void initState() {
    super.initState();
    // Inicializáláskor meghívjuk a calculateMonthlyExpenses-t
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
        print('User document not found for userId: $userId');
        return 'Unknown';
      }
    } catch (e) {
      print('Error fetching user email for userId $userId: $e');
      return 'Unknown';
    }
  }

  Future<Map<String, Map<String, List<Map<String, dynamic>>>>> fetchGroupedData(
      AsyncSnapshot<QuerySnapshot> snapshot) async {
    if (widget.isGuest) {
      return {};
    }

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
        stream: widget.isGuest
            ? null
            : FirebaseFirestore.instance
            .collection('expense_tracker')
            .where('groupId', isEqualTo: widget.groupId)
            .snapshots(),
        builder: (context, snapshot) {
          if (widget.isGuest) {
            return const Center(child: Text('No expenses available in guest mode.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print('StreamBuilder error: ${snapshot.error}');
            if (snapshot.error.toString().contains('permission-denied')) {
              return const Center(child: Text('You do not have permission to view expenses for this group.'));
            }
            return Text('Error: ${snapshot.error}');
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Column(
              children: [
                const Expanded(
                  child: Center(child: Text('No expenses found.')),
                ),
                // Grafikon üres adatokkal
                if (_monthlyExpensesFuture != null) // Ellenőrizzük, hogy nem null-e
                  FutureBuilder<Map<String, dynamic>>(
                    future: _monthlyExpensesFuture,
                    builder: (context, futureSnapshot) {
                      if (futureSnapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      if (futureSnapshot.hasError) {
                        print('FutureBuilder error for chart: ${futureSnapshot.error}');
                        return const SizedBox.shrink();
                      }
                      final userExpenses = futureSnapshot.data?['userExpenses'] as Map<String, double>? ?? {};
                      if (userExpenses.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      // Számoljuk ki a legnagyobb értéket, hogy az intervallumot ennek megfelelően állítsuk be
                      final maxY = userExpenses.values.reduce((a, b) => a > b ? a : b) * 1.2;
                      // Intervallum dinamikus meghatározása: a maxY alapján választunk egy megfelelő lépésközt
                      final interval = (maxY / 5).ceilToDouble(); // 5 lépésközre osztjuk a tengelyt

                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          height: 300,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: maxY,
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    final userEmail = userExpenses.keys.toList()[groupIndex];
                                    return BarTooltipItem(
                                      '$userEmail\n${rod.toY.toStringAsFixed(2)} Ft',
                                      const TextStyle(color: Colors.white),
                                    );
                                  },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index < 0 || index >= userExpenses.length) {
                                        return SideTitleWidget(
                                          space: 8.0,
                                          angle: 0,
                                          meta: meta,
                                          child: const Text(''),
                                        );
                                      }
                                      final userEmail = userExpenses.keys.toList()[index];
                                      return SideTitleWidget(
                                        space: 8.0,
                                        angle: 0,
                                        meta: meta,
                                        child: Text(
                                          userEmail.length > 10 ? '${userEmail.substring(0, 7)}...' : userEmail,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      );
                                    },
                                    reservedSize: 40,
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: interval,
                                    getTitlesWidget: (value, meta) {
                                      return SideTitleWidget(
                                        space: 8.0,
                                        angle: 0,
                                        meta: meta,
                                        child: Text(
                                          '${value.toInt()} Ft',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    },
                                    reservedSize: 50,
                                  ),
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              gridData: const FlGridData(show: true),
                              barGroups: userExpenses.entries.toList().asMap().entries.map((entry) {
                                final index = entry.key;
                                final expense = entry.value.value;
                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: expense,
                                      color: Colors.blueAccent,
                                      width: 20,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            );
          }

          return FutureBuilder<Map<String, Map<String, List<Map<String, dynamic>>>>>(
            future: fetchGroupedData(snapshot),
            builder: (context, futureSnapshot) {
              if (futureSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (futureSnapshot.hasError) {
                print('FutureBuilder error: ${futureSnapshot.error}');
                return Text('Error: ${futureSnapshot.error}');
              }
              if (!futureSnapshot.hasData) {
                return const Center(child: Text('No data found.'));
              }

              final groupedData = futureSnapshot.data!;

              return SingleChildScrollView(
                child: Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: groupedData.entries.length,
                      itemBuilder: (context, index) {
                        final userEntry = groupedData.entries.toList()[index];
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
                      },
                    ),
                    if (_monthlyExpensesFuture != null)
                      FutureBuilder<Map<String, dynamic>>(
                        future: _monthlyExpensesFuture,
                        builder: (context, futureSnapshot) {
                          if (futureSnapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox.shrink();
                          }
                          if (futureSnapshot.hasError) {
                            print('FutureBuilder error for chart: ${futureSnapshot.error}');
                            return const SizedBox.shrink();
                          }
                          final userExpenses = futureSnapshot.data?['userExpenses'] as Map<String, double>? ?? {};
                          if (userExpenses.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final maxY = userExpenses.values.reduce((a, b) => a > b ? a : b) * 1.2;
                          final interval = (maxY / 5).ceilToDouble();

                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SizedBox(
                              height: 300,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: maxY,
                                  barTouchData: BarTouchData(
                                    enabled: true,
                                    touchTooltipData: BarTouchTooltipData(
                                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                        final userEmail = userExpenses.keys.toList()[groupIndex];
                                        return BarTooltipItem(
                                          '$userEmail\n${rod.toY.toStringAsFixed(2)} Ft',
                                          const TextStyle(color: Colors.white),
                                        );
                                      },
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          final index = value.toInt();
                                          if (index < 0 || index >= userExpenses.length) {
                                            return SideTitleWidget(
                                              space: 8.0,
                                              angle: 0,
                                              meta: meta,
                                              child: const Text(''),
                                            );
                                          }
                                          final userEmail = userExpenses.keys.toList()[index];
                                          return SideTitleWidget(
                                            space: 8.0,
                                            angle: 0,
                                            meta: meta,
                                            child: Text(
                                              userEmail.length > 10 ? '${userEmail.substring(0, 7)}...' : userEmail,
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          );
                                        },
                                        reservedSize: 40,
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: interval,
                                        getTitlesWidget: (value, meta) {
                                          return SideTitleWidget(
                                            space: 8.0,
                                            angle: 0,
                                            meta: meta,
                                            child: Text(
                                              '${value.toInt()} Ft',
                                              style: const TextStyle(fontSize: 10),
                                            ),
                                          );
                                        },
                                        reservedSize: 50,
                                      ),
                                    ),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  gridData: const FlGridData(show: true),
                                  barGroups: userExpenses.entries.toList().asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final expense = entry.value.value;
                                    return BarChartGroupData(
                                      x: index,
                                      barRods: [
                                        BarChartRodData(
                                          toY: expense,
                                          color: Colors.blueAccent,
                                          width: 20,
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
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
        },
      ),
    );
  }
}