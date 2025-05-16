import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Providers/theme_provider.dart';
import '../welcomescreen/login.dart';
import 'package:smartpantri/generated/l10n.dart';

class PrivacySecuritySettingsScreen extends StatefulWidget {
  final Color groupColor; // Hozzáadva a groupColor paraméter

  const PrivacySecuritySettingsScreen({
    super.key,
    required this.groupColor, // Kötelező paraméter
  });

  @override
  _PrivacySecuritySettingsScreenState createState() => _PrivacySecuritySettingsScreenState();
}

class _PrivacySecuritySettingsScreenState extends State<PrivacySecuritySettingsScreen> {
  bool _twoFA = false;
  DateTime? _lastCodeTime;
  final _auth = FirebaseAuth.instance;
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTwoFA();
    _saveDeviceInfo();
  }

  Future<void> _loadTwoFA() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _twoFA = prefs.getBool('twoFactorEnabled') ?? false;
    });
  }

  Future<void> _saveTwoFA(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('twoFactorEnabled', v);
  }

  Future<void> _saveDeviceInfo() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final deviceInfo = DeviceInfoPlugin();
    String name, model, os;
    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      name = 'Android Device';
      model = info.model ?? 'Unknown';
      os = 'Android ${info.version.release}';
    } else {
      final info = await deviceInfo.iosInfo;
      name = 'iOS Device';
      model = info.utsname.machine ?? 'Unknown';
      os = 'iOS ${info.systemVersion}';
    }
    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(user.uid)
        .collection('devices')
        .add({
      'deviceName': name,
      'deviceModel': model,
      'osVersion': os,
      'lastLogin': Timestamp.now(),
    });
  }

  Future<void> _toggle2FA(bool enable) async {
    final user = _auth.currentUser;
    final l10n = AppLocalizations.of(context)!;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseLogInToUse2FA)),
      );
      return;
    }
    final now = DateTime.now();
    if (enable && _lastCodeTime != null && now.difference(_lastCodeTime!).inSeconds < 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.wait60SecondsForNewCode)),
      );
      return;
    }

    if (enable) {
      try {
        final sendUrl = 'https://us-central1-smartpantri-dc717.cloudfunctions.net/sendMfaCode';
        final sendResp = await http.post(
          Uri.parse(sendUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'data': {'email': user.email}}),
        );
        _lastCodeTime = now;
        if (sendResp.statusCode == 200) {
          final code = await _showCodeDialog(email: user.email!);
          if (code == null) return;
          final verifyResp = await http.post(
            Uri.parse('https://us-central1-smartpantri-dc717.cloudfunctions.net/verifyMfaCode'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'data': {'code': code}}),
          );
          final ok = verifyResp.statusCode == 200 && jsonDecode(verifyResp.body)['result']['success'];
          setState(() => _twoFA = ok);
          await _saveTwoFA(ok);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ok ? l10n.twoFAEnabled : l10n.invalidVerificationCode)),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorDuring2FASetup(e.toString()))),
        );
      }
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(l10n.disable2FA, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          content: Text(l10n.confirmDisable2FA, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.disable, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        setState(() => _twoFA = false);
        await _saveTwoFA(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.twoFADisabled)),
        );
      }
    }
  }

  Future<String?> _showCodeDialog({required String email}) {
    final ctrl = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(l10n.enterEmailVerificationCode, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.sixDigitCodeLabel,
            labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
            filled: true,
            fillColor: Theme.of(context).cardColor,
          ),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text(l10n.cancel, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: Text(l10n.verify, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final u = _auth.currentUser;
    final l10n = AppLocalizations.of(context)!;
    if (u == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noUserLoggedIn)),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(l10n.deleteAccount, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.confirmDeleteAccount, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.enterPasswordToConfirm,
                labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          ),
          TextButton(
            onPressed: () {
              if (_passwordController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.pleaseEnterPassword)),
                );
              } else {
                Navigator.pop(context, true);
              }
            },
            child: Text(l10n.deleteAccount, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final cred = EmailAuthProvider.credential(email: u.email!, password: _passwordController.text.trim());
      await u.reauthenticateWithCredential(cred);

      final fs = FirebaseFirestore.instance;
      final tokensSnap = await fs.collection('users').doc(u.uid).collection('tokens').get();
      for (var d in tokensSnap.docs) {
        await d.reference.delete();
      }
      final devSnap = await fs.collection('sessions').doc(u.uid).collection('devices').get();
      for (var d in devSnap.docs) {
        await d.reference.delete();
      }
      await fs.collection('sessions').doc(u.uid).delete();
      await fs.collection('users').doc(u.uid).delete();

      await u.delete();
      await _auth.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.accountDeleted)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorDeletingAccount(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final effectiveColor = theme.useGlobalTheme ? theme.primaryColor : widget.groupColor;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.privacyAndSecurity,
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
        backgroundColor: effectiveColor, // effectiveColor használata
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              effectiveColor.withOpacity(0.2), // effectiveColor használata
              Theme.of(context).brightness == Brightness.dark ? Colors.grey[900]! : Colors.grey[200]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: Text(l10n.twoFactorAuthentication, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              activeColor: widget.groupColor, // groupColor használata
              value: _twoFA,
              onChanged: _toggle2FA,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.loggedInDevices,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: Theme.of(context).textTheme.titleLarge?.fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sessions')
                  .doc(_auth.currentUser?.uid)
                  .collection('devices')
                  .orderBy('lastLogin', descending: true)
                  .snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Text(l10n.noLoggedInDevicesFound,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                  );
                }
                return Column(
                  children: docs.map((doc) {
                    final data = doc.data()! as Map<String, dynamic>;
                    final name = data['deviceName'] ?? '';
                    final model = data['deviceModel'] ?? '';
                    final os = data['osVersion'] ?? '';
                    final ts = (data['lastLogin'] as Timestamp).toDate();
                    final time = DateFormat('yyyy/MM/dd HH:mm').format(ts);
                    return Card(
                      color: Theme.of(context).cardColor,
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text('$name ($model)', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                        subtitle: Text(
                          '${l10n.osLabel(os)} • $time',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                        ),
                        trailing: TextButton(
                          child: Text(l10n.signOut, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('sessions')
                                .doc(_auth.currentUser!.uid)
                                .collection('devices')
                                .doc(doc.id)
                                .delete();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.deviceSignedOut(name))),
                            );
                          },
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            Card(
              color: Theme.of(context).cardColor,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.error),
                title: Text(l10n.deleteAccount, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: _deleteAccount,
              ),
            ),
          ],
        ),
      ),
    );
  }
}