import 'package:chota_pos_demo/main.dart';
import 'package:chota_pos_demo/state/app_state.dart';
import 'package:chota_pos_demo/widgets/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps frames for [d]. Used instead of pumpAndSettle because the
/// Components page has indeterminate spinners that never settle.
Future<void> settleFor(WidgetTester tester, [Duration d = const Duration(seconds: 1)]) async {
  for (var t = Duration.zero; t < d; t += const Duration(milliseconds: 50)) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('Validators', () {
    test('email', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('bad@'), isNotNull);
      expect(Validators.email('a@b.co'), isNull);
    });
    test('number range', () {
      expect(Validators.number('abc'), isNotNull);
      expect(Validators.number('0', min: 1), isNotNull);
      expect(Validators.number('5', min: 1, max: 10), isNull);
    });
  });

  testWidgets('login validation then success opens shell', (tester) async {
    tester.view.physicalSize = const Size(800, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ChotaPosApp(state: AppState()));
    expect(find.text('Sign in to continue'), findsOneWidget);

    await tester.tap(find.text('Login'));
    await tester.pump();
    expect(find.text('Password is required'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'admin123');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsWidgets);
  });

  testWidgets('every drawer page builds at Pi resolution', (tester) async {
    tester.view.physicalSize = const Size(800, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final state = AppState();
    // login() uses a real delay; run it outside the fake-async test zone.
    await tester.runAsync(() => state.login('admin@chota.pos', 'admin123'));
    await tester.pumpWidget(ChotaPosApp(state: state));

    for (final page in ['Forms', 'Dialogs', 'Data Table', 'Components', 'Lists & Tabs', 'Settings', 'Dashboard']) {
      await tester.tap(find.byTooltip('Open navigation menu'));
      await settleFor(tester);
      final item = find.descendant(of: find.byType(NavigationDrawer), matching: find.text(page));
      await tester.scrollUntilVisible(item, 100,
          scrollable: find.descendant(of: find.byType(NavigationDrawer), matching: find.byType(Scrollable)));
      await tester.tap(item);
      await settleFor(tester);
      expect(tester.takeException(), isNull, reason: page);
      expect(find.descendant(of: find.byType(AppBar), matching: find.text(page)), findsOneWidget);
    }
  });
}
