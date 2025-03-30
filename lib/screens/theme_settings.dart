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
        return Scaffold(
          appBar: AppBar(title: const Text('Theme and Appearance')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleDarkMode(value);
                  },
                ),
                ListTile(
                  title: const Text('Pick a Color'),
                  subtitle: Text(
                    'Current color',
                    style: TextStyle(color: themeProvider.primaryColor),
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
                              onPressed: () {
                                themeProvider.setPrimaryColor(selectedColor);
                                Navigator.of(context).pop();
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