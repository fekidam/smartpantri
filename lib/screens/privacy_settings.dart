import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

import 'login.dart'; // Cseréld ki a saját bejelentkező képernyőd útvonalára

class PrivacySecuritySettingsScreen extends StatefulWidget {
  const PrivacySecuritySettingsScreen({super.key});

  @override
  _PrivacySecuritySettingsScreenState createState() => _PrivacySecuritySettingsScreenState();
}

class _PrivacySecuritySettingsScreenState extends State<PrivacySecuritySettingsScreen> {
  bool _twoFactorEnabled = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken == null) {
          throw Exception('Failed to retrieve FCM token.');
        }

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
          'token': fcmToken,
        });

        print('Device info saved: $deviceName, $deviceModel, $osVersion, $fcmToken');
      } catch (e) {
        print('Error saving device info: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving device info: $e')),
        );
      }
    }
  }

  Future<void> _toggleTwoFactorAuthentication(bool value) async {
    if (value) {
      await _showPhoneNumberDialog();
    } else {
      try {
        final user = _auth.currentUser;
        if (user != null) {
          final enrolledFactors = await user.multiFactor.getEnrolledFactors();
          final phoneFactor = enrolledFactors.firstWhere(
                (factor) => factor is PhoneMultiFactorInfo,
            orElse: () => throw Exception('No phone factor found.'),
          );
          await user.multiFactor.unenroll(factorUid: phoneFactor.uid);
          setState(() {
            _twoFactorEnabled = false;
          });
          await _saveSettings();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Two Factor Authentication disabled.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error disabling 2FA: $e')),
        );
      }
    }
  }

  Future<void> _showPhoneNumberDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enable Two Factor Authentication'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please enter your phone number to enable 2FA.'),
              TextField(
                controller: _phoneNumberController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (e.g., +1234567890)',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Verify'),
              onPressed: () async {
                String phoneNumber = _phoneNumberController.text.trim();
                if (phoneNumber.isEmpty || !phoneNumber.startsWith('+')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid phone number (e.g., +1234567890)')),
                  );
                  return;
                }

                Navigator.of(context).pop();

                try {
                  await _auth.currentUser?.multiFactor.getSession().then((session) async {
                    await _auth.verifyPhoneNumber(
                      multiFactorSession: session,
                      phoneNumber: phoneNumber,
                      verificationCompleted: (PhoneAuthCredential credential) async {
                        await _auth.currentUser?.multiFactor.enroll(
                          PhoneMultiFactorGenerator.getAssertion(credential),
                        );
                        setState(() {
                          _twoFactorEnabled = true;
                        });
                        await _saveSettings();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Two Factor Authentication enabled.')),
                        );
                      },
                      verificationFailed: (FirebaseAuthException e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Verification failed: $e')),
                        );
                      },
                      codeSent: (String verificationId, int? resendToken) async {
                        String? smsCode = await _showSmsCodeDialog();
                        if (smsCode != null) {
                          PhoneAuthCredential credential = PhoneAuthProvider.credential(
                            verificationId: verificationId,
                            smsCode: smsCode,
                          );
                          await _auth.currentUser?.multiFactor.enroll(
                            PhoneMultiFactorGenerator.getAssertion(credential),
                          );
                          setState(() {
                            _twoFactorEnabled = true;
                          });
                          await _saveSettings();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Two Factor Authentication enabled.')),
                          );
                        }
                      },
                      codeAutoRetrievalTimeout: (String verificationId) {},
                    );
                  });
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error enabling 2FA: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<String?> _showSmsCodeDialog() async {
    final TextEditingController smsCodeController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter SMS Code'),
          content: TextField(
            controller: smsCodeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'SMS Code'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Verify'),
              onPressed: () {
                String smsCode = smsCodeController.text.trim();
                if (smsCode.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter the SMS code.')),
                  );
                  return;
                }
                Navigator.of(context).pop(smsCode);
              },
            ),
          ],
        );
      },
    );
  }

  // Delete Account logika
  Future<void> _deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user is currently logged in.')),
      );
      return;
    }

    // 1. Kérjünk megerősítést és jelszót a felhasználótól
    bool? confirmed = await _showDeleteConfirmationDialog();
    if (confirmed != true) {
      return;
    }

    try {
      // 2. Újra hitelesítjük a felhasználót a jelszóval
      String email = user.email ?? '';
      String password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email or password cannot be empty.')),
        );
        return;
      }

      // Újra hitelesítés
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // 3. Töröljük a Firestore-ban tárolt adatokat
      await _deleteUserData(user.uid);

      // 4. Töröljük a felhasználó fiókját a Firebase Authenticationből
      await user.delete();

      // 5. Kijelentkeztetjük a felhasználót
      await _auth.signOut();

      // 6. Navigáljunk vissza a bejelentkező képernyőre
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()), // Cseréld ki a saját bejelentkező képernyődre
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
    // Töröljük a sessions dokumentumot és az összes algyűjteményt (pl. devices)
    final sessionsRef = _firestore.collection('sessions').doc(uid);
    final devicesRef = sessionsRef.collection('devices');

    // Töröljük a devices algyűjtemény összes dokumentumát
    final devicesSnapshot = await devicesRef.get();
    for (var doc in devicesSnapshot.docs) {
      await doc.reference.delete();
    }

    // Töröljük a sessions dokumentumot
    await sessionsRef.delete();

    // Ha van users gyűjteményed, akkor azt is törölheted
    // Példa: await _firestore.collection('users').doc(uid).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy and Security')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            SwitchListTile(
              title: const Text('Two Factor Authentication (2FA)'),
              value: _twoFactorEnabled,
              onChanged: (value) {
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
              onTap: () {
                _deleteAccount();
              },
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
    final messaging = FirebaseMessaging.instance;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Logged In Devices')),
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
              String token = device['token'] ?? '';
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
                trailing: FutureBuilder<String?>(
                  future: messaging.getToken(),
                  builder: (context, tokenSnapshot) {
                    if (!tokenSnapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    bool isCurrentDevice = tokenSnapshot.data == token;

                    return isCurrentDevice
                        ? const Text(
                      'This Device',
                      style: TextStyle(color: Colors.grey),
                    )
                        : TextButton(
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
                    );
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