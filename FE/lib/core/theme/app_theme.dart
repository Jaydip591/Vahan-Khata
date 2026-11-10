import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Every screen starts with a dark ink header, so the phone's status bar (time, signal,
/// battery) must use light icons on a see-through bar. The bottom navigation bar follows
/// the card colour of the current theme.
SystemUiOverlayStyle get kInkStatusBar => SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // Android
      statusBarBrightness: Brightness.dark, // iOS
      systemNavigationBarColor: AppColors.card,
      systemNavigationBarIconBrightness: AppColors.dark ? Brightness.light : Brightness.dark,
    );

abstract final class AppSizes {
  static const buttonHeight = 56.0;
  static const fieldHeight = 56.0;
  static const radius = 16.0;
  static const pad = 16.0;
  static const fontBody = 18.0;
  static const fontAmount = 28.0;
  static const fontTitle = 22.0;
}

abstract final class AppTheme {
  static const fontFamily = 'NotoSansGujarati';

  static ThemeData light() => _withMode(false);
  static ThemeData dark() => _withMode(true);

  /// Builds the theme with the token getters switched to the wanted mode.
  static ThemeData _withMode(bool dark) {
    final before = AppColors.dark;
    AppColors.dark = dark;
    try {
      return _build(dark);
    } finally {
      AppColors.dark = before;
    }
  }

  static ThemeData _build(bool dark) {
    final scheme = (dark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
      primary: AppColors.text,
      onPrimary: dark ? AppColors.ink : Colors.white,
      secondary: AppColors.gold,
      onSecondary: AppColors.ink,
      surface: AppColors.card,
      onSurface: AppColors.text,
      error: AppColors.expense,
      onError: Colors.white,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radius),
    );
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: scheme,
      brightness: dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: AppColors.ivory,
      canvasColor: AppColors.card,
      dividerColor: AppColors.line,
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: AppColors.card, modalBackgroundColor: AppColors.card),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.ink2,
        contentTextStyle: TextStyle(fontFamily: fontFamily, fontSize: 16, color: Colors.white),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: AppSizes.fontTitle,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: TextStyle(fontSize: 19, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontSize: AppSizes.fontBody),
        bodyMedium: TextStyle(fontSize: 16),
        bodySmall: TextStyle(fontSize: 14),
        labelLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ).apply(bodyColor: AppColors.text, displayColor: AppColors.text),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          shape: shape,
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: AppSizes.fontBody,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          shape: shape,
          side: BorderSide(color: AppColors.text, width: 1.5),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: AppSizes.fontBody,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
