import 'package:flutter/material.dart';

/// Ink and gold palette. Never hardcode colours in widgets: add a token here.
///
/// Brand colours that look the same in light and dark are `const`. Surface, text and
/// line colours are getters that follow [dark]; the app root sets it from the chosen
/// theme and rebuilds every widget when it changes (see `app.dart`).
abstract final class AppColors {
  /// True while the app shows its dark theme.
  static bool dark = false;

  // ── Same in both themes ────────────────────────────────────────────
  /// Brand ink: headers, hero cards, icon circles, text on gold.
  static const ink = Color(0xFF12161C);
  static const ink2 = Color(0xFF1E252E);
  static const ink3 = Color(0xFF2C3540);
  static const gold = Color(0xFFC8A24A);
  static const mutedOnInk = Color(0xFFB9B2A3);
  static const incomeOnInk = Color(0xFF5FD0AE);
  static const expenseOnInk = Color(0xFFFF8E80);

  // ── Follow the theme ───────────────────────────────────────────────
  /// Page background.
  static Color get ivory => dark ? const Color(0xFF0B0E12) : const Color(0xFFF6F3EE);

  /// Cards, sheets, fields.
  static Color get card => dark ? const Color(0xFF181D24) : Colors.white;

  /// Main text and icons on cards and the page.
  static Color get text => dark ? const Color(0xFFEDE8DF) : ink;
  static Color get muted => dark ? const Color(0xFFA39C8E) : const Color(0xFF7A7468);
  static Color get line => dark ? const Color(0xFF29303A) : const Color(0xFFE8E2D8);
  static Color get fieldLine => dark ? const Color(0xFF3A434E) : const Color(0xFFD9D2C4);

  /// Soft grey fill behind small icons and neutral tags.
  static Color get chipFill => dark ? const Color(0xFF252C35) : const Color(0xFFEFEBE2);
  static Color get goldSoft => dark ? const Color(0xFF3A3120) : const Color(0xFFF3EAD3);
  static Color get goldLine => dark ? const Color(0xFF5E4C24) : const Color(0xFFE6D6A8);

  /// Selected chip: ink with white text on light, gold with ink text on dark.
  static Color get selected => dark ? gold : ink;
  static Color get onSelected => dark ? ink : Colors.white;

  /// Switch thumb and similar accents drawn on top of [selected].
  static Color get selectedAccent => dark ? ink : gold;

  /// Income and profit: always emerald.
  static Color get income => dark ? incomeOnInk : const Color(0xFF1F8A70);

  /// Expense and "baaki": always coral.
  static Color get expense => dark ? expenseOnInk : const Color(0xFFD2574A);

  // Status tags (paid / partly / due / neutral): background, text.
  static Color get tagGoodBg => dark ? const Color(0xFF173A31) : const Color(0xFFDCEFE8);
  static Color get tagGoodFg => dark ? incomeOnInk : const Color(0xFF14584A);
  static Color get tagWarnFg => dark ? const Color(0xFFE8C77A) : const Color(0xFF7A5A12);
  static Color get tagBadBg => dark ? const Color(0xFF45231F) : const Color(0xFFF8E0DC);
  static Color get tagBadFg => dark ? expenseOnInk : const Color(0xFF8E3027);
}
