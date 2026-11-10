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

  @override
  String get newTrip => 'New trip';

  @override
  String get editTrip => 'Edit trip';

  @override
  String get copyLastTrip => 'Same as last trip';

  @override
  String get quickRoutes => 'Quick routes (one tap)';

  @override
  String get vehicle => 'Vehicle';

  @override
  String get party => 'Party';

  @override
  String get driver => 'Driver';

  @override
  String get choosePlace => 'Choose a place';

  @override
  String get bhada => 'Bhada (freight)';

  @override
  String get tapToType => 'Tap the amount to type it';

  @override
  String get advanceReceived => 'Advance received';

  @override
  String get advFull => 'Full';

  @override
  String get advHalf => 'Half';

  @override
  String get advNone => 'None';

  @override
  String get advCustom => 'Other';

  @override
  String get advanceLabel => 'Advance';

  @override
  String get balanceLeft => 'Balance';

  @override
  String get howReceived => 'How received';

  @override
  String get modeCash => 'Cash';

  @override
  String get modeOnline => 'Online';

  @override
  String get whichAccount => 'Which account';

  @override
  String get dateLabel => 'Date';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get otherDate => 'Other date';

  @override
  String get tripSaved => 'Trip saved';

  @override
  String get needAccountFirst => 'Add an account first (More → Accounts)';

  @override
  String get needVehicleFirst => 'Add a vehicle first (More → Vehicles)';

  @override
  String get needPartyFirst => 'Add a party first (More → Parties)';

  @override
  String get chooseVehicle => 'Choose a vehicle';

  @override
  String get chooseParty => 'Choose a party';

  @override
  String get chooseRoute => 'Choose from and to';

  @override
  String get emptyTrips => 'No trips this month';

  @override
  String get tripDetail => 'Trip details';

  @override
  String get closeTrip => 'Close trip';

  @override
  String get reopenTrip => 'Reopen trip';

  @override
  String get statusRunning => 'Running';

  @override
  String get statusClosed => 'Closed';

  @override
  String get payUnpaid => 'Due';

  @override
  String get payPartial => 'Part paid';

  @override
  String get payPaid => 'Paid';

  @override
  String get receivedLabel => 'Received';

  @override
  String get advanceNotEditable =>
      'Advance can\'t be changed here. Add payments from the Khata tab.';

  @override
  String get amountLabel => 'Amount';

  @override
  String get amountOk => 'OK';

  @override
  String get enterAmount => 'Enter an amount';

  @override
  String get whatExpense => 'What was the expense?';

  @override
  String get catDiesel => 'Diesel';

  @override
  String get catToll => 'Toll';

  @override
  String get catRepair => 'Repair';

  @override
  String get catAllowance => 'Food / allowance';

  @override
  String get catChallan => 'Challan';

  @override
  String get catOther => 'Other';

  @override
  String get liters => 'Liters';

  @override
  String get ratePerLiter => 'Rate / liter';

  @override
  String get odometer => 'Odometer (km)';

  @override
  String get repairKind => 'What was repaired?';

  @override
  String get rkTyre => 'Tyre';

  @override
  String get rkOil => 'Oil';

  @override
  String get rkEngine => 'Engine';

  @override
  String get rkBattery => 'Battery';

  @override
  String get rkService => 'Service';

  @override
  String get expenseSaved => 'Expense saved';

  @override
  String get recentExpenses => 'This month\'s expenses';

  @override
  String get emptyExpenses => 'No expenses this month';

  @override
  String get paidFrom => 'Paid from';

  @override
  String get khataTitle => 'Party khata';

  @override
  String get totalDue => 'Total to receive';

  @override
  String daysOld(int days) {
    return '$days days old';
  }

  @override
  String get settled => 'Settled';

  @override
  String get receivePayment => 'Payment received';

  @override
  String get whoPaid => 'Who paid';

  @override
  String get howMuch => 'How much received';

  @override
  String get payAll => 'All';

  @override
  String get payHalf => 'Half';

  @override
  String get payCustom => 'Other amount';

  @override
  String get willCredit => 'Will be credited';

  @override
  String get remaining => 'Will remain';

  @override
  String get paymentSaved => 'Payment saved';

  @override
  String get totalBhada => 'Total bhada';

  @override
  String get totalReceived => 'Total received';

  @override
  String get tripsHeading => 'Trips';

  @override
  String get paymentsHeading => 'Payments';

  @override
  String get partyHasCredit => 'Credit with us';

  @override
  String get monthPrev => 'Previous month';

  @override
  String get monthNext => 'Next month';

  @override
  String get creditLabel => 'Credit';

  @override
  String get newPartyShort => 'Party';

  @override
  String get homeDueCard => 'To receive';

  @override
  String get noPartyYet => 'Add a party first';

  @override
  String get advanceTag => 'Advance';

  @override
  String get deletePaymentTitle => 'Delete this payment?';

  @override
  String get chooseAccount => 'Choose an account';

  @override
  String get reportVehicle => 'Vehicles';

  @override
  String get reportParty => 'Parties';

  @override
  String get reportMonths => 'Months';

  @override
  String get reportExpense => 'Expenses';

  @override
  String get profitLabel => 'Profit';

  @override
  String get incomeLabel => 'Income';

  @override
  String get expenseLabel => 'Expense';

  @override
  String get bhadaLabel => 'Bhada';

  @override
  String tripsCount(Object count) {
    return '$count trips';
  }

  @override
  String mileageValue(Object value) {
    return '$value km/l';
  }

  @override
  String kmValue(Object km) {
    return '$km km';
  }

  @override
  String get emptyReport => 'Nothing recorded this month';

  @override
  String get totalExpense => 'Total expense';

  @override
  String get homeProfit => 'This month\'s profit';

  @override
  String vsLastMonth(Object amount) {
    return 'Last month $amount';
  }

  @override
  String get collectedLabel => 'Received';

  @override
  String get vehicleProfitTitle => 'Vehicle-wise profit';

  @override
  String get seeAll => 'See all';

  @override
  String get otherExpenses => 'Other expenses';

  @override
  String get litersLabel => 'Liters';

  @override
  String get avgRate => 'Avg rate';

  @override
  String get entriesLabel => 'Entries';

  @override
  String get monthDetails => 'Month details';

  @override
  String litersValue(Object value) {
    return '$value L';
  }

  @override
  String rateValue(Object rate) {
    return '$rate/L';
  }

  @override
  String pendingStrip(Object count) {
    return '$count entries not sent yet';
  }

  @override
  String get pendingTitle => 'Waiting to send';

  @override
  String get allSent => 'Everything is sent';

  @override
  String get pendingHelp =>
      'These entries are safe on your phone. They are sent automatically when the internet is back.';

  @override
  String get sendNow => 'Send now';

  @override
  String get notSentYet => 'Not sent yet';

  @override
  String get notSentFailed => 'Rejected';

  @override
  String get notSentFailedHelp =>
      'The server did not accept this entry. Delete it and enter it again.';

  @override
  String get deletePendingTitle => 'Delete this entry?';

  @override
  String get deletePendingBody =>
      'This entry has not reached the server. If you delete it, it is gone for good.';

  @override
  String get savedOffline =>
      'No internet. Saved on the phone, it will be sent when you are online.';

  @override
  String logoutPendingWarning(Object count) {
    return '$count entries are not sent yet. They will be lost if you log out.';
  }

  @override
  String get fuelLabel => 'Fuel';

  @override
  String get fuelType => 'Fuel type';

  @override
  String get catPetrol => 'Petrol';

  @override
  String get catCng => 'CNG';

  @override
  String get fuelCngPetrol => 'CNG + Petrol';

  @override
  String get kgLabel => 'Kg';

  @override
  String kgValue(Object value) {
    return '$value kg';
  }

  @override
  String mileageKg(Object value) {
    return '$value km/kg';
  }

  @override
  String get whichFuel => 'Which fuel?';

  @override
  String rateKg(Object rate) {
    return '$rate/kg';
  }

  @override
  String get exportTitle => 'Share / Export';

  @override
  String get exportPdf => 'PDF';

  @override
  String get exportPdfHelp => 'Best for WhatsApp';

  @override
  String get exportExcel => 'Excel';

  @override
  String get exportExcelHelp => 'Open in Excel or Google Sheets';

  @override
  String get exporting => 'Preparing the file…';

  @override
  String get exportFailed => 'Could not create the file. Try again.';

  @override
  String get docParty => 'Party statement';

  @override
  String get docMonth => 'Monthly report';

  @override
  String get colDate => 'Date';

  @override
  String get colRoute => 'Route';

  @override
  String get colDue => 'Due';

  @override
  String get colMode => 'Mode';

  @override
  String get colAccount => 'Account';

  @override
  String get colCategory => 'Category';

  @override
  String get colAmount => 'Amount';

  @override
  String get colQty => 'Qty';

  @override
  String get colOdometer => 'Odometer';

  @override
  String get colParty => 'Party';

  @override
  String pageOf(Object n, Object total) {
    return 'Page $n of $total';
  }

  @override
  String generatedOn(Object date) {
    return 'Made on $date';
  }

  @override
  String get sheetSummary => 'Summary';

  @override
  String get tripExpenses => 'Trip expenses';

  @override
  String get tripNet => 'Trip profit';

  @override
  String get noTripExpenses => 'No expense on this trip yet';

  @override
  String get forTrip => 'Trip';

  @override
  String get addTripExpense => 'Add expense for this trip';

  @override
  String get vibration => 'Vibration on tap';

  @override
  String get reportBalance => 'Balance';

  @override
  String get balanceTotal => 'Total in all accounts';

  @override
  String get balanceAllTime => 'From the start till today';

  @override
  String get balanceIn => 'In';

  @override
  String get balanceOut => 'Out';

  @override
  String get balanceOpening => 'Opening';

  @override
  String balanceNoAccount(Object amount) {
    return '$amount of expenses have no account';
  }

  @override
  String get inactiveTag => 'Off';

  @override
  String get profile => 'Profile';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get phoneLabel => 'Mobile number';

  @override
  String get phoneOptional => 'Mobile number (optional)';

  @override
  String get phoneInvalid => 'Enter a 10 digit number';

  @override
  String get noPhone => 'No number added';

  @override
  String get companyLabel => 'Company';

  @override
  String get roleLabel => 'Role';

  @override
  String get roleSuperadmin => 'Owner (full access)';

  @override
  String get usernameLabel => 'Username';

  @override
  String get changePassword => 'Change password';

  @override
  String get currentPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmPassword => 'New password again';

  @override
  String get passwordMismatch => 'The two passwords are not the same';

  @override
  String get wrongCurrentPassword => 'The current password is wrong';

  @override
  String get passwordChanged =>
      'Password changed. Other phones are logged out.';

  @override
  String get passwordChangeNote =>
      'Changing the password logs out every other phone. This phone stays logged in.';

  @override
  String get settings => 'Settings';

  @override
  String get manage => 'Records';

  @override
  String get appVersion => 'App version';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get thisWeek => 'This week';

  @override
  String get weekTrips => 'Trips done';

  @override
  String get weekEarned => 'Earned';

  @override
  String get weekSpent => 'Spent';

  @override
  String get weekLeft => 'Left';

  @override
  String get weekEmpty => 'No trip or expense this week yet';

  @override
  String get weekBarsNote => 'Earning each day';

  @override
  String get weekdaysShort => 'Mon,Tue,Wed,Thu,Fri,Sat,Sun';

  @override
  String get themeLabel => 'Look (light / dark)';

  @override
  String get themeSystem => 'Like phone';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get emptyTripsHint => 'Add your first trip';

  @override
  String get emptyExpensesHint => 'Pick a tile above to add an expense';

  @override
  String get emptyPartiesHint => 'Parties appear when you add a trip';

  @override
  String get emptyReportHint => 'Add trips and expenses to see them here';

  @override
  String get shortcutTrip => 'New trip';

  @override
  String get shortcutExpense => 'Add expense';

  @override
  String get shortcutPayment => 'Payment received';

  @override
  String get reportYear => 'Year';

  @override
  String get docYear => 'Yearly report';

  @override
  String fyLabel(Object label) {
    return 'Financial year $label';
  }

  @override
  String fyRange(Object from, Object to) {
    return 'April $from – March $to';
  }

  @override
  String get fyPrev => 'Previous year';

  @override
  String get fyNext => 'Next year';

  @override
  String get yearProfit => 'Profit this year';

  @override
  String get colMonth => 'Month';

  @override
  String get colTrips => 'Trips';

  @override
  String get byMonth => 'Month by month';

  @override
  String get byVehicle => 'Vehicle by vehicle';

  @override
  String get shareYear => 'Whole year as PDF / Excel';

  @override
  String get payByUpi => 'Pay by UPI';

  @override
  String get payWhom => 'Pay whom?';

  @override
  String get scanQr => 'Scan QR';

  @override
  String get typeUpiId => 'Type UPI ID';

  @override
  String get scanHint => 'Hold the pump\'s or shop\'s UPI QR inside the square';

  @override
  String get notUpiQr => 'This is not a UPI QR';

  @override
  String get payeeName => 'Name (e.g. Pump - Kamrej)';

  @override
  String get upiIdLabel => 'UPI ID';

  @override
  String get upiIdHint => 'e.g. kamrejpump@okaxis';

  @override
  String get upiIdInvalid => 'A UPI ID looks like name@bank';

  @override
  String get savePayee => 'Save and continue';

  @override
  String get payees => 'UPI payees';

  @override
  String get emptyPayees => 'No UPI payee saved yet';

  @override
  String get addPayee => 'Add UPI payee';

  @override
  String get editPayee => 'Edit UPI payee';

  @override
  String get upiOpening => 'Opening Google Pay…';

  @override
  String get upiFailed => 'Payment did not go through. Nothing was saved.';

  @override
  String get upiNoApp => 'No UPI app on this phone';

  @override
  String get upiAskTitle => 'Did the payment go through?';

  @override
  String get upiAskBody =>
      'The UPI app did not give a clear answer. Press \"Yes\" only if the money was sent.';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String upiPaidTo(Object name) {
    return 'UPI · $name';
  }

  @override
  String get upiNeedsInternet => 'UPI needs internet';

  @override
  String get catAllowanceTile => 'Food /\nallowance';
}
