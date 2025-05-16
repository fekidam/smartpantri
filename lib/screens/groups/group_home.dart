import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartpantri/screens/groups/your_groups.dart';
import '../../generated/l10n.dart';
import '../../models/data.dart';
import 'info_dialog.dart';
import '../../Providers/theme_provider.dart';
import 'group_detail.dart';
import 'create_groups.dart';
import 'share_group.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class HomeScreen extends StatefulWidget {
  final bool isGuest;

  const HomeScreen({Key? key, required this.isGuest}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription<QuerySnapshot>? _groupsSubscription;
  final StreamController<List<Map<String, dynamic>>> _groupsController = StreamController.broadcast();

  @override
  void initState() {
    super.initState();
    _showInfoDialogIfFirstLaunch();
  }

  @override
  void dispose() {
    _groupsSubscription?.cancel();
    _groupsController.close();
    super.dispose();
  }

  Future<void> _showInfoDialogIfFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('hasSeenHomeInfo') ?? false;
    if (!hasSeen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => InfoDialog(
            title: AppLocalizations.of(context)!.welcomeToYourGroups,
            message: AppLocalizations.of(context)!.yourGroupsInfo,
            onDismiss: () async {
              await prefs.setBool('hasSeenHomeInfo', true);
            },
          ),
        );
      });
    }
  }

  Stream<List<Map<String, dynamic>>> _fetchGroups() {
    return FirebaseAuth.instance.authStateChanges().asyncMap((User? user) async {
      if (widget.isGuest || user == null) {
        return [
          {
            'group': Group(
              id: 'demo_group_id',
              name: AppLocalizations.of(context)!.demoGroup,
              color: '00FF00',
              sharedWith: ['guest'],
            ),
            'isShared': false,
          }
        ];
      }

      final snapshots = FirebaseFirestore.instance
          .collection('groups')
          .where('sharedWith', arrayContains: user.uid)
          .snapshots();
      return snapshots.map((snap) {
        return snap.docs.map((doc) {
          final g = Group.fromJson(doc.id, doc.data());
          return {'group': g, 'isShared': g.sharedWith.length > 1} as Map<String, dynamic>;
        }).toList();
      }).first;
    });
  }

  Future<void> _showEditGroupDialog(Group group) async {
    final nameCtrl = TextEditingController(text: group.name);
    Color selectedColor = Color(int.parse('0xFF${group.color}'));
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (_, setSt) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.editGroup),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context)!.groupName),
                ),
                const SizedBox(height: 10),
                Text(AppLocalizations.of(context)!.groupTagColor),
                const SizedBox(height: 10),
                BlockPicker(
                  pickerColor: selectedColor,
                  onColorChanged: (c) => setSt(() => selectedColor = c),
                  availableColors: const [
                    Colors.blue,
                    Colors.green,
                    Colors.orange,
                    Colors.purple,
                    Colors.red,
                    Colors.teal,
                    Colors.yellow,
                    Colors.pink,
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('groups').doc(group.id).update({
                    'name': nameCtrl.text,
                    'color': selectedColor.value.toRadixString(16).substring(2),
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.groupUpdatedSuccessfully),
                    ),
                  );
                }
              },
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _deleteGroup(Group group) async {
    await FirebaseFirestore.instance.collection('groups').doc(group.id).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.groupDeleted)),
    );
  }

  Color _darken(Color c, [double amt = .2]) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness - amt).clamp(0.0, 1.0)).toColor();
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
  }) {
    final theme = Provider.of<ThemeProvider>(context);
    final color = _darken(theme.primaryColor);
    final fontSizeScale = theme.fontSizeScale;
    final iconStyle = theme.iconStyle;

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon != null
          ? Icon(
        iconStyle == 'filled'
            ? icon
            : icon == Icons.list
            ? Icons.list_outlined
            : icon,
        color: Colors.white,
      )
          : const SizedBox.shrink(),
      label: Text(text, style: TextStyle(fontSize: 16 * fontSizeScale)),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 4,
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.primaryColor.withOpacity(gradientOpacity),
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]!
                  : Colors.grey[200]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _fetchGroups(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(
                  child: Text(
                    l10n.errorFetchingGroups(snap.error.toString()),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium!.color,
                      fontSize: 14 * fontSizeScale,
                    ),
                  ),
                );
              }
              final data = snap.data ?? [];
              if (data.isEmpty) {
                return Center(
                  child: Text(
                    l10n.noGroupsFound,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium!.color,
                      fontSize: 14 * fontSizeScale,
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: data.length,
                itemBuilder: (_, i) {
                  final group = data[i]['group'] as Group;
                  final shared = data[i]['isShared'] as bool;
                  final color = Color(int.parse('0xFF${group.color}'));
                  return Card(
                    color: Theme.of(context).cardColor,
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: color),
                      title: Text(
                        group.name,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16 * fontSizeScale,
                        ),
                      ),
                      subtitle: shared
                          ? Text(
                        l10n.shared,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 14 * fontSizeScale,
                        ),
                      )
                          : null,
                      trailing: widget.isGuest
                          ? null
                          : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              iconStyle == 'filled' ? Icons.person_add : Icons.person_add_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ShareGroupScreen(groupId: group.id),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              iconStyle == 'filled' ? Icons.edit : Icons.edit_outlined,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            onPressed: () => _showEditGroupDialog(group),
                          ),
                          IconButton(
                            icon: Icon(
                              iconStyle == 'filled' ? Icons.delete : Icons.delete_outlined,
                              color: Colors.red,
                            ),
                            onPressed: () => _deleteGroup(group),
                          ),
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GroupDetailScreen(
                            group: group,
                            isGuest: widget.isGuest,
                            isShared: shared,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _buildActionButton(
            text: l10n.viewYourGroups,
            icon: iconStyle == 'filled' ? Icons.list : Icons.list_outlined,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => YourGroupsScreen(isGuest: widget.isGuest)),
            ),
          ),
        ),
      ),
      floatingActionButton: widget.isGuest
          ? null
          : FloatingActionButton(
        backgroundColor: _darken(theme.primaryColor),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CreateGroupScreen(isGuest: widget.isGuest)),
        ),
        child: Icon(iconStyle == 'filled' ? Icons.add : Icons.add_outlined),
      ),
    );
  }
}