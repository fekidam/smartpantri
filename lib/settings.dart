import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool openLastUsedAtLaunch = true;
  bool keepScreenOn = false;

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            user != null
                ? ListTile(
                    leading: CircleAvatar(
                      child: Text(user.email![0].toUpperCase()),
                    ),
                    title: Text(user.email!),
                  )
                : Container(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Appearance'),
              onTap: () {
                // Handle appearance settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              onTap: () {
                // Handle notifications settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Manage categories'),
              onTap: () {
                // Handle manage categories
              },
            ),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Report a bug'),
              onTap: () {
                // Handle report a bug
              },
            ),
            SwitchListTile(
              title: const Text('Open last used at launch'),
              value: openLastUsedAtLaunch,
              onChanged: (bool value) {
                setState(() {
                  openLastUsedAtLaunch = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Keep the screen turned on'),
              value: keepScreenOn,
              onChanged: (bool value) {
                setState(() {
                  keepScreenOn = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
