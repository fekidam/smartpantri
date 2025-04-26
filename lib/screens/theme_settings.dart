import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../services/theme_provider.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  _ThemeSettingsScreenState createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Ellenőrizzük, hogy vendég módban vagyunk-e
        bool isGuest = FirebaseAuth.instance.currentUser == null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Theme and Appearance'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                if (isGuest)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'Note: Guest mode settings are saved locally on this device.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  value: themeProvider.isDarkMode,
                  onChanged: (value) async {
                    try {
                      await themeProvider.toggleDarkMode(value);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error saving dark mode: $e')),
                      );
                    }
                  },
                ),
                ListTile(
                  title: const Text('Pick a Color'),
                  subtitle: Text(
                    'Current color',
                    style: TextStyle(color: themeProvider.primaryColor),
                  ),
                  trailing: CircleAvatar(
                    backgroundColor: themeProvider.primaryColor,
                    radius: 16,
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        Color selectedColor = themeProvider.primaryColor;
                        return AlertDialog(
                          title: const Text('Pick a Color'),
                          content: SingleChildScrollView(
                            child: BlockPicker(
                              pickerColor: themeProvider.primaryColor,
                              onColorChanged: (color) {
                                selectedColor = color;
                              },
                              availableColors: const [
                                Colors.blue,
                                Colors.green,
                                Colors.red,
                                Colors.purple,
                                Colors.orange,
                                Colors.teal,
                                Colors.yellow,
                                Colors.pink,
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                try {
                                  await themeProvider.setPrimaryColor(selectedColor);
                                  Navigator.of(context).pop();
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error saving color: $e')),
                                  );
                                }
                              },
                              child: const Text('Save'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}