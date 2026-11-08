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

  @override
  String get vehicles => 'Vehicles';

  @override
  String get drivers => 'Drivers';

  @override
  String get parties => 'Parties';

  @override
  String get accounts => 'Accounts';

  @override
  String get users => 'Users';

  @override
  String get addVehicle => 'Add vehicle';

  @override
  String get editVehicle => 'Edit vehicle';

  @override
  String get vehicleType => 'Vehicle type';

  @override
  String get typeEicher => 'Eicher';

  @override
  String get typeBolero => 'Bolero';

  @override
  String get typeTataAce => 'Tata Ace';

  @override
  String get typeTruck => 'Truck';

  @override
  String get typeTempo => 'Tempo';

  @override
  String get typeOther => 'Other';

  @override
  String get vehicleName => 'Vehicle name';

  @override
  String get vehicleNameHint => 'Filled automatically, you can change it';

  @override
  String get vehicleNumber => 'Vehicle number';

  @override
  String get docDates => 'More details (insurance, PUC dates)';

  @override
  String get docInsurance => 'Insurance expires';

  @override
  String get docPuc => 'PUC expires';

  @override
  String get docFitness => 'Fitness expires';

  @override
  String get docPermit => 'Permit expires';

  @override
  String get docTax => 'Tax due';

  @override
  String get pickDate => 'Pick a date';

  @override
  String get addDriver => 'Add driver';

  @override
  String get editDriver => 'Edit driver';

  @override
  String get name => 'Name';

  @override
  String get phone => 'Phone number';

  @override
  String get defaultVehicle => 'Usual vehicle';

  @override
  String get none => 'None';

  @override
  String get addParty => 'Add party';

  @override
  String get editParty => 'Edit party';

  @override
  String get partyName => 'Party name';

  @override
  String get paymentCycle => 'Usually pays';

  @override
  String get cycleDaily => 'Daily';

  @override
  String get cycleTenDays => 'Every 10 days';

  @override
  String get cycleMonthly => 'Monthly';

  @override
  String get addAccount => 'Add account';

  @override
  String get editAccount => 'Edit account';

  @override
  String get accountName => 'Account name';

  @override
  String get accountNameHint => 'e.g. Cash - Jaydip';

  @override
  String get kindCash => 'Cash';

  @override
  String get kindBank => 'Bank';

  @override
  String get kindUpi => 'UPI';

  @override
  String get openingBalance => 'Opening balance';

  @override
  String get addUser => 'Add user';

  @override
  String get editUser => 'Edit user';

  @override
  String get fullName => 'Full name';

  @override
  String get newPasswordOptional => 'New password (leave empty to keep)';

  @override
  String get userActive => 'Active';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get usernameRule =>
      '3-32 characters: lowercase letters, digits, . - _';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get deleteConfirmTitle => 'Delete this?';

  @override
  String get deleteConfirmBody => 'It will be removed from the list.';

  @override
  String get emptyVehicles => 'No vehicles yet';

  @override
  String get emptyDrivers => 'No drivers yet';

  @override
  String get emptyParties => 'No parties yet';

  @override
  String get emptyAccounts => 'No accounts yet';

  @override
  String get emptyUsers => 'No users yet';

  @override
  String get emptyHint => 'Add one with the button below';

  @override
  String get required => 'This field is required';

  @override
  String get invalidNumber => 'Enter a valid vehicle number';

  @override
  String get invalidPhone => 'Enter a valid phone number';

  @override
  String get errorDuplicate => 'This already exists';

  @override
  String get errorInvalid => 'Check the details';

  @override
  String get retry => 'Try again';

  @override
  String get placeSearchHint => 'Search a place (Surat, સુરત)';

  @override
  String get placePopular => 'Popular';

  @override
  String get placeNoResult => 'No place found';

  @override
  String get placeAddHint => 'Pick the Gujarati spelling';

  @override
  String get placeChecking => 'Finding the Gujarati name…';

  @override
  String get placeTypeGujarati => 'Type the name in Gujarati';

  @override
  String get fromPlace => 'From';

  @override
  String get toPlace => 'To';

  @override
  String placeAdd(String name) {
    return 'Add “$name”';
  }

  @override
  String get userInactive => 'Inactive';
}
