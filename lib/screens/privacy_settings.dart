import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:provider/provider.dart'; // Provider import hozzáadása
import '../services/theme_provider.dart'; // ThemeProvider import hozzáadása
import 'login.dart';

class PrivacySecuritySettingsScreen extends StatefulWidget {
  const PrivacySecuritySettingsScreen({super.key});

  @override
  _PrivacySecuritySettingsScreenState createState() => _PrivacySecuritySettingsScreenState();
}

class _PrivacySecuritySettingsScreenState extends State<PrivacySecuritySettingsScreen> {
  bool _twoFactorEnabled = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _passwordController = TextEditingController();
  DateTime? _lastCodeRequestTime;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _saveDeviceInfo();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _twoFactorEnabled = prefs.getBool('twoFactorEnabled') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('twoFactorEnabled', _twoFactorEnabled);
  }

  Future<void> _saveDeviceInfo() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        String deviceName;
        String? deviceModel;
        String? osVersion;

        if (Platform.isAndroid) {
          AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
          deviceName = 'Android Device';
          deviceModel = androidInfo.model;
          osVersion = 'Android ${androidInfo.version.release}';
        } else if (Platform.isIOS) {
          IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
          deviceName = 'iOS Device';
          deviceModel = iosInfo.utsname.machine;
          osVersion = 'iOS ${iosInfo.systemVersion}';
        } else {
          deviceName = 'Unknown Device';
          deviceModel = 'Unknown';
          osVersion = 'Unknown';
        }

        await _firestore
            .collection('sessions')
            .doc(user.uid)
            .collection('devices')
            .add({
          'deviceName': deviceName,
          'deviceModel': deviceModel,
          'osVersion': osVersion,
          'lastLogin': Timestamp.now(),
        });
      } catch (e) {
        print('Error saving device info: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving device info: $e')),
        );
      }
    }
  }

  Future<void> _toggleTwoFactorAuthentication(bool enable) async {
    final user = _auth.currentUser;
    final email = user?.email;

    if (email == null) {
      print("User email is missing.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User email is missing.')),
      );
      return;
    }

    print("User is logged in: ${user?.uid}, email: $email");

    if (enable) {
      if (_lastCodeRequestTime != null &&
          DateTime.now().difference(_lastCodeRequestTime!).inSeconds < 60) {
        print("Rate limit: Please wait 60 seconds before requesting a new code.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please wait 60 seconds before requesting a new code.')),
        );
        return;
      }

      try {
        print("Calling sendMfaCode Cloud Function via HTTP...");
        final url = 'https://us-central1-smartpantri-dc717.cloudfunctions.net/sendMfaCode';
        print("Request URL: $url");
        print("Request headers: {'Content-Type': 'application/json'}");
        print("Request body: ${jsonEncode({'data': {'email': email}})}");

        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'data': {
              'email': email,
            },
          }),
        );

        print("Response status: ${response.statusCode}");
        print("Response body: ${response.body}");

        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          print("sendMfaCode response: $result");
          _lastCodeRequestTime = DateTime.now();

          String? code = await _showEmailCodeDialog(email: email);
          if (code == null) {
            print("User cancelled code entry.");
            return;
          }

          print("Calling verifyMfaCode Cloud Function via HTTP...");
          final verifyResponse = await http.post(
            Uri.parse('https://us-central1-smartpantri-dc717.cloudfunctions.net/verifyMfaCode'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'data': {
                'code': code,
              },
            }),
          );

          print("verifyMfaCode response status: ${verifyResponse.statusCode}");
          print("verifyMfaCode response body: ${verifyResponse.body}");

          if (verifyResponse.statusCode == 200) {
            final verifyResult = jsonDecode(verifyResponse.body);
            print("verifyMfaCode response: $verifyResult");

            if (verifyResult['result']['success'] == true) {
              setState(() => _twoFactorEnabled = true);
              await _saveSettings();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('2FA enabled via email.')),
              );
            } else {
              print("Invalid verification code received.");
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invalid verification code.')),
              );
            }
          } else {
            print("verifyMfaCode failed with status: ${verifyResponse.statusCode}, body: ${verifyResponse.body}");
            throw Exception('Failed to verify MFA code: ${verifyResponse.body}');
          }
        } else {
          print("sendMfaCode failed with status: ${response.statusCode}, body: ${response.body}");
          throw Exception('Failed to send MFA code: ${response.body}');
        }
      } catch (e) {
        print("Error during 2FA setup: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during 2FA setup: $e')),
        );
      }
    } else {
      bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Disable 2FA'),
            content: const Text('Are you sure you want to disable Two Factor Authentication?'),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: const Text('Disable', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        setState(() => _twoFactorEnabled = false);
        await _saveSettings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('2FA disabled.')),
        );
      }
    }
  }

  Future<String?> _showEmailCodeDialog({required String email}) async {
    final TextEditingController codeController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Email Verification Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('You have 10 minutes to enter the code before it expires.'),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '6-digit code'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(null);
              },
            ),
            TextButton(
              child: const Text('Resend Code'),
              onPressed: () async {
                if (_lastCodeRequestTime != null &&
                    DateTime.now().difference(_lastCodeRequestTime!).inSeconds < 60) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please wait 60 seconds before requesting a new code.')),
                  );
                  return;
                }

                try {
                  final callable = FirebaseFunctions.instance.httpsCallable('sendMfaCode');
                  await callable.call(<String, dynamic>{'email': email});
                  _lastCodeRequestTime = DateTime.now();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code resent successfully.')),
                  );
                } on FirebaseFunctionsException catch (e) {
                  String errorMessage;
                  if (e.code == 'internal' &&
                      e.message?.contains('Failed to send email') == true) {
                    errorMessage = 'Failed to resend email. Please try again later.';
                  } else {
                    errorMessage = 'Error resending code: ${e.message}';
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errorMessage)),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Unexpected error resending code: $e')),
                  );
                }
              },
            ),
            TextButton(
              child: const Text('Verify'),
              onPressed: () {
                final code = codeController.text.trim();
                if (code.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter the code.')),
                  );
                } else if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid 6-digit code.')),
                  );
                } else {
                  Navigator.of(context).pop(code);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user is currently logged in.')),
      );
      return;
    }

    bool? confirmed = await _showDeleteConfirmationDialog();
    if (confirmed != true) return;

    try {
      String email = user.email ?? '';
      String password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email or password cannot be empty.')),
        );
        return;
      }

      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      await _deleteUserData(user.uid);

      await user.delete();
      await _auth.signOut();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account successfully deleted.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting account: $e')),
      );
    }
  }

  Future<bool?> _showDeleteConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Are you sure you want to delete your account? This action cannot be undone.'),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Enter your password to confirm',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                if (_passwordController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your password.')),
                  );
                  return;
                }
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteUserData(String uid) async {
    final tokensRef = _firestore.collection('users').doc(uid).collection('tokens');
    final tokensSnapshot = await tokensRef.get();
    for (var doc in tokensSnapshot.docs) {
      await doc.reference.delete();
    }

    final sessionsRef = _firestore.collection('sessions').doc(uid);
    final devicesRef = sessionsRef.collection('devices');
    final devicesSnapshot = await devicesRef.get();
    for (var doc in devicesSnapshot.docs) {
      await doc.reference.delete();
    }
    await sessionsRef.delete();

    await _firestore.collection('users').doc(uid).delete();
  }

  @override
  Widget build(BuildContext context) {
    // ThemeProvider lekérése
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy and Security'),
        backgroundColor: themeProvider.primaryColor, // AppBar színe a ThemeProvider-ből
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            SwitchListTile(
              title: const Text('Two Factor Authentication (2FA)'),
              value: _twoFactorEnabled,
              onChanged: (value) {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please log in to use 2FA')),
                  );
                  return;
                }
                print("2FA Switch toggled: $value");
                _toggleTwoFactorAuthentication(value);
              },
            ),
            ListTile(
              title: const Text('Logged In Devices'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoggedInDevicesScreen(),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
              onTap: _deleteAccount,
            ),
          ],
        ),
      ),
    );
  }
}

class LoggedInDevicesScreen extends StatelessWidget {
  const LoggedInDevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final firestore = FirebaseFirestore.instance;
    // ThemeProvider lekérése
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Logged In Devices'),
          backgroundColor: themeProvider.primaryColor, // AppBar színe a ThemeProvider-ből
        ),
        body: const Center(child: Text('User not logged in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logged In Devices'),
        backgroundColor: themeProvider.primaryColor, // AppBar színe a ThemeProvider-ből
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('sessions')
            .doc(user.uid)
            .collection('devices')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No logged in devices found.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var device = snapshot.data!.docs[index];
              String deviceName = device['deviceName'] ?? 'Unknown Device';
              String deviceModel = device['deviceModel'] ?? 'Unknown';
              String osVersion = device['osVersion'] ?? 'Unknown';
              Timestamp lastLogin = device['lastLogin'] ?? Timestamp.now();
              String deviceId = device.id;

              return ListTile(
                title: Text('$deviceName ($deviceModel)'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('OS: $osVersion'),
                    Text(
                      'Last Login: ${lastLogin.toDate().toString()}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                trailing: TextButton(
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () async {
                    try {
                      await firestore
                          .collection('sessions')
                          .doc(user.uid)
                          .collection('devices')
                          .doc(deviceId)
                          .delete();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$deviceName signed out.')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error signing out: $e')),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}