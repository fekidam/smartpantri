import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartpantri/generated/l10n.dart';
import 'package:smartpantri/Providers/language_provider.dart';
import '../../Providers/theme_provider.dart';

class LanguageRegionSettingsScreen extends StatelessWidget {
  final Color groupColor; // Hozzáadva a groupColor paraméter

  const LanguageRegionSettingsScreen({
    super.key,
    required this.groupColor, // Kötelező paraméter
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final effectiveColor = themeProvider.useGlobalTheme ? themeProvider.primaryColor : groupColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.languageAndRegion),
        backgroundColor: effectiveColor, // effectiveColor használata
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(
              title: Text(AppLocalizations.of(context)!.selectLanguage),
              subtitle: Text(
                languageProvider.locale.languageCode == 'hu'
                    ? AppLocalizations.of(context)!.hungarian
                    : AppLocalizations.of(context)!.english,
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(AppLocalizations.of(context)!.selectLanguage),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: Text(AppLocalizations.of(context)!.english),
                          onTap: () {
                            languageProvider.setLocale(const Locale('en'));
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: Text(AppLocalizations.of(context)!.hungarian),
                          onTap: () {
                            languageProvider.setLocale(const Locale('hu'));
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.selectRegion),
              subtitle: Text(
                languageProvider.locale.languageCode == 'hu'
                    ? AppLocalizations.of(context)!.hungary
                    : AppLocalizations.of(context)!.usa,
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(AppLocalizations.of(context)!.selectRegion),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: Text(AppLocalizations.of(context)!.usa),
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: Text(AppLocalizations.of(context)!.hungary),
                          onTap: () {
                            Navigator.pop(context);
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