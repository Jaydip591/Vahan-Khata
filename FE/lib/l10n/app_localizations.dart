import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
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
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('gu'),
  ];

  /// No description provided for @appName.
  ///
  /// In gu, this message translates to:
  /// **'વાહન ખાતા'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In gu, this message translates to:
  /// **'તમારો આખો હિસાબ, એક જગ્યાએ'**
  String get tagline;

  /// No description provided for @username.
  ///
  /// In gu, this message translates to:
  /// **'યુઝરનેમ'**
  String get username;

  /// No description provided for @password.
  ///
  /// In gu, this message translates to:
  /// **'પાસવર્ડ'**
  String get password;

  /// No description provided for @loginButton.
  ///
  /// In gu, this message translates to:
  /// **'લોગિન કરો'**
  String get loginButton;

  /// No description provided for @stayLoggedInNote.
  ///
  /// In gu, this message translates to:
  /// **'એક વાર લોગિન, લોગઆઉટ સુધી ચાલુ'**
  String get stayLoggedInNote;

  /// No description provided for @enterUsername.
  ///
  /// In gu, this message translates to:
  /// **'યુઝરનેમ લખો'**
  String get enterUsername;

  /// No description provided for @enterPassword.
  ///
  /// In gu, this message translates to:
  /// **'પાસવર્ડ લખો'**
  String get enterPassword;

  /// No description provided for @loginInvalid.
  ///
  /// In gu, this message translates to:
  /// **'યુઝરનેમ અથવા પાસવર્ડ ખોટો છે'**
  String get loginInvalid;

  /// No description provided for @loginDisabled.
  ///
  /// In gu, this message translates to:
  /// **'આ એકાઉન્ટ બંધ છે'**
  String get loginDisabled;

  /// No description provided for @errorNoConnection.
  ///
  /// In gu, this message translates to:
  /// **'સર્વર સાથે જોડાઈ શકાયું નથી. ઇન્ટરનેટ તપાસો'**
  String get errorNoConnection;

  /// No description provided for @errorGeneric.
  ///
  /// In gu, this message translates to:
  /// **'કંઈક ખોટું થયું. ફરી પ્રયત્ન કરો'**
  String get errorGeneric;

  /// No description provided for @tabHome.
  ///
  /// In gu, this message translates to:
  /// **'હોમ'**
  String get tabHome;

  /// No description provided for @tabTrips.
  ///
  /// In gu, this message translates to:
  /// **'ટ્રીપ'**
  String get tabTrips;

  /// No description provided for @tabKharcha.
  ///
  /// In gu, this message translates to:
  /// **'ખર્ચ'**
  String get tabKharcha;

  /// No description provided for @tabKhata.
  ///
  /// In gu, this message translates to:
  /// **'ખાતા'**
  String get tabKhata;

  /// No description provided for @tabReport.
  ///
  /// In gu, this message translates to:
  /// **'રિપોર્ટ'**
  String get tabReport;

  /// No description provided for @more.
  ///
  /// In gu, this message translates to:
  /// **'વધુ'**
  String get more;

  /// No description provided for @language.
  ///
  /// In gu, this message translates to:
  /// **'ભાષા'**
  String get language;

  /// No description provided for @languageGujarati.
  ///
  /// In gu, this message translates to:
  /// **'ગુજરાતી'**
  String get languageGujarati;

  /// No description provided for @languageEnglish.
  ///
  /// In gu, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @logout.
  ///
  /// In gu, this message translates to:
  /// **'લોગઆઉટ'**
  String get logout;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In gu, this message translates to:
  /// **'લોગઆઉટ કરવું છે?'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmBody.
  ///
  /// In gu, this message translates to:
  /// **'ફરી લોગિન કરવું પડશે.'**
  String get logoutConfirmBody;

  /// No description provided for @cancel.
  ///
  /// In gu, this message translates to:
  /// **'રદ કરો'**
  String get cancel;

  /// No description provided for @hello.
  ///
  /// In gu, this message translates to:
  /// **'નમસ્તે, {name}'**
  String hello(String name);

  /// No description provided for @comingSoon.
  ///
  /// In gu, this message translates to:
  /// **'આ સુવિધા જલ્દી આવશે'**
  String get comingSoon;

  /// No description provided for @vehicles.
  ///
  /// In gu, this message translates to:
  /// **'ગાડીઓ'**
  String get vehicles;

  /// No description provided for @drivers.
  ///
  /// In gu, this message translates to:
  /// **'ડ્રાઇવરો'**
  String get drivers;

  /// No description provided for @parties.
  ///
  /// In gu, this message translates to:
  /// **'પાર્ટીઓ'**
  String get parties;

  /// No description provided for @accounts.
  ///
  /// In gu, this message translates to:
  /// **'ખાતા (Cash / Bank)'**
  String get accounts;

  /// No description provided for @users.
  ///
  /// In gu, this message translates to:
  /// **'યુઝર્સ'**
  String get users;

  /// No description provided for @addVehicle.
  ///
  /// In gu, this message translates to:
  /// **'નવી ગાડી ઉમેરો'**
  String get addVehicle;

  /// No description provided for @editVehicle.
  ///
  /// In gu, this message translates to:
  /// **'ગાડી સુધારો'**
  String get editVehicle;

  /// No description provided for @vehicleType.
  ///
  /// In gu, this message translates to:
  /// **'ગાડીનો પ્રકાર'**
  String get vehicleType;

  /// No description provided for @typeEicher.
  ///
  /// In gu, this message translates to:
  /// **'આઇશર'**
  String get typeEicher;

  /// No description provided for @typeBolero.
  ///
  /// In gu, this message translates to:
  /// **'બોલેરો'**
  String get typeBolero;

  /// No description provided for @typeTataAce.
  ///
  /// In gu, this message translates to:
  /// **'ટાટા એસ'**
  String get typeTataAce;

  /// No description provided for @typeTruck.
  ///
  /// In gu, this message translates to:
  /// **'ટ્રક'**
  String get typeTruck;

  /// No description provided for @typeTempo.
  ///
  /// In gu, this message translates to:
  /// **'ટેમ્પો'**
  String get typeTempo;

  /// No description provided for @typeOther.
  ///
  /// In gu, this message translates to:
  /// **'બીજું'**
  String get typeOther;

  /// No description provided for @vehicleName.
  ///
  /// In gu, this message translates to:
  /// **'ગાડીનું નામ'**
  String get vehicleName;

  /// No description provided for @vehicleNameHint.
  ///
  /// In gu, this message translates to:
  /// **'આપોઆપ ભરાય છે, બદલી શકાય'**
  String get vehicleNameHint;

  /// No description provided for @vehicleNumber.
  ///
  /// In gu, this message translates to:
  /// **'ગાડી નંબર'**
  String get vehicleNumber;

  /// No description provided for @docDates.
  ///
  /// In gu, this message translates to:
  /// **'વધુ વિગત (વીમો, PUC તારીખ)'**
  String get docDates;

  /// No description provided for @docInsurance.
  ///
  /// In gu, this message translates to:
  /// **'વીમો પૂરો થાય'**
  String get docInsurance;

  /// No description provided for @docPuc.
  ///
  /// In gu, this message translates to:
  /// **'PUC પૂરું થાય'**
  String get docPuc;

  /// No description provided for @docFitness.
  ///
  /// In gu, this message translates to:
  /// **'ફિટનેસ પૂરું થાય'**
  String get docFitness;

  /// No description provided for @docPermit.
  ///
  /// In gu, this message translates to:
  /// **'પરમિટ પૂરું થાય'**
  String get docPermit;

  /// No description provided for @docTax.
  ///
  /// In gu, this message translates to:
  /// **'ટેક્સ ભરવાનો'**
  String get docTax;

  /// No description provided for @pickDate.
  ///
  /// In gu, this message translates to:
  /// **'તારીખ પસંદ કરો'**
  String get pickDate;

  /// No description provided for @addDriver.
  ///
  /// In gu, this message translates to:
  /// **'નવો ડ્રાઇવર'**
  String get addDriver;

  /// No description provided for @editDriver.
  ///
  /// In gu, this message translates to:
  /// **'ડ્રાઇવર સુધારો'**
  String get editDriver;

  /// No description provided for @name.
  ///
  /// In gu, this message translates to:
  /// **'નામ'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In gu, this message translates to:
  /// **'ફોન નંબર'**
  String get phone;

  /// No description provided for @defaultVehicle.
  ///
  /// In gu, this message translates to:
  /// **'મુખ્ય ગાડી'**
  String get defaultVehicle;

  /// No description provided for @none.
  ///
  /// In gu, this message translates to:
  /// **'કોઈ નહીં'**
  String get none;

  /// No description provided for @addParty.
  ///
  /// In gu, this message translates to:
  /// **'નવી પાર્ટી'**
  String get addParty;

  /// No description provided for @editParty.
  ///
  /// In gu, this message translates to:
  /// **'પાર્ટી સુધારો'**
  String get editParty;

  /// No description provided for @partyName.
  ///
  /// In gu, this message translates to:
  /// **'પાર્ટીનું નામ'**
  String get partyName;

  /// No description provided for @paymentCycle.
  ///
  /// In gu, this message translates to:
  /// **'પેમેન્ટ ક્યારે આપે'**
  String get paymentCycle;

  /// No description provided for @cycleDaily.
  ///
  /// In gu, this message translates to:
  /// **'રોજ'**
  String get cycleDaily;

  /// No description provided for @cycleTenDays.
  ///
  /// In gu, this message translates to:
  /// **'10 દિવસે'**
  String get cycleTenDays;

  /// No description provided for @cycleMonthly.
  ///
  /// In gu, this message translates to:
  /// **'મહિને'**
  String get cycleMonthly;

  /// No description provided for @addAccount.
  ///
  /// In gu, this message translates to:
  /// **'નવું ખાતું'**
  String get addAccount;

  /// No description provided for @editAccount.
  ///
  /// In gu, this message translates to:
  /// **'ખાતું સુધારો'**
  String get editAccount;

  /// No description provided for @accountName.
  ///
  /// In gu, this message translates to:
  /// **'ખાતાનું નામ'**
  String get accountName;

  /// No description provided for @accountNameHint.
  ///
  /// In gu, this message translates to:
  /// **'જેમ કે Cash - જયદીપ'**
  String get accountNameHint;

  /// No description provided for @kindCash.
  ///
  /// In gu, this message translates to:
  /// **'રોકડ'**
  String get kindCash;

  /// No description provided for @kindBank.
  ///
  /// In gu, this message translates to:
  /// **'બેંક'**
  String get kindBank;

  /// No description provided for @kindUpi.
  ///
  /// In gu, this message translates to:
  /// **'UPI'**
  String get kindUpi;

  /// No description provided for @openingBalance.
  ///
  /// In gu, this message translates to:
  /// **'શરૂઆતની રકમ'**
  String get openingBalance;

  /// No description provided for @addUser.
  ///
  /// In gu, this message translates to:
  /// **'નવો યુઝર'**
  String get addUser;

  /// No description provided for @editUser.
  ///
  /// In gu, this message translates to:
  /// **'યુઝર સુધારો'**
  String get editUser;

  /// No description provided for @fullName.
  ///
  /// In gu, this message translates to:
  /// **'પૂરું નામ'**
  String get fullName;

  /// No description provided for @newPasswordOptional.
  ///
  /// In gu, this message translates to:
  /// **'નવો પાસવર્ડ (ખાલી રાખો તો બદલાશે નહીં)'**
  String get newPasswordOptional;

  /// No description provided for @userActive.
  ///
  /// In gu, this message translates to:
  /// **'ચાલુ છે'**
  String get userActive;

  /// No description provided for @passwordTooShort.
  ///
  /// In gu, this message translates to:
  /// **'પાસવર્ડ ઓછામાં ઓછા 6 અક્ષરનો રાખો'**
  String get passwordTooShort;

  /// No description provided for @usernameRule.
  ///
  /// In gu, this message translates to:
  /// **'3-32 અક્ષર: નાના અંગ્રેજી અક્ષર, આંકડા, . - _'**
  String get usernameRule;

  /// No description provided for @save.
  ///
  /// In gu, this message translates to:
  /// **'સેવ કરો'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In gu, this message translates to:
  /// **'કાઢી નાખો'**
  String get delete;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In gu, this message translates to:
  /// **'કાઢી નાખવું છે?'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmBody.
  ///
  /// In gu, this message translates to:
  /// **'તે લિસ્ટમાંથી હટી જશે.'**
  String get deleteConfirmBody;

  /// No description provided for @emptyVehicles.
  ///
  /// In gu, this message translates to:
  /// **'હજી કોઈ ગાડી નથી'**
  String get emptyVehicles;

  /// No description provided for @emptyDrivers.
  ///
  /// In gu, this message translates to:
  /// **'હજી કોઈ ડ્રાઇવર નથી'**
  String get emptyDrivers;

  /// No description provided for @emptyParties.
  ///
  /// In gu, this message translates to:
  /// **'હજી કોઈ પાર્ટી નથી'**
  String get emptyParties;

  /// No description provided for @emptyAccounts.
  ///
  /// In gu, this message translates to:
  /// **'હજી કોઈ ખાતું નથી'**
  String get emptyAccounts;

  /// No description provided for @emptyUsers.
  ///
  /// In gu, this message translates to:
  /// **'હજી કોઈ યુઝર નથી'**
  String get emptyUsers;

  /// No description provided for @emptyHint.
  ///
  /// In gu, this message translates to:
  /// **'નીચેના બટનથી ઉમેરો'**
  String get emptyHint;

  /// No description provided for @required.
  ///
  /// In gu, this message translates to:
  /// **'આ ખાનું ભરવું જરૂરી છે'**
  String get required;

  /// No description provided for @invalidNumber.
  ///
  /// In gu, this message translates to:
  /// **'સાચો ગાડી નંબર લખો'**
  String get invalidNumber;

  /// No description provided for @invalidPhone.
  ///
  /// In gu, this message translates to:
  /// **'સાચો ફોન નંબર લખો'**
  String get invalidPhone;

  /// No description provided for @errorDuplicate.
  ///
  /// In gu, this message translates to:
  /// **'આ પહેલેથી લિસ્ટમાં છે'**
  String get errorDuplicate;

  /// No description provided for @errorInvalid.
  ///
  /// In gu, this message translates to:
  /// **'વિગત તપાસો'**
  String get errorInvalid;

  /// No description provided for @retry.
  ///
  /// In gu, this message translates to:
  /// **'ફરી પ્રયત્ન'**
  String get retry;

  /// No description provided for @placeSearchHint.
  ///
  /// In gu, this message translates to:
  /// **'સ્થળ શોધો (Surat, સુરત)'**
  String get placeSearchHint;

  /// No description provided for @placePopular.
  ///
  /// In gu, this message translates to:
  /// **'વધુ વપરાતા'**
  String get placePopular;

  /// No description provided for @placeNoResult.
  ///
  /// In gu, this message translates to:
  /// **'કોઈ સ્થળ મળ્યું નથી'**
  String get placeNoResult;

  /// No description provided for @placeAddHint.
  ///
  /// In gu, this message translates to:
  /// **'ગુજરાતી નામ પસંદ કરો'**
  String get placeAddHint;

  /// No description provided for @placeChecking.
  ///
  /// In gu, this message translates to:
  /// **'ગુજરાતી નામ શોધી રહ્યા છીએ…'**
  String get placeChecking;

  /// No description provided for @placeTypeGujarati.
  ///
  /// In gu, this message translates to:
  /// **'ગુજરાતીમાં નામ લખો'**
  String get placeTypeGujarati;

  /// No description provided for @fromPlace.
  ///
  /// In gu, this message translates to:
  /// **'ક્યાંથી'**
  String get fromPlace;

  /// No description provided for @toPlace.
  ///
  /// In gu, this message translates to:
  /// **'ક્યાં સુધી'**
  String get toPlace;

  /// No description provided for @placeAdd.
  ///
  /// In gu, this message translates to:
  /// **'“{name}” ઉમેરો'**
  String placeAdd(String name);

  /// No description provided for @userInactive.
  ///
  /// In gu, this message translates to:
  /// **'બંધ'**
  String get userInactive;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'gu'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppL10nEn();
    case 'gu':
      return AppL10nGu();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
