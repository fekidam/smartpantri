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
import 'group_home.dart';

class GroupDetailScreen extends StatefulWidget {
  final Group group;
  final bool isGuest;
  final bool isShared;
  final Map? arguments;

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
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Naplózás a debugoláshoz
    print('Group color from Firestore: ${widget.group.color}');
    final groupColor = _hexToColor(widget.group.color); // Biztosítjuk, hogy mindig érvényes Color-t kapunk
    _pages = [
      GroupHomeScreen(groupId: widget.group.id, isGuest: widget.isGuest, groupColor: groupColor),
      RecipeSuggestionsScreen(
        fromGroupScreen: true,
        isGuest: widget.isGuest,
        groupColor: groupColor,
      ),
      widget.isShared
          ? GroupAndAIChatScreen(
        groupId: widget.group.id,
        isGuest: widget.isGuest,
        isShared: widget.isShared,
        groupColor: groupColor,
      )
          : AIChatScreen(
        fromGroupScreen: true,
        groupColor: groupColor,
      ),
      if (widget.isShared && !widget.isGuest)
        NotificationsScreen(
          groupId: widget.group.id,
          isGuest: widget.isGuest,
          fromGroupScreen: true,
          groupColor: groupColor,
        ),
      SettingsScreen(
        isGuest: widget.isGuest,
        isShared: widget.isShared,
        groupColor: groupColor, // Átadjuk a groupColor-t
      ),
    ];
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

  Color _hexToColor(String hex) {
    // Már garantált, hogy hex nem null, de ellenőrizzük a hosszt
    var c = hex.replaceAll('#', '').trim().toUpperCase();
    if (c.length != 6) {
      print('A szín hossza nem 6 karakter: $hex, alapértelmezett szín használata: 4CAF50');
      return const Color(0xFF4CAF50); // Alapértelmezett zöld szín
    }
    c = 'FF$c'; // Hozzáadjuk az alfa csatornát
    try {
      return Color(int.parse('0x$c'));
    } catch (e) {
      print('Hiba a szín konverzió során: $hex - $e, alapértelmezett szín használata: 4CAF50');
      return const Color(0xFF4CAF50); // Alapértelmezett zöld szín
    }
  }

  Color _darken(Color color, [double amount = .2]) {
    final hsl = HSLColor.fromColor(color);
    final l = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(l).toColor();
  }

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
    final effectiveColor = theme.useGlobalTheme ? theme.primaryColor : groupColor;
    final navBg = _darken(effectiveColor);
    final fontSizeScale = theme.fontSizeScale;
    final gradientOpacity = theme.gradientOpacity;
    final iconStyle = theme.iconStyle;

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
            child: _pages[_selectedIndex],
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