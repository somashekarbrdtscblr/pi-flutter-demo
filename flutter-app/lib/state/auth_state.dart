import 'package:flutter/foundation.dart';

/// In-memory login session. Lost on restart by design.
class AuthState extends ChangeNotifier {
  static const demoEmail = 'admin@demo.com';
  static const demoPassword = 'admin123';

  AuthState({this.loginDelay = const Duration(milliseconds: 700)});

  /// Fake network latency; tests pass Duration.zero.
  final Duration loginDelay;

  String? _user;

  String? get user => _user;
  bool get isLoggedIn => _user != null;

  /// Demo check against fixed credentials. Replace with a real API call.
  Future<bool> login(String email, String password) async {
    await Future<void>.delayed(loginDelay);
    if (email.trim().toLowerCase() != demoEmail || password != demoPassword) {
      return false;
    }
    _user = email.trim();
    notifyListeners();
    return true;
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}
