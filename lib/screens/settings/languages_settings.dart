import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartpantri/generated/l10n.dart';
import 'package:smartpantri/Providers/language_provider.dart';
import '../../Providers/theme_provider.dart';

// Nyelv- és régióbeállítások képernyője
class LanguageRegionSettingsScreen extends StatelessWidget {
  final Color groupColor; // Csoport színe

  const LanguageRegionSettingsScreen({
    super.key,
    required this.groupColor, // Kötelező paraméter
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context); // Nyelvszolgáltató provider
    final themeProvider = Provider.of<ThemeProvider>(context); // Témaszolgáltató provider
    // Határozza meg a használni kívánt színt a globális téma vagy csoportszín alapján
    final effectiveColor = themeProvider.useGlobalTheme ? themeProvider.primaryColor : groupColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.languageAndRegion), // AppBar cím
        backgroundColor: effectiveColor, // effectiveColor használata
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        // Nyelv- és régióbeállítások listázása
        child: ListView(
          children: [
            ListTile(
              title: Text(AppLocalizations.of(context)!.selectLanguage), // Nyelv kiválasztása cím
              subtitle: Text(
                // Aktuális nyelv megjelenítése
                languageProvider.locale.languageCode == 'hu'
                    ? AppLocalizations.of(context)!.hungarian
                    : AppLocalizations.of(context)!.english,
              ),
              onTap: () {
                // Nyelv kiválasztó dialógus megjelenítése
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(AppLocalizations.of(context)!.selectLanguage),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: Text(AppLocalizations.of(context)!.english), // Angol nyelv kiválasztása
                          onTap: () {
                            languageProvider.setLocale(const Locale('en')); // Angol nyelv beállítása
                            Navigator.pop(context); // Dialógus bezárása
                          },
                        ),
                        ListTile(
                          title: Text(AppLocalizations.of(context)!.hungarian), // Magyar nyelv kiválasztása
                          onTap: () {
                            languageProvider.setLocale(const Locale('hu')); // Magyar nyelv beállítása
                            Navigator.pop(context); // Dialógus bezárása
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.selectRegion), // Régió kiválasztása cím
              subtitle: Text(
                // Aktuális régió megjelenítése
                languageProvider.locale.languageCode == 'hu'
                    ? AppLocalizations.of(context)!.hungary
                    : AppLocalizations.of(context)!.usa,
              ),
              onTap: () {
                // Régió kiválasztó dialógus megjelenítése
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(AppLocalizations.of(context)!.selectRegion),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: Text(AppLocalizations.of(context)!.usa), // USA régió
                          onTap: () {
                            Navigator.pop(context); // Dialógus bezárása
                          },
                        ),
                        ListTile(
                          title: Text(AppLocalizations.of(context)!.hungary), // Magyarország régió
                          onTap: () {
                            Navigator.pop(context); // Dialógus bezárása
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}