import 'package:flutter/material.dart';

/// Colours carry a lot of the design's weight here.
///
/// The one rule that matters: a missed day is [missed] — a warm grey — and
/// never red. Red reads as failure, failure reads as "this app makes me feel
/// bad", and that is how habit apps get deleted. Grey reads as a neutral fact.
abstract final class AppColors {
  static const background = Color(0xFF0E100F);
  static const card = Color(0xFF171A19);
  static const cardRaised = Color(0xFF1E2221);
  static const divider = Color(0xFF2A2E2C);

  static const textPrimary = Color(0xFFF2F4F3);
  static const textSecondary = Color(0xFF8C918E);
  static const textFaint = Color(0xFF5B615E);

  /// The full version: the visually loud option.
  static const accentSurface = Color(0xFFD6F2E4);
  static const accentOnSurface = Color(0xFF0A5C3D);

  static const full = Color(0xFF1E9E74);
  static const floor = Color(0xFF86E3BD);
  static const missed = Color(0xFFC8C4BB);
  static const rest = Color(0xFF3A4341);
  static const empty = Color(0xFF202423);
}

ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.full,
    onPrimary: Colors.white,
    secondary: AppColors.floor,
    surface: AppColors.card,
    onSurface: AppColors.textPrimary,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,
    dividerColor: AppColors.divider,
    fontFamily: 'Helvetica Neue',
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.1,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: TextStyle(fontSize: 15, color: AppColors.textPrimary),
      bodyMedium: TextStyle(fontSize: 14, color: AppColors.textSecondary),
      bodySmall: TextStyle(fontSize: 12, color: AppColors.textFaint),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardRaised,
      hintStyle: const TextStyle(color: AppColors.textFaint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.full, width: 1.5),
      ),
      errorStyle: const TextStyle(color: AppColors.missed, fontSize: 12.5),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.missed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.missed, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accentSurface,
        foregroundColor: AppColors.accentOnSurface,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        textStyle: const TextStyle(fontSize: 14),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.cardRaised,
      contentTextStyle: TextStyle(color: AppColors.textPrimary, fontSize: 14),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
