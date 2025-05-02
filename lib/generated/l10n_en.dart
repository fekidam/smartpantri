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

  @override
  String get logIn => 'Log In';

  @override
  String get register => 'Register';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueAsGuest => 'Continue as Guest';

  @override
  String get continuingAsGuest => 'Continuing as Guest';

  @override
  String get googleSignInCancelled => 'Google sign-in cancelled.';

  @override
  String googleSignInError(String error) {
    return 'Google sign-in error: $error';
  }

  @override
  String get enterYourEmail => 'Enter your email';

  @override
  String get password => 'Password';

  @override
  String get pleaseFillInBothFields => 'Please fill in both fields!';

  @override
  String get pleaseVerifyYourEmail => 'Please verify your email address to log in.';

  @override
  String get userNotFound => 'User not found.';

  @override
  String get wrongPassword => 'Invalid password.';

  @override
  String get invalidEmail => 'Invalid email address.';

  @override
  String loginError(String error) {
    return 'Login error: $error';
  }

  @override
  String get dontHaveAnAccountRegister => 'Don\'t have an account? Register';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get email => 'Email';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get selectBirthDate => 'Select Birth Date';

  @override
  String get firstNameRequired => 'First Name is required.';

  @override
  String get lastNameRequired => 'Last Name is required.';

  @override
  String get emailRequired => 'Email is required.';

  @override
  String get invalidEmailFormat => 'Please enter a valid email address.';

  @override
  String get passwordRequired => 'Password is required.';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters long.';

  @override
  String get confirmPasswordRequired => 'Please confirm your password.';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match.';

  @override
  String get emailAlreadyInUse => 'This email address is already in use.';

  @override
  String get weakPassword => 'The password is too weak.';

  @override
  String get registrationError => 'An error occurred during registration.';

  @override
  String get unknownError => 'An unknown error occurred.';

  @override
  String get verifyEmail => 'Verify Email';

  @override
  String get verificationEmailSent => 'Verification email sent. Please check your inbox.';

  @override
  String get iHaveVerifiedMyEmail => 'I have verified my email';

  @override
  String get pleaseVerifyYourEmailFirst => 'Please verify your email first.';

  @override
  String get yourGroups => 'Your Groups';

  @override
  String get demoGroup => 'Demo Group';

  @override
  String get noGroupsFound => 'No groups found';

  @override
  String get shared => 'Shared';

  @override
  String get editGroup => 'Edit Group';

  @override
  String get groupName => 'Group Name';

  @override
  String get groupTagColor => 'Group Tag Color';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get groupUpdatedSuccessfully => 'Group updated successfully';

  @override
  String get groupDeleted => 'Group deleted';

  @override
  String errorFetchingGroups(String error) {
    return 'Error fetching groups: $error';
  }

  @override
  String get viewYourGroups => 'View Your Groups';

  @override
  String get home => 'Home';

  @override
  String get recipes => 'Recipes';

  @override
  String get chat => 'Chat';

  @override
  String get notifications => 'Notifications';

  @override
  String get profile => 'Profile';

  @override
  String get featureRequiresLogin => 'This feature requires login';

  @override
  String get createNewGroup => 'Create New Group';

  @override
  String get selectColor => 'Select Color';

  @override
  String get addGroup => 'Add Group';

  @override
  String get pleaseEnterGroupName => 'Please enter a group name.';

  @override
  String get userNotLoggedIn => 'User is not logged in!';

  @override
  String get failedToCreateGroup => 'Failed to create group. Please try again.';

  @override
  String get guestModeRestriction => 'Creating groups is not available in Guest Mode. Please log in to access this feature.';

  @override
  String get shareGroup => 'Share Group';

  @override
  String get enterEmailToShareWith => 'Enter email to share with';

  @override
  String get pleaseEnterEmailAddress => 'Please enter an email address.';

  @override
  String get groupSharedSuccessfully => 'Group shared successfully! The user has been notified.';

  @override
  String errorSharingGroup(String error) {
    return 'Error sharing group: $error';
  }

  @override
  String get aggregatedShoppingList => 'Aggregated Shopping List';

  @override
  String get noItemsInConsolidatedList => 'No items in the consolidated list.';

  @override
  String get quantityLabel => 'Quantity';

  @override
  String get priceLabel => 'Price';

  @override
  String get unitLabel => 'Unit';

  @override
  String get unknownItem => 'Unknown';

  @override
  String editItem(String itemName) {
    return 'Edit: $itemName';
  }

  @override
  String get currencySymbol => 'Ft';

  @override
  String get notAvailable => 'N/A';

  @override
  String get homeTitle => 'Home';

  @override
  String get expenseTracker => 'Expense Tracker';

  @override
  String get whatsInTheFridge => 'What\'s in the Fridge?';

  @override
  String get shoppingList => 'Shopping List';

  @override
  String get monthlySummary => 'Monthly Summary';

  @override
  String get totalExpense => 'Total Expense';

  @override
  String get byUsers => 'By Users:';

  @override
  String get ok => 'OK';

  @override
  String get noExpensesInGuestMode => 'No expenses available in guest mode.';

  @override
  String get noExpensesFound => 'No expenses found.';

  @override
  String get accessDenied => 'Access Denied';

  @override
  String get noAccessToGroup => 'You do not have access to this group.';

  @override
  String get noItemsFoundInFridge => 'No items found in the fridge.';

  @override
  String get itemExpiringSoon => 'Item Expiring Soon';

  @override
  String itemExpiringMessage(String itemName, String expirationDate) {
    return '$itemName is expiring on $expirationDate!';
  }

  @override
  String get expiration => 'Expiration';

  @override
  String get setExpirationDateTime => 'Set Expiration Date and Time';

  @override
  String get errorSavingItem => 'Error saving item';

  @override
  String get expires => 'Expires';

  @override
  String get noName => 'No name';

  @override
  String get servingsLabel => 'Servings';

  @override
  String get ingredientsLabel => 'Ingredients';

  @override
  String get instructionsLabel => 'Instructions';

  @override
  String get noInstructionsAvailable => 'No instructions available';

  @override
  String get failedToLoadRecipeDetails => 'Failed to load recipe details';

  @override
  String get aiChat => 'AI Chat';

  @override
  String get groupChat => 'Group Chat';

  @override
  String get typeAMessage => 'Type a message...';

  @override
  String get enterMessage => 'Enter message...';

  @override
  String errorSendingMessage(String error) {
    return 'Error sending message: $error';
  }

  @override
  String get needSharedGroupForFeature => 'You need a shared group to use this feature.';

  @override
  String get featureOnlyInSharedGroups => 'This feature is only available in shared groups.';

  @override
  String get switchChat => 'Switch Chat';

  @override
  String get notificationsNotAvailableInGuestMode => 'Notifications are not available in Guest Mode. Please log in to access this feature.';

  @override
  String get noNotificationsFound => 'No notifications found.';

  @override
  String errorLoadingNotifications(String error) {
    return 'Error loading notifications: $error';
  }

  @override
  String get goingShopping => 'Going Shopping';

  @override
  String get whatsMissing => 'What\'s Missing?';

  @override
  String get whosGoingShopping => 'Who\'s Going Shopping?';

  @override
  String get iAmGoingShoppingToday => 'I am going shopping today.';

  @override
  String get whatsMissingFromShoppingList => 'What\'s missing from the shopping list?';

  @override
  String get whosGoingShoppingToday => 'Who\'s going shopping today?';

  @override
  String sender(String sender) {
    return 'Sender: $sender';
  }

  @override
  String get noMessage => 'No message';

  @override
  String get noTimestampAvailable => 'No timestamp available';

  @override
  String get settings => 'Settings';

  @override
  String get profileSettings => 'Profile Settings';

  @override
  String get privacyAndSecurity => 'Privacy and Security';

  @override
  String get themeAndAppearance => 'Theme and Appearance';

  @override
  String get returnToWelcomeScreen => 'Return to Welcome Screen';

  @override
  String get logOut => 'Log out';

  @override
  String errorLoggingOut(String error) {
    return 'Error logging out: $error';
  }

  @override
  String get guestModeSettingsNote => 'Note: Guest mode settings are saved locally on this device.';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get pickAColor => 'Pick a Color';

  @override
  String get currentColor => 'Current color';

  @override
  String errorSavingDarkMode(String error) {
    return 'Error saving dark mode: $error';
  }

  @override
  String errorSavingColor(String error) {
    return 'Error saving color: $error';
  }

  @override
  String get pleaseLogInToEditProfile => 'Please log in to edit your profile.';

  @override
  String get cropImage => 'Crop Image';

  @override
  String get currentPasswordLabel => 'Current Password (required for password update)';

  @override
  String get newPasswordLabel => 'New Password (optional)';

  @override
  String get passwordTooShortError => 'Password must be at least 6 characters long.';

  @override
  String get currentPasswordRequiredError => 'Please enter your current password to update the new password.';

  @override
  String get profileUpdated => 'Your Profile is Updated!';

  @override
  String somethingWentWrong(String error) {
    return 'Something went wrong: $error';
  }

  @override
  String get imageTooLarge => 'Image too large. Max 2MB.';

  @override
  String get profilePictureUpdated => 'Profile picture updated successfully!';

  @override
  String errorUploadingImage(String error) {
    return 'Error uploading image: $error';
  }

  @override
  String get managedByGoogle => 'Managed by Google';

  @override
  String get twoFactorAuthentication => 'Two Factor Authentication (2FA)';

  @override
  String get loggedInDevices => 'Logged In Devices';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get confirmDeleteAccount => 'Are you sure you want to delete your account? This action cannot be undone.';

  @override
  String get pleaseLogInToUse2FA => 'Please log in to use 2FA';

  @override
  String errorSavingDeviceInfo(String error) {
    return 'Error saving device info: $error';
  }

  @override
  String get userEmailMissing => 'User email is missing.';

  @override
  String get wait60SecondsForNewCode => 'Please wait 60 seconds before requesting a new code.';

  @override
  String get disable2FA => 'Disable 2FA';

  @override
  String get confirmDisable2FA => 'Are you sure you want to disable Two Factor Authentication?';

  @override
  String get disable => 'Disable';

  @override
  String get twoFAEnabled => '2FA enabled via email.';

  @override
  String get invalidVerificationCode => 'Invalid verification code.';

  @override
  String get twoFADisabled => '2FA disabled.';

  @override
  String errorDuring2FASetup(String error) {
    return 'Error during 2FA setup: $error';
  }

  @override
  String get enterEmailVerificationCode => 'Enter Email Verification Code';

  @override
  String get codeExpirationNote => 'You have 10 minutes to enter the code before it expires.';

  @override
  String get sixDigitCodeLabel => '6-digit code';

  @override
  String get resendCode => 'Resend Code';

  @override
  String get verify => 'Verify';

  @override
  String get pleaseEnterCode => 'Please enter the code.';

  @override
  String get invalidCodeError => 'Please enter a valid 6-digit code.';

  @override
  String get codeResentSuccessfully => 'Code resent successfully.';

  @override
  String get failedToResendEmail => 'Failed to resend email. Please try again later.';

  @override
  String errorResendingCode(String error) {
    return 'Error resending code: $error';
  }

  @override
  String unexpectedErrorResendingCode(String error) {
    return 'Unexpected error resending code: $error';
  }

  @override
  String get noUserLoggedIn => 'No user is currently logged in.';

  @override
  String get emailOrPasswordEmpty => 'Email or password cannot be empty.';

  @override
  String get enterPasswordToConfirm => 'Enter your password to confirm';

  @override
  String get pleaseEnterPassword => 'Please enter your password.';

  @override
  String get accountDeleted => 'Account successfully deleted.';

  @override
  String errorDeletingAccount(String error) {
    return 'Error deleting account: $error';
  }

  @override
  String get userNotLoggedInError => 'User not logged in.';

  @override
  String get noLoggedInDevicesFound => 'No logged in devices found.';

  @override
  String errorLoadingDevices(String error) {
    return 'Error loading devices: $error';
  }

  @override
  String osLabel(String osVersion) {
    return 'OS: $osVersion';
  }

  @override
  String lastLoginLabel(String lastLogin) {
    return 'Last Login: $lastLogin';
  }

  @override
  String get signOut => 'Sign Out';

  @override
  String deviceSignedOut(String deviceName) {
    return '$deviceName signed out.';
  }

  @override
  String errorSigningOut(String error) {
    return 'Error signing out: $error';
  }

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get messageNotifications => 'Message Notifications';

  @override
  String get updateNotifications => 'Notifications on Updates';

  @override
  String get selectAllergies => 'Select Allergies';

  @override
  String get selectAll => 'Select All';

  @override
  String get deselectAll => 'Deselect All';

  @override
  String get allergyDairy => 'Dairy';

  @override
  String get allergyEgg => 'Egg';

  @override
  String get allergyGluten => 'Gluten';

  @override
  String get allergyPeanut => 'Peanut';

  @override
  String get allergySeafood => 'Seafood';

  @override
  String get allergySesame => 'Sesame';

  @override
  String get allergyShellfish => 'Shellfish';

  @override
  String get allergySoy => 'Soy';

  @override
  String get allergySulfite => 'Sulfite';

  @override
  String get allergyTreeNut => 'Tree Nut';

  @override
  String get allergyWheat => 'Wheat';

  @override
  String guestCartLimitMessage(int limit) {
    return 'Guest users can only add up to $limit items. Please log in to add more.';
  }

  @override
  String itemAlreadySelectedBy(String selectedBy) {
    return 'This item is already selected by $selectedBy.';
  }

  @override
  String get onlyDeleteOwnItems => 'You can only delete items you added.';

  @override
  String get onlyEditOwnItems => 'You can only edit items you added.';

  @override
  String get searchForProducts => 'Search for products';

  @override
  String get shoppingCart => 'Shopping Cart';

  @override
  String itemRemoved(String itemName) {
    return '$itemName removed';
  }

  @override
  String selectedBy(String selectedBy) {
    return 'Selected by: $selectedBy';
  }

  @override
  String get unitKg => 'kg';

  @override
  String get unitG => 'g';

  @override
  String get unitPcs => 'pcs';

  @override
  String get unitLiters => 'liters';

  @override
  String get addNewProduct => 'Add New Product';

  @override
  String get nameLabelEn => 'Name (English)';

  @override
  String get nameLabelHu => 'Name (Hungarian)';

  @override
  String get categoryLabelEn => 'Category (English)';

  @override
  String get categoryLabelHu => 'Category (Hungarian)';

  @override
  String get fillAllFields => 'Please fill all fields!';

  @override
  String get productAdded => 'Product added successfully!';

  @override
  String get optionalFieldsNote => 'English fields are optional when using Hungarian.';

  @override
  String get fillAtLeastOneName => 'Please fill at least one name (Hungarian or English)!';

  @override
  String get fillAtLeastOneCategory => 'Please fill at least one category (Hungarian or English)!';

  @override
  String get fillHungarianName => 'Please fill the Hungarian name!';

  @override
  String get fillHungarianCategory => 'Please fill the Hungarian category!';

  @override
  String get fillEnglishName => 'Please fill the English name!';

  @override
  String get fillEnglishCategory => 'Please fill the English category!';
}
