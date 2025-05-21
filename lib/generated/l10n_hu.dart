// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get appTitle => 'SmartPantri';

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

  @override
  String get logIn => 'Bejelentkezés';

  @override
  String get register => 'Regisztráció';

  @override
  String get continueWithGoogle => 'Folytatás Google-lal';

  @override
  String get continueAsGuest => 'Folytatás vendégként';

  @override
  String get continuingAsGuest => 'Folytatás vendégként';

  @override
  String get googleSignInCancelled => 'Google bejelentkezés megszakítva.';

  @override
  String googleSignInError(String error) {
    return 'Google bejelentkezési hiba: $error';
  }

  @override
  String get enterYourEmail => 'Add meg az email címed';

  @override
  String get password => 'Jelszó';

  @override
  String get pleaseFillInBothFields => 'Kérlek, töltsd ki mindkét mezőt!';

  @override
  String get pleaseVerifyYourEmail => 'Kérlek, erősítsd meg az email címedet a bejelentkezéshez.';

  @override
  String get userNotFound => 'Felhasználó nem található.';

  @override
  String get wrongPassword => 'Érvénytelen jelszó.';

  @override
  String get invalidEmail => 'Érvénytelen email cím.';

  @override
  String loginError(String error) {
    return 'Bejelentkezési hiba: $error';
  }

  @override
  String get dontHaveAnAccountRegister => 'Nincs fiókod? Regisztrálj';

  @override
  String get firstName => 'Keresztnév';

  @override
  String get lastName => 'Vezetéknév';

  @override
  String get email => 'Email';

  @override
  String get confirmPassword => 'Jelszó megerősítése';

  @override
  String get selectBirthDate => 'Születési dátum kiválasztása';

  @override
  String get firstNameRequired => 'A keresztnév kötelező.';

  @override
  String get lastNameRequired => 'A vezetéknév kötelező.';

  @override
  String get emailRequired => 'Az email kötelező.';

  @override
  String get invalidEmailFormat => 'Kérlek, adj meg egy érvényes email címet.';

  @override
  String get passwordRequired => 'A jelszó kötelező.';

  @override
  String get passwordTooShort => 'A jelszónak legalább 6 karakterből kell állnia.';

  @override
  String get confirmPasswordRequired => 'Kérlek, erősítsd meg a jelszavadat.';

  @override
  String get passwordsDoNotMatch => 'A jelszavak nem egyeznek.';

  @override
  String get emailAlreadyInUse => 'Ez az email cím már használatban van.';

  @override
  String get weakPassword => 'A jelszó túl gyenge.';

  @override
  String get registrationFailed => 'A regisztráció váratlan hiba miatt sikertelen.';

  @override
  String get registrationError => 'Hiba történt a regisztráció során.';

  @override
  String get unknownError => 'Ismeretlen hiba történt.';

  @override
  String get verifyEmail => 'Email megerősítése';

  @override
  String get verificationEmailSent => 'Egy megerősítő emailt küldtünk az email címedre.';

  @override
  String get iHaveVerifiedMyEmail => 'Megerősítettem az email címemet';

  @override
  String get pleaseVerifyYourEmailFirst => 'Kérlek, először erősítsd meg az email címedet.';

  @override
  String get noUserFound => 'Nincs ilyen felhasználó.';

  @override
  String errorSendingVerificationEmail(String error) {
    return 'Hiba a megerősítő email küldésekor: $error';
  }

  @override
  String get yourGroups => 'Csoportjaid';

  @override
  String get demoGroup => 'Demó Csoport';

  @override
  String get noGroupsFound => 'Nem találhatóak csoportok';

  @override
  String get shared => 'Megosztott';

  @override
  String get editGroup => 'Csoport szerkesztése';

  @override
  String get groupName => 'Csoport neve';

  @override
  String get groupTagColor => 'Csoport címke színe';

  @override
  String get cancel => 'Mégse';

  @override
  String get save => 'Mentés';

  @override
  String get groupUpdatedSuccessfully => 'Csoport sikeresen frissítve';

  @override
  String get groupDeleted => 'Csoport törölve';

  @override
  String errorFetchingGroups(String error) {
    return 'Hiba a csoportok lekérésekor: $error';
  }

  @override
  String get viewYourGroups => 'Összesített Lista';

  @override
  String get home => 'Főoldal';

  @override
  String get recipes => 'Receptek';

  @override
  String get chat => 'Csevegés';

  @override
  String get notifications => 'Értesítések';

  @override
  String get profile => 'Profil';

  @override
  String get featureRequiresLogin => 'Ez a funkció bejelentkezést igényel';

  @override
  String get createNewGroup => 'Új csoport létrehozása';

  @override
  String get selectColor => 'Szín kiválasztása';

  @override
  String get addGroup => 'Csoport hozzáadása';

  @override
  String get pleaseEnterGroupName => 'Kérlek, add meg a csoport nevét.';

  @override
  String get userNotLoggedIn => 'A felhasználó nincs bejelentkezve';

  @override
  String get failedToCreateGroup => 'Nem sikerült létrehozni a csoportot. Kérlek, próbáld újra.';

  @override
  String get guestModeRestriction => 'A csoportok létrehozása nem elérhető vendég módban. Kérlek, jelentkezz be a funkció használatához.';

  @override
  String get shareGroup => 'Csoport megosztása';

  @override
  String get enterEmailToShareWith => 'Add meg az email címet a megosztáshoz';

  @override
  String get pleaseEnterEmailAddress => 'Kérlek, add meg az email címet.';

  @override
  String get groupSharedSuccessfully => 'Csoport sikeresen megosztva! A felhasználó értesítve lett.';

  @override
  String errorSharingGroup(String error) {
    return 'Hiba a csoport megosztása során: $error';
  }

  @override
  String get aggregatedShoppingList => 'Összevont bevásárlólista';

  @override
  String get noItemsInConsolidatedList => 'Nincsenek elemek az összevont listában.';

  @override
  String get quantityLabel => 'Mennyiség';

  @override
  String get priceLabel => 'Ár';

  @override
  String get unitLabel => 'Mértékegység';

  @override
  String get unknownItem => 'Ismeretlen';

  @override
  String editItem(String itemName) {
    return 'Szerkesztés: $itemName';
  }

  @override
  String get currencySymbol => 'Ft';

  @override
  String get notAvailable => 'N/A';

  @override
  String get homeTitle => 'Főoldal';

  @override
  String get expenseTracker => 'Kiadáskövető';

  @override
  String get whatsInTheFridge => 'Mi van a hűtőben?';

  @override
  String get shoppingList => 'Bevásárlólista';

  @override
  String get monthlySummary => 'Havi összegzés';

  @override
  String get totalExpense => 'Összes kiadás';

  @override
  String get byUsers => 'Felhasználók szerint:';

  @override
  String get ok => 'OK';

  @override
  String get noExpensesInGuestMode => 'Vendég módban nem érhetők el kiadások.';

  @override
  String get noExpensesFound => 'Nem találhatóak kiadások.';

  @override
  String get accessDenied => 'Hozzáférés megtagadva';

  @override
  String get noAccessToGroup => 'Nincs hozzáférésed ehhez a csoporthoz.';

  @override
  String get noItemsFoundInFridge => 'Nem található elem a hűtőben.';

  @override
  String get itemExpiringSoon => 'Termék hamarosan lejár';

  @override
  String itemExpiringMessage(String itemName, String expirationDate) {
    return '$itemName lejár ekkor: $expirationDate!';
  }

  @override
  String get expiration => 'Lejárat';

  @override
  String get setExpirationDateTime => 'Lejárati dátum és idő beállítása';

  @override
  String get errorSavingItem => 'Hiba az elem mentésekor';

  @override
  String get expires => 'Lejár';

  @override
  String get noName => 'Névtelen';

  @override
  String get servingsLabel => 'Adagok';

  @override
  String get ingredientsLabel => 'Hozzávalók';

  @override
  String get instructionsLabel => 'Elkészítés';

  @override
  String get noInstructionsAvailable => 'Nincsenek elérhető utasítások';

  @override
  String get failedToLoadRecipeDetails => 'Nem sikerült betölteni a recept részleteit';

  @override
  String get aiChat => 'AI Csevegés';

  @override
  String get groupChat => 'Csoportos Csevegés';

  @override
  String get typeAMessage => 'Írj egy üzenetet...';

  @override
  String get enterMessage => 'Üzenet írása...';

  @override
  String errorSendingMessage(String error) {
    return 'Hiba az üzenet küldésekor: $error';
  }

  @override
  String get needSharedGroupForFeature => 'Ehhez a funkcióhoz megosztott csoport szükséges.';

  @override
  String get featureOnlyInSharedGroups => 'Ez a funkció csak megosztott csoportokban érhető el.';

  @override
  String get switchChat => 'Csevegés váltása';

  @override
  String get notificationsNotAvailableInGuestMode => 'Az értesítések nem érhetők el vendég módban. Kérlek, jelentkezz be a funkció használatához.';

  @override
  String get noNotificationsFound => 'Nem találhatóak értesítések.';

  @override
  String errorLoadingNotifications(String error) {
    return 'Hiba az értesítések betöltésekor: $error';
  }

  @override
  String get goingShopping => 'Bevásárolni megyek';

  @override
  String get whatsMissing => 'Mi hiányzik?';

  @override
  String get whosGoingShopping => 'Ki megy bevásárolni?';

  @override
  String get iAmGoingShoppingToday => 'Ma bevásárolni megyek.';

  @override
  String get whatsMissingFromShoppingList => 'Mi hiányzik a bevásárlólistáról?';

  @override
  String get whosGoingShoppingToday => 'Ki megy ma bevásárolni?';

  @override
  String get noMessage => 'Nincs üzenet';

  @override
  String get noTimestampAvailable => 'Nincs elérhető időbélyeg';

  @override
  String get settings => 'Beállítások';

  @override
  String get profileSettings => 'Profilbeállítások';

  @override
  String get privacyAndSecurity => 'Adatvédelem és Biztonság';

  @override
  String get themeAndAppearance => 'Téma és Megjelenés';

  @override
  String get returnToWelcomeScreen => 'Vissza a Üdvözlőképernyőhöz';

  @override
  String get logOut => 'Kijelentkezés';

  @override
  String errorLoggingOut(String error) {
    return 'Hiba a kijelentkezés során: $error';
  }

  @override
  String get guestModeSettingsNote => 'Megjegyzés: A vendég mód beállításai helyben, ezen az eszközön kerülnek mentésre.';

  @override
  String get darkMode => 'Sötét Mód';

  @override
  String get pickAColor => 'Szín kiválasztása';

  @override
  String get currentColor => 'Jelenlegi szín';

  @override
  String errorSavingDarkMode(String error) {
    return 'Hiba a sötét mód mentése során: $error';
  }

  @override
  String errorSavingColor(String error) {
    return 'Hiba a szín mentése során: $error';
  }

  @override
  String get pleaseLogInToEditProfile => 'Kérlek, jelentkezz be a profil szerkesztéséhez.';

  @override
  String get cropImage => 'Kép kivágása';

  @override
  String get currentPasswordLabel => 'Jelenlegi Jelszó (jelszófrissítéshez szükséges)';

  @override
  String get newPasswordLabel => 'Új Jelszó (opcionális)';

  @override
  String get passwordTooShortError => 'A jelszónak legalább 6 karakterből kell állnia.';

  @override
  String get currentPasswordRequiredError => 'Kérlek, add meg a jelenlegi jelszavadat az új jelszó frissítéséhez.';

  @override
  String get profileUpdated => 'A profilod frissítve!';

  @override
  String somethingWentWrong(String error) {
    return 'Valami hiba történt: $error';
  }

  @override
  String get imageTooLarge => 'A kép túl nagy. Maximum 2MB.';

  @override
  String get profilePictureUpdated => 'Profilkép sikeresen frissítve!';

  @override
  String errorUploadingImage(String error) {
    return 'Hiba a kép feltöltése során: $error';
  }

  @override
  String get managedByGoogle => 'Google által kezelve';

  @override
  String get twoFactorAuthentication => 'Kétfaktoros Hitelesítés (2FA)';

  @override
  String get loggedInDevices => 'Bejelentkezett Eszközök';

  @override
  String get deleteAccount => 'Fiók Törlése';

  @override
  String get confirmDeleteAccount => 'Biztosan törölni szeretnéd a fiókodat? Ez a művelet nem vonható vissza.';

  @override
  String get pleaseLogInToUse2FA => 'Kérlek, jelentkezz be a 2FA használatához';

  @override
  String errorSavingDeviceInfo(String error) {
    return 'Hiba az eszközinformációk mentése során: $error';
  }

  @override
  String get userEmailMissing => 'A felhasználói email hiányzik.';

  @override
  String get wait60SecondsForNewCode => 'Kérlek, várj 60 másodpercet, mielőtt új kódot kérsz.';

  @override
  String get disable2FA => '2FA Kikapcsolása';

  @override
  String get confirmDisable2FA => 'Biztosan ki szeretnéd kapcsolni a Kétfaktoros Hitelesítést?';

  @override
  String get disable => 'Kikapcsolás';

  @override
  String get twoFAEnabled => '2FA engedélyezve emailen keresztül.';

  @override
  String get invalidVerificationCode => 'Érvénytelen ellenőrző kód.';

  @override
  String get twoFADisabled => '2FA kikapcsolva.';

  @override
  String errorDuring2FASetup(String error) {
    return 'Hiba a 2FA beállítása során: $error';
  }

  @override
  String get enterEmailVerificationCode => 'Add meg az Email Ellenőrző Kódot';

  @override
  String get codeExpirationNote => '10 perced van a kód megadására, mielőtt lejár.';

  @override
  String get sixDigitCodeLabel => '6 jegyű kód';

  @override
  String get resendCode => 'Kód Újraküldése';

  @override
  String get verify => 'Ellenőrzés';

  @override
  String get pleaseEnterCode => 'Kérlek, add meg a kódot.';

  @override
  String get invalidCodeError => 'Kérlek, adj meg egy érvényes 6 jegyű kódot.';

  @override
  String get codeResentSuccessfully => 'Kód sikeresen újraküldve.';

  @override
  String get failedToResendEmail => 'Nem sikerült újraküldeni az emailt. Kérlek, próbáld újra később.';

  @override
  String errorResendingCode(String error) {
    return 'Hiba a kód újraküldése során: $error';
  }

  @override
  String unexpectedErrorResendingCode(String error) {
    return 'Váratlan hiba a kód újraküldése során: $error';
  }

  @override
  String get noUserLoggedIn => 'Jelenleg nincs bejelentkezett felhasználó.';

  @override
  String get youLeftTheGroup => 'Elhagytad a csoportot.';

  @override
  String get emailOrPasswordEmpty => 'Az email vagy jelszó nem lehet üres.';

  @override
  String get enterPasswordToConfirm => 'Add meg a jelszavadat a megerősítéshez';

  @override
  String get pleaseEnterPassword => 'Kérlek, add meg a jelszavadat.';

  @override
  String get accountDeleted => 'Fiók sikeresen törölve.';

  @override
  String errorDeletingAccount(String error) {
    return 'Hiba a fiók törlése során: $error';
  }

  @override
  String get userNotLoggedInError => 'A felhasználó nincs bejelentkezve.';

  @override
  String get noLoggedInDevicesFound => 'Nem találhatóak bejelentkezett eszközök.';

  @override
  String errorLoadingDevices(String error) {
    return 'Hiba az eszközök betöltése során: $error';
  }

  @override
  String osLabel(String osVersion) {
    return 'OS: $osVersion';
  }

  @override
  String lastLoginLabel(String lastLogin) {
    return 'Utolsó Bejelentkezés: $lastLogin';
  }

  @override
  String get signOut => 'Kijelentkezés';

  @override
  String deviceSignedOut(String deviceName) {
    return '$deviceName kijelentkezett.';
  }

  @override
  String errorSigningOut(String error) {
    return 'Hiba a kijelentkezés során: $error';
  }

  @override
  String get enableNotifications => 'Értesítések Engedélyezése';

  @override
  String get messageNotifications => 'Üzenet Értesítések';

  @override
  String get updateNotifications => 'Frissítési Értesítések';

  @override
  String get selectAllergies => 'Allergiák Kiválasztása';

  @override
  String get selectAll => 'Összes Kiválasztása';

  @override
  String get deselectAll => 'Összes Kiválasztás Törlése';

  @override
  String get allergyDairy => 'Tejtermék';

  @override
  String get allergyEgg => 'Tojás';

  @override
  String get allergyGluten => 'Glutén';

  @override
  String get allergyPeanut => 'Földimogyoró';

  @override
  String get allergySeafood => 'Tengeri ételek';

  @override
  String get allergySesame => 'Szezám';

  @override
  String get allergyShellfish => 'Kagylók';

  @override
  String get allergySoy => 'Szója';

  @override
  String get allergySulfite => 'Szulfit';

  @override
  String get allergyTreeNut => 'Diófélék';

  @override
  String get allergyWheat => 'Búza';

  @override
  String guestCartLimitMessage(int limit) {
    return 'A vendég felhasználók legfeljebb $limit terméket adhatnak hozzá. Kérlek, jelentkezz be, hogy többet adhass hozzá.';
  }

  @override
  String itemAlreadySelectedBy(String selectedBy) {
    return 'Ezt a terméket már $selectedBy kiválasztotta.';
  }

  @override
  String get onlyDeleteOwnItems => 'Csak azokat a termékeket törölheted, amelyeket te adtál hozzá.';

  @override
  String get onlyEditOwnItems => 'Csak azokat a termékeket szerkesztheted, amelyeket te adtál hozzá.';

  @override
  String get searchForProducts => 'Termékek keresése';

  @override
  String get shoppingCart => 'Bevásárlókosár';

  @override
  String itemRemoved(String itemName) {
    return '$itemName eltávolítva';
  }

  @override
  String selectedBy(String selectedBy) {
    return 'Kiválasztotta: $selectedBy';
  }

  @override
  String get unitKg => 'kilogramm';

  @override
  String get unitG => 'gramm';

  @override
  String get unitPcs => 'darab';

  @override
  String get unitLiters => 'liter';

  @override
  String get addNewProduct => 'Új termék hozzáadása';

  @override
  String get nameLabelEn => 'Név (angol, opcionális)';

  @override
  String get nameLabelHu => 'Név (magyar)';

  @override
  String get categoryLabelEn => 'Kategória (angol, opcionális)';

  @override
  String get categoryLabelHu => 'Kategória (magyar)';

  @override
  String get fillAllFields => 'Kérlek, töltsd ki az összes kötelező mezőt!';

  @override
  String get productAdded => 'Termék sikeresen hozzáadva!';

  @override
  String get optionalFieldsNote => 'Az angol mezők kitöltése nem kötelező magyar nyelvi beállítás esetén.';

  @override
  String get fillAtLeastOneName => 'Kérlek töltsd ki legalább az egyik nevet (magyar vagy angol)!';

  @override
  String get fillAtLeastOneCategory => 'Kérlek töltsd ki legalább az egyik kategóriát (magyar vagy angol)!';

  @override
  String get fillHungarianName => 'Kérlek töltsd ki a magyar nevet!';

  @override
  String get fillHungarianCategory => 'Kérlek töltsd ki a magyar kategóriát!';

  @override
  String get fillEnglishName => 'Kérlek töltsd ki az angol nevet!';

  @override
  String get fillEnglishCategory => 'Kérlek töltsd ki az angol kategóriát!';

  @override
  String get translationApiKeyMissing => 'Hiányzik a Google Translate API kulcs.';

  @override
  String failedToTranslateText(String statusCode, String body) {
    return 'Nem sikerült a szöveg fordítása: $statusCode - $body';
  }

  @override
  String translationError(String error) {
    return 'Fordítási hiba: $error';
  }

  @override
  String errorCheckingVerification(String error) {
    return 'Hiba az email ellenőrzése során: $error';
  }

  @override
  String addToCart(String itemName) {
    return 'Hozzáadás a kosárhoz: $itemName';
  }

  @override
  String itemEdited(String itemName) {
    return 'Tétel szerkesztve: $itemName';
  }

  @override
  String get guest => 'Vendég';

  @override
  String get fairShare => 'Tisztességes rész';

  @override
  String get perUser => 'felhasználónként';

  @override
  String get totalLabel => 'Összesen';

  @override
  String get unknown => 'Ismeretlen';

  @override
  String errorCheckingGroupMembership(String error) {
    return 'Hiba a csoporttagság ellenőrzése során: $error';
  }

  @override
  String get apiKeyMissing => 'Hiányzik az OpenAI API kulcs.';

  @override
  String aiResponseError(String statusCode, String body) {
    return 'Hiba az AI válasz lekérése során: Állapot $statusCode, $body';
  }

  @override
  String get failedToReceiveAIResponse => 'Nem sikerült választ kapni az AI-tól.';

  @override
  String get noGroupIdFound => 'Nem található csoport azonosító.';

  @override
  String get groupNotFound => 'A csoport nem található.';

  @override
  String errorNavigatingToGroupChat(String error) {
    return 'Hiba a csoportos csevegésre navigálás során: $error';
  }

  @override
  String get noMessagesYet => 'Még nincsenek üzenetek.';

  @override
  String get welcomeToYourGroups => 'Üdvözöljük a Csoportjaidnál!';

  @override
  String guestCartLimitReached(Object limit) {
    return 'Elérted a vendég módban engedélyezett $limit termék maximális limitjét.';
  }

  @override
  String get yourGroupsInfo => 'Ez a képernyő segít a csoportjaid kezelésében. Ha több csoportból szeretnél termékeket megvásárolni, azok itt összevonásra kerülnek, így nem kell mindig egyenként megnézned a csoportok bevásárlólistáit. Csak kattints az Összesített Lista gombra!';

  @override
  String get gotIt => 'Megértettem';

  @override
  String get welcomeToSmartPantri => 'Üdvözöljük a SmartPantri-ban!';

  @override
  String get welcomeDialogMessage => 'Ez az alkalmazás segít a bevásárlólisták kezelésére több csoportban. Adjon hozzá termékeket, kövesse nyomon a kiadásokat, és nézze meg, mi van a hűtőjében – mindezt egy helyen.';

  @override
  String get aggregatedListInfoTitle => 'Az Összevont Bevásárlólistáról';

  @override
  String get yourGroupsInfoTitle => 'Információ a Csoportjaidról';

  @override
  String get aggregatedListInfoMessage => 'Ebben a listában a jelölőnégyzettel megjelölheti a megvásárolt termékeket. Ha egy terméket a jelölőnégyzet bepipálásával töröl, az hozzáadódik a Kiadáskövetőhöz és a \'Mi van a hűtőben?\' szekcióhoz. Ha nincs bepipálva, a termék egyszerűen törlődik.';

  @override
  String get alreadyHaveAccountLogin => 'Már van fiókod? Jelentkezz be';

  @override
  String get tooManyRequests => 'Túl sok kérés.';

  @override
  String get userAlreadyInGroup => 'A felhasználó már tagja a csoportnak.';

  @override
  String get noItemsInYourGroups => 'Nincs termék az összesített listádban.';

  @override
  String get registrationErrorUnexpected => 'Váratlan regisztrációs hiba.';

  @override
  String get outOfScopeResponse => 'Sajnos erre a kérdésre nem tudok válaszolni, csak az alkalmazás használatával és receptekkel kapcsolatban tudok segíteni.';

  @override
  String get iconStyle => 'Ikonstílus';

  @override
  String get gradientOpacity => 'Gradiens átlátszóság';

  @override
  String get fontSize => 'Betűméret';

  @override
  String get useGlobalTheme => 'Globális téma használata';

  @override
  String get delete => 'Törlés';

  @override
  String get addToShoppingList => 'Hozzáadás a Bevásárlólistához';

  @override
  String itemAddedToShoppingList(String itemName) {
    return 'Elem hozzáadva a bevásárlólistához: $itemName';
  }

  @override
  String get continueToApp => 'Folytatás az alkalmazásban';

  @override
  String get emailVerifiedSuccessfully => 'Email sikeresen megerősítve!';

  @override
  String get offlineModeMessage => 'Offline módban vagy. Előfordulhat, hogy néhány funkció nem megfelelő.';

  @override
  String sender(String senderName) {
    return '$senderName';
  }

  @override
  String fromGroup(String groupName) {
    return '$groupName-ból';
  }
}
