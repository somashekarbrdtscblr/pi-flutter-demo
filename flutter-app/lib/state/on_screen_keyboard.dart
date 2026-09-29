import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/keyboard_layouts.dart';

/// Turned on by the Pi build (`--dart-define=ON_SCREEN_KEYBOARD=true`).
/// flutter-pi has no system keyboard, so the app draws its own.
const onScreenKeyboardEnabled = bool.fromEnvironment('ON_SCREEN_KEYBOARD');

enum ShiftState { off, once, locked }

/// In-app on-screen keyboard, plugged in as Flutter's visual text input
/// control. Every text field talks to it automatically; no per-field code.
///
/// Opens only when the text field was focused by touch. The platform text
/// input keeps receiving state, so a physical keyboard still types.
class OnScreenKeyboard extends ChangeNotifier with TextInputControl {
  OnScreenKeyboard(this._prefs)
    : _language =
          KeyboardLanguage.values.asNameMap()[_prefs.getString(_languageKey)] ??
          KeyboardLanguage.english;

  static const _languageKey = 'keyboardLanguage';

  final SharedPreferences _prefs;

  TextInputClient? _client;
  TextInputConfiguration _config = const TextInputConfiguration();
  TextEditingValue _value = TextEditingValue.empty;

  bool _visible = false;
  KeyboardLanguage _language;
  KeyboardPage _page = KeyboardPage.letters;
  ShiftState _shift = ShiftState.off;
  bool _forceFullLayout = false;
  DateTime _lastShiftTap = DateTime(0);

  bool get visible => _visible;
  KeyboardLanguage get language => _language;
  KeyboardPage get page => _page;
  ShiftState get shift => _shift;
  TextInputAction get inputAction => _config.inputAction;

  bool get _numeric =>
      _config.inputType.index == TextInputType.number.index ||
      _config.inputType.index == TextInputType.phone.index;

  /// Rows of keys for the current state.
  List<List<KeyDef>> get rows {
    final lettersLabel = _language.isIndic
        ? indicLettersLabel(_language)
        : 'ABC';
    return switch (_page) {
      KeyboardPage.numpad => numpad(
        phone: _config.inputType.index == TextInputType.phone.index,
      ),
      KeyboardPage.symbols => symbolsPage(
        more: false,
        lettersLabel: lettersLabel,
      ),
      KeyboardPage.moreSymbols => symbolsPage(
        more: true,
        lettersLabel: lettersLabel,
      ),
      KeyboardPage.vowels => indicVowels(_language),
      KeyboardPage.languages => const [],
      KeyboardPage.letters =>
        _language.isIndic
            ? indicLetters(_language)
            : englishLetters(
                upper: _shift != ShiftState.off,
                email:
                    _config.inputType.index == TextInputType.emailAddress.index,
              ),
    };
  }

  void install() {
    TextInput.setInputControl(this);
    FocusManager.instance.addHighlightModeListener(_onHighlightModeChanged);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightModeChanged);
    TextInput.restorePlatformInputControl();
    super.dispose();
  }

  // Mouse or physical key used: hide, the user is not on the touch screen.
  void _onHighlightModeChanged(FocusHighlightMode mode) {
    if (mode == FocusHighlightMode.traditional) _setVisible(false);
  }

  void _setVisible(bool visible) {
    if (_visible == visible) return;
    _visible = visible;
    notifyListeners();
  }

  // ---- TextInputControl (called by the framework) ---------------------------

  @override
  void attach(TextInputClient client, TextInputConfiguration configuration) {
    _client = client;
    _config = configuration;
    _forceFullLayout = false;
    _resetPage();
  }

  @override
  void detach(TextInputClient client) {
    if (_client != client) return;
    _client = null;
    _setVisible(false);
  }

  @override
  void updateConfig(TextInputConfiguration configuration) {
    _config = configuration;
    _resetPage();
  }

  @override
  void setEditingState(TextEditingValue value) {
    _value = value;
    _autoShift();
  }

  @override
  void show() {
    if (FocusManager.instance.highlightMode != FocusHighlightMode.touch) return;
    _setVisible(true);
  }

  @override
  void hide() => _setVisible(false);

  // ---- Key handling (called by the keyboard widget) -------------------------

  void press(KeyDef key) {
    switch (key.action) {
      case KeyAction.char:
        _insert(
          _shift == ShiftState.off || _language.isIndic
              ? key.text
              : key.text.toUpperCase(),
        );
        if (_shift == ShiftState.once) _shift = ShiftState.off;
        _autoShift();
      case KeyAction.space:
        _insert(' ');
        _autoShift();
      case KeyAction.backspace:
        backspace();
      case KeyAction.enter:
        _enter();
      case KeyAction.shift:
        _toggleShift();
      case KeyAction.symbols:
        _page = KeyboardPage.symbols;
      case KeyAction.moreSymbols:
        _page = KeyboardPage.moreSymbols;
      case KeyAction.vowels:
        _page = KeyboardPage.vowels;
      case KeyAction.letters:
        _forceFullLayout = true;
        _page = KeyboardPage.letters;
      case KeyAction.language:
        _page = _page == KeyboardPage.languages
            ? KeyboardPage.letters
            : KeyboardPage.languages;
      case KeyAction.hide:
        _setVisible(false);
    }
    notifyListeners();
  }

  void selectLanguage(KeyboardLanguage language) {
    _language = language;
    _prefs.setString(_languageKey, language.name);
    _forceFullLayout = true;
    _page = KeyboardPage.letters;
    _autoShift();
    notifyListeners();
  }

  /// Deletes the selection, or one code point before the cursor. Indic users
  /// expect this (removes a vowel sign, not the whole syllable).
  void backspace() {
    final text = _value.text;
    final sel = _selection;
    if (!sel.isCollapsed) {
      _replace(sel.start, sel.end, '');
    } else if (sel.start > 0) {
      final surrogatePair =
          sel.start >= 2 && _isLowSurrogate(text.codeUnitAt(sel.start - 1));
      _replace(sel.start - (surrogatePair ? 2 : 1), sel.start, '');
    }
    _autoShift();
    notifyListeners();
  }

  // ---- Internals ------------------------------------------------------------

  TextSelection get _selection => _value.selection.isValid
      ? _value.selection
      : TextSelection.collapsed(offset: _value.text.length);

  void _insert(String text) {
    final sel = _selection;
    _replace(sel.start, sel.end, text);
  }

  void _replace(int start, int end, String text) {
    _value = TextEditingValue(
      text: _value.text.replaceRange(start, end, text),
      selection: TextSelection.collapsed(offset: start + text.length),
    );
    TextInput.updateEditingValue(_value);
  }

  void _enter() {
    if (_config.inputType.index == TextInputType.multiline.index) {
      _insert('\n');
    } else {
      _client?.performAction(_config.inputAction);
    }
  }

  // Tap: one capital. Double tap: caps lock. Tap again: off.
  void _toggleShift() {
    final now = DateTime.now();
    final doubleTap =
        now.difference(_lastShiftTap) < const Duration(milliseconds: 350);
    _lastShiftTap = now;
    _shift = switch (_shift) {
      ShiftState.off => ShiftState.once,
      ShiftState.once => doubleTap ? ShiftState.locked : ShiftState.off,
      ShiftState.locked => ShiftState.off,
    };
  }

  void _resetPage() {
    _page = _numeric && !_forceFullLayout
        ? KeyboardPage.numpad
        : KeyboardPage.letters;
    _shift = ShiftState.off;
    _autoShift();
    notifyListeners();
  }

  /// Applies the field's textCapitalization (e.g. names start with capitals).
  void _autoShift() {
    if (_shift == ShiftState.locked || _language.isIndic) return;
    final before = _value.text.substring(
      0,
      _selection.start.clamp(0, _value.text.length),
    );
    final trimmed = before.trimRight();
    final wantCapital = switch (_config.textCapitalization) {
      TextCapitalization.characters => true,
      TextCapitalization.words => before.isEmpty || before.endsWith(' '),
      TextCapitalization.sentences =>
        trimmed.isEmpty ||
            (before.endsWith(' ') && RegExp(r'[.!?]$').hasMatch(trimmed)),
      TextCapitalization.none => false,
    };
    _shift = wantCapital ? ShiftState.once : ShiftState.off;
  }

  static bool _isLowSurrogate(int unit) => unit >= 0xDC00 && unit <= 0xDFFF;
}

/// Repeats [action] while a key is held (used for backspace).
class KeyRepeater {
  Timer? _timer;

  void start(VoidCallback action) {
    action();
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 400), () {
      _timer = Timer.periodic(
        const Duration(milliseconds: 60),
        (_) => action(),
      );
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
