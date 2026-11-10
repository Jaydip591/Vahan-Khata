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

  /// No description provided for @newTrip.
  ///
  /// In gu, this message translates to:
  /// **'નવી ટ્રીપ'**
  String get newTrip;

  /// No description provided for @editTrip.
  ///
  /// In gu, this message translates to:
  /// **'ટ્રીપ સુધારો'**
  String get editTrip;

  /// No description provided for @copyLastTrip.
  ///
  /// In gu, this message translates to:
  /// **'પાછલી ટ્રીપ જેવી'**
  String get copyLastTrip;

  /// No description provided for @quickRoutes.
  ///
  /// In gu, this message translates to:
  /// **'ઝડપી રૂટ (એક ટેપ)'**
  String get quickRoutes;

  /// No description provided for @vehicle.
  ///
  /// In gu, this message translates to:
  /// **'ગાડી'**
  String get vehicle;

  /// No description provided for @party.
  ///
  /// In gu, this message translates to:
  /// **'પાર્ટી'**
  String get party;

  /// No description provided for @driver.
  ///
  /// In gu, this message translates to:
  /// **'ડ્રાઇવર'**
  String get driver;

  /// No description provided for @choosePlace.
  ///
  /// In gu, this message translates to:
  /// **'સ્થળ પસંદ કરો'**
  String get choosePlace;

  /// No description provided for @bhada.
  ///
  /// In gu, this message translates to:
  /// **'ભાડું'**
  String get bhada;

  /// No description provided for @tapToType.
  ///
  /// In gu, this message translates to:
  /// **'લખવા માટે રકમ પર ટેપ કરો'**
  String get tapToType;

  /// No description provided for @advanceReceived.
  ///
  /// In gu, this message translates to:
  /// **'એડવાન્સ મળ્યું'**
  String get advanceReceived;

  /// No description provided for @advFull.
  ///
  /// In gu, this message translates to:
  /// **'પૂરું'**
  String get advFull;

  /// No description provided for @advHalf.
  ///
  /// In gu, this message translates to:
  /// **'અડધું'**
  String get advHalf;

  /// No description provided for @advNone.
  ///
  /// In gu, this message translates to:
  /// **'કંઈ નહીં'**
  String get advNone;

  /// No description provided for @advCustom.
  ///
  /// In gu, this message translates to:
  /// **'બીજું'**
  String get advCustom;

  /// No description provided for @advanceLabel.
  ///
  /// In gu, this message translates to:
  /// **'એડવાન્સ'**
  String get advanceLabel;

  /// No description provided for @balanceLeft.
  ///
  /// In gu, this message translates to:
  /// **'બાકી'**
  String get balanceLeft;

  /// No description provided for @howReceived.
  ///
  /// In gu, this message translates to:
  /// **'કેવી રીતે મળ્યું'**
  String get howReceived;

  /// No description provided for @modeCash.
  ///
  /// In gu, this message translates to:
  /// **'રોકડ'**
  String get modeCash;

  /// No description provided for @modeOnline.
  ///
  /// In gu, this message translates to:
  /// **'ઓનલાઇન'**
  String get modeOnline;

  /// No description provided for @whichAccount.
  ///
  /// In gu, this message translates to:
  /// **'કયા ખાતામાં'**
  String get whichAccount;

  /// No description provided for @dateLabel.
  ///
  /// In gu, this message translates to:
  /// **'તારીખ'**
  String get dateLabel;

  /// No description provided for @today.
  ///
  /// In gu, this message translates to:
  /// **'આજે'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In gu, this message translates to:
  /// **'ગઈકાલે'**
  String get yesterday;

  /// No description provided for @otherDate.
  ///
  /// In gu, this message translates to:
  /// **'બીજી તારીખ'**
  String get otherDate;

  /// No description provided for @tripSaved.
  ///
  /// In gu, this message translates to:
  /// **'ટ્રીપ સેવ થઈ'**
  String get tripSaved;

  /// No description provided for @needAccountFirst.
  ///
  /// In gu, this message translates to:
  /// **'પહેલા ખાતું ઉમેરો (વધુ → ખાતા)'**
  String get needAccountFirst;

  /// No description provided for @needVehicleFirst.
  ///
  /// In gu, this message translates to:
  /// **'પહેલા ગાડી ઉમેરો (વધુ → ગાડીઓ)'**
  String get needVehicleFirst;

  /// No description provided for @needPartyFirst.
  ///
  /// In gu, this message translates to:
  /// **'પહેલા પાર્ટી ઉમેરો (વધુ → પાર્ટીઓ)'**
  String get needPartyFirst;

  /// No description provided for @chooseVehicle.
  ///
  /// In gu, this message translates to:
  /// **'ગાડી પસંદ કરો'**
  String get chooseVehicle;

  /// No description provided for @chooseParty.
  ///
  /// In gu, this message translates to:
  /// **'પાર્ટી પસંદ કરો'**
  String get chooseParty;

  /// No description provided for @chooseRoute.
  ///
  /// In gu, this message translates to:
  /// **'ક્યાંથી અને ક્યાં સુધી પસંદ કરો'**
  String get chooseRoute;

  /// No description provided for @emptyTrips.
  ///
  /// In gu, this message translates to:
  /// **'આ મહિને કોઈ ટ્રીપ નથી'**
  String get emptyTrips;

  /// No description provided for @tripDetail.
  ///
  /// In gu, this message translates to:
  /// **'ટ્રીપની વિગત'**
  String get tripDetail;

  /// No description provided for @closeTrip.
  ///
  /// In gu, this message translates to:
  /// **'ટ્રીપ પૂરી કરો'**
  String get closeTrip;

  /// No description provided for @reopenTrip.
  ///
  /// In gu, this message translates to:
  /// **'ફરી ચાલુ કરો'**
  String get reopenTrip;

  /// No description provided for @statusRunning.
  ///
  /// In gu, this message translates to:
  /// **'ચાલુ'**
  String get statusRunning;

  /// No description provided for @statusClosed.
  ///
  /// In gu, this message translates to:
  /// **'પૂરી'**
  String get statusClosed;

  /// No description provided for @payUnpaid.
  ///
  /// In gu, this message translates to:
  /// **'બાકી'**
  String get payUnpaid;

  /// No description provided for @payPartial.
  ///
  /// In gu, this message translates to:
  /// **'આંશિક'**
  String get payPartial;

  /// No description provided for @payPaid.
  ///
  /// In gu, this message translates to:
  /// **'મળી ગયા'**
  String get payPaid;

  /// No description provided for @receivedLabel.
  ///
  /// In gu, this message translates to:
  /// **'મળ્યા'**
  String get receivedLabel;

  /// No description provided for @advanceNotEditable.
  ///
  /// In gu, this message translates to:
  /// **'એડવાન્સ અહીં બદલાતું નથી. પેમેન્ટ ખાતા ટેબમાંથી ઉમેરો.'**
  String get advanceNotEditable;

  /// No description provided for @amountLabel.
  ///
  /// In gu, this message translates to:
  /// **'રકમ'**
  String get amountLabel;

  /// No description provided for @amountOk.
  ///
  /// In gu, this message translates to:
  /// **'બરાબર'**
  String get amountOk;

  /// No description provided for @enterAmount.
  ///
  /// In gu, this message translates to:
  /// **'રકમ લખો'**
  String get enterAmount;

  /// No description provided for @whatExpense.
  ///
  /// In gu, this message translates to:
  /// **'શેનો ખર્ચ?'**
  String get whatExpense;

  /// No description provided for @catDiesel.
  ///
  /// In gu, this message translates to:
  /// **'ડીઝલ'**
  String get catDiesel;

  /// No description provided for @catToll.
  ///
  /// In gu, this message translates to:
  /// **'ટોલ'**
  String get catToll;

  /// No description provided for @catRepair.
  ///
  /// In gu, this message translates to:
  /// **'રિપેર'**
  String get catRepair;

  /// No description provided for @catAllowance.
  ///
  /// In gu, this message translates to:
  /// **'ખાવા-પીવા / ભથ્થું'**
  String get catAllowance;

  /// No description provided for @catChallan.
  ///
  /// In gu, this message translates to:
  /// **'ચલણ'**
  String get catChallan;

  /// No description provided for @catOther.
  ///
  /// In gu, this message translates to:
  /// **'બીજું'**
  String get catOther;

  /// No description provided for @liters.
  ///
  /// In gu, this message translates to:
  /// **'લિટર'**
  String get liters;

  /// No description provided for @ratePerLiter.
  ///
  /// In gu, this message translates to:
  /// **'ભાવ / લિટર'**
  String get ratePerLiter;

  /// No description provided for @odometer.
  ///
  /// In gu, this message translates to:
  /// **'ઓડોમીટર (કિમી)'**
  String get odometer;

  /// No description provided for @repairKind.
  ///
  /// In gu, this message translates to:
  /// **'શું રિપેર કર્યું?'**
  String get repairKind;

  /// No description provided for @rkTyre.
  ///
  /// In gu, this message translates to:
  /// **'ટાયર'**
  String get rkTyre;

  /// No description provided for @rkOil.
  ///
  /// In gu, this message translates to:
  /// **'ઓઇલ'**
  String get rkOil;

  /// No description provided for @rkEngine.
  ///
  /// In gu, this message translates to:
  /// **'એન્જિન'**
  String get rkEngine;

  /// No description provided for @rkBattery.
  ///
  /// In gu, this message translates to:
  /// **'બેટરી'**
  String get rkBattery;

  /// No description provided for @rkService.
  ///
  /// In gu, this message translates to:
  /// **'સર્વિસ'**
  String get rkService;

  /// No description provided for @expenseSaved.
  ///
  /// In gu, this message translates to:
  /// **'ખર્ચ સેવ થયો'**
  String get expenseSaved;

  /// No description provided for @recentExpenses.
  ///
  /// In gu, this message translates to:
  /// **'આ મહિનાનો ખર્ચ'**
  String get recentExpenses;

  /// No description provided for @emptyExpenses.
  ///
  /// In gu, this message translates to:
  /// **'આ મહિને કોઈ ખર્ચ નથી'**
  String get emptyExpenses;

  /// No description provided for @paidFrom.
  ///
  /// In gu, this message translates to:
  /// **'કયા ખાતામાંથી'**
  String get paidFrom;

  /// No description provided for @khataTitle.
  ///
  /// In gu, this message translates to:
  /// **'પાર્ટી ખાતા'**
  String get khataTitle;

  /// No description provided for @totalDue.
  ///
  /// In gu, this message translates to:
  /// **'કુલ બાકી લેવાના'**
  String get totalDue;

  /// No description provided for @daysOld.
  ///
  /// In gu, this message translates to:
  /// **'{days} દિવસ જૂનું'**
  String daysOld(int days);

  /// No description provided for @settled.
  ///
  /// In gu, this message translates to:
  /// **'ચૂકતે'**
  String get settled;

  /// No description provided for @receivePayment.
  ///
  /// In gu, this message translates to:
  /// **'પેમેન્ટ મળ્યું'**
  String get receivePayment;

  /// No description provided for @whoPaid.
  ///
  /// In gu, this message translates to:
  /// **'કોણે આપ્યા'**
  String get whoPaid;

  /// No description provided for @howMuch.
  ///
  /// In gu, this message translates to:
  /// **'કેટલા મળ્યા'**
  String get howMuch;

  /// No description provided for @payAll.
  ///
  /// In gu, this message translates to:
  /// **'બધા'**
  String get payAll;

  /// No description provided for @payHalf.
  ///
  /// In gu, this message translates to:
  /// **'અડધા'**
  String get payHalf;

  /// No description provided for @payCustom.
  ///
  /// In gu, this message translates to:
  /// **'બીજી રકમ'**
  String get payCustom;

  /// No description provided for @willCredit.
  ///
  /// In gu, this message translates to:
  /// **'જમા થશે'**
  String get willCredit;

  /// No description provided for @remaining.
  ///
  /// In gu, this message translates to:
  /// **'બાકી રહેશે'**
  String get remaining;

  /// No description provided for @paymentSaved.
  ///
  /// In gu, this message translates to:
  /// **'પેમેન્ટ સેવ થયું'**
  String get paymentSaved;

  /// No description provided for @totalBhada.
  ///
  /// In gu, this message translates to:
  /// **'કુલ ભાડું'**
  String get totalBhada;

  /// No description provided for @totalReceived.
  ///
  /// In gu, this message translates to:
  /// **'કુલ મળ્યા'**
  String get totalReceived;

  /// No description provided for @tripsHeading.
  ///
  /// In gu, this message translates to:
  /// **'ટ્રીપ'**
  String get tripsHeading;

  /// No description provided for @paymentsHeading.
  ///
  /// In gu, this message translates to:
  /// **'પેમેન્ટ'**
  String get paymentsHeading;

  /// No description provided for @partyHasCredit.
  ///
  /// In gu, this message translates to:
  /// **'એડવાન્સ જમા'**
  String get partyHasCredit;

  /// No description provided for @monthPrev.
  ///
  /// In gu, this message translates to:
  /// **'પાછલો મહિનો'**
  String get monthPrev;

  /// No description provided for @monthNext.
  ///
  /// In gu, this message translates to:
  /// **'આવતો મહિનો'**
  String get monthNext;

  /// No description provided for @creditLabel.
  ///
  /// In gu, this message translates to:
  /// **'એડવાન્સ જમા'**
  String get creditLabel;

  /// No description provided for @newPartyShort.
  ///
  /// In gu, this message translates to:
  /// **'પાર્ટી'**
  String get newPartyShort;

  /// No description provided for @homeDueCard.
  ///
  /// In gu, this message translates to:
  /// **'બાકી લેવાના'**
  String get homeDueCard;

  /// No description provided for @noPartyYet.
  ///
  /// In gu, this message translates to:
  /// **'પહેલા પાર્ટી ઉમેરો'**
  String get noPartyYet;

  /// No description provided for @advanceTag.
  ///
  /// In gu, this message translates to:
  /// **'એડવાન્સ'**
  String get advanceTag;

  /// No description provided for @deletePaymentTitle.
  ///
  /// In gu, this message translates to:
  /// **'આ પેમેન્ટ કાઢી નાખવું છે?'**
  String get deletePaymentTitle;

  /// No description provided for @chooseAccount.
  ///
  /// In gu, this message translates to:
  /// **'ખાતું પસંદ કરો'**
  String get chooseAccount;

  /// No description provided for @reportVehicle.
  ///
  /// In gu, this message translates to:
  /// **'ગાડી'**
  String get reportVehicle;

  /// No description provided for @reportParty.
  ///
  /// In gu, this message translates to:
  /// **'પાર્ટી'**
  String get reportParty;

  /// No description provided for @reportMonths.
  ///
  /// In gu, this message translates to:
  /// **'મહિના'**
  String get reportMonths;

  /// No description provided for @reportExpense.
  ///
  /// In gu, this message translates to:
  /// **'ખર્ચ'**
  String get reportExpense;

  /// No description provided for @profitLabel.
  ///
  /// In gu, this message translates to:
  /// **'નફો'**
  String get profitLabel;

  /// No description provided for @incomeLabel.
  ///
  /// In gu, this message translates to:
  /// **'આવક'**
  String get incomeLabel;

  /// No description provided for @expenseLabel.
  ///
  /// In gu, this message translates to:
  /// **'જાવક'**
  String get expenseLabel;

  /// No description provided for @bhadaLabel.
  ///
  /// In gu, this message translates to:
  /// **'ભાડું'**
  String get bhadaLabel;

  /// No description provided for @tripsCount.
  ///
  /// In gu, this message translates to:
  /// **'{count} ટ્રીપ'**
  String tripsCount(Object count);

  /// No description provided for @mileageValue.
  ///
  /// In gu, this message translates to:
  /// **'{value} કિમી/લિટર'**
  String mileageValue(Object value);

  /// No description provided for @kmValue.
  ///
  /// In gu, this message translates to:
  /// **'{km} કિમી'**
  String kmValue(Object km);

  /// No description provided for @emptyReport.
  ///
  /// In gu, this message translates to:
  /// **'આ મહિને કંઈ નોંધાયું નથી'**
  String get emptyReport;

  /// No description provided for @totalExpense.
  ///
  /// In gu, this message translates to:
  /// **'કુલ ખર્ચ'**
  String get totalExpense;

  /// No description provided for @homeProfit.
  ///
  /// In gu, this message translates to:
  /// **'આ મહિનાનો નફો'**
  String get homeProfit;

  /// No description provided for @vsLastMonth.
  ///
  /// In gu, this message translates to:
  /// **'ગયા મહિને {amount}'**
  String vsLastMonth(Object amount);

  /// No description provided for @collectedLabel.
  ///
  /// In gu, this message translates to:
  /// **'મળ્યા'**
  String get collectedLabel;

  /// No description provided for @vehicleProfitTitle.
  ///
  /// In gu, this message translates to:
  /// **'ગાડી પ્રમાણે નફો'**
  String get vehicleProfitTitle;

  /// No description provided for @seeAll.
  ///
  /// In gu, this message translates to:
  /// **'બધું જુઓ'**
  String get seeAll;

  /// No description provided for @otherExpenses.
  ///
  /// In gu, this message translates to:
  /// **'બીજા ખર્ચ'**
  String get otherExpenses;

  /// No description provided for @litersLabel.
  ///
  /// In gu, this message translates to:
  /// **'લિટર'**
  String get litersLabel;

  /// No description provided for @avgRate.
  ///
  /// In gu, this message translates to:
  /// **'સરેરાશ ભાવ'**
  String get avgRate;

  /// No description provided for @entriesLabel.
  ///
  /// In gu, this message translates to:
  /// **'એન્ટ્રી'**
  String get entriesLabel;

  /// No description provided for @monthDetails.
  ///
  /// In gu, this message translates to:
  /// **'મહિનાની વિગત'**
  String get monthDetails;

  /// No description provided for @litersValue.
  ///
  /// In gu, this message translates to:
  /// **'{value} લિટર'**
  String litersValue(Object value);

  /// No description provided for @rateValue.
  ///
  /// In gu, this message translates to:
  /// **'{rate}/લિટર'**
  String rateValue(Object rate);

  /// No description provided for @pendingStrip.
  ///
  /// In gu, this message translates to:
  /// **'{count} એન્ટ્રી મોકલવાની બાકી'**
  String pendingStrip(Object count);

  /// No description provided for @pendingTitle.
  ///
  /// In gu, this message translates to:
  /// **'મોકલવાની બાકી'**
  String get pendingTitle;

  /// No description provided for @allSent.
  ///
  /// In gu, this message translates to:
  /// **'બધું મોકલાઈ ગયું'**
  String get allSent;

  /// No description provided for @pendingHelp.
  ///
  /// In gu, this message translates to:
  /// **'આ એન્ટ્રી ફોનમાં સલામત છે. ઇન્ટરનેટ મળતાં જ આપમેળે મોકલાશે.'**
  String get pendingHelp;

  /// No description provided for @sendNow.
  ///
  /// In gu, this message translates to:
  /// **'હમણાં મોકલો'**
  String get sendNow;

  /// No description provided for @notSentYet.
  ///
  /// In gu, this message translates to:
  /// **'મોકલવાની બાકી'**
  String get notSentYet;

  /// No description provided for @notSentFailed.
  ///
  /// In gu, this message translates to:
  /// **'સર્વરે ના પાડી'**
  String get notSentFailed;

  /// No description provided for @notSentFailedHelp.
  ///
  /// In gu, this message translates to:
  /// **'સર્વરે આ એન્ટ્રી સ્વીકારી નથી. કાઢીને ફરી લખો.'**
  String get notSentFailedHelp;

  /// No description provided for @deletePendingTitle.
  ///
  /// In gu, this message translates to:
  /// **'આ એન્ટ્રી કાઢી નાખવી?'**
  String get deletePendingTitle;

  /// No description provided for @deletePendingBody.
  ///
  /// In gu, this message translates to:
  /// **'આ એન્ટ્રી હજી સર્વર પર ગઈ નથી. કાઢી નાખશો તો કાયમ માટે જશે.'**
  String get deletePendingBody;

  /// No description provided for @savedOffline.
  ///
  /// In gu, this message translates to:
  /// **'ઇન્ટરનેટ નથી. એન્ટ્રી ફોનમાં સાચવી, નેટ આવતાં મોકલાશે.'**
  String get savedOffline;

  /// No description provided for @logoutPendingWarning.
  ///
  /// In gu, this message translates to:
  /// **'{count} એન્ટ્રી હજી મોકલાઈ નથી. લૉગઆઉટ કરશો તો તે જતી રહેશે.'**
  String logoutPendingWarning(Object count);

  /// No description provided for @fuelLabel.
  ///
  /// In gu, this message translates to:
  /// **'ઇંધણ'**
  String get fuelLabel;

  /// No description provided for @fuelType.
  ///
  /// In gu, this message translates to:
  /// **'ઇંધણનો પ્રકાર'**
  String get fuelType;

  /// No description provided for @catPetrol.
  ///
  /// In gu, this message translates to:
  /// **'પેટ્રોલ'**
  String get catPetrol;

  /// No description provided for @catCng.
  ///
  /// In gu, this message translates to:
  /// **'CNG'**
  String get catCng;

  /// No description provided for @fuelCngPetrol.
  ///
  /// In gu, this message translates to:
  /// **'CNG + પેટ્રોલ'**
  String get fuelCngPetrol;

  /// No description provided for @kgLabel.
  ///
  /// In gu, this message translates to:
  /// **'કિગ્રા'**
  String get kgLabel;

  /// No description provided for @kgValue.
  ///
  /// In gu, this message translates to:
  /// **'{value} કિગ્રા'**
  String kgValue(Object value);

  /// No description provided for @mileageKg.
  ///
  /// In gu, this message translates to:
  /// **'{value} કિમી/કિગ્રા'**
  String mileageKg(Object value);

  /// No description provided for @whichFuel.
  ///
  /// In gu, this message translates to:
  /// **'કયું ઇંધણ?'**
  String get whichFuel;

  /// No description provided for @rateKg.
  ///
  /// In gu, this message translates to:
  /// **'{rate}/કિગ્રા'**
  String rateKg(Object rate);

  /// No description provided for @exportTitle.
  ///
  /// In gu, this message translates to:
  /// **'શેર / એક્સપોર્ટ'**
  String get exportTitle;

  /// No description provided for @exportPdf.
  ///
  /// In gu, this message translates to:
  /// **'PDF'**
  String get exportPdf;

  /// No description provided for @exportPdfHelp.
  ///
  /// In gu, this message translates to:
  /// **'વોટ્સએપ માટે સૌથી સારું'**
  String get exportPdfHelp;

  /// No description provided for @exportExcel.
  ///
  /// In gu, this message translates to:
  /// **'Excel'**
  String get exportExcel;

  /// No description provided for @exportExcelHelp.
  ///
  /// In gu, this message translates to:
  /// **'Excel કે Google Sheets માં ખોલવા માટે'**
  String get exportExcelHelp;

  /// No description provided for @exporting.
  ///
  /// In gu, this message translates to:
  /// **'ફાઇલ તૈયાર થાય છે…'**
  String get exporting;

  /// No description provided for @exportFailed.
  ///
  /// In gu, this message translates to:
  /// **'ફાઇલ બની શકી નહીં. ફરી પ્રયત્ન કરો.'**
  String get exportFailed;

  /// No description provided for @docParty.
  ///
  /// In gu, this message translates to:
  /// **'પાર્ટી સ્ટેટમેન્ટ'**
  String get docParty;

  /// No description provided for @docMonth.
  ///
  /// In gu, this message translates to:
  /// **'માસિક રિપોર્ટ'**
  String get docMonth;

  /// No description provided for @colDate.
  ///
  /// In gu, this message translates to:
  /// **'તારીખ'**
  String get colDate;

  /// No description provided for @colRoute.
  ///
  /// In gu, this message translates to:
  /// **'રૂટ'**
  String get colRoute;

  /// No description provided for @colDue.
  ///
  /// In gu, this message translates to:
  /// **'બાકી'**
  String get colDue;

  /// No description provided for @colMode.
  ///
  /// In gu, this message translates to:
  /// **'રીત'**
  String get colMode;

  /// No description provided for @colAccount.
  ///
  /// In gu, this message translates to:
  /// **'ખાતું'**
  String get colAccount;

  /// No description provided for @colCategory.
  ///
  /// In gu, this message translates to:
  /// **'પ્રકાર'**
  String get colCategory;

  /// No description provided for @colAmount.
  ///
  /// In gu, this message translates to:
  /// **'રકમ'**
  String get colAmount;

  /// No description provided for @colQty.
  ///
  /// In gu, this message translates to:
  /// **'જથ્થો'**
  String get colQty;

  /// No description provided for @colOdometer.
  ///
  /// In gu, this message translates to:
  /// **'ઓડોમીટર'**
  String get colOdometer;

  /// No description provided for @colParty.
  ///
  /// In gu, this message translates to:
  /// **'પાર્ટી'**
  String get colParty;

  /// No description provided for @pageOf.
  ///
  /// In gu, this message translates to:
  /// **'પાનું {n} / {total}'**
  String pageOf(Object n, Object total);

  /// No description provided for @generatedOn.
  ///
  /// In gu, this message translates to:
  /// **'બનાવ્યું {date}'**
  String generatedOn(Object date);

  /// No description provided for @sheetSummary.
  ///
  /// In gu, this message translates to:
  /// **'સારાંશ'**
  String get sheetSummary;

  /// No description provided for @tripExpenses.
  ///
  /// In gu, this message translates to:
  /// **'ટ્રીપનો ખર્ચ'**
  String get tripExpenses;

  /// No description provided for @tripNet.
  ///
  /// In gu, this message translates to:
  /// **'આ ટ્રીપનો નફો'**
  String get tripNet;

  /// No description provided for @noTripExpenses.
  ///
  /// In gu, this message translates to:
  /// **'આ ટ્રીપમાં હજી ખર્ચ નથી'**
  String get noTripExpenses;

  /// No description provided for @forTrip.
  ///
  /// In gu, this message translates to:
  /// **'ટ્રીપ'**
  String get forTrip;

  /// No description provided for @addTripExpense.
  ///
  /// In gu, this message translates to:
  /// **'આ ટ્રીપનો ખર્ચ ઉમેરો'**
  String get addTripExpense;

  /// No description provided for @vibration.
  ///
  /// In gu, this message translates to:
  /// **'ટેપ પર વાઇબ્રેશન'**
  String get vibration;

  /// No description provided for @reportBalance.
  ///
  /// In gu, this message translates to:
  /// **'બેલેન્સ'**
  String get reportBalance;

  /// No description provided for @balanceTotal.
  ///
  /// In gu, this message translates to:
  /// **'બધા ખાતામાં કુલ'**
  String get balanceTotal;

  /// No description provided for @balanceAllTime.
  ///
  /// In gu, this message translates to:
  /// **'શરૂઆતથી આજ સુધી'**
  String get balanceAllTime;

  /// No description provided for @balanceIn.
  ///
  /// In gu, this message translates to:
  /// **'આવ્યા'**
  String get balanceIn;

  /// No description provided for @balanceOut.
  ///
  /// In gu, this message translates to:
  /// **'ગયા'**
  String get balanceOut;

  /// No description provided for @balanceOpening.
  ///
  /// In gu, this message translates to:
  /// **'શરૂઆત'**
  String get balanceOpening;

  /// No description provided for @balanceNoAccount.
  ///
  /// In gu, this message translates to:
  /// **'{amount} ખર્ચમાં ખાતું પસંદ કર્યું નથી'**
  String balanceNoAccount(Object amount);

  /// No description provided for @inactiveTag.
  ///
  /// In gu, this message translates to:
  /// **'બંધ'**
  String get inactiveTag;

  /// No description provided for @profile.
  ///
  /// In gu, this message translates to:
  /// **'પ્રોફાઇલ'**
  String get profile;

  /// No description provided for @editProfile.
  ///
  /// In gu, this message translates to:
  /// **'પ્રોફાઇલ બદલો'**
  String get editProfile;

  /// No description provided for @phoneLabel.
  ///
  /// In gu, this message translates to:
  /// **'મોબાઇલ નંબર'**
  String get phoneLabel;

  /// No description provided for @phoneOptional.
  ///
  /// In gu, this message translates to:
  /// **'મોબાઇલ નંબર (જરૂરી નથી)'**
  String get phoneOptional;

  /// No description provided for @phoneInvalid.
  ///
  /// In gu, this message translates to:
  /// **'10 આંકડાનો નંબર લખો'**
  String get phoneInvalid;

  /// No description provided for @noPhone.
  ///
  /// In gu, this message translates to:
  /// **'નંબર ઉમેર્યો નથી'**
  String get noPhone;

  /// No description provided for @companyLabel.
  ///
  /// In gu, this message translates to:
  /// **'કંપની'**
  String get companyLabel;

  /// No description provided for @roleLabel.
  ///
  /// In gu, this message translates to:
  /// **'ભૂમિકા'**
  String get roleLabel;

  /// No description provided for @roleSuperadmin.
  ///
  /// In gu, this message translates to:
  /// **'માલિક (બધી છૂટ)'**
  String get roleSuperadmin;

  /// No description provided for @usernameLabel.
  ///
  /// In gu, this message translates to:
  /// **'યુઝરનેમ'**
  String get usernameLabel;

  /// No description provided for @changePassword.
  ///
  /// In gu, this message translates to:
  /// **'પાસવર્ડ બદલો'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In gu, this message translates to:
  /// **'હાલનો પાસવર્ડ'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In gu, this message translates to:
  /// **'નવો પાસવર્ડ'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In gu, this message translates to:
  /// **'નવો પાસવર્ડ ફરી લખો'**
  String get confirmPassword;

  /// No description provided for @passwordMismatch.
  ///
  /// In gu, this message translates to:
  /// **'બંને પાસવર્ડ સરખા નથી'**
  String get passwordMismatch;

  /// No description provided for @wrongCurrentPassword.
  ///
  /// In gu, this message translates to:
  /// **'હાલનો પાસવર્ડ ખોટો છે'**
  String get wrongCurrentPassword;

  /// No description provided for @passwordChanged.
  ///
  /// In gu, this message translates to:
  /// **'પાસવર્ડ બદલાઈ ગયો. બીજા ફોનમાંથી લોગઆઉટ થયું.'**
  String get passwordChanged;

  /// No description provided for @passwordChangeNote.
  ///
  /// In gu, this message translates to:
  /// **'પાસવર્ડ બદલવાથી બીજા બધા ફોનમાંથી લોગઆઉટ થશે. આ ફોન ચાલુ રહેશે.'**
  String get passwordChangeNote;

  /// No description provided for @settings.
  ///
  /// In gu, this message translates to:
  /// **'સેટિંગ્સ'**
  String get settings;

  /// No description provided for @manage.
  ///
  /// In gu, this message translates to:
  /// **'માહિતી'**
  String get manage;

  /// No description provided for @appVersion.
  ///
  /// In gu, this message translates to:
  /// **'એપ વર્ઝન'**
  String get appVersion;

  /// No description provided for @profileSaved.
  ///
  /// In gu, this message translates to:
  /// **'પ્રોફાઇલ સાચવી'**
  String get profileSaved;

  /// No description provided for @thisWeek.
  ///
  /// In gu, this message translates to:
  /// **'આ અઠવાડિયું'**
  String get thisWeek;

  /// No description provided for @weekTrips.
  ///
  /// In gu, this message translates to:
  /// **'ફેરા'**
  String get weekTrips;

  /// No description provided for @weekEarned.
  ///
  /// In gu, this message translates to:
  /// **'કમાણી'**
  String get weekEarned;

  /// No description provided for @weekSpent.
  ///
  /// In gu, this message translates to:
  /// **'ખર્ચ'**
  String get weekSpent;

  /// No description provided for @weekLeft.
  ///
  /// In gu, this message translates to:
  /// **'બચ્યા'**
  String get weekLeft;

  /// No description provided for @weekEmpty.
  ///
  /// In gu, this message translates to:
  /// **'આ અઠવાડિયે હજી કોઈ ટ્રીપ કે ખર્ચ નથી'**
  String get weekEmpty;

  /// No description provided for @weekBarsNote.
  ///
  /// In gu, this message translates to:
  /// **'દરરોજની કમાણી'**
  String get weekBarsNote;

  /// No description provided for @weekdaysShort.
  ///
  /// In gu, this message translates to:
  /// **'સોમ,મંગળ,બુધ,ગુરુ,શુક્ર,શનિ,રવિ'**
  String get weekdaysShort;
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
