import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../generated/l10n.dart';
import '../../models/data.dart';
import '../../Providers/theme_provider.dart';
import 'group_detail.dart';

class CreateGroupScreen extends StatefulWidget {
  final bool isGuest;

  const CreateGroupScreen({Key? key, required this.isGuest}) : super(key: key);

  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _nameController = TextEditingController();
  Color _selectedColor = Colors.blue;
  final List<Color> _colorOptions = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.yellow,
    Colors.pink,
  ];
  bool _loading = false;

  Color _darken(Color c, [double amt = .2]) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness - amt).clamp(0.0, 1.0)).toColor();
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback? onPressed,
  }) {
    final theme = Provider.of<ThemeProvider>(context);
    final color = _darken(theme.primaryColor);
    final fontSizeScale = theme.fontSizeScale;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 4,
      ),
      child: Text(text, style: TextStyle(fontSize: 16 * fontSizeScale)),
    );
  }

  Future<void> _saveGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.userNotLoggedIn)),
      );
      setState(() => _loading = false);
      return;
    }
    final hex = _selectedColor.value.toRadixString(16).substring(2);
    final groupData = {
      'name': name,
      'color': hex,
      'userId': user.uid,
      'sharedWith': [user.uid],
    };
    try {
      final docRef = await FirebaseFirestore.instance.collection('groups').add(groupData);
      final groupId = docRef.id;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GroupDetailScreen(
            group: Group(
              id: groupId,
              name: name,
              color: hex,
              userId: user.uid,
              sharedWith: [user.uid],
            ),
            isGuest: widget.isGuest,
            isShared: false,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.failedToCreateGroup)),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final fontSizeScale = theme.fontSizeScale;
    final gradientOpacity = theme.gradientOpacity;
    final iconStyle = theme.iconStyle;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            iconStyle == 'filled' ? Icons.arrow_back : Icons.arrow_back_outlined,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.createNewGroup,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20 * fontSizeScale,
          ),
        ),
        centerTitle: true,
      ),
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
          child: widget.isGuest
              ? Center(
            child: Text(
              l10n.guestModeRestriction,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16 * fontSizeScale,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          )
              : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.groupName,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16 * fontSizeScale,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.selectColor,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16 * fontSizeScale,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  children: _colorOptions.map((c) {
                    final selected = c == _selectedColor;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = c),
                      child: Container(
                        padding: selected ? const EdgeInsets.all(3) : null,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(backgroundColor: c, radius: 20),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                _buildActionButton(
                  text: l10n.addGroup,
                  onPressed: _loading ? null : _saveGroup,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}