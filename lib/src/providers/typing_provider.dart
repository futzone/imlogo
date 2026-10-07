import 'dart:convert';

import 'package:dication/src/core/models/typing_result.dart';
import 'package:dication/src/core/typing/typing_config.dart';
import 'package:dication/src/core/typing/typing_words.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _resultsBox = 'typing_results';
const _settingsBox = 'typing_settings';
const _configKey = 'config';

/// Mashq uchun so'zlar to'plami (`assets/words/uz.txt`).
final typingWordsProvider = FutureProvider<List<String>>((ref) async {
  final raw = await rootBundle.loadString('assets/words/uz.txt');
  return parseWordList(raw);
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
