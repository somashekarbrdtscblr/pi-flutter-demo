import 'package:flutter/material.dart';

ThemeData buildTheme(Color seed, Brightness brightness) {
  return ThemeData(
    colorSchemeSeed: seed,
    brightness: brightness,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
