import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartpantri/models/data.dart';
import 'package:smartpantri/screens/notifications/notifications.dart';
import 'package:smartpantri/screens/recipes/recipe_suggestions.dart';
import 'package:smartpantri/screens/settings/settings.dart';
import 'package:smartpantri/screens/chats/group_and_ai_chat.dart';
import 'package:smartpantri/screens/chats/ai_chat.dart';
import 'package:smartpantri/Providers/theme_provider.dart';
import '../../generated/l10n.dart';
import '../homescreen/homescreen.dart';

// Fő képernyő, ami egy csoporton belül megjeleníti az aloldalakat (home, receptek, chat, stb.)
class GroupDetailScreen extends StatefulWidget {
  final Group group;              // Csoport objektum (id, név, szín, stb.)
  final bool isGuest;             // Vendég módban van-e a felhasználó
  final bool isShared;            // Meg van-e osztva a csoport másokkal
  final Map? arguments;           // Navigációs argumentum

  const GroupDetailScreen({
    Key? key,
    required this.group,
    required this.isGuest,
    required this.isShared,
    this.arguments,
  }) : super(key: key);

  @override
  _GroupDetailScreenState createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  int _selectedIndex = 0;         // Aktív tab indexe
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    // Debug: megjelenítjük a csoport színét
    print('Group color from Firestore: ${widget.group.color}');
    final groupColor = _hexToColor(widget.group.color);

    // Az aloldalak definiálása
    _pages = [
      GroupHomeScreen(groupId: widget.group.id, isGuest: widget.isGuest, groupColor: groupColor),
      RecipeSuggestionsScreen(fromGroupScreen: true, isGuest: widget.isGuest, groupColor: groupColor),
      widget.isShared
          ? GroupAndAIChatScreen(
        groupId: widget.group.id,
        isGuest: widget.isGuest,
        isShared: widget.isShared,
        groupColor: groupColor,
      )
          : AIChatScreen(fromGroupScreen: true, groupColor: groupColor),
      if (widget.isShared && !widget.isGuest)
        NotificationsScreen(
          groupId: widget.group.id,
          isGuest: widget.isGuest,
          fromGroupScreen: true,
          groupColor: groupColor,
        ),
      SettingsScreen(isGuest: widget.isGuest, isShared: widget.isShared, groupColor: groupColor),
    ];

    // Navigációs paraméter alapján tab kiválasztása
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = widget.arguments;
      if (args != null && args.containsKey('selectedIndex')) {
        final idx = args['selectedIndex'] as int;
        if (idx >= 0 && idx < _pages.length) {
          setState(() => _selectedIndex = idx);
        }
      }
    });
  }

  // HEX kód konvertálása Color objektummá
  Color _hexToColor(String hex) {
    var c = hex.replaceAll('#', '').trim().toUpperCase();
    if (c.length != 6) {
      print('Hibás színkód, visszaadjuk az alapértelmezett zöldet');
      return const Color(0xFF4CAF50);
    }
    c = 'FF$c'; // hozzáadjuk az alfát
    try {
      return Color(int.parse('0x$c'));
    } catch (e) {
      print('Színkonverziós hiba: $e');
      return const Color(0xFF4CAF50);
    }
  }

  // Szín sötétítése navigációs háttérhez
  Color _darken(Color color, [double amount = .2]) {
    final hsl = HSLColor.fromColor(color);
    final l = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(l).toColor();
  }

  // Tab kiválasztása – vendég mód tiltja a chatet és értesítéseket
  void _onItemTapped(int index) {
    if (widget.isGuest && (index == 2 || (widget.isShared && index == 3))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.featureRequiresLogin)),
      );
      return;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Provider.of<ThemeProvider>(context);
    final groupColor = _hexToColor(widget.group.color);

    // Globális téma vagy csoportszín használata
    final effectiveColor = theme.useGlobalTheme ? theme.primaryColor : groupColor;
    final navBg = _darken(effectiveColor);
    final fontSizeScale = theme.fontSizeScale;
    final gradientOpacity = theme.gradientOpacity;
    final iconStyle = theme.iconStyle;

    // Navigációs menüpontok (feltételesen az értesítések)
    final navItems = [
      BottomNavigationBarItem(
        icon: Icon(iconStyle == 'filled' ? Icons.home : Icons.home_outlined),
        label: l10n.home,
      ),
      BottomNavigationBarItem(
        icon: Icon(iconStyle == 'filled' ? Icons.restaurant_menu : Icons.restaurant_menu_outlined),
        label: l10n.recipes,
      ),
      BottomNavigationBarItem(
        icon: Icon(iconStyle == 'filled' ? Icons.chat : Icons.chat_outlined),
        label: l10n.chat,
      ),
      if (widget.isShared)
        BottomNavigationBarItem(
          icon: Icon(iconStyle == 'filled' ? Icons.notifications : Icons.notifications_outlined),
          label: l10n.notifications,
        ),
      BottomNavigationBarItem(
        icon: Icon(iconStyle == 'filled' ? Icons.person : Icons.person_outlined),
        label: l10n.profile,
      ),
    ];

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.group.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20 * fontSizeScale,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            backgroundColor: effectiveColor,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            centerTitle: true,
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  effectiveColor.withOpacity(gradientOpacity),
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[900]!
                      : Colors.grey[200]!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: _pages[_selectedIndex], // Az aktuális aloldal megjelenítése
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: navItems,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: navBg,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
            showUnselectedLabels: true,
            selectedLabelStyle: TextStyle(fontSize: 12 * fontSizeScale),
            unselectedLabelStyle: TextStyle(fontSize: 12 * fontSizeScale),
            type: BottomNavigationBarType.fixed,
            elevation: 8,
          ),
        );
      },
    );
  }
}
