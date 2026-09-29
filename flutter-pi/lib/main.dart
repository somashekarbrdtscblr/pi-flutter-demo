import 'package:flutter/material.dart';

import 'app_state.dart';
import 'pages/login_page.dart';
import 'widgets/home_shell.dart';

void main() {
  runApp(PiDemoApp(state: AppState()));
}

class PiDemoApp extends StatelessWidget {
  const PiDemoApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      notifier: state,
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) => MaterialApp(
          title: 'Pi Demo',
          debugShowCheckedModeBanner: false,
          themeMode: state.themeMode,
          theme: _theme(state.seed, Brightness.light),
          darkTheme: _theme(state.seed, Brightness.dark),
          home: state.isLoggedIn ? const HomeShell() : const LoginPage(),
        ),
      ),
    );
  }

  static ThemeData _theme(Color seed, Brightness brightness) {
    return ThemeData(
      colorSchemeSeed: seed,
      brightness: brightness,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
