/// Build-time configuration. Override with --dart-define, e.g.
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
abstract final class AppConfig {
  /// 10.0.2.2 is the host machine as seen from the Android emulator.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// UPI payments from the Kharcha sheet open Google Pay directly. When false, Android
  /// shows the list of every UPI app. If Google Pay is not installed the list is shown anyway.
  /// Change it here and build a new APK (owner's choice: a code setting, not a switch in the app).
  static const upiOnlyGooglePay = true;

  /// Google Pay's Android package.
  static const googlePayPackage = 'com.google.android.apps.nbu.paisa.user';
}
