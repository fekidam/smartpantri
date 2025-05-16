import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Providers/theme_provider.dart';
import 'package:smartpantri/generated/l10n.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ThemeSettingsScreen extends StatelessWidget {
  final Color? groupColor; // Opcionális groupColor paraméter hozzáadása

  const ThemeSettingsScreen({super.key, this.groupColor});

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final isDark = themeProv.isDarkMode;
    final primary = themeProv.primaryColor;
    final useGlobalTheme = themeProv.useGlobalTheme;
    final fontSizeScale = themeProv.fontSizeScale;
    final gradientOpacity = themeProv.gradientOpacity;
    final iconStyle = themeProv.iconStyle;
    final l10n = AppLocalizations.of(context)!;

    // Határozzuk meg az effectiveColor-t a useGlobalTheme alapján
    final effectiveColor = useGlobalTheme ? primary : (groupColor ?? primary);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.themeAndAppearance,
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
        backgroundColor: effectiveColor, // effectiveColor használata
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              effectiveColor.withOpacity(gradientOpacity), // effectiveColor használata
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]!
                  : Colors.grey[200]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: Text(
                l10n.darkMode,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16 * fontSizeScale),
              ),
              activeColor: effectiveColor, // effectiveColor használata
              value: isDark,
              onChanged: (v) {
                themeProv.toggleDarkMode(v);
                themeProv.notifyListeners();
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                l10n.useGlobalTheme,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16 * fontSizeScale),
              ),
              activeColor: effectiveColor, // effectiveColor használata
              value: useGlobalTheme,
              onChanged: (v) {
                themeProv.toggleGlobalTheme(v);
                themeProv.notifyListeners();
              },
            ),
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).cardColor,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(
                  l10n.pickAColor,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16 * fontSizeScale),
                ),
                subtitle: Text(
                  l10n.currentColor,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 14 * fontSizeScale),
                ),
                trailing: CircleAvatar(backgroundColor: primary, radius: 16),
                onTap: () {
                  Color pick = primary;
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: Theme.of(context).cardColor,
                      title: Text(
                        l10n.pickAColor,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16 * fontSizeScale),
                      ),
                      content: SingleChildScrollView(
                        child: BlockPicker(
                          pickerColor: primary,
                          onColorChanged: (c) => pick = c,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            l10n.cancel,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14 * fontSizeScale),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            themeProv.setPrimaryColor(pick);
                            themeProv.notifyListeners();
                            Navigator.pop(context);
                          },
                          child: Text(
                            l10n.save,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14 * fontSizeScale),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).cardColor,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(
                  l10n.fontSize,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16 * fontSizeScale),
                ),
                subtitle: Slider(
                  value: fontSizeScale,
                  min: 0.8,
                  max: 1.2,
                  divisions: 4,
                  label: '${(fontSizeScale * 100).round()}%',
                  onChanged: (v) {
                    themeProv.setFontSizeScale(v);
                    themeProv.notifyListeners();
                  },
                ),
                trailing: Text(
                  '${(fontSizeScale * 100).round()}%',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14 * fontSizeScale),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).cardColor,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(
                  l10n.gradientOpacity,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16 * fontSizeScale),
                ),
                subtitle: Slider(
                  value: gradientOpacity,
                  min: 0.1,
                  max: 0.5,
                  divisions: 4,
                  label: '${(gradientOpacity * 100).round()}%',
                  onChanged: (v) {
                    themeProv.setGradientOpacity(v);
                    themeProv.notifyListeners();
                  },
                ),
                trailing: Text(
                  '${(gradientOpacity * 100).round()}%',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14 * fontSizeScale),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).cardColor,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(
                  l10n.iconStyle,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16 * fontSizeScale),
                ),
                subtitle: DropdownButton<String>(
                  value: iconStyle,
                  items: ['filled', 'outlined'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: TextStyle(fontSize: 14 * fontSizeScale),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    themeProv.setIconStyle(v ?? 'filled');
                    themeProv.notifyListeners();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}