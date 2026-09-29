import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'router.dart';
import 'state/auth_state.dart';
import 'state/on_screen_keyboard.dart';
import 'state/product_store.dart';
import 'state/settings_state.dart';
import 'theme/app_theme.dart';
import 'widgets/on_screen_keyboard.dart';

class App extends StatefulWidget {
  const App({
    super.key,
    required this.prefs,
    this.onScreenKeyboard = onScreenKeyboardEnabled,
  });

  final SharedPreferences prefs;

  /// Draw an in-app keyboard for touch input (Pi build only by default).
  final bool onScreenKeyboard;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _auth = AuthState();
  final _products = ProductStore();
  late final _settings = SettingsState(widget.prefs);
  late final OnScreenKeyboard? _keyboard = widget.onScreenKeyboard
      ? (OnScreenKeyboard(widget.prefs)..install())
      : null;
  // Created once so theme changes don't rebuild the router.
  late final GoRouter _router = createRouter(_auth);

  @override
  void dispose() {
    _router.dispose();
    _auth.dispose();
    _products.dispose();
    _settings.dispose();
    _keyboard?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _settings),
        ChangeNotifierProvider.value(value: _products),
      ],
      child: Consumer<SettingsState>(
        builder: (context, settings, _) => MaterialApp.router(
          title: 'Chota POS',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: buildTheme(settings.seed, Brightness.light),
          darkTheme: buildTheme(settings.seed, Brightness.dark),
          routerConfig: _router,
          builder: _keyboard == null
              ? null
              : (context, child) =>
                    KeyboardHost(keyboard: _keyboard, child: child!),
        ),
      ),
    );
  }
}
