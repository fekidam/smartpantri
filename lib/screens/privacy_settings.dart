import 'package:flutter/material.dart';

class PrivacySecuritySettingsScreen extends StatelessWidget{
  const PrivacySecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy and Security')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            SwitchListTile(
                title: const Text('Two Factor Authentication (2FA)'),
                value: false,
                onChanged: (value){
                 //TODO:
                },
            ),
            ListTile(
              title: const Text('Logged In Devices'),
              onTap: () {
                //TODO:
              },
            ),
            ListTile(
              title: const Text('Delete Account'),
              onTap: (){
                //TODO:
              },
            )
          ],
        ),
      ),
    );
  }
}