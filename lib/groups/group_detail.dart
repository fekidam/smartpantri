import 'package:flutter/material.dart';
import 'package:smartpantri/models/data.dart';
import 'package:smartpantri/screens/notifications.dart';
import 'package:smartpantri/screens/chat_screen.dart';
import 'package:smartpantri/screens/recipe_suggestions.dart';
import 'package:smartpantri/screens/settings.dart';
import '../screens/homescreen.dart';
import 'package:smartpantri/screens/ai_chat_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final Group group;
  final bool isGuest;
  final bool isShared;

  const GroupDetailScreen({
    super.key,
    required this.group,
    required this.isGuest,
    required this.isShared,
  });

  @override
  _GroupDetailScreenState createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;
  late final List<BottomNavigationBarItem> _navItems;

  @override
  void initState() {
    super.initState();
    _pages = [
      GroupHomeScreen(groupId: widget.group.id, isGuest: widget.isGuest),
      RecipeSuggestionsScreen(isGuest: widget.isGuest),
      widget.isShared && !widget.isGuest
          ? GroupChatScreen(groupId: widget.group.id, isGuest: widget.isGuest)
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
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        backgroundColor: Color(int.parse('0xFF${widget.group.color}')),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (widget.isGuest && (index == 2 || (widget.isShared && index == 3))) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('This feature requires login')),
            );
            return;
          }
          _onItemTapped(index);
        },
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        backgroundColor: Colors.black,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}