enum TypingMode { time, words }

class TypingConfig {
  final TypingMode mode;

  /// `time` rejimida — soniyalar, `words` rejimida — so'zlar soni.
  final int amount;
  final bool punctuation;
  final bool numbers;

  const TypingConfig({
    this.mode = TypingMode.time,
    this.amount = 30,
    this.punctuation = false,
    this.numbers = false,
  });

  static const List<int> timeOptions = [15, 30, 60, 120];
  static const List<int> wordOptions = [10, 25, 50, 100];

  List<int> get options => mode == TypingMode.time ? timeOptions : wordOptions;

  TypingConfig copyWith({
    TypingMode? mode,
    int? amount,
    bool? punctuation,
    bool? numbers,
  }) {
    return TypingConfig(
      mode: mode ?? this.mode,
      amount: amount ?? this.amount,
      punctuation: punctuation ?? this.punctuation,
      numbers: numbers ?? this.numbers,
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

  String get label => mode == TypingMode.time ? '$amount soniya' : '$amount so‘z';

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'amount': amount,
        'punctuation': punctuation,
        'numbers': numbers,
      };

  factory TypingConfig.fromJson(Map<String, dynamic> json) {
    return TypingConfig(
      mode: TypingMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => TypingMode.time,
      ),
      amount: json['amount'] ?? 30,
      punctuation: json['punctuation'] ?? false,
      numbers: json['numbers'] ?? false,
    );
  }
}
