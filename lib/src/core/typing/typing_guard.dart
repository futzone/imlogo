/// Tez yozish natijasini avtomatik yozish (script), nusxalab qo'yish va
/// soxtalashtirishdan himoyalash evristikalari — saytdagi
/// `src/lib/app/typing/guard.ts` (analyzeTyping) bilan bir xil. Ilova natijani
/// darhol belgilaydi, server esa bosishlar logini qayta o'ynab, qaror qabul qiladi.
///
/// Odam klavishlarni hech qachon bir maromda bosmaydi va bir zumda ko'p belgi
/// kirita olmaydi; script esa aynan shunday qiladi.
library;

import 'dart:math';

/// Kiritish maydonidagi bitta o'zgarish (ilova yozadi, server qayta o'ynaydi).
class TypingLogEntry {
  /// Mashq boshidan beri o'tgan vaqt, ms (0.1 gacha yaxlitlangan).
  final double t;

  /// Maydondagi matn yoki `null` — bo'sh holatda "o'chirish" bosildi (qarang: applyTypingValue).
  final String? v;

  /// Kiritish turi (brauzerdagi `InputEvent.inputType` nomlari bilan).
  final String it;

  /// Shu o'zgarishdan oldin bosilgan klavish; bosilmagan bo'lsa — `null`.
  final String? k;

  const TypingLogEntry({required this.t, required this.v, required this.it, required this.k});

  Map<String, dynamic> toJson() => {'t': t, 'v': v, 'it': it, 'k': k};
}

/// Qayta o'ynash natijasida har bir o'zgarish: nechta belgi qo'shildi.
class TypingInputEvent {
  final double t;
  final int added;
  final String it;
  final bool keyed;

  const TypingInputEvent({required this.t, required this.added, required this.it, required this.keyed});
}

class TypingGuardConfig {
  /// Shu oynada (ms) [burstMaxChars] dan ko'p belgi bo'lsa — bir zumda kiritilgan.
  final double burstWindowMs;
  final int burstMaxChars;

  /// Bir soniyalik oynada shundan ko'p belgi — odam uchun imkonsiz tezlik.
  final int secondMaxChars;

  /// Belgilar orasidagi o'rtacha vaqt (ms) bundan kam bo'lmasligi kerak.
  final double minMeanIntervalMs;

  /// Oraliqlar o'zgaruvchanligi (CV) bundan past bo'lsa — bir xil maromda, odam emas.
  final double minIntervalVariation;

  /// Xulosa uchun kamida shuncha oraliq kerak.
  final int minIntervals;

  /// Shundan uzun to'xtash (o'ylash, chalg'ish) maromga qo'shilmaydi.
  final double maxIntervalMs;
  final double maxWpm;

  /// Bir hodisada bir nechta belgi kiritgan `insertText` lar soni shundan oshmasin.
  final int maxMultiInserts;

  /// Klavish bosilmasdan kiritilgan o'zgarishlar ulushi.
  final double maxUnkeyedRatio;

  const TypingGuardConfig({
    this.burstWindowMs = 100,
    this.burstMaxChars = 8,
    this.secondMaxChars = 25,
    this.minMeanIntervalMs = 25,
    this.minIntervalVariation = 0.1,
    this.minIntervals = 20,
    this.maxIntervalMs = 2000,
    this.maxWpm = 250,
    this.maxMultiInserts = 0,
    this.maxUnkeyedRatio = 0.1,
  });
}

/// Server qaytaradigan bayroqlar (nomlari saytdagi `TypingFlag` bilan bir xil).
const Map<String, String> typingFlagMessages = {
  'burst': 'bir zumda köp belgi kiritilgan',
  'second_burst': 'odam uçun imkonsiz tezlik',
  'fast_intervals': 'belgilar orasidagi vaqt juda qisqa',
  'uniform_rhythm': 'avtomatik yozişga öxşaydi',
  'wpm': 'tezlik 250 WPM dan yuqori',
  'multi_insert': 'matn bir yöla kiritilgan',
  'no_keydown': 'matn klavişsiz kiritilgan',
  'server_time': 'vaqt server vaqtiga mos emas',
  'unverified': 'natija serverda tekşirilmadi',
};

/// Natija ostidagi izoh: nega reytingga yoki rekordga kirmadi.
String typingFlagNotice(List<String> flags, {required bool signedIn}) {
  final reasons = flags.map((flag) => typingFlagMessages[flag] ?? flag).join(', ');
  return '${signedIn ? 'Natija reytingga kiritilmadi' : 'Natija rekordga kiritilmadi'}: $reasons';
}

/// Har bir qo'shilgan belgining payti (bir hodisada bir nechta belgi — bir xil payt).
List<double> _charTimes(List<TypingInputEvent> events) => [
      for (final event in events)
        for (var i = 0; i < event.added; i++) event.t,
    ];

/// [times] ichida [windowMs] dan qisqa oraliqqa [count] ta belgi sig'adimi.
bool _hasDenseWindow(List<double> times, int count, double windowMs) {
  for (var i = 0; i + count - 1 < times.length; i++) {
    if (times[i + count - 1] - times[i] < windowMs) return true;
  }
  return false;
}

/// Natijani shubhali qiladigan belgilar (bo'sh ro'yxat — hammasi joyida).
List<String> analyzeTyping(
  List<TypingInputEvent> events,
  double wpm, {
  TypingGuardConfig config = const TypingGuardConfig(),
}) {
  final flags = <String>[];
  final times = _charTimes(events);

  if (_hasDenseWindow(times, config.burstMaxChars + 1, config.burstWindowMs)) flags.add('burst');
  if (_hasDenseWindow(times, config.secondMaxChars + 1, 1000)) flags.add('second_burst');

  final intervals = <double>[];
  for (var i = 1; i < times.length; i++) {
    final interval = times[i] - times[i - 1];
    if (interval <= config.maxIntervalMs) intervals.add(interval);
  }
  if (intervals.length >= config.minIntervals) {
    final mean = intervals.reduce((a, b) => a + b) / intervals.length;
    if (mean < config.minMeanIntervalMs) flags.add('fast_intervals');
    final variance = intervals.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / intervals.length;
    if (mean <= 0 || sqrt(variance) / mean < config.minIntervalVariation) flags.add('uniform_rhythm');
  }

  if (wpm > config.maxWpm) flags.add('wpm');

  final inserts = events.where((event) => event.added > 0).toList();
  final multi = inserts.where((event) => event.it == 'insertText' && event.added > 1).length;
  if (multi > config.maxMultiInserts) flags.add('multi_insert');
  final unkeyed = inserts.where((event) => !event.keyed).length;
  if (unkeyed > 0 && unkeyed / max(1, inserts.length) > config.maxUnkeyedRatio) flags.add('no_keydown');

  return flags;
}
