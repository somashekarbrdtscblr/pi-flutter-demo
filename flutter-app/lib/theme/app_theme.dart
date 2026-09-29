import 'package:flutter/material.dart';

/// Bundled Noto fonts (pubspec.yaml), used for glyphs Roboto lacks.
/// The Pi ships no Indic fonts, so without these Indic text shows as boxes.
/// They contain digits and punctuation but no Latin letters, so they must
/// never be the first font English text falls back to.
const indicFontFallback = [
  'NotoSansDevanagari',
  'NotoSansBengali',
  'NotoSansGurmukhi',
  'NotoSansGujarati',
  'NotoSansOriya',
  'NotoSansTamil',
  'NotoSansTelugu',
  'NotoSansKannada',
  'NotoSansMalayalam',
];

ThemeData buildTheme(Color seed, Brightness brightness) {
  return ThemeData(
    colorSchemeSeed: seed,
    brightness: brightness,
    // Bundled, so every platform (and the Pi) renders the same Latin font.
    fontFamily: 'Roboto',
    fontFamilyFallback: indicFontFallback,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
