import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode + seed colour, persisted across restarts.
class SettingsState extends ChangeNotifier {
  SettingsState(this._prefs)
    : _themeMode =
          ThemeMode.values.asNameMap()[_prefs.getString(_themeKey)] ??
          ThemeMode.light,
      _seed = Color(_prefs.getInt(_seedKey) ?? seedColors.first.toARGB32());

  static const _themeKey = 'themeMode';
  static const _seedKey = 'seedColor';

  static const seedColors = <Color>[
    Colors.indigo,
    Colors.teal,
    Colors.deepOrange,
    Colors.pink,
    Colors.green,
    Colors.purple,
    Colors.blueGrey,
  ];

  final SharedPreferences _prefs;
  ThemeMode _themeMode;
  Color _seed;

  ThemeMode get themeMode => _themeMode;
  Color get seed => _seed;

  set themeMode(ThemeMode mode) {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    _prefs.setString(_themeKey, mode.name);
  }

  set seed(Color color) {
    if (color.toARGB32() == _seed.toARGB32()) return;
    _seed = color;
    notifyListeners();
    _prefs.setInt(_seedKey, color.toARGB32());
  }
}
