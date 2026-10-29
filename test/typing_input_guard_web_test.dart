@TestOn('browser')
library;

import 'package:dication/src/core/typing/typing_input_guard.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;

void main() {
  testWidgets('brauzerda JS yuborgan hodisa qabul qilinmaydi', (tester) async {
    final guard = TypingInputGuard(strict: true);
    addTearDown(guard.dispose);

    // Flutter'ning o'z klavish hodisalari (DOM'dan tashqari) to'siq bo'lmaydi.
    await simulateKeyDownEvent(LogicalKeyboardKey.keyA);
    expect(guard.accept(1, composing: false), isTrue);
    expect(guard.takeKey(), 'a');
    await simulateKeyUpEvent(LogicalKeyboardKey.keyA);

    // Script: maydonga qiymat yozib, hodisalarni qo'lda yuboradi.
    web.document.body!.dispatchEvent(web.KeyboardEvent('keydown', web.KeyboardEventInit(key: 'b', bubbles: true)));
    web.document.body!.dispatchEvent(web.Event('input', web.EventInit(bubbles: true)));
    await simulateKeyDownEvent(LogicalKeyboardKey.keyB);
    expect(guard.accept(1, composing: false), isFalse);
    expect(guard.takeKey(), isNull, reason: 'rad etilgan o‘zgarish klavishi logga tushmaydi');
    await simulateKeyUpEvent(LogicalKeyboardKey.keyB);

    // Keyingi haqiqiy bosish yana qabul qilinadi.
    await simulateKeyDownEvent(LogicalKeyboardKey.keyC);
    expect(guard.accept(1, composing: false), isTrue);
    await simulateKeyUpEvent(LogicalKeyboardKey.keyC);
    // Flutter web soxta keydown uchun keyup kutish taymerini qo'yadi.
    await tester.pump(const Duration(seconds: 3));
  });
}
