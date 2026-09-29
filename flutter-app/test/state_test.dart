import 'package:flutter/material.dart';
import 'package:flutter_app/state/auth_state.dart';
import 'package:flutter_app/state/product_store.dart';
import 'package:flutter_app/state/settings_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AuthState', () {
    test('accepts only the demo credentials', () async {
      final auth = AuthState(loginDelay: Duration.zero);
      expect(await auth.login('admin@demo.com', 'wrong1'), isFalse);
      expect(
        await auth.login('other@demo.com', AuthState.demoPassword),
        isFalse,
      );
      expect(auth.isLoggedIn, isFalse);

      expect(
        await auth.login(' Admin@Demo.com ', AuthState.demoPassword),
        isTrue,
      );
      expect(auth.user, 'Admin@Demo.com');

      auth.logout();
      expect(auth.isLoggedIn, isFalse);
    });
  });

  group('ProductStore', () {
    test('add, update and totals', () {
      final store = ProductStore();
      final before = store.items.length;
      final p = store.add(
        name: 'Tea',
        category: 'Beverages',
        price: 10,
        qty: 3,
      );

      expect(store.items.length, before + 1);
      expect(p.sku, startsWith('SKU-'));

      store.update(p.copyWith(qty: 5));
      expect(store.items.last.qty, 5);
      expect(store.items.last.value, 50);
    });

    test('removeWhere + restore puts items back in place', () {
      final store = ProductStore();
      final original = store.items.map((p) => p.id).toList();
      final removed = store.removeWhere((p) => p.category == 'Dairy');

      expect(removed, isNotEmpty);
      expect(store.items.any((p) => p.category == 'Dairy'), isFalse);

      store.restore(removed);
      expect(store.items.map((p) => p.id).toList(), original);
    });
  });

  group('SettingsState', () {
    test('persists theme mode and seed colour', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final settings = SettingsState(prefs)
        ..themeMode = ThemeMode.dark
        ..seed = Colors.teal;

      final reloaded = SettingsState(prefs);
      expect(reloaded.themeMode, ThemeMode.dark);
      expect(reloaded.seed.toARGB32(), Colors.teal.toARGB32());
      expect(settings.themeMode, reloaded.themeMode);
    });

    test('defaults when nothing is saved', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsState(await SharedPreferences.getInstance());
      expect(settings.themeMode, ThemeMode.light);
      expect(
        settings.seed.toARGB32(),
        SettingsState.seedColors.first.toARGB32(),
      );
    });
  });
}
