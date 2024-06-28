import 'package:flutter/material.dart';
import 'recipe_suggestions.dart';
import 'chat_screen.dart';
import 'notifications.dart';
import 'settings.dart';

class HomeScreen extends StatefulWidget {
  final bool isGuest;

  const HomeScreen({Key? key, this.isGuest = false}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _pages = <Widget>[
      HomeContent(isGuest: widget.isGuest),
      const RecipeSuggestionsScreen(),
      const ChatScreen(),
      const NotificationsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Recipes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  final bool isGuest;

  const HomeContent({Key? key, required this.isGuest}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: const Text('Shopping Lists'),
          onTap: () {
            Navigator.pushNamed(context, '/shopping-lists');
          },
        ),
        ListTile(
          title: const Text('Expenses'),
          onTap: () {
            Navigator.pushNamed(context, '/expenses');
          },
        ),
        ListTile(
          title: const Text('What\'s in the Fridge'),
          onTap: () {
            Navigator.pushNamed(context, '/fridge-items');
          },
        ),
      ],
    );
  }
}
