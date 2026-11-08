// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Vahan Khata';

  @override
  String get tagline => 'All your accounts, in one place';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get loginButton => 'Log in';

  @override
  String get stayLoggedInNote =>
      'Log in once, stay logged in until you log out';

  @override
  String get enterUsername => 'Enter your username';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get loginInvalid => 'Incorrect username or password';

  @override
  String get loginDisabled => 'This account is disabled';

  @override
  String get errorNoConnection =>
      'Can\'t reach the server. Check your internet';

  @override
  String get errorGeneric => 'Something went wrong. Try again';

  @override
  String get tabHome => 'Home';

  @override
  String get tabTrips => 'Trips';

  @override
  String get tabKharcha => 'Expenses';

  @override
  String get tabKhata => 'Khata';

  @override
  String get tabReport => 'Reports';

  @override
  String get more => 'More';

  @override
  String get language => 'Language';

  @override
  String get languageGujarati => 'ગુજરાતી';

  @override
  String get languageEnglish => 'English';

  @override
  String get logout => 'Log out';

  @override
  String get logoutConfirmTitle => 'Log out?';

  @override
  String get logoutConfirmBody => 'You will need to log in again.';

  @override
  String get cancel => 'Cancel';

  @override
  String hello(String name) {
    return 'Hello, $name';
  }

  @override
  String get comingSoon => 'This feature is coming soon';
}
