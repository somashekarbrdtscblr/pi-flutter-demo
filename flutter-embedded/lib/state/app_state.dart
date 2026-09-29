import 'package:flutter/material.dart';

/// App-wide state: auth session + theme. Dependency-free (ChangeNotifier +
/// InheritedNotifier) to keep the embedded bundle small.
class AppState extends ChangeNotifier {
  String? _user;
  ThemeMode _themeMode = ThemeMode.light;
  Color _seed = Colors.indigo;

  String? get user => _user;
  bool get isLoggedIn => _user != null;
  ThemeMode get themeMode => _themeMode;
  Color get seed => _seed;

  /// Demo auth: any valid email + password "admin123".
  Future<bool> login(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (password != 'admin123') return false;
    _user = email;
    notifyListeners();
    return true;
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
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
