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
