import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state/on_screen_keyboard.dart';
import '../utils/keyboard_layouts.dart';

/// Key of the keyboard panel, for tests.
const onScreenKeyboardKey = ValueKey('onScreenKeyboard');

/// Docks the on-screen keyboard under the app. The app (including dialogs,
/// which live in its navigator) shrinks to the space above the keyboard.
class KeyboardHost extends StatefulWidget {
  const KeyboardHost({super.key, required this.keyboard, required this.child});

  final OnScreenKeyboard keyboard;
  final Widget child;

  @override
  State<KeyboardHost> createState() => _KeyboardHostState();
}

class _KeyboardHostState extends State<KeyboardHost> {
  bool _wasVisible = false;

  @override
  void initState() {
    super.initState();
    widget.keyboard.addListener(_onKeyboardChanged);
  }

  @override
  void dispose() {
    widget.keyboard.removeListener(_onKeyboardChanged);
    super.dispose();
  }

  // After the keyboard opens the page is shorter; scroll the focused field
  // back into view.
  void _onKeyboardChanged() {
    final visible = widget.keyboard.visible;
    if (visible && !_wasVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final focused = FocusManager.instance.primaryFocus?.context;
        if (focused != null && focused.mounted) {
          Scrollable.ensureVisible(
            focused,
            duration: const Duration(milliseconds: 150),
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          );
        }
      });
    }
    _wasVisible = visible;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: widget.child),
        ListenableBuilder(
          listenable: widget.keyboard,
          builder: (context, _) => widget.keyboard.visible
              // Counts as part of the text field, so tapping keys does not
              // trigger the field's "tap outside" (which would unfocus it).
              ? TextFieldTapRegion(
                  child: _KeyboardView(
                    widget.keyboard,
                    key: onScreenKeyboardKey,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _KeyboardView extends StatelessWidget {
  const _KeyboardView(this.keyboard, {super.key});

  final OnScreenKeyboard keyboard;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final keyHeight = (size.height * 0.085).clamp(36.0, 54.0);
    final numpad = keyboard.page == KeyboardPage.numpad;

    return Material(
      color: scheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: numpad ? 420 : 960),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Header(keyboard),
                  if (keyboard.page == KeyboardPage.languages)
                    _LanguagePicker(keyboard, height: keyHeight)
                  else
                    for (final row in keyboard.rows)
                      SizedBox(
                        height: keyHeight,
                        child: Row(
                          children: [
                            for (final key in row)
                              Expanded(
                                flex: (key.flex * 10).round(),
                                child: _Key(keyboard: keyboard, keyDef: key),
                              ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.keyboard);

  final OnScreenKeyboard keyboard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          const SizedBox(width: 8),
          Icon(
            Icons.keyboard,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(keyboard.language.label, style: theme.textTheme.labelLarge),
          const Spacer(),
          SizedBox(
            width: 56,
            child: _Key(
              keyboard: keyboard,
              keyDef: const KeyDef(KeyAction.hide),
              plain: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker(this.keyboard, {required this.height});

  final OnScreenKeyboard keyboard;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Fixed grid (no scrolling) sized to fit all languages in the space the
    // letter keys normally take.
    final columns = math.max(
      2,
      (MediaQuery.sizeOf(context).width / 160).floor(),
    );
    final languages = KeyboardLanguage.values;
    final rowCount = (languages.length / columns).ceil();
    return SizedBox(
      height: height * 4,
      child: Column(
        children: [
          for (var r = 0; r < rowCount; r++)
            Expanded(
              child: Row(
                children: [
                  for (var c = 0; c < columns; c++)
                    Expanded(
                      child: r * columns + c < languages.length
                          ? _languageTile(
                              theme,
                              scheme,
                              languages[r * columns + c],
                            )
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _languageTile(
    ThemeData theme,
    ColorScheme scheme,
    KeyboardLanguage lang,
  ) {
    return _Pressable(
      onPressed: () => keyboard.selectLanguage(lang),
      color: lang == keyboard.language
          ? scheme.primaryContainer
          : scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(lang.label, style: theme.textTheme.titleMedium),
              Text(lang.languages, style: theme.textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _Key extends StatefulWidget {
  const _Key({
    required this.keyboard,
    required this.keyDef,
    this.plain = false,
  });

  final OnScreenKeyboard keyboard;
  final KeyDef keyDef;

  /// No key background (header buttons).
  final bool plain;

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> {
  final _repeater = KeyRepeater();

  @override
  void dispose() {
    _repeater.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = widget.keyboard;
    final key = widget.keyDef;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final special =
        key.action != KeyAction.char && key.action != KeyAction.space;
    final active =
        (key.action == KeyAction.shift && keyboard.shift != ShiftState.off) ||
        (key.action == KeyAction.language &&
            keyboard.page == KeyboardPage.languages);

    final Widget content = switch (key.action) {
      KeyAction.backspace => const Icon(Icons.backspace_outlined, size: 20),
      KeyAction.shift => Icon(
        keyboard.shift == ShiftState.locked
            ? Icons.keyboard_capslock
            : Icons.arrow_upward,
        size: 20,
      ),
      KeyAction.enter => Icon(switch (keyboard.inputAction) {
        TextInputAction.next => Icons.arrow_forward,
        TextInputAction.search => Icons.search,
        TextInputAction.send => Icons.send,
        TextInputAction.newline => Icons.keyboard_return,
        _ => Icons.check,
      }, size: 20),
      KeyAction.language => const Icon(Icons.language, size: 20),
      KeyAction.hide => const Icon(Icons.keyboard_hide, size: 20),
      KeyAction.space => Text(
        keyboard.language.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      _ => FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          keyboard.shift != ShiftState.off && !keyboard.language.isIndic
              ? key.label.toUpperCase()
              : key.label,
          // Indic letters are denser; draw them larger.
          style: keyboard.language.isIndic
              ? theme.textTheme.titleLarge
              : theme.textTheme.titleMedium?.copyWith(fontSize: 18),
        ),
      ),
    };

    final color = widget.plain
        ? null
        : active
        ? scheme.primaryContainer
        : special
        ? scheme.secondaryContainer
        : scheme.surfaceContainerHighest;

    // Backspace repeats while held; other keys fire once on release.
    if (key.action == KeyAction.backspace) {
      return _Pressable(
        color: color,
        onDown: () => _repeater.start(keyboard.backspace),
        onUp: _repeater.stop,
        child: content,
      );
    }
    return _Pressable(
      color: color,
      onPressed: () => keyboard.press(key),
      child: content,
    );
  }
}

/// Key surface. Uses a raw [Listener] (no gesture arena, no focus) so typing
/// is immediate and never steals focus from the text field.
class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.child,
    this.color,
    this.onPressed,
    this.onDown,
    this.onUp,
  });

  final Widget child;
  final Color? color;
  final VoidCallback? onPressed;
  final VoidCallback? onDown;
  final VoidCallback? onUp;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  void _set(bool pressed) {
    if (mounted) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        _set(true);
        widget.onDown?.call();
      },
      onPointerUp: (_) {
        _set(false);
        widget.onUp?.call();
        widget.onPressed?.call();
      },
      onPointerCancel: (_) {
        _set(false);
        widget.onUp?.call();
      },
      child: Padding(
        padding: const EdgeInsets.all(2.5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _pressed
                ? scheme.primary.withValues(alpha: 0.35)
                : widget.color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}
