import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart'; // Provider import hozzáadása
import '../services/theme_provider.dart'; // ThemeProvider import hozzáadása

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  _NotificationsSettingsScreenState createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationSettingsScreen> {
  bool notificationsEnabled = true;
  bool messageNotifications = true;
  bool updateNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      messageNotifications = prefs.getBool('messageNotifications') ?? true;
      updateNotifications = prefs.getBool('updateNotifications') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', notificationsEnabled);
    await prefs.setBool('messageNotifications', messageNotifications);
    await prefs.setBool('updateNotifications', updateNotifications);
  }

  void _configureFCM() {
    if (!notificationsEnabled) {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {});
      return;
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        String? messageType = message.data['type'];

        if (messageType == 'update' && !updateNotifications) {
          return;
        }

        if (messageType == 'message' && !messageNotifications) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${message.notification!.title}: ${message.notification!.body}',
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ThemeProvider lekérése
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: themeProvider.primaryColor, // AppBar színe a ThemeProvider-ből
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            SwitchListTile(
              title: const Text('Enable Notifications'),
              value: notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  notificationsEnabled = value;
                  if (!notificationsEnabled) {
                    messageNotifications = false;
                    updateNotifications = false;
                  }
                });
                _saveSettings();
                _configureFCM();
              },
            ),
            SwitchListTile(
              title: const Text('Message Notifications'),
              value: messageNotifications,
              onChanged: notificationsEnabled
                  ? (value) {
                setState(() {
                  messageNotifications = value;
                });
                _saveSettings();
                _configureFCM();
              }
                  : null,
            ),
            SwitchListTile(
              title: const Text('Notifications on Updates'),
              value: updateNotifications,
              onChanged: notificationsEnabled
                  ? (value) {
                setState(() {
                  updateNotifications = value;
                });
                _saveSettings();
                _configureFCM();
              }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}