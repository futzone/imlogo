import 'dart:convert';
import 'dart:io';

import 'package:dication/src/core/models/typing_result.dart';
import 'package:dication/src/core/typing/typing_config.dart';
import 'package:dication/src/core/typing/typing_guard.dart';
import 'package:dication/src/core/typing/typing_replay.dart';
import 'package:flutter_test/flutter_test.dart';

/// Server natijani bosishlar logidan saytdagi JS dvigatel bilan qayta
/// hisoblaydi. Ilova hisobi u bilan aynan bir xil bo'lishi kerak: aks holda
/// ilova ko'rsatgan natija va bayroqlar serverdagidan farq qiladi.
/// `fixtures/typing_replay_cases.json` sayt kodi bilan yasalgan
/// (`node tool/typing_replay_fixture.mjs`).
void main() {
  final cases = jsonDecode(File('test/fixtures/typing_replay_cases.json').readAsStringSync()) as List;

  for (final raw in cases) {
    final item = raw as Map<String, dynamic>;
    test(item['name'], () {
      final config = TypingConfig.fromJson(Map<String, dynamic>.from(item['config']));
      final words = [for (final word in item['words'] as List) word as String];
      final log = [
        for (final entry in item['log'] as List)
          TypingLogEntry(
            t: (entry['t'] as num).toDouble(),
            v: entry['v'] as String?,
            it: entry['it'] as String,
            k: entry['k'] as String?,
          ),
      ];
      final expected = item['expected'] as Map<String, dynamic>;

      final replay = replayTypingLog(config, words, log);
      expect(replay.engine.finished, expected['finished']);
      if (expected['result'] == null) return;

      final result = TypingResult.fromEngine(replay.engine);
      final want = expected['result'] as Map<String, dynamic>;
      const eps = 1e-9;
      expect(result.wpm, closeTo((want['wpm'] as num).toDouble(), eps), reason: 'wpm');
      expect(result.raw, closeTo((want['raw'] as num).toDouble(), eps), reason: 'raw');
      expect(result.accuracy, closeTo((want['accuracy'] as num).toDouble(), eps), reason: 'accuracy');
      expect(result.consistency, closeTo((want['consistency'] as num).toDouble(), eps), reason: 'consistency');
      expect(result.correctChars, want['correctChars']);
      expect(result.incorrectChars, want['incorrectChars']);
      expect(result.extraChars, want['extraChars']);
      expect(result.missedChars, want['missedChars']);
      expect(result.seconds, closeTo((want['seconds'] as num).toDouble(), eps), reason: 'seconds');

      final samples = want['samples'] as List;
      expect(result.samples.length, samples.length, reason: 'kesimlar soni');
      for (var i = 0; i < samples.length; i++) {
        final s = samples[i] as List;
        expect(result.samples[i].second, s[0]);
        expect(result.samples[i].wpm, closeTo((s[1] as num).toDouble(), eps), reason: 'kesim $i wpm');
        expect(result.samples[i].raw, (s[2] as num).toDouble());
        expect(result.samples[i].errors, s[3]);
      }

      expect(analyzeTyping(replay.events, result.wpm), expected['flags']);
    });
  }
}
