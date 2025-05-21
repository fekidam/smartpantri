import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import '../../Providers/theme_provider.dart';
import 'package:smartpantri/generated/l10n.dart';

// Értesítési beállítások képernyője
class NotificationSettingsScreen extends StatefulWidget {
  final Color groupColor; // Csoport színe

  const NotificationSettingsScreen({
    super.key,
    required this.groupColor, // Kötelező paraméter
  });

  @override
  _NotificationsSettingsScreenState createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _enabled = true; // Értesítések engedélyezése
  bool _messageNotifs = true; // Üzenet értesítések
  bool _updateNotifs = false; // Frissítési értesítések

  @override
  void initState() {
    super.initState();
    _loadPrefs(); // Beállítások betöltése
  }

  // Elmentett beállítások betöltése SharedPreferences-ből
  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enabled = prefs.getBool('notificationsEnabled') ?? true;
      _messageNotifs = prefs.getBool('messageNotifications') ?? true;
      _updateNotifs = prefs.getBool('updateNotifications') ?? false;
    });
  }

  // Beállítások mentése SharedPreferences-be
  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', _enabled);
    await prefs.setBool('messageNotifications', _messageNotifs);
    await prefs.setBool('updateNotifications', _updateNotifs);
  }

  // FCM (Firebase Cloud Messaging) konfigurálása
  void _configureFCM() {
    FirebaseMessaging.onMessage.listen((message) {
      if (!_enabled) return; // Ha az értesítések ki vannak kapcsolva, kilép
      final type = message.data['type'];
      if (type == 'message' && !_messageNotifs) return; // Üzenet értesítés szűrése
      if (type == 'update' && !_updateNotifs) return; // Frissítési értesítés szűrése
      if (message.notification != null) {
        // Értesítés megjelenítése snackbar formájában
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
    final theme = Provider.of<ThemeProvider>(context); // Témaszolgáltató provider
    // Határozza meg a használni kívánt színt a globális téma vagy csoportszín alapján
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
              title: Text(l10n.enableNotifications,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              value: _enabled,
              activeColor: widget.groupColor, // groupColor használata
              onChanged: (v) {
                setState(() {
                  _enabled = v;
                  if (!v) {
                    _messageNotifs = false; // Üzenet értesítések kikapcsolása
                    _updateNotifs = false; // Frissítési értesítések kikapcsolása
                  }
                });
                _savePrefs(); // Beállítások mentése
                _configureFCM(); // FCM újrakonfigurálása
              },
            ),
            SwitchListTile(
              title: Text(l10n.messageNotifications,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              value: _messageNotifs,
              activeColor: widget.groupColor, // groupColor használata
              onChanged: _enabled
                  ? (v) {
                setState(() => _messageNotifs = v); // Üzenet értesítések állítása
                _savePrefs(); // Beállítások mentése
                _configureFCM(); // FCM újrakonfigurálása
              }
                  : null,
            ),
            SwitchListTile(
              title: Text(l10n.updateNotifications,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              value: _updateNotifs,
              activeColor: widget.groupColor,
              onChanged: _enabled
                  ? (v) {
                setState(() => _updateNotifs = v); // Frissítési értesítések állítása
                _savePrefs(); // Beállítások mentése
                _configureFCM(); // FCM újrakonfigurálása
              }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}