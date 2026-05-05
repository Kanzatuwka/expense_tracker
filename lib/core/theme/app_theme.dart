import 'package:flutter/material.dart';

/// Zentrale ThemeData für Light- und Dark-Mode.
///
/// Beide Themes basieren auf demselben Indigo-Seed-Color — das stellt
/// visuelle Kontinuität zwischen den Modi sicher. Material 3
/// [ColorScheme.fromSeed] erzeugt die volle Farbpalette automatisch.
class AppTheme {
  AppTheme._();

  static const _seedColor = Colors.indigo;

  static ThemeData light() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData dark() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }
}
