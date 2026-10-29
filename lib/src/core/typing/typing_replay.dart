import 'package:dication/src/core/typing/typing_config.dart';
import 'package:dication/src/core/typing/typing_engine.dart';
import 'package:dication/src/core/typing/typing_guard.dart';
import 'package:dication/src/core/typing/typing_input.dart';

class TypingReplay {
  final TypingEngine engine;
  final List<TypingInputEvent> events;

  const TypingReplay(this.engine, this.events);
}

/// Bosishlar logini berilgan so'zlar ustida qaytadan o'ynaydi (saytdagi
/// `replay.ts` bilan bir xil): natija ilovadagi bilan bir xil chiqadi. Vaqt
/// rejimida mashq belgilangan vaqtda yakunlanadi; so'zlar va gaplar rejimida
/// esa oxirgi so'z terilmagan bo'lsa, `engine.finished` — `false`.
TypingReplay replayTypingLog(TypingConfig config, List<String> words, List<TypingLogEntry> log) {
  final engine = TypingEngine(config: config, fixedWords: words);
  final state = TypingInputState();
  final events = <TypingInputEvent>[];

  for (final entry in log) {
    // So'zlar tugagan bo'lsa (vaqt rejimida odam uchun imkonsiz tezlik) — log shu yerda to'xtaydi.
    if (engine.finished || engine.outOfWords) break;
    final before = engine.current.length;
    // Bo'sh holatda "o'chirish" — qo'shilgan belgi yo'q.
    final value = entry.v;
    final added = value == null ? 0 : (value.length - before).clamp(0, value.length);
    events.add(TypingInputEvent(t: entry.t, added: added, it: entry.it, keyed: entry.k != null));
    applyTypingValue(engine, state, value, Duration(microseconds: (entry.t * 1000).round()));
  }

  if (config.mode == TypingMode.time && engine.started) engine.tick(Duration(seconds: config.amount));
  return TypingReplay(engine, events);
}
