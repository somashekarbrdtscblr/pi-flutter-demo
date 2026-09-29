import 'package:flutter/material.dart';

/// Global app state: auth + theme. Kept dependency-free (no provider/riverpod)
/// so the bundle stays small for the Pi Zero 2W.
class AppState extends ChangeNotifier {
  static const demoEmail = 'admin@demo.com';
  static const demoPassword = 'admin123';

  String? _user;
  ThemeMode _themeMode = ThemeMode.light;
  Color _seed = Colors.indigo;

  String? get user => _user;
  bool get isLoggedIn => _user != null;
  ThemeMode get themeMode => _themeMode;
  Color get seed => _seed;

  /// Fake async login. Replace with a real API call.
  Future<bool> login(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (email.trim().toLowerCase() == demoEmail && password == demoPassword) {
      _user = email.trim();
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _user = null;
    notifyListeners();
  }

  set themeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  set seed(Color color) {
    _seed = color;
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    super.key,
    required AppState super.notifier,
    required super.child,
  });

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Read without subscribing to rebuilds (use in callbacks).
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
