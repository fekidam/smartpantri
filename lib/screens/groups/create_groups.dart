import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../generated/l10n.dart';
import '../../models/data.dart';
import '../../Providers/theme_provider.dart';
import 'group_detail.dart';

// Új csoport létrehozására szolgáló képernyő
class CreateGroupScreen extends StatefulWidget {
  final bool isGuest; // Megmutatja, hogy vendég módban van-e a felhasználó

  const CreateGroupScreen({Key? key, required this.isGuest}) : super(key: key);

  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _nameController = TextEditingController(); // Csoportnév vezérlő
  Color _selectedColor = Colors.blue; // Alapértelmezett szín
  final List<Color> _colorOptions = [ // Választható színek
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.yellow,
    Colors.pink,
  ];
  bool _loading = false; // Betöltési állapot

  // Szín sötétítése a gombhoz
  Color _darken(Color c, [double amt = .2]) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness - amt).clamp(0.0, 1.0)).toColor();
  }

  // Gomb felépítése
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

  // Csoport mentése Firestore-ba
  Future<void> _saveGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;

    // Ha nincs bejelentkezve a felhasználó
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.userNotLoggedIn)),
      );
      setState(() => _loading = false);
      return;
    }

    // Színt hexadecimális formátumba alakítom
    final hex = _selectedColor.value.toRadixString(16).substring(2);

    // Csoport adatainak összeállítása
    final groupData = {
      'name': name,
      'color': hex,
      'userId': user.uid,
      'sharedWith': [user.uid],
    };

    try {
      // Új dokumentum létrehozása a "groups" kollekcióban
      final docRef = await FirebaseFirestore.instance.collection('groups').add(groupData);
      final groupId = docRef.id;

      // Navigálás a részletező oldalra
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
      // Hiba esetén visszajelzés
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
          // Vendég módban csak figyelmeztetés jelenik meg
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
          // Normál esetben a csoportlétrehozó űrlap
              : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // Csoportnév beírása
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.groupName,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16 * fontSizeScale,
                  ),
                ),

                const SizedBox(height: 24),

                // Színválasztó felirat
                Text(
                  l10n.selectColor,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16 * fontSizeScale,
                  ),
                ),
                const SizedBox(height: 12),

                // Színválasztó körök
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
                            color: selected
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(backgroundColor: c, radius: 20),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),

                // Csoport létrehozása gomb
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
