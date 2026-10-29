import 'package:dication/src/core/translit/translit.dart';

/// `sentences` — tasodifiy tanlangan tayyor gaplar ketma-ketligi.
enum TypingMode { time, words, sentences }

class TypingConfig {
  final TypingMode mode;

  /// `time` rejimida — soniyalar, `words` rejimida — so'zlar, `sentences`
  /// rejimida — gaplar soni.
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
  static const List<int> sentenceOptions = [3, 5, 10, 20];

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

  List<int> get options => switch (mode) {
        TypingMode.time => timeOptions,
        TypingMode.words => wordOptions,
        TypingMode.sentences => sentenceOptions,
      };

  /// Gaplarda tinish belgilari va raqamlar o'zi bor, shuning uchun bu rejimda
  /// qo'shimchalar hisobga olinmaydi (sozlamada esa boshqa rejimlar uchun saqlanadi).
  bool get hasExtras => mode != TypingMode.sentences;

  /// Mashqda haqiqatda ishlatiladigan sozlama.
  TypingConfig get effective =>
      hasExtras ? this : copyWith(punctuation: false, numbers: false);

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
      amount: switch (newMode) {
        TypingMode.time => 30,
        TypingMode.words => 25,
        TypingMode.sentences => 5,
      },
    );
  }

  String get label => switch (mode) {
        TypingMode.time => '$amount soniya',
        TypingMode.words => '$amount söz',
        TypingMode.sentences => '$amount gap',
      };

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
      mode: switch (json['mode']) {
        'words' => TypingMode.words,
        'sentences' => TypingMode.sentences,
        _ => TypingMode.time,
      },
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
