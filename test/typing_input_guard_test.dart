import 'package:dication/src/core/typing/typing_input_guard.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('kompyuter (klavish talab qilinadi)', () {
    testWidgets('klavish bosilib terilgan bitta belgi qabul qilinadi', (tester) async {
      final guard = TypingInputGuard(strict: true);
      addTearDown(guard.dispose);

      await simulateKeyDownEvent(LogicalKeyboardKey.keyA);
      expect(guard.accept(1, composing: false), isTrue);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyA);
    });

    testWidgets('klavishsiz qo‘yilgan matn qabul qilinmaydi', (tester) async {
      final guard = TypingInputGuard(strict: true);
      addTearDown(guard.dispose);

      expect(guard.accept(1, composing: false), isFalse, reason: 'script yozgan belgi');
      await simulateKeyDownEvent(LogicalKeyboardKey.keyV);
      expect(guard.accept(12, composing: false), isFalse, reason: 'bir hodisada ko‘p belgi (paste)');
      await simulateKeyUpEvent(LogicalKeyboardKey.keyV);
      // Bitta bosish faqat bitta kiritishga yetadi (qabul qilingach, klavish logga olinadi).
      await simulateKeyDownEvent(LogicalKeyboardKey.keyB);
      expect(guard.accept(1, composing: false), isTrue);
      expect(guard.takeKey(), 'b');
      expect(guard.accept(1, composing: false), isFalse);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyB);
    });

    testWidgets('o‘chirish va IME bilan yozish to‘xtatilmaydi', (tester) async {
      final guard = TypingInputGuard(strict: true);
      addTearDown(guard.dispose);

      expect(guard.accept(-1, composing: false), isTrue);
      expect(guard.accept(2, composing: true), isTrue);
    });
  });

  testWidgets('telefonda ekran klaviaturasi klavish hodisasisiz yozadi', (tester) async {
    final guard = TypingInputGuard(strict: false);
    addTearDown(guard.dispose);

    expect(guard.accept(1, composing: false), isTrue);
    expect(guard.takeKey(), TypingInputGuard.softKeyboard, reason: 'aks holda server no_keydown deb belgilaydi');
  });

  testWidgets('logga oxirgi bosilgan klavish yoziladi va bir marta ishlatiladi', (tester) async {
    final guard = TypingInputGuard(strict: true);
    addTearDown(guard.dispose);

    await simulateKeyDownEvent(LogicalKeyboardKey.keyA);
    expect(guard.accept(1, composing: false), isTrue);
    expect(guard.takeKey(), 'a');
    expect(guard.takeKey(), isNull, reason: 'kompyuterda klavishsiz o‘zgarish — null');
    await simulateKeyUpEvent(LogicalKeyboardKey.keyA);
  });
}
