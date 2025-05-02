import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';
import 'login.dart';
import 'package:smartpantri/generated/l10n.dart'; // AppLocalizations import

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
          SnackBar(content: Text(AppLocalizations.of(context)!.errorSavingDeviceInfo(e.toString()))),
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
        SnackBar(content: Text(AppLocalizations.of(context)!.userEmailMissing)),
      );
      return;
    }

    print("User is logged in: ${user?.uid}, email: $email");

    if (enable) {
      if (_lastCodeRequestTime != null &&
          DateTime.now().difference(_lastCodeRequestTime!).inSeconds < 60) {
        print("Rate limit: Please wait 60 seconds before requesting a new code.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.wait60SecondsForNewCode)),
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
                SnackBar(content: Text(AppLocalizations.of(context)!.twoFAEnabled)),
              );
            } else {
              print("Invalid verification code received.");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.invalidVerificationCode)),
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
          SnackBar(content: Text(AppLocalizations.of(context)!.errorDuring2FASetup(e.toString()))),
        );
      }
    } else {
      bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.disable2FA),
            content: Text(AppLocalizations.of(context)!.confirmDisable2FA),
            actions: <Widget>[
              TextButton(
                child: Text(AppLocalizations.of(context)!.cancel),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: Text(AppLocalizations.of(context)!.disable, style: const TextStyle(color: Colors.red)),
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
          SnackBar(content: Text(AppLocalizations.of(context)!.twoFADisabled)),
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
          title: Text(AppLocalizations.of(context)!.enterEmailVerificationCode),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.codeExpirationNote),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.sixDigitCodeLabel),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancel),
              onPressed: () {
                Navigator.of(context).pop(null);
              },
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.resendCode),
              onPressed: () async {
                if (_lastCodeRequestTime != null &&
                    DateTime.now().difference(_lastCodeRequestTime!).inSeconds < 60) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.wait60SecondsForNewCode)),
                  );
                  return;
                }

                try {
                  final callable = FirebaseFunctions.instance.httpsCallable('sendMfaCode');
                  await callable.call(<String, dynamic>{'email': email});
                  _lastCodeRequestTime = DateTime.now();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.codeResentSuccessfully)),
                  );
                } on FirebaseFunctionsException catch (e) {
                  String errorMessage;
                  if (e.code == 'internal' &&
                      e.message?.contains('Failed to send email') == true) {
                    errorMessage = AppLocalizations.of(context)!.failedToResendEmail;
                  } else {
                    errorMessage = AppLocalizations.of(context)!.errorResendingCode(e.message ?? 'Unknown error');
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errorMessage)),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.unexpectedErrorResendingCode(e.toString()))),
                  );
                }
              },
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.verify),
              onPressed: () {
                final code = codeController.text.trim();
                if (code.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.pleaseEnterCode)),
                  );
                } else if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.invalidCodeError)),
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
        SnackBar(content: Text(AppLocalizations.of(context)!.noUserLoggedIn)),
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
          SnackBar(content: Text(AppLocalizations.of(context)!.emailOrPasswordEmpty)),
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
        SnackBar(content: Text(AppLocalizations.of(context)!.accountDeleted)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorDeletingAccount(e.toString()))),
      );
    }
  }

  Future<bool?> _showDeleteConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.deleteAccount),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.confirmDeleteAccount),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.enterPasswordToConfirm,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancel),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                if (_passwordController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.pleaseEnterPassword)),
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
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.privacyAndSecurity),
        backgroundColor: themeProvider.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.twoFactorAuthentication),
              value: _twoFactorEnabled,
              onChanged: (value) {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.pleaseLogInToUse2FA)),
                  );
                  return;
                }
                print("2FA Switch toggled: $value");
                _toggleTwoFactorAuthentication(value);
              },
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.loggedInDevices),
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
              title: Text(AppLocalizations.of(context)!.deleteAccount, style: const TextStyle(color: Colors.red)),
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
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.loggedInDevices),
          backgroundColor: themeProvider.primaryColor,
        ),
        body: Center(child: Text(AppLocalizations.of(context)!.userNotLoggedInError)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.loggedInDevices),
        backgroundColor: themeProvider.primaryColor,
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
            return Center(child: Text(AppLocalizations.of(context)!.errorLoadingDevices(snapshot.error.toString())));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text(AppLocalizations.of(context)!.noLoggedInDevicesFound));
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
                    Text(AppLocalizations.of(context)!.osLabel(osVersion)),
                    Text(
                      AppLocalizations.of(context)!.lastLoginLabel(lastLogin.toDate().toString()),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                trailing: TextButton(
                  child: Text(
                    AppLocalizations.of(context)!.signOut,
                    style: const TextStyle(color: Colors.red),
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
                        SnackBar(content: Text(AppLocalizations.of(context)!.deviceSignedOut(deviceName))),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.errorSigningOut(e.toString()))),
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