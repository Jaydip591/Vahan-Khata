import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small vibrations that make taps feel real. One place, so every widget feels the same.
/// Can be switched off in More (stored in the phone's settings).
abstract final class Haptics {
  static const _key = 'haptics_on';
  static bool enabled = true;

  static void load(SharedPreferences prefs) => enabled = prefs.getBool(_key) ?? true;

  static Future<void> setEnabled(SharedPreferences prefs, bool on) async {
    enabled = on;
    await prefs.setBool(_key, on);
    if (on) tap();
  }

  /// Light tick: choosing a chip, a keypad key, a tab, opening a row.
  static void tap() {
    if (enabled) HapticFeedback.selectionClick();
  }

  /// Firm press: the big action buttons.
  static void press() {
    if (enabled) HapticFeedback.mediumImpact();
  }

  /// Saved: two quick pulses.
  static Future<void> success() async {
    if (!enabled) return;
    await HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    if (enabled) await HapticFeedback.mediumImpact();
  }

  /// Something is wrong (empty amount, failed save).
  static void error() {
    if (enabled) HapticFeedback.heavyImpact();
  }

  /// Delete confirmed.
  static void heavy() {
    if (enabled) HapticFeedback.heavyImpact();
  }
}
