import 'dart:math';

import 'package:dication/src/core/typing/typing_config.dart';
import 'package:dication/src/core/typing/typing_text.dart';

/// Mashqning bir soniyalik kesimi (natija grafigi uchun).
class TypingSample {
  final int second;
  final double wpm;
  final double raw;
  final int errors;

  const TypingSample({
    required this.second,
    required this.wpm,
    required this.raw,
    required this.errors,
  });

  List<num> toJson() => [second, wpm, raw, errors];

  factory TypingSample.fromJson(List<dynamic> json) => TypingSample(
        second: (json[0] as num).toInt(),
        wpm: (json[1] as num).toDouble(),
        raw: (json[2] as num).toDouble(),
        errors: (json[3] as num).toInt(),
      );
}

class TypingStats {
  /// Daqiqasiga so'z: faqat to'g'ri terilgan so'zlarning belgilari / 5.
  final double wpm;

  /// Xatolarni hisobga olmagan "xom" tezlik.
  final double raw;

  /// To'g'ri bosilgan klavishlar foizi.
  final double accuracy;

  /// Tezlikning barqarorligi (0–100).
  final double consistency;
  final int correctChars;
  final int incorrectChars;
  final int extraChars;
  final int missedChars;

  const TypingStats({
    required this.wpm,
    required this.raw,
    required this.accuracy,
    required this.consistency,
    required this.correctChars,
    required this.incorrectChars,
    required this.extraChars,
    required this.missedChars,
  });
}

/// Tez yozish mashqining holati va hisob-kitobi. UI'dan mustaqil: vaqt
/// tashqaridan ([tick], [stats]) beriladi, shuning uchun test qilish oson.
class TypingEngine {
  /// So'zdan ortiqcha terilishi mumkin bo'lgan belgilar soni.
  static const int maxExtraChars = 8;
  static const int _timeModeBuffer = 60;

  final TypingConfig config;
  final String Function()? _nextWord;

  final List<String> words = [];
  final List<String> typed = [];
  final List<TypingSample> samples = [];

  String current = '';
  bool started = false;
  bool finished = false;
  Duration? finishedAt;

  int _correctKeys = 0;
  int _incorrectKeys = 0;
  int _secondKeys = 0;
  int _secondErrors = 0;

  /// [nextWord] — so'z beruvchi funksiya (vaqt va so'zlar rejimi) yoki
  /// [fixedWords] — tayyor so'zlar ro'yxati (gaplar rejimi: mashq shu so'zlar
  /// terilganda tugaydi).
  TypingEngine({
    required this.config,
    String Function()? nextWord,
    List<String>? fixedWords,
  })  : assert((nextWord == null) != (fixedWords == null)),
        _nextWord = nextWord {
    if (fixedWords != null) words.addAll(fixedWords);
    _fill();
  }

  /// Mashq so'zlar soni bilan cheklangan (vaqt rejimidan tashqari hammasi).
  bool get _fixedLength => config.mode != TypingMode.time;

  int get index => typed.length;

  String get target => words[index];

  /// So'zlar tugadimi (vaqt rejimida tayyor ro'yxat odam uchun imkonsiz tezlikda tugashi mumkin).
  bool get outOfWords => index >= words.length;

  void _fill() {
    final nextWord = _nextWord;
    if (nextWord == null) return;
    final wanted = config.mode == TypingMode.words
        ? config.amount
        : typed.length + _timeModeBuffer;
    while (words.length < wanted) {
      words.add(nextWord());
    }
  }

  void _keystroke(bool correct) {
    started = true;
    _secondKeys++;
    if (correct) {
      _correctKeys++;
    } else {
      _incorrectKeys++;
      _secondErrors++;
    }
  }

  /// Joriy so'z uchun kiritilgan matnni yangilaydi. Qo'shilgan har bir yangi
  /// belgi klavish bosilishi sifatida hisoblanadi.
  void setCurrent(String value, {Duration elapsed = Duration.zero}) {
    if (finished) return;
    _sampleUntil(elapsed);
    _checkTime(elapsed);
    if (finished) return;
    value = value.replaceAll(RegExp(r'\s'), '');
    final limit = target.length + maxExtraChars;
    if (value.length > limit) value = value.substring(0, limit);
    if (value == current) return;

    var common = 0;
    while (common < value.length &&
        common < current.length &&
        value[common] == current[common]) {
      common++;
    }
    for (var i = common; i < value.length; i++) {
      _keystroke(i < target.length && isSameTypingChar(value[i], target[i]));
    }
    current = value;

    // So'zlar va gaplar rejimida oxirgi so'z to'g'ri terilishi bilan mashq yakunlanadi.
    final isLastWord = _fixedLength && index == words.length - 1;
    if (isLastWord && isTypedWordCorrect(current, target)) {
      _commit(elapsed);
    }
  }

  /// Bo'sh joy: joriy so'zni yakunlab, keyingisiga o'tadi.
  void commitWord({Duration elapsed = Duration.zero}) {
    if (finished || current.isEmpty) return;
    _sampleUntil(elapsed);
    _checkTime(elapsed);
    if (finished) return;
    _keystroke(true);
    _commit(elapsed);
  }

  void _commit(Duration elapsed) {
    typed.add(current);
    current = '';
    if (_fixedLength && typed.length >= words.length) {
      _finish(elapsed);
    } else {
      _fill();
    }
  }

  /// Bo'sh holatda o'chirish: oldingi so'z xato terilgan bo'lsa, unga qaytadi.
  bool backToPreviousWord() {
    if (finished || current.isNotEmpty || typed.isEmpty) return false;
    final previous = typed.last;
    if (isTypedWordCorrect(previous, words[typed.length - 1])) return false;
    typed.removeLast();
    current = previous;
    return true;
  }

  /// Muntazam chaqiriladi: grafik uchun kesim yozadi va vaqt rejimida
  /// belgilangan vaqt tugagach mashqni yakunlaydi.
  void tick(Duration elapsed) {
    if (!started || finished) return;
    _sampleUntil(elapsed);
    _checkTime(elapsed);
  }

  /// O'tgan soniya kesimini yozadi. Klavish bosilganda ham chaqiriladi: taymer
  /// kechiksa, bosishlar keyingi soniyaga o'tib ketmasin va so'zlar rejimida
  /// yakunda yo'qolmasin — server kesimlardagi bosishlar sonini natija bilan
  /// solishtiradi.
  ///
  /// Har bir to'liq soniya uchun alohida kesim soniya chegarasidagi holat
  /// bo'yicha yoziladi (chaqiruv payti emas) — natija taymerga bog'liq emas va
  /// server bosishlar logini qayta o'ynaganda aynan shu kesimlar chiqadi
  /// (saytdagi `engine.ts` bilan bir xil).
  void _sampleUntil(Duration elapsed) {
    if (!started) return;
    var until = elapsed.inMicroseconds ~/ 1000000;
    if (config.mode == TypingMode.time) until = min(until, config.amount);
    while (samples.length < until) {
      final second = samples.length + 1;
      samples.add(TypingSample(
        second: second,
        wpm: stats(Duration(seconds: second)).wpm,
        raw: _secondKeys * 12.0,
        errors: _secondErrors,
      ));
      _secondKeys = 0;
      _secondErrors = 0;
    }
  }

  /// Vaqt rejimida vaqt tugagan bo'lsa (taymer kechikkan bo'lsa ham), keyingi
  /// bosishlar hisobga olinmaydi.
  void _checkTime(Duration elapsed) {
    if (started &&
        config.mode == TypingMode.time &&
        elapsed.inMicroseconds >= config.amount * 1000000) {
      _finish(Duration(seconds: config.amount));
    }
  }

  void _finish(Duration elapsed) {
    finished = true;
    finishedAt = elapsed;
  }

  TypingStats stats(Duration elapsed) {
    var correct = 0;
    var incorrect = 0;
    var extra = 0;
    var missed = 0;
    var wpmChars = 0;

    for (var i = 0; i < typed.length; i++) {
      final input = typed[i];
      final word = words[i];
      final shared = min(input.length, word.length);
      for (var j = 0; j < shared; j++) {
        if (isSameTypingChar(input[j], word[j])) {
          correct++;
        } else {
          incorrect++;
        }
      }
      if (input.length > word.length) extra += input.length - word.length;
      if (input.length < word.length) missed += word.length - input.length;

      if (isTypedWordCorrect(input, word)) {
        // So'zdan keyingi bo'sh joy ham hisobga olinadi (eng oxirgi so'zdan tashqari).
        final hasSpace = !_fixedLength || i < words.length - 1;
        wpmChars += word.length + (hasSpace ? 1 : 0);
      }
    }

    // Vaqt tugaganda yarim terilgan so'z: xatosiz bo'lsa, hisobga qo'shiladi.
    if (current.isNotEmpty) {
      final word = target;
      var prefixCorrect = current.length <= word.length;
      for (var j = 0; j < current.length; j++) {
        if (j < word.length && isSameTypingChar(current[j], word[j])) {
          correct++;
        } else if (j < word.length) {
          incorrect++;
          prefixCorrect = false;
        } else {
          extra++;
        }
      }
      if (prefixCorrect) wpmChars += current.length;
    }

    // Mikrosoniya aniqligida: server (JS) vaqtni millisoniya kasri bilan hisoblaydi.
    final minutes = elapsed.inMicroseconds / 60000000;
    final keys = _correctKeys + _incorrectKeys;

    return TypingStats(
      wpm: minutes <= 0 ? 0 : wpmChars / 5 / minutes,
      raw: minutes <= 0 ? 0 : keys / 5 / minutes,
      accuracy: keys == 0 ? 0 : _correctKeys / keys * 100,
      consistency: _consistency(),
      correctChars: correct,
      incorrectChars: incorrect,
      extraChars: extra,
      missedChars: missed,
    );
  }

  double _consistency() {
    if (samples.length < 2) return 0;
    final values = samples.map((s) => s.raw).toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    if (mean <= 0) return 0;
    final variance =
        values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
            values.length;
    final cv = sqrt(variance) / mean;
    return (1 - min(1.0, cv)) * 100;
  }
}
