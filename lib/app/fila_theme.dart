import 'package:flutter/material.dart';

abstract final class FilaColors {
  static const ink = Color(0xFF18211B);
  static const muted = Color(0xFF68736B);
  static const canvas = Color(0xFFF4F2E9);
  static const surface = Color(0xFFFFFEF8);
  static const line = Color(0xFFD8DDD5);
  static const green = Color(0xFF235C44);
  static const greenDark = Color(0xFF173C2B);
  static const greenLight = Color(0xFFD8EADF);
  static const lime = Color(0xFFD7F171);
  static const error = Color(0xFFB94438);
}

abstract final class FilaTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: FilaColors.green,
      onPrimary: Colors.white,
      primaryContainer: FilaColors.greenLight,
      onPrimaryContainer: FilaColors.ink,
      secondary: FilaColors.lime,
      onSecondary: FilaColors.ink,
      surface: FilaColors.surface,
      onSurface: FilaColors.ink,
      error: FilaColors.error,
      outline: FilaColors.line,
    );
    final base = ThemeData(colorScheme: colorScheme, useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: FilaColors.surface,
      textTheme: base.textTheme.copyWith(
        displayMedium: base.textTheme.displayMedium?.copyWith(
          color: FilaColors.ink,
          fontSize: 42,
          fontWeight: FontWeight.w800,
          height: 1.02,
          letterSpacing: -2.2,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          color: FilaColors.ink,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          height: 1.12,
          letterSpacing: -0.8,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          color: FilaColors.ink,
          fontWeight: FontWeight.w800,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          color: FilaColors.muted,
          fontSize: 16,
          height: 1.48,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          color: FilaColors.muted,
          height: 1.48,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      dividerColor: FilaColors.line,
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Colors.white,
        indicatorColor: FilaColors.green,
        selectedIconTheme: IconThemeData(color: Colors.white),
        selectedLabelTextStyle: TextStyle(
          color: FilaColors.green,
          fontWeight: FontWeight.w800,
        ),
        unselectedIconTheme: IconThemeData(color: FilaColors.muted),
        unselectedLabelTextStyle: TextStyle(
          color: FilaColors.muted,
          fontWeight: FontWeight.w700,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: FilaColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
    );
  }
}
