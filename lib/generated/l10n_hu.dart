// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get appTitle => 'OkosKamra';

  @override
  String get languageAndRegion => 'Nyelv és Régió';

  @override
  String get selectLanguage => 'Nyelv kiválasztása';

  @override
  String get selectRegion => 'Régió kiválasztása';

  @override
  String get english => 'Angol';

  @override
  String get hungarian => 'Magyar';

  @override
  String get usa => 'USA';

  @override
  String get hungary => 'Magyarország';

  @override
  String get recipeSuggestions => 'Receptajánlatok';

  @override
  String get noRecipesAvailable => 'Nincsenek elérhető receptek';

  @override
  String get viewDetails => 'Részletek megtekintése';

  @override
  String get failedToLoadImage => 'Nem sikerült betölteni a recept képet. Kérlek, ellenőrizd a kapcsolatodat.';

  @override
  String failedToLoadGroup(String error) {
    return 'Hiba a csoport betöltésekor: $error';
  }
}
