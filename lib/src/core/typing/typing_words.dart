import 'dart:math';

import 'package:dication/src/core/typing/typing_config.dart';
import 'package:dication/src/core/typing/typing_text.dart';

/// `assets/words/uz.txt` formatidagi matnni so'zlar ro'yxatiga aylantiradi:
/// har bir qatorda bitta so'z, `#` bilan boshlangan qatorlar — izoh.
List<String> parseWordList(String raw) {
  final seen = <String>{};
  final words = <String>[];
  for (final line in raw.split('\n')) {
    final word = normalizeTypingText(line.trim().toLowerCase());
    if (word.isEmpty || word.startsWith('#') || word.contains(' ')) continue;
    if (seen.add(word)) words.add(word);
  }
  return words;
}

/// So'zlar to'plamidan mashq uchun tasodifiy so'zlar ketma-ketligini beradi.
class TypingWordGenerator {
  final List<String> pool;
  final TypingConfig config;
  final Random _random;

  String? _last;
  bool _sentenceStart = true;

  TypingWordGenerator({
    required this.pool,
    required this.config,
    Random? random,
  })  : assert(pool.isNotEmpty),
        _random = random ?? Random();

  String next() {
    if (config.numbers && _random.nextInt(10) == 0) {
      _last = null;
      return _punctuate(_random.nextInt(1000).toString());
    }

    var word = pool[_random.nextInt(pool.length)];
    // Bir xil so'z ketma-ket ikki marta chiqmasin.
    for (var i = 0; i < 5 && word == _last && pool.length > 1; i++) {
      word = pool[_random.nextInt(pool.length)];
    }
    _last = word;
    return _punctuate(word);
  }

  String _punctuate(String word) {
    if (!config.punctuation) return word;

    if (_sentenceStart) {
      word = word[0].toUpperCase() + word.substring(1);
      _sentenceStart = false;
    }

    final roll = _random.nextInt(100);
    if (roll < 12) {
      _sentenceStart = true;
      const endings = ['.', '.', '.', '?', '!'];
      return word + endings[_random.nextInt(endings.length)];
    }
    if (roll < 26) return '$word,';
    if (roll < 29) return '$word;';
    if (roll < 32) return '$word:';
    return word;
  }
}
