// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Gujarati (`gu`).
class AppL10nGu extends AppL10n {
  AppL10nGu([String locale = 'gu']) : super(locale);

  @override
  String get appName => 'વાહન ખાતા';

  @override
  String get tagline => 'તમારો આખો હિસાબ, એક જગ્યાએ';

  @override
  String get username => 'યુઝરનેમ';

  @override
  String get password => 'પાસવર્ડ';

  @override
  String get loginButton => 'લોગિન કરો';

  @override
  String get stayLoggedInNote => 'એક વાર લોગિન, લોગઆઉટ સુધી ચાલુ';

  @override
  String get enterUsername => 'યુઝરનેમ લખો';

  @override
  String get enterPassword => 'પાસવર્ડ લખો';

  @override
  String get loginInvalid => 'યુઝરનેમ અથવા પાસવર્ડ ખોટો છે';

  @override
  String get loginDisabled => 'આ એકાઉન્ટ બંધ છે';

  @override
  String get errorNoConnection => 'સર્વર સાથે જોડાઈ શકાયું નથી. ઇન્ટરનેટ તપાસો';

  @override
  String get errorGeneric => 'કંઈક ખોટું થયું. ફરી પ્રયત્ન કરો';

  @override
  String get tabHome => 'હોમ';

  @override
  String get tabTrips => 'ટ્રીપ';

  @override
  String get tabKharcha => 'ખર્ચ';

  @override
  String get tabKhata => 'ખાતા';

  @override
  String get tabReport => 'રિપોર્ટ';

  @override
  String get more => 'વધુ';

  @override
  String get language => 'ભાષા';

  @override
  String get languageGujarati => 'ગુજરાતી';

  @override
  String get languageEnglish => 'English';

  @override
  String get logout => 'લોગઆઉટ';

  @override
  String get logoutConfirmTitle => 'લોગઆઉટ કરવું છે?';

  @override
  String get logoutConfirmBody => 'ફરી લોગિન કરવું પડશે.';

  @override
  String get cancel => 'રદ કરો';

  @override
  String hello(String name) {
    return 'નમસ્તે, $name';
  }

  @override
  String get comingSoon => 'આ સુવિધા જલ્દી આવશે';
}
