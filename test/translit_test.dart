import 'dart:convert';
import 'dart:io';

import 'package:dication/src/core/translit/translit.dart';
import 'package:flutter_test/flutter_test.dart';

/// Natijalar veb-saytdagi `core.ts` bilan bir xil bo'lishi kerak:
/// `fixtures/translit_cases.json` aynan o'sha kod bilan yasalgan.
void main() {
  final lexicon = parseLexicon(File('assets/translit/lexicon.txt').readAsStringSync());
  final path = Platform.environment['TRANSLIT_FIXTURE'] ?? 'test/fixtures/translit_cases.json';
  final cases = jsonDecode(File(path).readAsStringSync()) as List;

  test('veb-sayt bilan bir xil o‘giradi (${cases.length} holat)', () {
    for (final c in cases) {
      final from = Alphabet.values.byName(c['from']);
      final to = Alphabet.values.byName(c['to']);
      final out = transliterate(c['text'], from, to, lexicon, plainApostrophe: c['plain']);
      if (out != c['out']) {
        final a = out.split(' '), b = (c['out'] as String).split(' ');
        var i = 0;
        while (i < a.length && i < b.length && a[i] == b[i]) {
          i++;
        }
        fail('${c['from']}→${c['to']} plain=${c['plain']}: "${i < a.length ? a[i] : ''}" != "${i < b.length ? b[i] : ''}"');
      }
    }
  });
}
