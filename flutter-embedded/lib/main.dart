import 'package:flutter/material.dart';

import 'pages/home_shell.dart';
import 'pages/login_page.dart';
import 'state/app_state.dart';

void main() {
  runApp(ChotaPosApp(state: AppState()));
}

class ChotaPosApp extends StatelessWidget {
  const ChotaPosApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) => MaterialApp(
          title: 'Chota POS Demo',
          debugShowCheckedModeBanner: false,
          themeMode: state.themeMode,
          theme: ThemeData(
            colorSchemeSeed: state.seed,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: state.seed,
            brightness: Brightness.dark,
          ),
          home: state.isLoggedIn ? const HomeShell() : const LoginPage(),
        ),
      ),
    );
  }
}
