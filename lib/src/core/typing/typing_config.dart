import 'package:dication/src/core/translit/translit.dart';

enum TypingMode { time, words }

class TypingConfig {
  final TypingMode mode;

  /// `time` rejimida — soniyalar, `words` rejimida — so'zlar soni.
  final int amount;
  final bool punctuation;
  final bool numbers;

  /// So'zlar qaysi yozuvda: amaldagi lotin, yangi lotin yoki kirill.
  final Alphabet alphabet;

  const TypingConfig({
    this.mode = TypingMode.time,
    this.amount = 30,
    this.punctuation = false,
    this.numbers = false,
    this.alphabet = Alphabet.lotin,
  });

  static const List<int> timeOptions = [15, 30, 60, 120];
  static const List<int> wordOptions = [10, 25, 50, 100];

  /// Sozlamalar panelidagi yozuv tanlovi.
  static const Map<Alphabet, String> alphabetOptions = {
    Alphabet.lotin: 'eski',
    Alphabet.yangi: 'yangi',
    Alphabet.kirill: 'kirill',
  };

  static const Map<Alphabet, String> _alphabetLabels = {
    Alphabet.lotin: 'eski lotin',
    Alphabet.yangi: 'yangi lotin',
    Alphabet.kirill: 'kirill',
  };

  List<int> get options => mode == TypingMode.time ? timeOptions : wordOptions;

  TypingConfig copyWith({
    TypingMode? mode,
    int? amount,
    bool? punctuation,
    bool? numbers,
    Alphabet? alphabet,
  }) {
    return TypingConfig(
      mode: mode ?? this.mode,
      amount: amount ?? this.amount,
      punctuation: punctuation ?? this.punctuation,
      numbers: numbers ?? this.numbers,
      alphabet: alphabet ?? this.alphabet,
    );
  }

  /// Rejim almashganda miqdor yangi rejimning standart qiymatiga o'tadi.
  TypingConfig withMode(TypingMode newMode) {
    if (newMode == mode) return this;
    return copyWith(
      mode: newMode,
      amount: newMode == TypingMode.time ? 30 : 25,
    );
  }

  String get label => mode == TypingMode.time ? '$amount soniya' : '$amount söz';

  String get alphabetLabel => _alphabetLabels[alphabet]!;

  bool isSameAs(TypingConfig other) =>
      mode == other.mode &&
      amount == other.amount &&
      punctuation == other.punctuation &&
      numbers == other.numbers &&
      alphabet == other.alphabet;

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'amount': amount,
        'punctuation': punctuation,
        'numbers': numbers,
        'alphabet': alphabet.name,
      };

  /// Saqlangan (ishonchsiz) qiymatdan sozlamani tiklaydi — server yozuvidan ham.
  factory TypingConfig.fromJson(Map<String, dynamic> json) {
    return TypingConfig(
      mode: json['mode'] == 'words' ? TypingMode.words : TypingMode.time,
      amount: json['amount'] is num ? (json['amount'] as num).toInt() : 30,
      punctuation: json['punctuation'] == true,
      numbers: json['numbers'] == true,
      alphabet: switch (json['alphabet']) {
        'yangi' => Alphabet.yangi,
        'kirill' => Alphabet.kirill,
        _ => Alphabet.lotin,
      },
    );
  }
}
