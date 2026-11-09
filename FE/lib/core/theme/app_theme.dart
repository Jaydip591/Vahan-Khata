import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Every screen starts with a dark ink header, so the phone's status bar (time, signal,
/// battery) must use light icons on a see-through bar.
const kInkStatusBar = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light, // Android
  statusBarBrightness: Brightness.dark, // iOS
  systemNavigationBarColor: Colors.white,
  systemNavigationBarIconBrightness: Brightness.dark,
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

  static ThemeData light() {
    final scheme = const ColorScheme.light(
      primary: AppColors.ink,
      onPrimary: Colors.white,
      secondary: AppColors.gold,
      onSecondary: AppColors.ink,
      surface: AppColors.card,
      onSurface: AppColors.ink,
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
      scaffoldBackgroundColor: AppColors.ivory,
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: AppSizes.fontTitle,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: TextStyle(fontSize: 19, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontSize: AppSizes.fontBody),
        bodyMedium: TextStyle(fontSize: 16),
        bodySmall: TextStyle(fontSize: 14, color: AppColors.muted),
        labelLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ).apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
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
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          shape: shape,
          side: const BorderSide(color: AppColors.ink, width: 1.5),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: AppSizes.fontBody,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
