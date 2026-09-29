import 'package:flutter/material.dart';
import 'package:flutter_app/app.dart';
import 'package:flutter_app/state/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('login leads to dashboard, drawer navigates to products', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(App(prefs: prefs));
    await tester.pumpAndSettle();

    // Not logged in: router redirects to the login page.
    expect(find.text('Welcome back'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      AuthState.demoEmail,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      AuthState.demoPassword,
    );
    await tester.tap(find.text('Sign in'));
    await tester.pump(const Duration(seconds: 1)); // fake login delay
    await tester.pumpAndSettle();

    expect(find.textContaining('Hello, admin'), findsOneWidget);

    // Default test surface is 800x600: narrow layout, so use the drawer.
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationDrawer),
        matching: find.text('Products'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SKU-0001'), findsOneWidget);
    expect(find.text('Masala Chai'), findsOneWidget);
  });
}
