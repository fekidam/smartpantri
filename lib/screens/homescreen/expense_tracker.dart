import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../Providers/theme_provider.dart';
import 'package:smartpantri/generated/l10n.dart';

// Segítő függvény a hex szín konvertálására
Color hexToColor(String hexColor) {
  hexColor = hexColor.replaceAll('#', '');
  if (hexColor.length == 6) {
    hexColor = 'FF$hexColor';
  }
  return Color(int.parse(hexColor, radix: 16));
}

class ExpenseTrackerScreen extends StatefulWidget {
  final bool isGuest;
  final String groupId;
  final Color groupColor;

  const ExpenseTrackerScreen({
    Key? key,
    required this.isGuest,
    required this.groupId,
    required this.groupColor,
  }) : super(key: key);

  @override
  _ExpenseTrackerScreenState createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  Map<String, dynamic>? _monthlyExpenses;

  // Konstans átváltási ráta: 1 USD = 360 HUF
  static const double usdToHufRate = 360.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    calculateMonthlyExpenses().then((result) {
      setState(() {
        _monthlyExpenses = result;
      });
    });
  }

  Future<Map<String, dynamic>> calculateMonthlyExpenses() async {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    if (widget.isGuest) {
      return {
        'totalExpenses': 0.0,
        'userExpenses': {l10n.guest: 0.0},
        'userCount': 1,
        'fairShare': 0.0,
      };
    }

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final snap = await FirebaseFirestore.instance
        .collection('expense_tracker')
        .where('groupId', isEqualTo: widget.groupId)
        .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
        .get();

    double total = 0.0;
    final Map<String, double> userExpenses = {};
    final Set<String> userIds = {};

    for (var doc in snap.docs) {
      final data = doc.data();
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      final uid = data['userId'] as String? ?? 'guest';
      userIds.add(uid);

      final email = await getUserEmail(uid);

      total += amount;
      userExpenses[email] = (userExpenses[email] ?? 0.0) + amount;
    }

    final count = userIds.length;
    final fair = count > 0 ? total / count : 0.0;

    // Ha magyar nyelv, konvertáljuk HUF-ba
    final convertedTotal = locale == 'hu' ? total * usdToHufRate : total;
    final convertedUserExpenses = userExpenses.map((key, value) => MapEntry(key, locale == 'hu' ? value * usdToHufRate : value));
    final convertedFair = locale == 'hu' ? fair * usdToHufRate : fair;

    return {
      'totalExpenses': convertedTotal,
      'userExpenses': convertedUserExpenses,
      'userCount': count,
      'fairShare': convertedFair,
    };
  }

  Future<String> getUserEmail(String userId) async {
    final l10n = AppLocalizations.of(context)!;
    if (userId == 'guest') {
      return l10n.guest;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get(const GetOptions(source: Source.server));
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['email'] is String) {
          return data['email'] as String;
        }
      }
      return l10n.unknown;
    } catch (_) {
      return l10n.unknown;
    }
  }

  Future<Map<String, Map<String, List<Map<String, dynamic>>>>> fetchGroupedData(
      AsyncSnapshot<QuerySnapshot> snapshot) async {
    final Map<String, Map<String, List<Map<String, dynamic>>>> groupedData = {};
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    for (var doc in snapshot.data!.docs) {
      final data = doc.data() as Map<String, dynamic>;

      if (data['category'] is Map) {
        final categoryMap = Map<String, dynamic>.from(data['category']);
        data['category'] = categoryMap[locale] ?? categoryMap['en'] ?? l10n.unknownItem;
      }

      if (data['name'] is Map) {
        final nameMap = Map<String, dynamic>.from(data['name']);
        data['name'] = nameMap[locale] ?? nameMap['en'] ?? l10n.unknownItem;
      }

      final userId = data['userId'] ?? 'guest';
      final userEmail = widget.isGuest ? l10n.guest : await getUserEmail(userId);
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
    final l10n = AppLocalizations.of(context)!;
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final fontSizeScale = theme.fontSizeScale;
    final stats = _monthlyExpenses!;
    final total = stats['totalExpenses'] as double;
    final byUser = stats['userExpenses'] as Map<String, double>;
    final userCount = stats['userCount'] as int;
    final fair = stats['fairShare'] as double;
    final locale = Localizations.localeOf(context).languageCode;
    final currencySymbol = locale == 'hu' ? 'HUF' : l10n.currencySymbol;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          l10n.monthlySummary,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20 * fontSizeScale,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l10n.totalExpense}: ${total.toStringAsFixed(2)} $currencySymbol',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16 * fontSizeScale,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.byUsers,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16 * fontSizeScale,
                ),
              ),
              ...byUser.entries.map((e) => Text(
                '${e.key}: ${e.value.toStringAsFixed(2)} $currencySymbol',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 14 * fontSizeScale,
                ),
              )),
              const SizedBox(height: 8),
              Text(
                '${l10n.fairShare}: ${fair.toStringAsFixed(2)} $currencySymbol '
                    '(${l10n.perUser} $userCount)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14 * fontSizeScale,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.ok,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14 * fontSizeScale,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final fontSizeScale = theme.fontSizeScale;
    final gradientOpacity = theme.gradientOpacity;
    final iconStyle = theme.iconStyle;
    final effectiveColor = theme.useGlobalTheme ? theme.primaryColor : widget.groupColor;
    final locale = Localizations.localeOf(context).languageCode;
    final currencySymbol = locale == 'hu' ? 'HUF' : l10n.currencySymbol;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: effectiveColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            l10n.expenseTracker,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 20 * fontSizeScale.toDouble(),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: effectiveColor,
        actions: [
          IconButton(
            icon: Icon(
              iconStyle == 'filled' ? Icons.calendar_today : Icons.calendar_today_outlined,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: _showMonthlySummary,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              effectiveColor.withOpacity(gradientOpacity),
              Theme.of(context).brightness == Brightness.dark ? Colors.grey[900]! : Colors.grey[200]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: widget.isGuest
            ? Center(
          child: Text(
            l10n.noExpensesInGuestMode,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16 * fontSizeScale,
            ),
          ),
        )
            : StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('expense_tracker')
              .where('groupId', isEqualTo: widget.groupId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: effectiveColor));
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  '${l10n.somethingWentWrong}: ${snapshot.error}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16 * fontSizeScale,
                  ),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        l10n.noExpensesFound,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16 * fontSizeScale,
                        ),
                      ),
                    ),
                  ),
                  if (_monthlyExpenses != null)
                    Column(
                      children: [
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sections: (_monthlyExpenses!['userExpenses'] as Map<String, double>)
                                  .entries
                                  .map((entry) {
                                final index = (_monthlyExpenses!['userExpenses']
                                as Map<String, double>)
                                    .keys
                                    .toList()
                                    .indexOf(entry.key);
                                return PieChartSectionData(
                                  color: Colors.primaries[index % Colors.primaries.length],
                                  value: entry.value,
                                  title: '${entry.value.toStringAsFixed(0)} $currencySymbol',
                                  radius: 50,
                                  titleStyle: TextStyle(
                                    fontSize: 16 * fontSizeScale,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                );
                              }).toList(),
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                '${l10n.totalExpense}: ${(_monthlyExpenses!['totalExpenses'] as double).toStringAsFixed(2)} $currencySymbol',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 16 * fontSizeScale,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${l10n.fairShare}: ${(_monthlyExpenses!['fairShare'] as double).toStringAsFixed(2)} $currencySymbol '
                                    '(${l10n.perUser} ${_monthlyExpenses!['userCount'] as int})',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7),
                                  fontSize: 14 * fontSizeScale,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              );
            }

            return FutureBuilder<Map<String, Map<String, List<Map<String, dynamic>>>>>(
              future: fetchGroupedData(snapshot),
              builder: (context, futureSnapshot) {
                if (futureSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: effectiveColor));
                }
                if (futureSnapshot.hasError) {
                  return Center(
                    child: Text(
                      '${l10n.somethingWentWrong}: ${futureSnapshot.error}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16 * fontSizeScale,
                      ),
                    ),
                  );
                }
                if (!futureSnapshot.hasData || futureSnapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.noExpensesFound,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16 * fontSizeScale,
                      ),
                    ),
                  );
                }

                final groupedData = futureSnapshot.data!;

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: groupedData.entries.length,
                        itemBuilder: (context, index) {
                          final userEntry = groupedData.entries.toList()[index];
                          final userEmail = userEntry.key;
                          final dateEntries = userEntry.value;

                          return ExpansionTile(
                            title: Text(
                              userEmail,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 16 * fontSizeScale,
                              ),
                            ),
                            children: dateEntries.entries.map((dateEntry) {
                              final date = dateEntry.key;
                              final items = dateEntry.value;

                              final dailyTotal = items.fold<double>(
                                  0.0,
                                      (sum, item) =>
                                  sum + (item['amount']?.toDouble() ?? 0.0));
                              final convertedDailyTotal = locale == 'hu' ? dailyTotal * usdToHufRate : dailyTotal;

                              return ExpansionTile(
                                title: Text(
                                  '$date - ${l10n.totalExpense}: ${convertedDailyTotal.toStringAsFixed(2)} $currencySymbol',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                                    fontSize: 14 * fontSizeScale,
                                  ),
                                ),
                                children: items.map((item) {
                                  final itemAmount = (item['amount']?.toDouble() ?? 0.0);
                                  final convertedItemAmount = locale == 'hu' ? itemAmount * usdToHufRate : itemAmount;
                                  return ListTile(
                                    title: Text(
                                      item['name']?.toString() ?? l10n.unknownItem,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontSize:16 * fontSizeScale,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${l10n.priceLabel}: ${convertedItemAmount.toStringAsFixed(2)} $currencySymbol',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.7),
                                        fontSize: 14 * fontSizeScale,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                    if (_monthlyExpenses != null)
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: (_monthlyExpenses!['userExpenses']
                            as Map<String, double>)
                                .entries
                                .map((entry) {
                              final index = (_monthlyExpenses!['userExpenses']
                              as Map<String, double>)
                                  .keys
                                  .toList()
                                  .indexOf(entry.key);
                              return PieChartSectionData(
                                color:
                                Colors.primaries[index % Colors.primaries.length],
                                value: entry.value,
                                title: '${entry.value.toStringAsFixed(0)} $currencySymbol',
                                radius: 50,
                                titleStyle: TextStyle(
                                  fontSize: 16 * fontSizeScale,
                                  fontWeight: FontWeight.bold,
                                  color:
                                  Theme.of(context).colorScheme.onPrimary,
                                ),
                              );
                            }).toList(),
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                          ),
                        ),
                      ),
                    if (_monthlyExpenses != null)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              '${l10n.totalExpense}: ${(_monthlyExpenses!['totalExpenses'] as double).toStringAsFixed(2)} $currencySymbol',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 16 * fontSizeScale,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${l10n.fairShare}: ${(_monthlyExpenses!['fairShare'] as double).toStringAsFixed(2)} $currencySymbol '
                                  '(${l10n.perUser} ${_monthlyExpenses!['userCount'] as int})',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7),
                                fontSize: 14 * fontSizeScale,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}