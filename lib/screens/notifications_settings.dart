import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget{
  const NotificationSettingsScreen({super.key});

  @override
  _NotificationsSettingsScreenState createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationSettingsScreen>{
  bool notificationsEnabled = true;
  bool messageNotifications= true;
  bool updateNotifications = false;

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            SwitchListTile(
                title: const Text('Enable Notifications'),
                value: notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    notificationsEnabled = true;
                    // TODO:
                  });
                },
            ),
            SwitchListTile(
                title: const Text('Notifications on Updates'),
                value: updateNotifications,
                onChanged: (value){
                  setState(() {
                    //TODO:
                  });
                }
            ),
          ],
        ),
      ),
    );
  }
}