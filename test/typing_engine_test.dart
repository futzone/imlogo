import 'dart:math';

import 'package:dication/src/core/typing/typing_config.dart';
import 'package:dication/src/core/typing/typing_engine.dart';
import 'package:dication/src/core/typing/typing_guard.dart';
import 'package:dication/src/core/typing/typing_text.dart';
import 'package:dication/src/core/typing/typing_words.dart';
import 'package:flutter_test/flutter_test.dart';

TypingEngine engineFor(List<String> words, {TypingMode mode = TypingMode.words, int? amount}) {
  var i = 0;
  return TypingEngine(
    config: TypingConfig(mode: mode, amount: amount ?? words.length),
    nextWord: () => words[i++ % words.length],
  );
}

/// So'zni harfma-harf teradi (haqiqiy kiritish kabi).
void type(TypingEngine engine, String text) {
  for (var i = 1; i <= text.length; i++) {
    engine.setCurrent(text.substring(0, i));
  }
}

void main() {
  group('tutuq belgisi (yumshoq tekshiruv)', () {
    test('barcha apostrof variantlari bir xil qabul qilinadi', () {
      for (final variant in ["o'zbek", 'o‘zbek', 'o’zbek', 'oʻzbek', 'oʼzbek', 'o`zbek', 'o´zbek']) {
        expect(isTypedWordCorrect(variant, "o'zbek"), isTrue, reason: variant);
      }
      expect(isTypedWordCorrect('ozbek', "o'zbek"), isFalse);
      expect(isTypedWordCorrect('o"zbek', "o'zbek"), isFalse);
    });

    test('ko‘rsatishda o‘/g‘ va tutuq belgisi ajratiladi', () {
      expect(prettifyTypingWord("to'g'ri"), 'to‘g‘ri');
      expect(prettifyTypingWord("ma'no"), 'ma’no');
      expect(prettifyTypingWord("she'r").length, "she'r".length);
    });

    test('so‘zlar ro‘yxati o‘qilganda apostroflar bir xillashtiriladi', () {
      final words = parseWordList("# izoh\nOʻzbek\n\no‘zbek\n  bogʻ \nikki so'z\n");
      expect(words, ["o'zbek", "bog'"]);
    });
  });

  group('TypingEngine', () {
    test('xatosiz mashq: 100% aniqlik va to‘g‘ri WPM', () {
      final engine = engineFor(['salom', "o'zbek", 'til']);
      type(engine, 'salom');
      engine.commitWord();
      type(engine, 'oʻzbek');
      engine.commitWord();
      type(engine, 'til');

      expect(engine.finished, isTrue, reason: 'oxirgi so‘z terilishi bilan yakunlanadi');
      final stats = engine.stats(const Duration(seconds: 12));
      expect(stats.accuracy, 100);
      expect(stats.incorrectChars, 0);
      // 5 + 1 + 6 + 1 + 3 = 16 belgi, 12 soniyada: 16 / 5 / 0.2 = 16 WPM
      expect(stats.wpm, closeTo(16, 0.001));
      expect(stats.raw, closeTo(16, 0.001));
    });

    test('xato so‘z WPM ga qo‘shilmaydi, aniqlik pasayadi', () {
      final engine = engineFor(['kitob', 'maktab']);
      type(engine, 'kitab');
      engine.commitWord();
      type(engine, 'maktab');

      final stats = engine.stats(const Duration(seconds: 6));
      expect(stats.incorrectChars, 1);
      expect(stats.correctChars, 4 + 6);
      expect(stats.accuracy, lessThan(100));
      // faqat "maktab" (6 belgi): 6 / 5 / 0.1 = 12
      expect(stats.wpm, closeTo(12, 0.001));
    });

    test('ortiqcha va tushib qolgan belgilar hisoblanadi', () {
      final engine = engineFor(['bir', 'ikki', 'uch']);
      type(engine, 'birrr');
      engine.commitWord();
      type(engine, 'ik');
      engine.commitWord();

      final stats = engine.stats(const Duration(seconds: 5));
      expect(stats.extraChars, 2);
      expect(stats.missedChars, 2);
    });

    test('bo‘sh holatda bo‘sh joy e’tiborga olinmaydi', () {
      final engine = engineFor(['bir', 'ikki']);
      engine.commitWord();
      expect(engine.index, 0);
      expect(engine.started, isFalse);
    });

    test('faqat xato terilgan oldingi so‘zga qaytish mumkin', () {
      final engine = engineFor(['bir', 'ikki', 'uch']);
      type(engine, 'bir');
      engine.commitWord();
      expect(engine.backToPreviousWord(), isFalse);

      type(engine, 'ikk');
      engine.commitWord();
      expect(engine.backToPreviousWord(), isTrue);
      expect(engine.index, 1);
      expect(engine.current, 'ikk');
    });

    test('vaqt rejimi: vaqt tugaganda yakunlanadi va so‘zlar tugamaydi', () {
      final engine = engineFor(['a', 'b'], mode: TypingMode.time, amount: 15);
      for (var s = 1; s <= 15; s++) {
        type(engine, engine.target);
        engine.commitWord();
        engine.tick(Duration(seconds: s));
      }
      expect(engine.finished, isTrue);
      expect(engine.finishedAt, const Duration(seconds: 15));
      expect(engine.samples.length, 15);
      expect(engine.words.length, greaterThan(engine.typed.length));
    });

    test('ortiqcha belgilar soni cheklangan', () {
      final engine = engineFor(['ha', 'yo']);
      engine.setCurrent('ha${'x' * 30}');
      expect(engine.current.length, 2 + TypingEngine.maxExtraChars);
    });
  });

  group('TypingWordGenerator', () {
    test('bir xil so‘z ketma-ket chiqmaydi', () {
      final generator = TypingWordGenerator(
        pool: ['bir', 'ikki', 'uch'],
        config: const TypingConfig(),
        random: Random(1),
      );
      var previous = generator.next();
      for (var i = 0; i < 200; i++) {
        final word = generator.next();
        expect(word, isNot(previous));
        previous = word;
      }
    });

    test('tinish belgilari rejimida gap bosh harf bilan boshlanadi', () {
      final generator = TypingWordGenerator(
        pool: ['bir', 'ikki', 'uch'],
        config: const TypingConfig(punctuation: true),
        random: Random(2),
      );
      final words = List.generate(300, (_) => generator.next());
      expect(words.first[0], words.first[0].toUpperCase());
      for (var i = 0; i < words.length - 1; i++) {
        if (RegExp(r'[.?!]$').hasMatch(words[i])) {
          expect(words[i + 1][0], words[i + 1][0].toUpperCase());
        }
      }
      expect(words.any((w) => w.endsWith(',')), isTrue);
    });

    test('taymer kechiksa ham bosishlar kesimlardan yo‘qolmaydi', () {
      final engine = engineFor(['salom', 'dunyo']);
      // Taymer umuman ishlamadi: kesimlar faqat bosishlarda yoziladi.
      for (var i = 1; i <= 5; i++) {
        engine.setCurrent('salom'.substring(0, i), elapsed: Duration(milliseconds: i * 400));
      }
      engine.commitWord(elapsed: const Duration(milliseconds: 2400));
      for (var i = 1; i <= 5; i++) {
        engine.setCurrent('dunyo'.substring(0, i), elapsed: Duration(milliseconds: 2400 + i * 400));
      }
      expect(engine.finished, isTrue);
      final sampled = engine.samples.fold<double>(0, (sum, s) => sum + s.raw / 12);
      // 11 bosishdan faqat oxirgi to'liq bo'lmagan soniyadagilar kesimga tushmaydi.
      expect(sampled, greaterThanOrEqualTo(9));
      expect(engine.samples.length, 4);
    });

    test('vaqt rejimi: vaqt tugagach kechikkan bosishlar hisoblanmaydi', () {
      final engine = engineFor(['salom'], mode: TypingMode.time, amount: 15);
      type(engine, 'sa');
      engine.setCurrent('sal', elapsed: const Duration(seconds: 16));
      expect(engine.finished, isTrue);
      expect(engine.finishedAt, const Duration(seconds: 15));
      expect(engine.current, 'sa');
    });
  });

  group('gaplar rejimi', () {
    const config = TypingConfig(mode: TypingMode.sentences, amount: 2, punctuation: true, numbers: true);

    test('tayyor so‘zlar terilgach mashq yakunlanadi', () {
      final engine = TypingEngine(config: config.effective, fixedWords: ['Salom', 'dunyo.', 'Yaxshi.']);
      expect(engine.words, ['Salom', 'dunyo.', 'Yaxshi.']);
      type(engine, 'Salom');
      engine.commitWord();
      type(engine, 'dunyo.');
      engine.commitWord();
      expect(engine.finished, isFalse);
      type(engine, 'Yaxshi.');
      expect(engine.finished, isTrue);
      expect(engine.words.length, 3, reason: 'so‘zlar qo‘shilmaydi');
    });

    test('qo‘shimchalar hisobga olinmaydi, sozlama esa saqlanadi', () {
      expect(config.hasExtras, isFalse);
      expect(config.effective.punctuation, isFalse);
      expect(config.effective.numbers, isFalse);
      expect(config.withMode(TypingMode.time).punctuation, isTrue);
      expect(config.withMode(TypingMode.words).withMode(TypingMode.sentences).amount, 5);
      expect(config.label, '2 gap');
      expect(TypingConfig.fromJson(config.toJson()).mode, TypingMode.sentences);
    });

    test('gaplar ro‘yxati o‘qiladi va so‘zlarga ajratiladi', () {
      final pool = parseSentenceList("# izoh\nBu bogʻ.\n\nMen keldim!\n");
      expect(pool, ["Bu bog'.", 'Men keldim!']);
      final words = createSentenceWords(pool, 3, random: Random(3));
      expect(words.where((w) => RegExp(r'[.!]$').hasMatch(w)).length, 3);
    });
  });

  group('avtomatik yozishni aniqlash (analyzeTyping)', () {
    final random = Random(4);
    List<TypingInputEvent> keyed(List<double> times, {int added = 1, String it = 'insertText', bool keys = true}) =>
        [for (final t in times) TypingInputEvent(t: t, added: added, it: it, keyed: keys)];

    test('bir maromdagi yozish aniqlanadi', () {
      expect(analyzeTyping(keyed([for (var i = 0; i < 40; i++) i * 100.0]), 60), contains('uniform_rhythm'));
      expect(
        analyzeTyping(keyed([for (var i = 0; i < 40; i++) i * 150.0 + random.nextInt(5)]), 60),
        contains('uniform_rhythm'),
      );
    });

    test('odam yozishi va qisqa mashq to‘xtatilmaydi', () {
      var t = 0.0;
      final human = [for (var i = 0; i < 60; i++) t += 80 + random.nextInt(300)];
      expect(analyzeTyping(keyed(human), 60), isEmpty);
      expect(analyzeTyping(keyed([for (var i = 0; i < 10; i++) i * 100.0]), 60), isEmpty);
    });

    test('bir zumda kiritish, ko‘p belgili insertText va klavishsiz yozish', () {
      expect(analyzeTyping(keyed([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]), 60), contains('burst'));
      expect(analyzeTyping([TypingInputEvent(t: 0, added: 6, it: 'insertText', keyed: true)], 60),
          contains('multi_insert'));
      expect(analyzeTyping([TypingInputEvent(t: 0, added: 3, it: 'insertCompositionText', keyed: true)], 60),
          isNot(contains('multi_insert')));
      var t = 0.0;
      final times = [for (var i = 0; i < 30; i++) t += 80 + random.nextInt(300)];
      expect(analyzeTyping(keyed(times, keys: false), 60), contains('no_keydown'));
      expect(analyzeTyping(keyed(times), 300), contains('wpm'));
    });
  });
}
