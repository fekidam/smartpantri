import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../Providers/theme_provider.dart';
import 'package:smartpantri/generated/l10n.dart';

class NotificationsScreen extends StatefulWidget {
  final String groupId;
  final bool isGuest;
  final bool fromGroupScreen;
  final Color groupColor;

  const NotificationsScreen({
    super.key,
    required this.groupId,
    required this.isGuest,
    this.fromGroupScreen = false,
    this.groupColor = const Color(0xFF4CAF50),
  });

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _sendNotification(String messageKey) async {
    final user = _auth.currentUser;
    if (user == null || widget.groupId.isEmpty) return;

    final message = _getMessage(messageKey);
    await FirebaseFirestore.instance.collection('notifications').add({
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'sender': user.email,
      'groupId': widget.groupId,
    });

    final groupDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .get();
    if (!groupDoc.exists) return;

    final sharedWith = List<String>.from(groupDoc['sharedWith'] ?? []);
    for (final uid in sharedWith) {
      if (uid == user.uid) continue;
      final tokensSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('tokens')
          .get();
      for (final tok in tokensSnap.docs) {
        final fcm = tok['token'] as String? ?? '';
        final ok = await _sendPushNotification(fcm, message);
        if (!ok && fcm.startsWith('APA91')) {
          // Empty block - no action defined
        }
      }
    }
  }

  String _getMessage(String messageKey) {
    final l10n = AppLocalizations.of(context)!;
    switch (messageKey) {
      case 'iAmGoingShoppingToday':
        return l10n.iAmGoingShoppingToday;
      case 'whatsMissingFromShoppingList':
        return l10n.whatsMissingFromShoppingList;
      case 'whosGoingShoppingToday':
        return l10n.whosGoingShoppingToday;
      default:
        return l10n.noMessage;
    }
  }

  Future<bool> _sendPushNotification(String token, String message) async {
    try {
      final saJson = await rootBundle.loadString('assets/service_account_key.json');
      final Map<String, dynamic> saMap = jsonDecode(saJson);
      final creds = ServiceAccountCredentials.fromJson(saMap);
      final client = await clientViaServiceAccount(
        creds,
        ['https://www.googleapis.com/auth/cloud-platform'],
      );

      final projectId = saMap['project_id'] as String;
      final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send');
      final payload = {
        'message': {
          'token': token,
          'notification': {
            'title': AppLocalizations.of(context)!.notifications,
            'body': message,
          },
          'data': {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'screen': 'notifications',
            'groupId': widget.groupId,
          },
        },
      };
      final resp = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      client.close();
      return resp.statusCode == 200;
    } catch (e) {
      print('Error sending push notification: $e');
      return false;
    }
  }

  void _showNotificationOptions() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final fontSizeScale = theme.fontSizeScale;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOptionTile(Icons.shopping_cart, l10n.goingShopping, 'iAmGoingShoppingToday', fontSizeScale),
            _buildOptionTile(Icons.list, l10n.whatsMissing, 'whatsMissingFromShoppingList', fontSizeScale),
            _buildOptionTile(Icons.person, l10n.whosGoingShopping, 'whosGoingShoppingToday', fontSizeScale),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String title, String key, double fontSizeScale) {
    final effectiveColor = widget.fromGroupScreen ? widget.groupColor : Provider.of<ThemeProvider>(context).primaryColor;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: effectiveColor,
        child: Icon(icon, color: Theme.of(context).colorScheme.onPrimary),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 14 * fontSizeScale,
        ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        _sendNotification(key);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final fontSizeScale = theme.fontSizeScale;
    final gradientOpacity = theme.gradientOpacity;
    final effectiveColor = widget.fromGroupScreen ? widget.groupColor : theme.primaryColor;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: effectiveColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            l10n.notifications,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 20 * fontSizeScale.toDouble(),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: effectiveColor,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              effectiveColor.withOpacity(gradientOpacity),
              Theme.of(context).brightness == Brightness.dark ? Colors.grey[900]! : Colors.grey[200]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: widget.isGuest
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.notificationsNotAvailableInGuestMode,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16 * fontSizeScale,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        )
            : StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('groupId', isEqualTo: widget.groupId)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: effectiveColor));
            }
            if (snap.hasError) {
              return Center(
                child: Text(
                  l10n.errorLoadingNotifications(snap.error.toString()),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 14 * fontSizeScale,
                  ),
                ),
              );
            }
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(
                child: Text(
                  l10n.noNotificationsFound,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 16 * fontSizeScale,
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final data = docs[i].data()! as Map<String, dynamic>;
                final msg = data['message'] as String? ?? '';
                final sender = data['sender'] as String? ?? '';
                final ts = (data['timestamp'] as Timestamp?)?.toDate();
                final time = ts != null
                    ? DateFormat('yyyy/MM/dd HH:mm').format(ts)
                    : l10n.noTimestampAvailable;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  color: Theme.of(context).cardColor,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Icon(
                      Icons.notifications,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    title: Text(
                      msg,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14 * fontSizeScale,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${l10n.sender(sender)} • $time',
                        style: TextStyle(
                          fontSize: 12 * fontSizeScale,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: widget.isGuest
          ? null
          : FloatingActionButton(
        backgroundColor: effectiveColor,
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
        onPressed: _showNotificationOptions,
      ),
    );
  }
}