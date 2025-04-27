import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartpantri/models/data.dart';
import 'package:smartpantri/screens/notifications.dart';
import 'package:smartpantri/screens/recipe_suggestions.dart';
import 'package:smartpantri/screens/settings.dart';
import 'package:smartpantri/screens/group_and_ai_chat_screen.dart';
import 'package:smartpantri/screens/ai_chat_screen.dart';
import 'package:smartpantri/services/theme_provider.dart';
import '../screens/homescreen.dart';
import 'group_home.dart';

class GroupDetailScreen extends StatefulWidget {
  final Group group;
  final bool isGuest;
  final bool isShared;
  final Map<String, dynamic>? arguments;

  const GroupDetailScreen({
    super.key,
    required this.group,
    required this.isGuest,
    required this.isShared,
    this.arguments,
  });

  @override
  _GroupDetailScreenState createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;
  late final List<BottomNavigationBarItem> _navItems;

  // Helper method to convert hex string to Color
  Color _hexToColor(String hexColor) {
    try {
      // Remove any leading '#' if present and ensure the format is correct
      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor'; // Add alpha channel if not present
      }
      return Color(int.parse('0x$hexColor'));
    } catch (e) {
      print('Error parsing color: $hexColor, defaulting to blue');
      return Colors.blue; // Fallback color in case of parsing error
    }
  }

  @override
  void initState() {
    super.initState();
    // Convert the hex string to a Color object
    final groupColor = _hexToColor(widget.group.color);

    _pages = [
      GroupHomeScreen(groupId: widget.group.id, isGuest: widget.isGuest),
      RecipeSuggestionsScreen(isGuest: widget.isGuest),
      widget.isShared
          ? GroupAndAIChatScreen(
        groupId: widget.group.id,
        isGuest: widget.isGuest,
        isShared: widget.isShared,
        groupColor: groupColor, // Pass the converted Color object
      )
          : const AIChatScreen(),
      if (widget.isShared && !widget.isGuest)
        NotificationsScreen(groupId: widget.group.id, isGuest: widget.isGuest),
      SettingsScreen(isGuest: widget.isGuest, isShared: widget.isShared),
    ];

    _navItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home, color: Colors.green),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.restaurant_menu, color: Colors.green),
        label: 'Recipes',
      ),
      BottomNavigationBarItem(
        icon: Icon(
          Icons.chat,
          color: widget.isGuest ? Colors.grey : Colors.green,
        ),
        label: 'Chat',
      ),
      if (widget.isShared)
        BottomNavigationBarItem(
          icon: Icon(
            Icons.notifications,
            color: widget.isGuest ? Colors.grey : Colors.green,
          ),
          label: 'Notifications',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person, color: Colors.green),
        label: 'Profile',
      ),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.arguments != null && widget.arguments!.containsKey('selectedIndex')) {
        final index = widget.arguments!['selectedIndex'] as int;
        if (index >= 0 && index < _pages.length) {
          setState(() {
            _selectedIndex = index;
          });
        } else {
          print('Invalid selectedIndex: $index, defaulting to 0');
        }
      }
    });
  }

  void _onItemTapped(int index) {
    if (widget.isGuest && (index == 2 || (widget.isShared && index == 3))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This feature requires login')),
      );
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.group.name),
            backgroundColor: _hexToColor(widget.group.color), // Use group's color
            foregroundColor: Colors.white,
            automaticallyImplyLeading: true, // Back arrow to HomeScreen
            centerTitle: true,
          ),
          body: _pages[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            items: _navItems,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
            backgroundColor: Colors.black,
            type: BottomNavigationBarType.fixed,
          ),
        );
      },
    );
  }
}