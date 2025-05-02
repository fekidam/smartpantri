import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../services/theme_provider.dart';
import 'package:smartpantri/generated/l10n.dart'; // AppLocalizations import

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
        bool isGuest = FirebaseAuth.instance.currentUser == null;

        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.themeAndAppearance),
            backgroundColor: themeProvider.primaryColor,
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                if (isGuest)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      AppLocalizations.of(context)!.guestModeSettingsNote,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.darkMode),
                  value: themeProvider.isDarkMode,
                  onChanged: (value) async {
                    try {
                      await themeProvider.toggleDarkMode(value);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.errorSavingDarkMode(e.toString()))),
                      );
                    }
                  },
                ),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.pickAColor),
                  subtitle: Text(
                    AppLocalizations.of(context)!.currentColor,
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
                          title: Text(AppLocalizations.of(context)!.pickAColor),
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
                              child: Text(AppLocalizations.of(context)!.cancel),
                            ),
                            TextButton(
                              onPressed: () async {
                                try {
                                  await themeProvider.setPrimaryColor(selectedColor);
                                  Navigator.of(context).pop();
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(AppLocalizations.of(context)!.errorSavingColor(e.toString()))),
                                  );
                                }
                              },
                              child: Text(AppLocalizations.of(context)!.save),
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