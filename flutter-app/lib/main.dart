import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'state/settings_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Web: /products instead of /#/products. No-op on other platforms.
  usePathUrlStrategy();

  final prefs = await SharedPreferences.getInstance();
  runApp(App(settings: SettingsState(prefs)));
}
