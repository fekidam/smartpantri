import 'package:flutter/material.dart';
import 'package:smartpantri/groups/group_home.dart';
import 'package:smartpantri/models/data.dart';
import 'package:smartpantri/screens/chat_screen.dart';
import 'package:smartpantri/screens/notifications.dart';
import 'package:smartpantri/screens/recipe_suggestions.dart';
import 'package:smartpantri/screens/settings.dart';
class GroupDetailScreen extends StatefulWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  _GroupDetailScreenState createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      GroupHomeScreen(groupId: widget.group.id),
      const RecipeSuggestionsScreen(),
      const ChatScreen(),
      const NotificationsScreen(),
      const SettingsScreen(),
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.green),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu, color: Colors.green),
            label: 'Recipes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat, color: Colors.green),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications, color: Colors.green),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: Colors.green),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        backgroundColor: Colors.black,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
