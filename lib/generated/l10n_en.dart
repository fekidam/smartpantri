// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SmartPantry';

  @override
  String get languageAndRegion => 'Language and Region';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get selectRegion => 'Select Region';

  @override
  String get english => 'English';

  @override
  String get hungarian => 'Hungarian';

  @override
  String get usa => 'USA';

  @override
  String get hungary => 'Hungary';

  @override
  String get recipeSuggestions => 'Recipe Suggestions';

  @override
  String get noRecipesAvailable => 'No recipes available';

  @override
  String get viewDetails => 'View Details';

  @override
  String get failedToLoadImage => 'Failed to load recipe image. Please check your connection.';

  @override
  String failedToLoadGroup(String error) {
    return 'Error loading group: $error';
  }
}
