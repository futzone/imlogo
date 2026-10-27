import 'package:dication/src/core/models/detected_error.dart';
import 'package:dication/src/core/models/error_type.dart';
import 'package:dication/src/core/models/text_model.dart';
import 'package:dication/src/core/models/typing_result.dart';
import 'package:dication/src/core/models/work.dart';
import 'package:dication/src/core/typing/typing_config.dart';
import 'package:dication/src/core/typing/typing_engine.dart';
import 'package:dication/src/ui/pages/dictation_result_page.dart';
import 'package:dication/src/ui/pages/main_page.dart';
import 'package:dication/src/ui/screens/additional_screens/about_app_screen.dart';
import 'package:dication/src/ui/screens/main_screens/app_header.dart';
import 'package:dication/src/ui/screens/main_screens/before_start_screen.dart';
import 'package:dication/src/ui/screens/main_screens/main_card.dart';
import 'package:dication/src/ui/screens/main_screens/result_card.dart';
import 'package:dication/src/ui/screens/typing/typing_result_view.dart';
import 'package:dication/src/ui/screens/typing/typing_config_bar.dart';
import 'package:dication/src/ui/screens/typing/typing_words_view.dart';
import 'package:dication/src/ui/shell/app_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Har qanday "RenderFlex overflowed" xatosi testni yiqitadi. Test shrifti
/// haqiqiysidan kengroq, shuning uchun bu yerdan o'tgan joylashuv ilovada ham sig'adi.
const widths = [280.0, 320.0, 360.0, 390.0, 480.0, 599.0, 600.0, 700.0, 759.0, 760.0, 900.0, 1199.0, 1200.0, 1600.0];

const words = [
  "g'alaba", 'yetti', 'boy', 'til', 'ham', "noto'g'ri", 'ishlamoq', 'bormoq',
  'qachon', 'oldin', 'rasm', "bo'ldi", 'suv', 'yashil', 'kasb', 'kelmoq',
  'mustaqillik', 'klaviatura', "o'qituvchi", 'a',
];

Future<void> pumpAt(WidgetTester tester, double width, Widget child) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(16), child: child))),
  ));
  await tester.pump();
}

void main() {
  testWidgets('so‘zlar maydoni hech bir kenglikda toshib chiqmaydi', (tester) async {
    for (final width in widths) {
      for (final fontSize in [20.0, 24.0, 28.0]) {
        var i = 0;
        final engine = TypingEngine(
          config: const TypingConfig(mode: TypingMode.words, amount: 60),
          nextWord: () => words[i++ % words.length],
        );
        Widget view() => TypingWordsView(engine: engine, fontSize: fontSize, focused: true);

        await pumpAt(tester, width, view());
        expect(tester.takeException(), isNull, reason: 'boshlang‘ich holat, $width / $fontSize');

        // Ortiqcha belgilar bilan (so'z kengayadi) va bir necha qator pastga tushib.
        for (var w = 0; w < 25; w++) {
          engine.setCurrent('${engine.target}xxxxxxxx');
          await pumpAt(tester, width, view());
          expect(tester.takeException(), isNull, reason: '$w-so‘z, $width / $fontSize');
          engine.commitWord();
        }
      }
    }
  });

  testWidgets('sozlamalar paneli hech bir kenglikda toshib chiqmaydi', (tester) async {
    for (final width in widths) {
      for (final config in const [TypingConfig(), TypingConfig(mode: TypingMode.words, amount: 100)]) {
        await pumpAt(tester, width, TypingConfigBar(config: config, onChanged: (_) {}));
        expect(tester.takeException(), isNull, reason: '$width');
      }
    }
  });

  testWidgets('pastki menyu va bo‘lim yorliqlari hech bir kenglikda toshib chiqmaydi', (tester) async {
    for (final width in widths.where((w) => w < MainPage.sidebarBreakpoint)) {
      await pumpAt(
        tester,
        width,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MobileNavBar(tab: AppTab.translator, onOpen: (_) {}),
            SectionTabs(index: 0, onChanged: (_) {}, expand: true),
          ],
        ),
      );
      expect(tester.takeException(), isNull, reason: '$width');
    }
  });

  final text = TextModel(
    id: '1',
    title: 'Insof, nomus va haqgo‘ylik fidoyisi haqida juda uzun sarlavha',
    text: 'Matn',
    time: 45,
    length: 178,
    ageName: '15 va undan kattalar',
    className: '9 va undan katta sinflar uchun',
    url: 'https://example.com/a.m4a',
    createdDate: DateTime(2026, 2, 25, 10, 27),
  );
  final work = Work(
    id: '1',
    createdDate: DateTime(2026).toIso8601String(),
    ball: 85.5,
    baho: 4,
    errors: [
      DetectedError(
        type: ErrorType.IMLO,
        description: 'So‘zni noto‘g‘ri yozish: juda uzun tushuntirish matni shu yerda',
        originalFragment: 'Toshkentliklarning',
        userFragment: 'Toshkenliklarning',
        specificRuleCode: 'imlo',
        penaltyMultiplier: 1,
      ),
    ],
    text: text,
    imloErrorCount: 12,
    punktuatsionErrorCount: 3,
    uslubiyErrorCount: 0,
    grafikErrorCount: 1,
    worktime: 1234,
    input: 'Matn',
  );
  final typingResult = TypingResult(
    id: '1',
    createdAt: DateTime(2026),
    config: const TypingConfig(mode: TypingMode.words, amount: 100, punctuation: true, numbers: true),
    wpm: 123,
    raw: 140,
    accuracy: 100,
    consistency: 88,
    correctChars: 1234,
    incorrectChars: 123,
    extraChars: 12,
    missedChars: 45,
    seconds: 120,
    samples: [
      for (var i = 1; i <= 30; i++)
        TypingSample(second: i, wpm: 100.0 + i, raw: 120.0 + i, errors: i % 4 == 0 ? 1 : 0),
    ],
  );

  testWidgets('kartalar, natija va oynalar hech bir kenglikda toshib chiqmaydi', (tester) async {
    final screens = <String, Widget Function()>{
      'MainCard': () => MainCard(text: text, issDone: true),
      'ResultCard': () => ResultCard(model: work),
      'TypingResultView': () => SingleChildScrollView(
            child: TypingResultView(
              result: typingResult,
              previousBest: 110,
              onRestart: () {},
              onOpenHistory: () {},
            ),
          ),
      'AboutAppScreen': () => const AboutAppScreen(),
      'BeforeStartScreen': () => BeforeStartScreen(model: text),
    };
    for (final width in widths) {
      for (final entry in screens.entries) {
        await pumpAt(tester, width, entry.value());
        expect(tester.takeException(), isNull, reason: '${entry.key} @ $width');
      }
    }
  });

  testWidgets('diktant natijasi sahifasi hech bir kenglikda toshib chiqmaydi', (tester) async {
    for (final width in widths) {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(home: DictationResultPage(work: work, useBack: true)));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: '$width');
    }
  });
}
