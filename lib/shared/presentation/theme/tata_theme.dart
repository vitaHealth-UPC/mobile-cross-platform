import 'package:flutter/material.dart';

import 'tata_colors.dart';

/// Builds the Material theme from Tata typography, surfaces and native control styles.
abstract final class TataTheme {
  /// Dark variant. Screens that still use fixed [TataColors] keep their light surfaces;
  /// everything built from the Material theme follows this scheme.
  static ThemeData get dark => _derive(
    Brightness.dark,
    surface: const Color(0xFF151B28),
    background: const Color(0xFF0E1320),
    primary: const Color(0xFF9DB8F0),
    onPrimary: const Color(0xFF0B1B38),
    onSurface: const Color(0xFFE8ECF5),
  );

  /// Light variant with maximum text/background contrast.
  static ThemeData get lightHighContrast => _derive(
    Brightness.light,
    surface: Colors.white,
    background: Colors.white,
    primary: const Color(0xFF0B2347),
    onPrimary: Colors.white,
    onSurface: Colors.black,
    outlined: true,
  );

  /// Dark variant with maximum text/background contrast.
  static ThemeData get darkHighContrast => _derive(
    Brightness.dark,
    surface: Colors.black,
    background: Colors.black,
    primary: const Color(0xFFBFD3FF),
    onPrimary: Colors.black,
    onSurface: Colors.white,
    outlined: true,
  );

  static ThemeData _derive(
    Brightness brightness, {
    required Color surface,
    required Color background,
    required Color primary,
    required Color onPrimary,
    required Color onSurface,
    bool outlined = false,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: TataColors.primary,
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      surface: surface,
      onSurface: onSurface,
    );
    final base = light;
    final border = outlined
        ? BorderSide(color: onSurface, width: 1.5)
        : BorderSide.none;
    return base.copyWith(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: surface,
      textTheme: base.textTheme.apply(
        bodyColor: onSurface,
        displayColor: onSurface,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: surface,
        hintStyle: TextStyle(
          fontSize: 14,
          color: onSurface.withValues(alpha: 0.7),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: outlined ? border : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: outlined ? border : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size(double.infinity, 56),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
          side: outlined ? BorderSide(color: onSurface, width: 1.5) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static ThemeData get light => ThemeData(
    fontFamily: 'Inter',
    scaffoldBackgroundColor: TataColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: TataColors.primary,
      primary: TataColors.primary,
      surface: Colors.white,
      onSurface: TataColors.ink,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: TataColors.primary),
      ),
      hintStyle: const TextStyle(fontSize: 14, color: TataColors.muted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: TataColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: TataColors.link,
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
