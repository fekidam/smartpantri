import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'l10n_en.dart';
import 'l10n_hu.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hu')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'SmartPantri'**
  String get appTitle;

  /// No description provided for @languageAndRegion.
  ///
  /// In en, this message translates to:
  /// **'Language and Region'**
  String get languageAndRegion;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @selectRegion.
  ///
  /// In en, this message translates to:
  /// **'Select Region'**
  String get selectRegion;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hungarian.
  ///
  /// In en, this message translates to:
  /// **'Hungarian'**
  String get hungarian;

  /// No description provided for @usa.
  ///
  /// In en, this message translates to:
  /// **'USA'**
  String get usa;

  /// No description provided for @hungary.
  ///
  /// In en, this message translates to:
  /// **'Hungary'**
  String get hungary;

  /// No description provided for @recipeSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Recipe Suggestions'**
  String get recipeSuggestions;

  /// No description provided for @noRecipesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No recipes available'**
  String get noRecipesAvailable;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @failedToLoadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to load recipe image. Please check your connection.'**
  String get failedToLoadImage;

  /// Error message when group loading fails
  ///
  /// In en, this message translates to:
  /// **'Error loading group: {error}'**
  String failedToLoadGroup(String error);

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logIn;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuest;

  /// No description provided for @continuingAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continuing as Guest'**
  String get continuingAsGuest;

  /// No description provided for @googleSignInCancelled.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in cancelled.'**
  String get googleSignInCancelled;

  /// Error message for Google sign-in failure
  ///
  /// In en, this message translates to:
  /// **'Google sign-in error: {error}'**
  String googleSignInError(String error);

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @pleaseFillInBothFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in both fields!'**
  String get pleaseFillInBothFields;

  /// No description provided for @pleaseVerifyYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email to log in.'**
  String get pleaseVerifyYourEmail;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found.'**
  String get userNotFound;

  /// No description provided for @wrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Invalid password.'**
  String get wrongPassword;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address.'**
  String get invalidEmail;

  /// Error message for login failure
  ///
  /// In en, this message translates to:
  /// **'Login error: {error}'**
  String loginError(String error);

  /// No description provided for @dontHaveAnAccountRegister.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get dontHaveAnAccountRegister;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @selectBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Select Birth Date'**
  String get selectBirthDate;

  /// No description provided for @firstNameRequired.
  ///
  /// In en, this message translates to:
  /// **'First name is required.'**
  String get firstNameRequired;

  /// No description provided for @lastNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Last name is required.'**
  String get lastNameRequired;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required.'**
  String get emailRequired;

  /// No description provided for @invalidEmailFormat.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get invalidEmailFormat;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required.'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get passwordTooShort;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password.'**
  String get confirmPasswordRequired;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @emailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already in use.'**
  String get emailAlreadyInUse;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak.'**
  String get weakPassword;

  /// Error message when registration fails due to an unexpected error.
  ///
  /// In en, this message translates to:
  /// **'Registration failed due to an unexpected error.'**
  String get registrationFailed;

  /// No description provided for @registrationError.
  ///
  /// In en, this message translates to:
  /// **'Error during registration.'**
  String get registrationError;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred.'**
  String get unknownError;

  /// No description provided for @verifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get verifyEmail;

  /// No description provided for @verificationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'A verification email has been sent to your email address.'**
  String get verificationEmailSent;

  /// No description provided for @iHaveVerifiedMyEmail.
  ///
  /// In en, this message translates to:
  /// **'I have verified my email'**
  String get iHaveVerifiedMyEmail;

  /// No description provided for @pleaseVerifyYourEmailFirst.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email first.'**
  String get pleaseVerifyYourEmailFirst;

  /// No description provided for @noUserFound.
  ///
  /// In en, this message translates to:
  /// **'No user found.'**
  String get noUserFound;

  /// Error message for verification email sending failure
  ///
  /// In en, this message translates to:
  /// **'Error sending verification email: {error}'**
  String errorSendingVerificationEmail(String error);

  /// No description provided for @yourGroups.
  ///
  /// In en, this message translates to:
  /// **'Your Groups'**
  String get yourGroups;

  /// No description provided for @demoGroup.
  ///
  /// In en, this message translates to:
  /// **'Demo Group'**
  String get demoGroup;

  /// No description provided for @noGroupsFound.
  ///
  /// In en, this message translates to:
  /// **'No groups found'**
  String get noGroupsFound;

  /// No description provided for @shared.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get shared;

  /// No description provided for @editGroup.
  ///
  /// In en, this message translates to:
  /// **'Edit Group'**
  String get editGroup;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupName;

  /// No description provided for @groupTagColor.
  ///
  /// In en, this message translates to:
  /// **'Group Tag Color'**
  String get groupTagColor;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @groupUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Group updated successfully'**
  String get groupUpdatedSuccessfully;

  /// No description provided for @groupDeleted.
  ///
  /// In en, this message translates to:
  /// **'Group deleted'**
  String get groupDeleted;

  /// Error message for group fetching failure
  ///
  /// In en, this message translates to:
  /// **'Error fetching groups: {error}'**
  String errorFetchingGroups(String error);

  /// No description provided for @viewYourGroups.
  ///
  /// In en, this message translates to:
  /// **'Consolidated List'**
  String get viewYourGroups;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @recipes.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get recipes;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @featureRequiresLogin.
  ///
  /// In en, this message translates to:
  /// **'This feature requires login'**
  String get featureRequiresLogin;

  /// No description provided for @createNewGroup.
  ///
  /// In en, this message translates to:
  /// **'Create New Group'**
  String get createNewGroup;

  /// No description provided for @selectColor.
  ///
  /// In en, this message translates to:
  /// **'Select Color'**
  String get selectColor;

  /// No description provided for @addGroup.
  ///
  /// In en, this message translates to:
  /// **'Add Group'**
  String get addGroup;

  /// No description provided for @pleaseEnterGroupName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a group name.'**
  String get pleaseEnterGroupName;

  /// No description provided for @userNotLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'User is not logged in'**
  String get userNotLoggedIn;

  /// No description provided for @failedToCreateGroup.
  ///
  /// In en, this message translates to:
  /// **'Failed to create group. Please try again.'**
  String get failedToCreateGroup;

  /// No description provided for @guestModeRestriction.
  ///
  /// In en, this message translates to:
  /// **'Group creation is not available in guest mode. Please log in to use this feature.'**
  String get guestModeRestriction;

  /// No description provided for @shareGroup.
  ///
  /// In en, this message translates to:
  /// **'Share Group'**
  String get shareGroup;

  /// No description provided for @enterEmailToShareWith.
  ///
  /// In en, this message translates to:
  /// **'Enter email to share with'**
  String get enterEmailToShareWith;

  /// No description provided for @pleaseEnterEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter an email address.'**
  String get pleaseEnterEmailAddress;

  /// No description provided for @groupSharedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Group shared successfully! The user has been notified.'**
  String get groupSharedSuccessfully;

  /// Error message for group sharing failure
  ///
  /// In en, this message translates to:
  /// **'Error sharing group: {error}'**
  String errorSharingGroup(String error);

  /// No description provided for @aggregatedShoppingList.
  ///
  /// In en, this message translates to:
  /// **'Aggregated Shopping List'**
  String get aggregatedShoppingList;

  /// No description provided for @noItemsInConsolidatedList.
  ///
  /// In en, this message translates to:
  /// **'No items in consolidated list.'**
  String get noItemsInConsolidatedList;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityLabel;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceLabel;

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitLabel;

  /// No description provided for @unknownItem.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownItem;

  /// Title for the item edit dialog
  ///
  /// In en, this message translates to:
  /// **'Edit: {itemName}'**
  String editItem(String itemName);

  /// No description provided for @currencySymbol.
  ///
  /// In en, this message translates to:
  /// **'\$'**
  String get currencySymbol;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @expenseTracker.
  ///
  /// In en, this message translates to:
  /// **'Expense Tracker'**
  String get expenseTracker;

  /// No description provided for @whatsInTheFridge.
  ///
  /// In en, this message translates to:
  /// **'What\'s in the Fridge?'**
  String get whatsInTheFridge;

  /// No description provided for @shoppingList.
  ///
  /// In en, this message translates to:
  /// **'Shopping List'**
  String get shoppingList;

  /// No description provided for @monthlySummary.
  ///
  /// In en, this message translates to:
  /// **'Monthly Summary'**
  String get monthlySummary;

  /// No description provided for @totalExpense.
  ///
  /// In en, this message translates to:
  /// **'Total Expense'**
  String get totalExpense;

  /// No description provided for @byUsers.
  ///
  /// In en, this message translates to:
  /// **'By Users:'**
  String get byUsers;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @noExpensesInGuestMode.
  ///
  /// In en, this message translates to:
  /// **'Expenses are not available in guest mode.'**
  String get noExpensesInGuestMode;

  /// No description provided for @noExpensesFound.
  ///
  /// In en, this message translates to:
  /// **'No expenses found.'**
  String get noExpensesFound;

  /// No description provided for @accessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access denied'**
  String get accessDenied;

  /// No description provided for @noAccessToGroup.
  ///
  /// In en, this message translates to:
  /// **'You do not have access to this group.'**
  String get noAccessToGroup;

  /// No description provided for @noItemsFoundInFridge.
  ///
  /// In en, this message translates to:
  /// **'No items found in the fridge.'**
  String get noItemsFoundInFridge;

  /// No description provided for @itemExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Item expiring soon'**
  String get itemExpiringSoon;

  /// Notification text when an item is expiring soon
  ///
  /// In en, this message translates to:
  /// **'{itemName} expires on: {expirationDate}!'**
  String itemExpiringMessage(String itemName, String expirationDate);

  /// No description provided for @expiration.
  ///
  /// In en, this message translates to:
  /// **'Expiration'**
  String get expiration;

  /// No description provided for @setExpirationDateTime.
  ///
  /// In en, this message translates to:
  /// **'Set Expiration Date and Time'**
  String get setExpirationDateTime;

  /// No description provided for @errorSavingItem.
  ///
  /// In en, this message translates to:
  /// **'Error saving item'**
  String get errorSavingItem;

  /// No description provided for @expires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get expires;

  /// No description provided for @noName.
  ///
  /// In en, this message translates to:
  /// **'Unnamed'**
  String get noName;

  /// No description provided for @servingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Servings'**
  String get servingsLabel;

  /// No description provided for @ingredientsLabel.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get ingredientsLabel;

  /// No description provided for @instructionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructionsLabel;

  /// No description provided for @noInstructionsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No instructions available'**
  String get noInstructionsAvailable;

  /// No description provided for @failedToLoadRecipeDetails.
  ///
  /// In en, this message translates to:
  /// **'Failed to load recipe details'**
  String get failedToLoadRecipeDetails;

  /// No description provided for @aiChat.
  ///
  /// In en, this message translates to:
  /// **'AI Chat'**
  String get aiChat;

  /// No description provided for @groupChat.
  ///
  /// In en, this message translates to:
  /// **'Group Chat'**
  String get groupChat;

  /// No description provided for @typeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeAMessage;

  /// No description provided for @enterMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter message...'**
  String get enterMessage;

  /// Error message for message sending failure
  ///
  /// In en, this message translates to:
  /// **'Error sending message: {error}'**
  String errorSendingMessage(String error);

  /// No description provided for @needSharedGroupForFeature.
  ///
  /// In en, this message translates to:
  /// **'A shared group is required for this feature.'**
  String get needSharedGroupForFeature;

  /// No description provided for @featureOnlyInSharedGroups.
  ///
  /// In en, this message translates to:
  /// **'This feature is only available in shared groups.'**
  String get featureOnlyInSharedGroups;

  /// No description provided for @switchChat.
  ///
  /// In en, this message translates to:
  /// **'Switch Chat'**
  String get switchChat;

  /// No description provided for @notificationsNotAvailableInGuestMode.
  ///
  /// In en, this message translates to:
  /// **'Notifications are not available in guest mode. Please log in to use this feature.'**
  String get notificationsNotAvailableInGuestMode;

  /// No description provided for @noNotificationsFound.
  ///
  /// In en, this message translates to:
  /// **'No notifications found.'**
  String get noNotificationsFound;

  /// Error message for notification loading failure
  ///
  /// In en, this message translates to:
  /// **'Error loading notifications: {error}'**
  String errorLoadingNotifications(String error);

  /// No description provided for @goingShopping.
  ///
  /// In en, this message translates to:
  /// **'Going Shopping'**
  String get goingShopping;

  /// No description provided for @whatsMissing.
  ///
  /// In en, this message translates to:
  /// **'What\'s Missing?'**
  String get whatsMissing;

  /// No description provided for @whosGoingShopping.
  ///
  /// In en, this message translates to:
  /// **'Who\'s Going Shopping?'**
  String get whosGoingShopping;

  /// No description provided for @iAmGoingShoppingToday.
  ///
  /// In en, this message translates to:
  /// **'I am going shopping today.'**
  String get iAmGoingShoppingToday;

  /// No description provided for @whatsMissingFromShoppingList.
  ///
  /// In en, this message translates to:
  /// **'What\'s missing from the shopping list?'**
  String get whatsMissingFromShoppingList;

  /// No description provided for @whosGoingShoppingToday.
  ///
  /// In en, this message translates to:
  /// **'Who\'s going shopping today?'**
  String get whosGoingShoppingToday;

  /// Label for the notification sender
  ///
  /// In en, this message translates to:
  /// **'Sender: {sender}'**
  String sender(String sender);

  /// No description provided for @noMessage.
  ///
  /// In en, this message translates to:
  /// **'No message'**
  String get noMessage;

  /// No description provided for @noTimestampAvailable.
  ///
  /// In en, this message translates to:
  /// **'No timestamp available'**
  String get noTimestampAvailable;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile Settings'**
  String get profileSettings;

  /// No description provided for @privacyAndSecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy and Security'**
  String get privacyAndSecurity;

  /// No description provided for @themeAndAppearance.
  ///
  /// In en, this message translates to:
  /// **'Theme and Appearance'**
  String get themeAndAppearance;

  /// No description provided for @returnToWelcomeScreen.
  ///
  /// In en, this message translates to:
  /// **'Return to Welcome Screen'**
  String get returnToWelcomeScreen;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// Error message for logout failure
  ///
  /// In en, this message translates to:
  /// **'Error logging out: {error}'**
  String errorLoggingOut(String error);

  /// No description provided for @guestModeSettingsNote.
  ///
  /// In en, this message translates to:
  /// **'Note: Guest mode settings are saved locally on this device.'**
  String get guestModeSettingsNote;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @pickAColor.
  ///
  /// In en, this message translates to:
  /// **'Pick a Color'**
  String get pickAColor;

  /// No description provided for @currentColor.
  ///
  /// In en, this message translates to:
  /// **'Current Color'**
  String get currentColor;

  /// Error message for dark mode saving failure
  ///
  /// In en, this message translates to:
  /// **'Error saving dark mode: {error}'**
  String errorSavingDarkMode(String error);

  /// Error message for color saving failure
  ///
  /// In en, this message translates to:
  /// **'Error saving color: {error}'**
  String errorSavingColor(String error);

  /// No description provided for @pleaseLogInToEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Please log in to edit profile.'**
  String get pleaseLogInToEditProfile;

  /// No description provided for @cropImage.
  ///
  /// In en, this message translates to:
  /// **'Crop Image'**
  String get cropImage;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Password (required for password update)'**
  String get currentPasswordLabel;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password (optional)'**
  String get newPasswordLabel;

  /// No description provided for @passwordTooShortError.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get passwordTooShortError;

  /// No description provided for @currentPasswordRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your current password to update your new password.'**
  String get currentPasswordRequiredError;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Your profile has been updated!'**
  String get profileUpdated;

  /// Error message for general errors
  ///
  /// In en, this message translates to:
  /// **'Something went wrong: {error}'**
  String somethingWentWrong(String error);

  /// No description provided for @imageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Image too large. Maximum 2MB.'**
  String get imageTooLarge;

  /// No description provided for @profilePictureUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile picture updated successfully!'**
  String get profilePictureUpdated;

  /// Error message for image upload failure
  ///
  /// In en, this message translates to:
  /// **'Error uploading image: {error}'**
  String errorUploadingImage(String error);

  /// No description provided for @managedByGoogle.
  ///
  /// In en, this message translates to:
  /// **'Managed by Google'**
  String get managedByGoogle;

  /// No description provided for @twoFactorAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication (2FA)'**
  String get twoFactorAuthentication;

  /// No description provided for @loggedInDevices.
  ///
  /// In en, this message translates to:
  /// **'Logged In Devices'**
  String get loggedInDevices;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @confirmDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone.'**
  String get confirmDeleteAccount;

  /// No description provided for @pleaseLogInToUse2FA.
  ///
  /// In en, this message translates to:
  /// **'Please log in to use 2FA'**
  String get pleaseLogInToUse2FA;

  /// Error message for device info saving failure
  ///
  /// In en, this message translates to:
  /// **'Error saving device info: {error}'**
  String errorSavingDeviceInfo(String error);

  /// No description provided for @userEmailMissing.
  ///
  /// In en, this message translates to:
  /// **'User email is missing.'**
  String get userEmailMissing;

  /// No description provided for @wait60SecondsForNewCode.
  ///
  /// In en, this message translates to:
  /// **'Please wait 60 seconds before requesting a new code.'**
  String get wait60SecondsForNewCode;

  /// No description provided for @disable2FA.
  ///
  /// In en, this message translates to:
  /// **'Disable 2FA'**
  String get disable2FA;

  /// No description provided for @confirmDisable2FA.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to disable Two-Factor Authentication?'**
  String get confirmDisable2FA;

  /// No description provided for @disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disable;

  /// No description provided for @twoFAEnabled.
  ///
  /// In en, this message translates to:
  /// **'2FA enabled via email.'**
  String get twoFAEnabled;

  /// No description provided for @invalidVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code.'**
  String get invalidVerificationCode;

  /// No description provided for @twoFADisabled.
  ///
  /// In en, this message translates to:
  /// **'2FA disabled.'**
  String get twoFADisabled;

  /// Error message for 2FA setup failure
  ///
  /// In en, this message translates to:
  /// **'Error during 2FA setup: {error}'**
  String errorDuring2FASetup(String error);

  /// No description provided for @enterEmailVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Email Verification Code'**
  String get enterEmailVerificationCode;

  /// No description provided for @codeExpirationNote.
  ///
  /// In en, this message translates to:
  /// **'You have 10 minutes to enter the code before it expires.'**
  String get codeExpirationNote;

  /// No description provided for @sixDigitCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get sixDigitCodeLabel;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @pleaseEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter the code.'**
  String get pleaseEnterCode;

  /// No description provided for @invalidCodeError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 6-digit code.'**
  String get invalidCodeError;

  /// No description provided for @codeResentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Code resent successfully.'**
  String get codeResentSuccessfully;

  /// No description provided for @failedToResendEmail.
  ///
  /// In en, this message translates to:
  /// **'Failed to resend email. Please try again later.'**
  String get failedToResendEmail;

  /// Error message for code resending failure
  ///
  /// In en, this message translates to:
  /// **'Error resending code: {error}'**
  String errorResendingCode(String error);

  /// Unexpected error during code resending
  ///
  /// In en, this message translates to:
  /// **'Unexpected error resending code: {error}'**
  String unexpectedErrorResendingCode(String error);

  /// No description provided for @noUserLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'No user is currently logged in.'**
  String get noUserLoggedIn;

  /// No description provided for @youLeftTheGroup.
  ///
  /// In en, this message translates to:
  /// **'You have left the group.'**
  String get youLeftTheGroup;

  /// No description provided for @emailOrPasswordEmpty.
  ///
  /// In en, this message translates to:
  /// **'Email or password cannot be empty.'**
  String get emailOrPasswordEmpty;

  /// No description provided for @enterPasswordToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to confirm'**
  String get enterPasswordToConfirm;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password.'**
  String get pleaseEnterPassword;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully.'**
  String get accountDeleted;

  /// Error message for account deletion failure
  ///
  /// In en, this message translates to:
  /// **'Error deleting account: {error}'**
  String errorDeletingAccount(String error);

  /// No description provided for @userNotLoggedInError.
  ///
  /// In en, this message translates to:
  /// **'User is not logged in.'**
  String get userNotLoggedInError;

  /// No description provided for @noLoggedInDevicesFound.
  ///
  /// In en, this message translates to:
  /// **'No logged in devices found.'**
  String get noLoggedInDevicesFound;

  /// Error message for device loading failure
  ///
  /// In en, this message translates to:
  /// **'Error loading devices: {error}'**
  String errorLoadingDevices(String error);

  /// Label for the operating system version
  ///
  /// In en, this message translates to:
  /// **'OS: {osVersion}'**
  String osLabel(String osVersion);

  /// Label for the last login time
  ///
  /// In en, this message translates to:
  /// **'Last Login: {lastLogin}'**
  String lastLoginLabel(String lastLogin);

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// Message when a device is signed out
  ///
  /// In en, this message translates to:
  /// **'{deviceName} signed out.'**
  String deviceSignedOut(String deviceName);

  /// Error message for sign-out failure
  ///
  /// In en, this message translates to:
  /// **'Error signing out: {error}'**
  String errorSigningOut(String error);

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @messageNotifications.
  ///
  /// In en, this message translates to:
  /// **'Message Notifications'**
  String get messageNotifications;

  /// No description provided for @updateNotifications.
  ///
  /// In en, this message translates to:
  /// **'Update Notifications'**
  String get updateNotifications;

  /// No description provided for @selectAllergies.
  ///
  /// In en, this message translates to:
  /// **'Select Allergies'**
  String get selectAllergies;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// No description provided for @allergyDairy.
  ///
  /// In en, this message translates to:
  /// **'Dairy'**
  String get allergyDairy;

  /// No description provided for @allergyEgg.
  ///
  /// In en, this message translates to:
  /// **'Egg'**
  String get allergyEgg;

  /// No description provided for @allergyGluten.
  ///
  /// In en, this message translates to:
  /// **'Gluten'**
  String get allergyGluten;

  /// No description provided for @allergyPeanut.
  ///
  /// In en, this message translates to:
  /// **'Peanut'**
  String get allergyPeanut;

  /// No description provided for @allergySeafood.
  ///
  /// In en, this message translates to:
  /// **'Seafood'**
  String get allergySeafood;

  /// No description provided for @allergySesame.
  ///
  /// In en, this message translates to:
  /// **'Sesame'**
  String get allergySesame;

  /// No description provided for @allergyShellfish.
  ///
  /// In en, this message translates to:
  /// **'Shellfish'**
  String get allergyShellfish;

  /// No description provided for @allergySoy.
  ///
  /// In en, this message translates to:
  /// **'Soy'**
  String get allergySoy;

  /// No description provided for @allergySulfite.
  ///
  /// In en, this message translates to:
  /// **'Sulfite'**
  String get allergySulfite;

  /// No description provided for @allergyTreeNut.
  ///
  /// In en, this message translates to:
  /// **'Tree Nut'**
  String get allergyTreeNut;

  /// No description provided for @allergyWheat.
  ///
  /// In en, this message translates to:
  /// **'Wheat'**
  String get allergyWheat;

  /// Message when a guest user reaches the cart limit
  ///
  /// In en, this message translates to:
  /// **'Guest users can add up to {limit} items. Please log in to add more.'**
  String guestCartLimitMessage(int limit);

  /// Message when an item is already selected by another user
  ///
  /// In en, this message translates to:
  /// **'This item is already selected by {selectedBy}.'**
  String itemAlreadySelectedBy(String selectedBy);

  /// No description provided for @onlyDeleteOwnItems.
  ///
  /// In en, this message translates to:
  /// **'You can only delete items you added.'**
  String get onlyDeleteOwnItems;

  /// No description provided for @onlyEditOwnItems.
  ///
  /// In en, this message translates to:
  /// **'You can only edit items you added.'**
  String get onlyEditOwnItems;

  /// No description provided for @searchForProducts.
  ///
  /// In en, this message translates to:
  /// **'Search for Products'**
  String get searchForProducts;

  /// No description provided for @shoppingCart.
  ///
  /// In en, this message translates to:
  /// **'Shopping Cart'**
  String get shoppingCart;

  /// Message when an item is removed from the cart
  ///
  /// In en, this message translates to:
  /// **'{itemName} removed'**
  String itemRemoved(String itemName);

  /// Label indicating who selected the item
  ///
  /// In en, this message translates to:
  /// **'Selected by: {selectedBy}'**
  String selectedBy(String selectedBy);

  /// No description provided for @unitKg.
  ///
  /// In en, this message translates to:
  /// **'kilogram'**
  String get unitKg;

  /// No description provided for @unitG.
  ///
  /// In en, this message translates to:
  /// **'gram'**
  String get unitG;

  /// No description provided for @unitPcs.
  ///
  /// In en, this message translates to:
  /// **'piece'**
  String get unitPcs;

  /// No description provided for @unitLiters.
  ///
  /// In en, this message translates to:
  /// **'liter'**
  String get unitLiters;

  /// No description provided for @addNewProduct.
  ///
  /// In en, this message translates to:
  /// **'Add New Product'**
  String get addNewProduct;

  /// No description provided for @nameLabelEn.
  ///
  /// In en, this message translates to:
  /// **'Name (English, optional)'**
  String get nameLabelEn;

  /// No description provided for @nameLabelHu.
  ///
  /// In en, this message translates to:
  /// **'Name (Hungarian)'**
  String get nameLabelHu;

  /// No description provided for @categoryLabelEn.
  ///
  /// In en, this message translates to:
  /// **'Category (English, optional)'**
  String get categoryLabelEn;

  /// No description provided for @categoryLabelHu.
  ///
  /// In en, this message translates to:
  /// **'Category (Hungarian)'**
  String get categoryLabelHu;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields!'**
  String get fillAllFields;

  /// No description provided for @productAdded.
  ///
  /// In en, this message translates to:
  /// **'Product added successfully!'**
  String get productAdded;

  /// No description provided for @optionalFieldsNote.
  ///
  /// In en, this message translates to:
  /// **'English fields are optional when using Hungarian settings.'**
  String get optionalFieldsNote;

  /// No description provided for @fillAtLeastOneName.
  ///
  /// In en, this message translates to:
  /// **'Please fill in at least one name (Hungarian or English)!'**
  String get fillAtLeastOneName;

  /// No description provided for @fillAtLeastOneCategory.
  ///
  /// In en, this message translates to:
  /// **'Please fill in at least one category (Hungarian or English)!'**
  String get fillAtLeastOneCategory;

  /// No description provided for @fillHungarianName.
  ///
  /// In en, this message translates to:
  /// **'Please fill in the Hungarian name!'**
  String get fillHungarianName;

  /// No description provided for @fillHungarianCategory.
  ///
  /// In en, this message translates to:
  /// **'Please fill in the Hungarian category!'**
  String get fillHungarianCategory;

  /// No description provided for @fillEnglishName.
  ///
  /// In en, this message translates to:
  /// **'Please fill in the English name!'**
  String get fillEnglishName;

  /// No description provided for @fillEnglishCategory.
  ///
  /// In en, this message translates to:
  /// **'Please fill in the English category!'**
  String get fillEnglishCategory;

  /// No description provided for @translationApiKeyMissing.
  ///
  /// In en, this message translates to:
  /// **'Google Translate API key is missing.'**
  String get translationApiKeyMissing;

  /// Error message for text translation failure
  ///
  /// In en, this message translates to:
  /// **'Failed to translate text: {statusCode} - {body}'**
  String failedToTranslateText(String statusCode, String body);

  /// Error message for general translation errors
  ///
  /// In en, this message translates to:
  /// **'Translation error: {error}'**
  String translationError(String error);

  /// Error message for email verification check failure
  ///
  /// In en, this message translates to:
  /// **'Error checking verification: {error}'**
  String errorCheckingVerification(String error);

  /// Title for the add to cart dialog
  ///
  /// In en, this message translates to:
  /// **'Add to Cart: {itemName}'**
  String addToCart(String itemName);

  /// Message when an item is edited
  ///
  /// In en, this message translates to:
  /// **'Item edited: {itemName}'**
  String itemEdited(String itemName);

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @fairShare.
  ///
  /// In en, this message translates to:
  /// **'Fair Share'**
  String get fairShare;

  /// No description provided for @perUser.
  ///
  /// In en, this message translates to:
  /// **'per user'**
  String get perUser;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// Error message for group membership check failure
  ///
  /// In en, this message translates to:
  /// **'Error checking group membership: {error}'**
  String errorCheckingGroupMembership(String error);

  /// No description provided for @apiKeyMissing.
  ///
  /// In en, this message translates to:
  /// **'OpenAI API key is missing.'**
  String get apiKeyMissing;

  /// Error message for AI response fetching failure
  ///
  /// In en, this message translates to:
  /// **'Error fetching AI response: Status {statusCode}, {body}'**
  String aiResponseError(String statusCode, String body);

  /// No description provided for @failedToReceiveAIResponse.
  ///
  /// In en, this message translates to:
  /// **'Failed to receive a response from the AI.'**
  String get failedToReceiveAIResponse;

  /// No description provided for @noGroupIdFound.
  ///
  /// In en, this message translates to:
  /// **'No group ID found.'**
  String get noGroupIdFound;

  /// No description provided for @groupNotFound.
  ///
  /// In en, this message translates to:
  /// **'Group not found.'**
  String get groupNotFound;

  /// Error message for group chat navigation failure
  ///
  /// In en, this message translates to:
  /// **'Error navigating to group chat: {error}'**
  String errorNavigatingToGroupChat(String error);

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet.'**
  String get noMessagesYet;

  /// No description provided for @welcomeToYourGroups.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Your Groups!'**
  String get welcomeToYourGroups;

  /// No description provided for @yourGroupsInfo.
  ///
  /// In en, this message translates to:
  /// **'This screen helps you manage all your groups. If you shop from multiple groups, their items will be consolidated here, so you don’t need to check each group’s shopping list individually. You just have to push the Consolidated list button!'**
  String get yourGroupsInfo;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got It'**
  String get gotIt;

  /// No description provided for @welcomeToSmartPantri.
  ///
  /// In en, this message translates to:
  /// **'Welcome to SmartPantri!'**
  String get welcomeToSmartPantri;

  /// No description provided for @welcomeDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'This app helps you manage your shopping lists across multiple groups. Add items, track expenses, and see what\'s in your fridge—all in one place.'**
  String get welcomeDialogMessage;

  /// No description provided for @aggregatedListInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'About the Aggregated Shopping List'**
  String get aggregatedListInfoTitle;

  /// No description provided for @yourGroupsInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Groups Information'**
  String get yourGroupsInfoTitle;

  /// No description provided for @aggregatedListInfoMessage.
  ///
  /// In en, this message translates to:
  /// **'In this list, you can mark items as purchased by ticking the checkbox. If you delete an item with the checkbox ticked, it will be added to your Expense Tracker and What\'s in the Fridge sections. If unticked, the item will simply be removed.'**
  String get aggregatedListInfoMessage;

  /// No description provided for @alreadyHaveAccountLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get alreadyHaveAccountLogin;

  /// No description provided for @tooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too Many Requests.'**
  String get tooManyRequests;

  /// No description provided for @registrationErrorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Unexpected registration error.'**
  String get registrationErrorUnexpected;

  /// Message displayed when the AI cannot answer a question because it is outside the scope of application usage and recipes.
  ///
  /// In en, this message translates to:
  /// **'I cannot answer this question. I can only assist with application usage and recipes.'**
  String get outOfScopeResponse;

  /// Label for the icon style selection setting.
  ///
  /// In en, this message translates to:
  /// **'Icon style'**
  String get iconStyle;

  /// Label for the gradient opacity adjustment setting.
  ///
  /// In en, this message translates to:
  /// **'Gradient opacity'**
  String get gradientOpacity;

  /// Label for the font size adjustment setting.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get fontSize;

  /// Label for the switch to toggle between using the global theme or group-specific colors.
  ///
  /// In en, this message translates to:
  /// **'Use global theme'**
  String get useGlobalTheme;

  /// Button text to delete an account or item
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @continueToApp.
  ///
  /// In en, this message translates to:
  /// **'Continue to App'**
  String get continueToApp;

  /// No description provided for @emailVerifiedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Email verified successfully!'**
  String get emailVerifiedSuccessfully;

  /// No description provided for @offlineModeMessage.
  ///
  /// In en, this message translates to:
  /// **'You are in offline mode. Some features may be unavailable.'**
  String get offlineModeMessage;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hu'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'hu': return AppLocalizationsHu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
