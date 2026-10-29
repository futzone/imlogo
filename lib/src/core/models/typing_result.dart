import 'package:dication/src/core/typing/typing_config.dart';
import 'package:dication/src/core/typing/typing_engine.dart';

/// Yakunlangan bitta tez yozish mashqining natijasi (qurilmada saqlanadi).
class TypingResult {
  final String id;
  final DateTime createdAt;
  final TypingConfig config;
  final double wpm;
  final double raw;
  final double accuracy;
  final double consistency;
  final int correctChars;
  final int incorrectChars;
  final int extraChars;
  final int missedChars;
  final double seconds;
  final List<TypingSample> samples;

  /// Shubhali natija belgilari (qarang: analyzeTyping). Bo'sh bo'lmasa, natija
  /// reytingga ham, "yangi rekord" ga ham kirmaydi.
  final List<String> flags;

  const TypingResult({
    required this.id,
    required this.createdAt,
    required this.config,
    required this.wpm,
    required this.raw,
    required this.accuracy,
    required this.consistency,
    required this.correctChars,
    required this.incorrectChars,
    required this.extraChars,
    required this.missedChars,
    required this.seconds,
    required this.samples,
    this.flags = const [],
  });

  /// Natija rekord va reyting uchun hisobga olinadimi.
  bool get isTrusted => flags.isEmpty;

  TypingResult withFlags(List<String> flags) => TypingResult(
        id: id,
        createdAt: createdAt,
        config: config,
        wpm: wpm,
        raw: raw,
        accuracy: accuracy,
        consistency: consistency,
        correctChars: correctChars,
        incorrectChars: incorrectChars,
        extraChars: extraChars,
        missedChars: missedChars,
        seconds: seconds,
        samples: samples,
        flags: flags,
      );

  /// Rekord: ishonchli natijalardagi eng yuqori WPM (bo'lmasa — `null`).
  static double? bestWpm(Iterable<TypingResult> results) {
    double? best;
    for (final result in results) {
      if (result.isTrusted && (best == null || result.wpm > best)) best = result.wpm;
    }
    return best;
  }

  factory TypingResult.fromEngine(TypingEngine engine) {
    final elapsed = engine.finishedAt ?? Duration.zero;
    final stats = engine.stats(elapsed);
    final now = DateTime.now();
    return TypingResult(
      id: now.microsecondsSinceEpoch.toString(),
      createdAt: now,
      config: engine.config,
      wpm: stats.wpm,
      raw: stats.raw,
      accuracy: stats.accuracy,
      consistency: stats.consistency,
      correctChars: stats.correctChars,
      incorrectChars: stats.incorrectChars,
      extraChars: stats.extraChars,
      missedChars: stats.missedChars,
      seconds: elapsed.inMicroseconds / 1000000,
      samples: List.of(engine.samples),
    );
  }

  String get formattedDate {
    final d = createdAt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}.${two(d.month)}.${two(d.day)}, ${two(d.hour)}:${two(d.minute)}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'config': config.toJson(),
        'wpm': wpm,
        'raw': raw,
        'accuracy': accuracy,
        'consistency': consistency,
        'correctChars': correctChars,
        'incorrectChars': incorrectChars,
        'extraChars': extraChars,
        'missedChars': missedChars,
        'seconds': seconds,
        'samples': samples.map((s) => s.toJson()).toList(),
        if (flags.isNotEmpty) 'flags': flags,
      };

  factory TypingResult.fromJson(Map<String, dynamic> json) {
    return TypingResult(
      id: json['id'],
      createdAt: DateTime.parse(json['createdAt']),
      config: TypingConfig.fromJson(Map<String, dynamic>.from(json['config'])),
      wpm: (json['wpm'] as num).toDouble(),
      raw: (json['raw'] as num).toDouble(),
      accuracy: (json['accuracy'] as num).toDouble(),
      consistency: (json['consistency'] as num).toDouble(),
      correctChars: json['correctChars'],
      incorrectChars: json['incorrectChars'],
      extraChars: json['extraChars'],
      missedChars: json['missedChars'],
      seconds: (json['seconds'] as num).toDouble(),
      samples: (json['samples'] as List)
          .map((s) => TypingSample.fromJson(s as List))
          .toList(),
      flags: [for (final flag in (json['flags'] as List? ?? const [])) flag.toString()],
    );
  }
}
