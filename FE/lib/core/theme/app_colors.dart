import 'package:flutter/material.dart';

/// Ink and gold palette. Never hardcode colours in widgets: add a token here.
abstract final class AppColors {
  static const ink = Color(0xFF12161C);
  static const ink2 = Color(0xFF1E252E);
  static const ink3 = Color(0xFF2C3540);
  static const gold = Color(0xFFC8A24A);
  static const goldSoft = Color(0xFFF3EAD3);
  static const goldLine = Color(0xFFE6D6A8);
  static const ivory = Color(0xFFF6F3EE);
  static const card = Colors.white;
  static const line = Color(0xFFE8E2D8);
  static const fieldLine = Color(0xFFD9D2C4);
  static const muted = Color(0xFF7A7468);
  static const mutedOnInk = Color(0xFFB9B2A3);

  /// Income and profit: always emerald.
  static const income = Color(0xFF1F8A70);
  static const incomeOnInk = Color(0xFF5FD0AE);

  /// Expense and "baaki": always coral.
  static const expense = Color(0xFFD2574A);
  static const expenseOnInk = Color(0xFFFF8E80);
}
