import 'package:dication/src/core/typing/typing_text.dart';

/// Yangi alifbo harfi → oddiy klaviaturadagi ikki belgilik yozilishi.
const Map<String, (String, String)> _digraphs = {
  'ş': ('s', 'h'),
  'ç': ('c', 'h'),
  'ö': ('o', "'"),
  'ğ': ('g', "'"),
};

String _withCaseOf(String source, String letter) =>
    source != source.toLowerCase() ? letter.toUpperCase() : letter;

class Composition {
  final String value;

  /// Birinchi belgisi terilib, ikkinchisi kutilayotgan harf o'rni.
  final int? pending;

  const Composition(this.value, this.pending);
}

/// Yangi alifbo mashqi: Ş, Ç, Ö, Ğ harflari oddiy klaviaturada yo'q, shuning
/// uchun ular "sh", "ch", "o'", "g'" deb ham terilishi mumkin. Kutilgan harf
/// shulardan biri bo'lsa, birinchi belgi darhol shu harf sifatida ko'rsatiladi,
/// ikkinchisi esa "yutiladi". Ikkinchi belgi boshqa bo'lsa, harf oddiy s/c/o/g
/// ga qaytadi (xato). Ş va boshqalarni to'g'ridan-to'g'ri terish ham ishlaydi.
///
/// Veb-saytdagi `compose.ts` bilan bir xil. [previous] — dvigateldagi joriy
/// qiymat, [typed] — maydondagi yangi qiymat, [finalize] — so'z bo'sh joy
/// bilan yakunlanmoqda.
Composition composeYangi(
  String previous,
  String typed,
  String target,
  int? pending, {
  bool finalize = false,
}) {
  // O'chirish yoki tahrir — hech narsa o'zgartirilmaydi.
  if (!typed.startsWith(previous)) return Composition(typed, null);

  var value = previous;
  var waiting = pending;
  void revert() {
    final at = waiting;
    if (at == null) return;
    final special = value[at].toLowerCase();
    value = value.substring(0, at) + _withCaseOf(value[at], _digraphs[special]!.$1) + value.substring(at + 1);
    waiting = null;
  }

  for (final char in typed.substring(previous.length).split('')) {
    if (waiting != null && waiting == value.length - 1) {
      final second = _digraphs[value[waiting!].toLowerCase()]!.$2;
      if (normalizeTypingChar(char.toLowerCase()) == second) {
        waiting = null;
        continue;
      }
      revert();
    }
    final expected = value.length < target.length ? target[value.length].toLowerCase() : null;
    final digraph = expected == null ? null : _digraphs[expected];
    if (digraph != null && char.toLowerCase() == digraph.$1) {
      value += _withCaseOf(char, expected!);
      waiting = value.length - 1;
    } else {
      value += char;
    }
  }

  if (finalize) revert();
  return Composition(value, waiting);
}
