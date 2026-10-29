import 'dart:convert';

import 'package:dication/src/core/models/typing_result.dart';
import 'package:dication/src/core/translit/translit.dart';
import 'package:dication/src/core/typing/typing_config.dart';
import 'package:dication/src/core/typing/typing_text.dart';
import 'package:dication/src/core/typing/typing_words.dart';
import 'package:dication/src/providers/translit_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _resultsBox = 'typing_results';
const _settingsBox = 'typing_settings';
const _configKey = 'config';

/// Mashq uchun so'zlar to'plami (`assets/words/uz.txt`). To'plam lotincha
/// saqlanadi, yangi alifbo va kirillga lug'at yordamida o'giriladi.
final typingWordsProvider = FutureProvider.family<List<String>, Alphabet>((ref, alphabet) async {
  final raw = await rootBundle.loadString('assets/words/uz.txt');
  final words = parseWordList(raw);
  if (alphabet == Alphabet.lotin) return words;
  final lexicon = await ref.watch(lexiconProvider.future);
  return [for (final word in words) transliterate(word, Alphabet.lotin, alphabet, lexicon)];
});

/// "Gaplar" rejimi uchun gaplar to'plami (`assets/words/uz-sentences.txt`).
final typingSentencesProvider = FutureProvider.family<List<String>, Alphabet>((ref, alphabet) async {
  final raw = await rootBundle.loadString('assets/words/uz-sentences.txt');
  final sentences = parseSentenceList(raw);
  if (alphabet == Alphabet.lotin) return sentences;
  final lexicon = await ref.watch(lexiconProvider.future);
  return [
    for (final sentence in sentences) normalizeTypingText(transliterate(sentence, Alphabet.lotin, alphabet, lexicon)),
  ];
});

/// Saqlangan natijalar, eng yangisi birinchi.
final typingHistoryProvider = FutureProvider<List<TypingResult>>((ref) async {
  final box = await Hive.openBox(_resultsBox);
  final results = <TypingResult>[];
  for (final item in box.values) {
    try {
      results.add(TypingResult.fromJson(jsonDecode(item)));
    } catch (_) {
      // Buzilgan yozuv tashlab ketiladi.
    }
  }
  results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return results;
});

class TypingStorage {
  static Future<void> saveResult(TypingResult result) async {
    final box = await Hive.openBox(_resultsBox);
    await box.put(result.id, jsonEncode(result.toJson()));
  }

  static Future<TypingConfig> loadConfig() async {
    final box = await Hive.openBox(_settingsBox);
    final raw = box.get(_configKey);
    if (raw == null) return const TypingConfig();
    try {
      return TypingConfig.fromJson(jsonDecode(raw));
    } catch (_) {
      return const TypingConfig();
    }
  }

  static Future<void> saveConfig(TypingConfig config) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put(_configKey, jsonEncode(config.toJson()));
  }
}
