import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'router.dart';
import 'state/auth_state.dart';
import 'state/product_store.dart';
import 'state/settings_state.dart';
import 'theme/app_theme.dart';

class App extends StatefulWidget {
  const App({super.key, required this.settings});

  final SettingsState settings;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _auth = AuthState();
  final _products = ProductStore();
  // Created once so theme changes don't rebuild the router.
  late final GoRouter _router = createRouter(_auth);

  @override
  void dispose() {
    _router.dispose();
    _auth.dispose();
    _products.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: widget.settings),
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
        ),
      ),
    );
  }
}
