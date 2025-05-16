import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import '../../Providers/theme_provider.dart';
import 'package:smartpantri/generated/l10n.dart';

class NotificationSettingsScreen extends StatefulWidget {
  final Color groupColor; // Hozzáadva a groupColor paraméter

  const NotificationSettingsScreen({
    super.key,
    required this.groupColor, // Kötelező paraméter
  });

  @override
  _NotificationsSettingsScreenState createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _enabled = true;
  bool _messageNotifs = true;
  bool _updateNotifs = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enabled = prefs.getBool('notificationsEnabled') ?? true;
      _messageNotifs = prefs.getBool('messageNotifications') ?? true;
      _updateNotifs = prefs.getBool('updateNotifications') ?? false;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', _enabled);
    await prefs.setBool('messageNotifications', _messageNotifs);
    await prefs.setBool('updateNotifications', _updateNotifs);
  }

  void _configureFCM() {
    FirebaseMessaging.onMessage.listen((message) {
      if (!_enabled) return;
      final type = message.data['type'];
      if (type == 'message' && !_messageNotifs) return;
      if (type == 'update' && !_updateNotifs) return;
      if (message.notification != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${message.notification!.title}: ${message.notification!.body}'),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final effectiveColor = theme.useGlobalTheme ? theme.primaryColor : widget.groupColor;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.notifications,
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
        backgroundColor: effectiveColor, // effectiveColor használata
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              effectiveColor.withOpacity(0.2), // effectiveColor használata
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]!
                  : Colors.grey[200]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: Text(l10n.enableNotifications, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              value: _enabled,
              activeColor: widget.groupColor, // groupColor használata
              onChanged: (v) {
                setState(() {
                  _enabled = v;
                  if (!v) {
                    _messageNotifs = false;
                    _updateNotifs = false;
                  }
                });
                _savePrefs();
                _configureFCM();
              },
            ),
            SwitchListTile(
              title: Text(l10n.messageNotifications, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              value: _messageNotifs,
              activeColor: widget.groupColor, // groupColor használata
              onChanged: _enabled
                  ? (v) {
                setState(() => _messageNotifs = v);
                _savePrefs();
                _configureFCM();
              }
                  : null,
            ),
            SwitchListTile(
              title: Text(l10n.updateNotifications, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              value: _updateNotifs,
              activeColor: widget.groupColor, // groupColor használata
              onChanged: _enabled
                  ? (v) {
                setState(() => _updateNotifs = v);
                _savePrefs();
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