import 'dart:math' as math;

/// Keyboard languages. The nine Indic scripts are encoded in parallel in
/// Unicode (same offset = same letter), so one offset layout serves them all.
enum KeyboardLanguage {
  english('English', 'English', 0),
  devanagari('देवनागरी', 'Hindi, Marathi, Nepali, Sanskrit…', 0x0900),
  bengali('বাংলা', 'Bengali, Assamese, Manipuri', 0x0980),
  gurmukhi('ਗੁਰਮੁਖੀ', 'Punjabi', 0x0A00),
  gujarati('ગુજરાતી', 'Gujarati', 0x0A80),
  odia('ଓଡ଼ିଆ', 'Odia', 0x0B00),
  tamil('தமிழ்', 'Tamil', 0x0B80),
  telugu('తెలుగు', 'Telugu', 0x0C00),
  kannada('ಕನ್ನಡ', 'Kannada', 0x0C80),
  malayalam('മലയാളം', 'Malayalam', 0x0D00);

  const KeyboardLanguage(this.label, this.languages, this.base);

  /// Name in its own script.
  final String label;

  /// Languages written with this script.
  final String languages;

  /// Start of the script's Unicode block (0 for English).
  final int base;

  bool get isIndic => base != 0;
}

enum KeyAction {
  char,
  backspace,
  shift,
  enter,
  space,
  symbols,
  letters,
  moreSymbols,
  vowels,
  language,
  hide,
}

class KeyDef {
  const KeyDef(this.action, {this.text = '', String? label, this.flex = 1})
    : label = label ?? text;

  const KeyDef.char(String text, {String? label})
    : this(KeyAction.char, text: text, label: label);

  final KeyAction action;

  /// Text inserted for [KeyAction.char].
  final String text;
  final String label;
  final double flex;
}

enum KeyboardPage { letters, vowels, symbols, moreSymbols, numpad, languages }

// ---- English -----------------------------------------------------------------

const _qwerty = ['qwertyuiop', 'asdfghjkl', 'zxcvbnm'];
const _symbols = ['1234567890', '@#₹_&-+()/', '*"\':;!?'];
const _moreSymbols = ['~`|•√π÷×¶∆', '€£¥\$^=°{}\\', '%©®™§[]<>'];

List<KeyDef> _chars(String s, {bool upper = false}) => [
  for (final c in s.split('')) KeyDef.char(upper ? c.toUpperCase() : c),
];

List<List<KeyDef>> englishLetters({required bool upper, required bool email}) =>
    [
      _chars(_qwerty[0], upper: upper),
      _chars(_qwerty[1], upper: upper),
      [
        const KeyDef(KeyAction.shift, flex: 1.5),
        ..._chars(_qwerty[2], upper: upper),
        const KeyDef(KeyAction.backspace, flex: 1.5),
      ],
      _bottomRow(
        const KeyDef(KeyAction.symbols, label: '?123'),
        left: KeyDef.char(email ? '@' : ','),
        right: const KeyDef.char('.'),
      ),
    ];

List<List<KeyDef>> symbolsPage({
  required bool more,
  required String lettersLabel,
}) {
  final rows = more ? _moreSymbols : _symbols;
  return [
    _chars(rows[0]),
    _chars(rows[1]),
    [
      KeyDef(
        more ? KeyAction.symbols : KeyAction.moreSymbols,
        label: more ? '?123' : '=\\<',
        flex: 1.5,
      ),
      ..._chars(rows[2]),
      const KeyDef(KeyAction.backspace, flex: 1.5),
    ],
    _bottomRow(
      KeyDef(KeyAction.letters, label: lettersLabel),
      left: const KeyDef.char(','),
      right: const KeyDef.char('.'),
    ),
  ];
}

List<List<KeyDef>> numpad({required bool phone}) => [
  [..._chars('123'), const KeyDef(KeyAction.backspace)],
  [..._chars('456'), const KeyDef(KeyAction.enter)],
  [..._chars('789'), const KeyDef(KeyAction.hide)],
  [
    const KeyDef(KeyAction.letters, label: 'ABC'),
    const KeyDef.char('0'),
    KeyDef.char(phone ? '+' : '.'),
    KeyDef.char(phone ? ' ' : '-', label: phone ? '␣' : '-'),
  ],
];

List<KeyDef> _bottomRow(
  KeyDef modeKey, {
  required KeyDef left,
  required KeyDef right,
}) => [
  KeyDef(modeKey.action, label: modeKey.label, flex: 1.5),
  const KeyDef(KeyAction.language),
  left,
  const KeyDef(KeyAction.space, flex: 4),
  right,
  const KeyDef(KeyAction.enter, flex: 1.5),
];

// ---- Indic -------------------------------------------------------------------

// Offsets inside a script block (Devanagari names shown).
// Vowel signs + anusvara + virama: ा ि ी ु ू ृ े ै ो ौ ं ्
const _signOffsets = [
  0x3E,
  0x3F,
  0x40,
  0x41,
  0x42,
  0x43,
  0x47,
  0x48,
  0x4B,
  0x4C,
  0x02,
  0x4D,
];
// Consonants: क…ह, ळ ऴ ऱ ऩ
const _consonantOffsets = [
  0x15, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, //
  0x1F, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28,
  0x2A, 0x2B, 0x2C, 0x2D, 0x2E, 0x2F, 0x30, 0x32, 0x35, 0x36,
  0x37, 0x38, 0x39, 0x33, 0x34, 0x31, 0x29,
];
// Independent vowels अ…औ, then candra/short vowels and rarer signs.
const _vowelOffsets = [
  0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0F, 0x10, 0x13, 0x14, //
  0x0D, 0x11, 0x0E, 0x12, 0x45, 0x49, 0x46, 0x4A, 0x03, 0x01, 0x3C, 0x3D,
];
const _digitOffsets = [
  0x66,
  0x67,
  0x68,
  0x69,
  0x6A,
  0x6B,
  0x6C,
  0x6D,
  0x6E,
  0x6F,
];

// Combining marks get a dotted circle on their key so they are visible.
const _combiningOffsets = {
  0x01,
  0x03,
  0x3C,
  ..._signOffsets,
  0x45,
  0x46,
  0x49,
  0x4A,
};

// Offsets a script does not have (unassigned, or a consonant precomposed with
// nukta, which should be typed as consonant + nukta). Generated from the
// Unicode 16 character database.
const _missing = <KeyboardLanguage, Set<int>>{
  KeyboardLanguage.devanagari: {0x29, 0x31, 0x34},
  KeyboardLanguage.bengali: {
    0x0D,
    0x0E,
    0x11,
    0x12,
    0x29,
    0x31,
    0x33,
    0x34,
    0x35,
    0x45,
    0x46,
    0x49,
    0x4A,
  },
  KeyboardLanguage.gurmukhi: {
    0x0B,
    0x0D,
    0x0E,
    0x11,
    0x12,
    0x29,
    0x31,
    0x33,
    0x34,
    0x36,
    0x37,
    0x3D,
    0x43,
    0x45,
    0x46,
    0x49,
    0x4A, //
  },
  KeyboardLanguage.gujarati: {0x0E, 0x12, 0x29, 0x31, 0x34, 0x46, 0x4A},
  KeyboardLanguage.odia: {
    0x0D,
    0x0E,
    0x11,
    0x12,
    0x29,
    0x31,
    0x34,
    0x45,
    0x46,
    0x49,
    0x4A,
  },
  KeyboardLanguage.tamil: {
    0x01,
    0x0B,
    0x0D,
    0x11,
    0x16,
    0x17,
    0x18,
    0x1B,
    0x1D,
    0x20,
    0x21,
    0x22,
    0x25,
    0x26,
    0x27,
    0x2B, //
    0x2C, 0x2D, 0x3C, 0x3D, 0x43, 0x45, 0x49,
  },
  KeyboardLanguage.telugu: {0x0D, 0x11, 0x29, 0x45, 0x49},
  KeyboardLanguage.kannada: {0x0D, 0x11, 0x29, 0x34, 0x45, 0x49},
  KeyboardLanguage.malayalam: {0x0D, 0x11, 0x45, 0x49},
};

// Script-specific letters outside the shared layout, as (label, inserted
// text). Nukta letters are inserted decomposed (Unicode normal form).
const _extras = <KeyboardLanguage, List<(String, String)>>{
  KeyboardLanguage.devanagari: [
    ('\u095C', '\u0921\u093C'),
    ('\u095D', '\u0922\u093C'),
    ('\u0965', '\u0965'),
    ('\u0950', '\u0950'),
  ],
  KeyboardLanguage.bengali: [
    ('\u09CE', '\u09CE'),
    ('\u09F0', '\u09F0'),
    ('\u09F1', '\u09F1'),
    ('\u09DC', '\u09A1\u09BC'),
    ('\u09DD', '\u09A2\u09BC'),
    ('\u09DF', '\u09AF\u09BC'),
  ],
  KeyboardLanguage.gurmukhi: [
    ('\u25CC\u0A70', '\u0A70'),
    ('\u25CC\u0A71', '\u0A71'),
    ('\u0A72', '\u0A72'),
    ('\u0A73', '\u0A73'),
    ('\u0A5C', '\u0A5C'),
    ('\u0A59', '\u0A16\u0A3C'),
    ('\u0A5A', '\u0A17\u0A3C'),
    ('\u0A5B', '\u0A1C\u0A3C'),
    ('\u0A5E', '\u0A2B\u0A3C'),
  ],
  KeyboardLanguage.odia: [
    ('\u0B5C', '\u0B21\u0B3C'),
    ('\u0B5D', '\u0B22\u0B3C'),
    ('\u0B5F', '\u0B5F'),
    ('\u0B71', '\u0B71'),
  ],
  KeyboardLanguage.tamil: [('\u0BD0', '\u0BD0')],
  KeyboardLanguage.malayalam: [
    ('\u0D7A', '\u0D7A'),
    ('\u0D7B', '\u0D7B'),
    ('\u0D7C', '\u0D7C'),
    ('\u0D7D', '\u0D7D'),
    ('\u0D7E', '\u0D7E'),
  ],
};

// Scripts that end sentences with a danda (।) rather than a full stop.
const _dandaScripts = {
  KeyboardLanguage.devanagari,
  KeyboardLanguage.bengali,
  KeyboardLanguage.gurmukhi,
  KeyboardLanguage.odia,
};

const _maxKeysPerRow = 12;

List<KeyDef> _indicKeys(KeyboardLanguage lang, List<int> offsets) {
  final missing = _missing[lang] ?? const {};
  return [
    for (final o in offsets)
      if (!missing.contains(o))
        KeyDef.char(
          String.fromCharCode(lang.base + o),
          label: _combiningOffsets.contains(o)
              ? '◌${String.fromCharCode(lang.base + o)}'
              : String.fromCharCode(lang.base + o),
        ),
  ];
}

/// Splits [keys] into the fewest rows of at most [_maxKeysPerRow], evenly.
List<List<KeyDef>> _rows(List<KeyDef> keys) {
  if (keys.isEmpty) return const [];
  final count = (keys.length / _maxKeysPerRow).ceil();
  final perRow = (keys.length / count).ceil();
  return [
    for (var i = 0; i < keys.length; i += perRow)
      keys.sublist(i, math.min(i + perRow, keys.length)),
  ];
}

/// Label of the key that switches between consonants and vowels pages.
String indicVowelsLabel(KeyboardLanguage lang) =>
    String.fromCharCode(lang.base + 0x05);
String indicLettersLabel(KeyboardLanguage lang) =>
    String.fromCharCode(lang.base + 0x15);

List<List<KeyDef>> indicLetters(KeyboardLanguage lang) {
  final consonants = _rows(_indicKeys(lang, _consonantOffsets));
  consonants.last = [
    ...consonants.last,
    const KeyDef(KeyAction.backspace, flex: 1.5),
  ];
  return [
    _indicKeys(lang, _signOffsets),
    ...consonants,
    _indicBottomRow(lang, vowels: false),
  ];
}

List<List<KeyDef>> indicVowels(KeyboardLanguage lang) {
  final extras = [
    for (final (label, text) in _extras[lang] ?? const <(String, String)>[])
      KeyDef.char(text, label: label),
  ];
  return [
    ..._rows(_indicKeys(lang, _vowelOffsets)),
    _indicKeys(lang, _digitOffsets),
    [...extras, const KeyDef(KeyAction.backspace, flex: 1.5)],
    _indicBottomRow(lang, vowels: true),
  ];
}

List<KeyDef> _indicBottomRow(KeyboardLanguage lang, {required bool vowels}) =>
    _bottomRow(
      const KeyDef(KeyAction.symbols, label: '?123'),
      left: vowels
          ? KeyDef(KeyAction.letters, label: indicLettersLabel(lang))
          : KeyDef(KeyAction.vowels, label: indicVowelsLabel(lang)),
      right: _dandaScripts.contains(lang)
          ? const KeyDef.char('।')
          : const KeyDef.char('.'),
    );
