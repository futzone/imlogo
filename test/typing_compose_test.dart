import 'package:dication/src/core/typing/typing_compose.dart';
import 'package:flutter_test/flutter_test.dart';

/// Belgilarni birma-bir terib, so'zning yakuniy ko'rinishini qaytaradi.
String typeWord(String keys, String target, {bool finalize = false}) {
  var value = '';
  int? pending;
  for (final key in keys.split('')) {
    final composed = composeYangi(value, value + key, target, pending);
    value = composed.value;
    pending = composed.pending;
  }
  if (finalize) value = composeYangi(value, value, target, pending, finalize: true).value;
  return value;
}

void main() {
  test('sh, ch, o‘, g‘ yangi harfga aylanadi', () {
    expect(typeWord('shahar', 'şahar'), 'şahar');
    expect(typeWord('choy', 'çoy'), 'çoy');
    expect(typeWord("o'zbek", 'özbek'), 'özbek');
    expect(typeWord('g‘alaba', 'ğalaba'), 'ğalaba');
    expect(typeWord('Shahar', 'Şahar'), 'Şahar');
  });

  test('to‘g‘ridan-to‘g‘ri terilgan harf ham qabul qilinadi', () {
    expect(typeWord('şahar', 'şahar'), 'şahar');
  });

  test('ikkinchi belgi mos kelmasa, oddiy harfga qaytadi', () {
    expect(typeWord('sahar', 'şahar'), 'sahar');
    expect(typeWord('s', 'şahar', finalize: true), 's');
  });

  test('kutilmagan joyda "sh" o‘zgarmaydi', () {
    expect(typeWord('ishoq', 'ishoq'), 'ishoq');
  });
}
