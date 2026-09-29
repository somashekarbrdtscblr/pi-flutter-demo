import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/state/on_screen_keyboard.dart';
import 'package:flutter_app/utils/keyboard_layouts.dart';
import 'package:flutter_app/widgets/on_screen_keyboard.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('layouts', () {
    test('every Indic page has rows of at most 12 keys + backspace', () {
      for (final lang in KeyboardLanguage.values.where((l) => l.isIndic)) {
        for (final page in [indicLetters(lang), indicVowels(lang)]) {
          for (final row in page) {
            expect(
              row.length,
              lessThanOrEqualTo(13),
              reason: '${lang.name} row',
            );
            for (final key in row.where((k) => k.action == KeyAction.char)) {
              expect(key.text, isNotEmpty);
            }
          }
        }
      }
    });

    test('scripts only get letters they have', () {
      String chars(List<List<KeyDef>> rows) => rows
          .expand((r) => r)
          .where((k) => k.action == KeyAction.char)
          .map((k) => k.text)
          .join();

      // Tamil has no aspirated KHA (U+0B96 is unassigned).
      expect(chars(indicLetters(KeyboardLanguage.tamil)), isNot(contains('஖')));
      expect(chars(indicLetters(KeyboardLanguage.tamil)), contains('க')); // க
      // Devanagari nukta letters are typed decomposed: ड़ = ड + ़
      expect(chars(indicVowels(KeyboardLanguage.devanagari)), contains('ड़'));
      expect(
        chars(indicVowels(KeyboardLanguage.devanagari)),
        isNot(contains('ड़')),
      );
    });
  });

  group('keyboard', () {
    late OnScreenKeyboard keyboard;

    Future<void> pumpFields(WidgetTester tester, List<Widget> fields) async {
      SharedPreferences.setMockInitialValues({});
      keyboard = OnScreenKeyboard(await SharedPreferences.getInstance())
        ..install();
      addTearDown(keyboard.dispose);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              KeyboardHost(keyboard: keyboard, child: child!),
          home: Scaffold(body: Column(children: fields)),
        ),
      );
    }

    Finder keyboardPanel() => find.byKey(onScreenKeyboardKey);
    Finder keyLabel(String label) =>
        find.descendant(of: keyboardPanel(), matching: find.text(label));
    Finder keyIcon(IconData icon) =>
        find.descendant(of: keyboardPanel(), matching: find.byIcon(icon));

    Future<void> type(WidgetTester tester, List<String> labels) async {
      for (final l in labels) {
        await tester.tap(keyLabel(l));
        await tester.pump();
      }
    }

    testWidgets('opens on touch, types into the field, backspace deletes', (
      tester,
    ) async {
      final controller = TextEditingController();
      await pumpFields(tester, [TextField(controller: controller)]);

      await tester.tap(find.byType(TextField)); // touch by default
      await tester.pumpAndSettle();
      expect(keyboardPanel(), findsOneWidget);

      await type(tester, ['h', 'i']);
      await tester.tap(keyIcon(Icons.backspace_outlined));
      await tester.pump();
      await type(tester, ['o']);
      expect(controller.text, 'ho');

      // Field keeps focus while typing on the keyboard.
      expect(FocusManager.instance.primaryFocus?.context?.widget, isA<Focus>());
    });

    testWidgets('does not open on mouse click', (tester) async {
      await pumpFields(tester, [const TextField()]);

      await tester.tap(find.byType(TextField), kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      expect(keyboardPanel(), findsNothing);

      await tester.tap(find.byType(TextField)); // now by touch
      await tester.pumpAndSettle();
      expect(keyboardPanel(), findsOneWidget);
    });

    testWidgets('number fields get the number pad', (tester) async {
      final controller = TextEditingController();
      await pumpFields(tester, [
        TextField(controller: controller, keyboardType: TextInputType.number),
      ]);

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(keyLabel('q'), findsNothing);

      await type(tester, ['4', '2', '.', '5']);
      expect(controller.text, '42.5');
    });

    testWidgets('word capitalization and enter moves to the next field', (
      tester,
    ) async {
      final first = TextEditingController();
      final second = TextEditingController();
      await pumpFields(tester, [
        TextField(
          controller: first,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
        ),
        TextField(controller: second),
      ]);

      await tester.tap(find.byType(TextField).first);
      await tester.pumpAndSettle();
      // Labels follow shift: capital at the start of each word.
      await type(tester, ['J', 'o']);
      await tester.tap(
        find
            .descendant(
              of: keyboardPanel(),
              matching: find.text(KeyboardLanguage.english.label),
            )
            .last, // space bar (the header shows the language too)
      );
      await tester.pump();
      await type(tester, ['D']);
      expect(first.text, 'Jo D');

      await tester.tap(keyIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();
      await type(tester, ['x']);
      expect(second.text, 'x');
    });

    testWidgets(
      'Kannada: consonant + vowel sign, backspace removes only the sign',
      (tester) async {
        final controller = TextEditingController();
        await pumpFields(tester, [TextField(controller: controller)]);

        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();
        await tester.tap(keyIcon(Icons.language));
        await tester.pumpAndSettle();
        await tester.tap(find.text('ಕನ್ನಡ'));
        await tester.pumpAndSettle();

        await type(tester, ['ಕ', '◌ಾ']);
        expect(controller.text, 'ಕಾ');

        await tester.tap(keyIcon(Icons.backspace_outlined));
        await tester.pump();
        expect(controller.text, 'ಕ');
        expect(keyboard.language, KeyboardLanguage.kannada);
      },
    );

    testWidgets('hide button closes the keyboard', (tester) async {
      await pumpFields(tester, [const TextField()]);
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      await tester.tap(keyIcon(Icons.keyboard_hide).first);
      await tester.pumpAndSettle();
      expect(keyboardPanel(), findsNothing);
    });
  });
}
