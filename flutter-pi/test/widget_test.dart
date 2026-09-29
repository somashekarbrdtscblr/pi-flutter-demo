import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pi_demo/app_state.dart';
import 'package:pi_demo/main.dart';

void main() {
  testWidgets('login validates, then signs in to dashboard', (tester) async {
    await tester.pumpWidget(PiDemoApp(state: AppState()));

    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      AppState.demoEmail,
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      AppState.demoPassword,
    );
    await tester.tap(find.text('Sign in'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
  });

  testWidgets('wrong password shows error', (tester) async {
    await tester.pumpWidget(PiDemoApp(state: AppState()));
    await tester.enterText(
      find.byType(TextFormField).at(0),
      AppState.demoEmail,
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong123');
    await tester.tap(find.text('Sign in'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Invalid email or password'), findsOneWidget);
  });

  testWidgets('every drawer page builds', (tester) async {
    tester.view.physicalSize = const Size(800, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final state = AppState();
    // login() uses Future.delayed; run it on the real clock, not fake async.
    await tester.runAsync(
      () => state.login(AppState.demoEmail, AppState.demoPassword),
    );
    await tester.pumpWidget(PiDemoApp(state: state));

    for (final page in [
      'Components',
      'Forms',
      'Dialogs',
      'Editable Table',
      'Lists & Layout',
      'Settings',
      'Dashboard',
    ]) {
      // Timed pumps: some pages have indeterminate progress indicators, so
      // pumpAndSettle would never settle.
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationDrawer),
          matching: find.text(page),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull, reason: page);
    }
  });
}
