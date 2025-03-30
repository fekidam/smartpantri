import 'package:flutter/material.dart';

class LanguageRegionSettingsScreen extends StatelessWidget{
  const LanguageRegionSettingsScreen({super.key});

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: const Text('Language and Region')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(
              title: const Text('Select Language'),
              subtitle: const Text('English'),
              onTap: (){
                //TODO:
              },
            ),
            ListTile(
              title: const Text('Select Region'),
              subtitle: const Text('USA'),
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