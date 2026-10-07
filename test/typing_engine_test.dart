import 'dart:math';

import 'package:dication/src/core/typing/typing_config.dart';
import 'package:dication/src/core/typing/typing_engine.dart';
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
  });
}
