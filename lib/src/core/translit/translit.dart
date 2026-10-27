/// O'zbek yozuvlari orasida transliteratsiya: kirill, amaldagi lotin (1995)
/// va yangi lotin alifbosi (ş, ç, ö, ğ).
///
/// Veb-saytdagi `src/lib/translit/core.ts` ning aynan nusxasi — qoidalar
/// ikkala joyda birga o'zgartirilishi kerak.
///
/// Ichki ko'rinishda lotin so'z kichik harflarda, "`" — oʻ/gʻ belgisi,
/// "'" — tutuq belgisi (ʼ) bilan yoziladi. Foydalanuvchi matnida bu ikkisi
/// farqlanmaydi, shuning uchun lug'at kalitlarida ikkalasi ham "'" bo'ladi.
library;

enum Alphabet { lotin, yangi, kirill }

/// Lug'at: kalit (lotincha yozilish) → kirillcha so'z.
typedef Lexicon = Map<String, String>;

/// Foydalanuvchi oʻ/gʻ yoki tutuq uchun yozishi mumkin bo'lgan belgilar.
const String apostrophes = "'`‘’ʻʼ´ʹ′";
final RegExp _apostropheRe = RegExp('[$apostrophes]');
const String _modifier = 'ʻ'; // U+02BB — oʻ, gʻ
const String _tutuq = 'ʼ'; // U+02BC — tutuq belgisi

/// Prefiks bo'yicha qidirilganda lug'at kalitining eng kichik uzunligi.
const int _minPrefix = 5;

const String _cyrVowels = 'аеёиоуэюяў';

const Map<String, String> _cyrCommon = {
  'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'ё': 'yo', 'ж': 'j', 'з': 'z', 'и': 'i', 'й': 'y',
  'к': 'k', 'л': 'l', 'м': 'm', 'н': 'n', 'о': 'o', 'п': 'p', 'р': 'r', 'с': 's', 'т': 't', 'у': 'u',
  'ф': 'f', 'х': 'x', 'э': 'e', 'ю': 'yu', 'я': 'ya', 'қ': 'q', 'ҳ': 'h', 'ъ': "'", 'ы': 'i',
};
const Map<String, String> _cyrLotin = {'ш': 'sh', 'ч': 'ch', 'щ': 'shch', 'ў': 'o`', 'ғ': 'g`'};
const Map<String, String> _cyrYangi = {'ш': 'ş', 'ч': 'ç', 'щ': 'şç', 'ў': 'ö', 'ғ': 'ğ'};

/// Rasmiy yozilishi qoidadan farq qiladigan so'z boshlari.
const List<(String, String)> _cyrOverrides = [
  ('сентябр', 'sentabr'),
  ('октябр', 'oktabr'),
];

/// Kirillcha so'zni (kichik harflarda) ichki lotin ko'rinishiga o'giradi.
String cyrWordToLatin(String word, Alphabet target) {
  final special = target == Alphabet.yangi ? _cyrYangi : _cyrLotin;
  final out = StringBuffer();
  var start = 0;
  for (final (prefix, latin) in _cyrOverrides) {
    if (word.startsWith(prefix)) {
      out.write(latin);
      start = prefix.length;
      break;
    }
  }
  for (var i = start; i < word.length; i++) {
    final c = word[i];
    final prev = i > 0 ? word[i - 1] : '';
    if (c == 'е') {
      // So'z boshida, unli, ъ yoki ь dan keyin — "ye".
      out.write(prev.isEmpty || _cyrVowels.contains(prev) || prev == 'ъ' || prev == 'ь' ? 'ye' : 'e');
    } else if (c == 'ц') {
      out.write(prev.isNotEmpty && _cyrVowels.contains(prev) ? 'ts' : 's');
    } else if (c == 'ь') {
      // батальон → batalyon; boshqa hollarda yozilmaydi.
      if (i + 1 < word.length && word[i + 1] == 'о') out.write('y');
    } else if (c == 'ҳ' && prev == 'с') {
      // Исҳоқ: eski lotinda "sh" (ш) bilan adashmasligi uchun tutuq qo'yiladi,
      // yangi alifboda ş alohida harf — ajratish shart emas.
      out.write(target == Alphabet.yangi ? 'h' : "'h");
    } else {
      out.write(special[c] ?? _cyrCommon[c] ?? c);
    }
  }
  return out.toString();
}

/// Lug'at kaliti: barcha tutuq/oʻ belgilari bir xil "'" bo'ladi.
String toKey(String latin) => latin.replaceAll(_apostropheRe, "'");

const Map<String, String> _latinCyr = {
  'a': 'а', 'b': 'б', 'c': 'ц', 'd': 'д', 'f': 'ф', 'g': 'г', 'h': 'ҳ', 'i': 'и', 'j': 'ж', 'k': 'к',
  'l': 'л', 'm': 'м', 'n': 'н', 'o': 'о', 'p': 'п', 'q': 'қ', 'r': 'р', 's': 'с', 't': 'т', 'u': 'у',
  'v': 'в', 'w': 'в', 'x': 'х', 'y': 'й', 'z': 'з',
};
const Map<String, String> _latinDigraphs = {'sh': 'ш', 'ch': 'ч', 'yo': 'ё', 'yu': 'ю', 'ya': 'я', 'ye': 'е'};

String _at(String s, int i) => i >= 0 && i < s.length ? s[i] : '';

String _slice(String s, int start, [int? end]) {
  final from = start.clamp(0, s.length);
  final to = (end ?? s.length).clamp(from, s.length);
  return s.substring(from, to);
}

/// Lug'at prefiksi shu nuqtada kesilsa, harf birikmasi bo'linib qoladimi.
bool _splitsDigraph(String key, int at) =>
    _at(key, at) == "'" || _at(key, at) == '`' || _latinDigraphs.containsKey(_slice(key, at - 1, at + 1));

/// Lotincha so'zni qoidalar bo'yicha kirillga o'giradi.
/// [strictTutuq] bo'lsa, "o'"/"g'" dagi "'" tutuq hisoblanadi (yangi alifbodan
/// kelgan matn: u yerda oʻ/gʻ "`" bilan belgilangan); aks holda — oʻ/gʻ.
String naiveLatinToCyr(String latin, [String prevCyr = '', bool strictTutuq = false]) {
  final out = StringBuffer();
  var prev = prevCyr;
  void push(String s) {
    out.write(s);
    prev = s[s.length - 1];
  }

  for (var i = 0; i < latin.length;) {
    final c = latin[i];
    final next = _at(latin, i + 1);
    final mark = next == '`' || (next == "'" && !strictTutuq);
    final third = _at(latin, i + 2);
    if (c == 'y' && next == 'o' && (third == '`' || (third == "'" && !strictTutuq))) {
      push('йў'); // yoʻq, yoʻl
      i += 3;
    } else if ((c == 'o' || c == 'g') && mark) {
      push(c == 'o' ? 'ў' : 'ғ');
      i += 2;
    } else if (c == 's' && (next == "'" || next == '`') && third == 'h') {
      push('сҳ');
      i += 3;
    } else if (_latinDigraphs.containsKey(_slice(latin, i, i + 2))) {
      push(_latinDigraphs[_slice(latin, i, i + 2)]!);
      i += 2;
    } else if (c == 'e') {
      push(prev.isEmpty || _cyrVowels.contains(prev) ? 'э' : 'е');
      i += 1;
    } else if (c == "'" || c == '`') {
      push('ъ');
      i += 1;
    } else {
      push(_latinCyr[c] ?? c);
      i += 1;
    }
  }
  return out.toString();
}

class _LexiconHit {
  final String cyr;

  /// Kalitning lug'atga mos kelgan qismi uzunligi.
  final int length;

  const _LexiconHit(this.cyr, this.length);
}

/// Avval to'liq so'z, keyin eng uzun so'z boshi (o'zak + qo'shimchalar uchun).
_LexiconHit? _lookupLexicon(Lexicon lexicon, String key, [bool Function(_LexiconHit hit)? accept]) {
  final exact = lexicon[key];
  if (exact != null) {
    final hit = _LexiconHit(exact, key.length);
    if (accept == null || accept(hit)) return hit;
  }
  for (var n = key.length - 1; n >= _minPrefix; n--) {
    if (_splitsDigraph(key, n)) continue;
    final cyr = lexicon[key.substring(0, n)];
    if (cyr != null) {
      final hit = _LexiconHit(cyr, n);
      if (accept == null || accept(hit)) return hit;
    }
  }
  return null;
}

/// Amaldagi lotin (ichki ko'rinish) → kirill.
String lotinWordToCyr(String latin, Lexicon lexicon, [bool strictTutuq = false, String? source]) {
  final key = toKey(latin);
  // Yangi alifbodan kelgan so'zda lug'at topgan variant asl yozuvga mos bo'lishi shart.
  final accept =
      source == null ? null : (_LexiconHit hit) => source.startsWith(cyrWordToLatin(hit.cyr, Alphabet.yangi));
  final hit = _lookupLexicon(lexicon, key, accept);
  if (hit == null) return naiveLatinToCyr(latin, '', strictTutuq);
  return hit.cyr + naiveLatinToCyr(latin.substring(hit.length), hit.cyr[hit.cyr.length - 1], strictTutuq);
}

/// Amaldagi lotin → yangi alifbo, faqat qoidalar bo'yicha.
String _naiveLotinToYangi(String latin) {
  final out = StringBuffer();
  for (var i = 0; i < latin.length;) {
    final c = latin[i];
    final next = _at(latin, i + 1);
    if (c == 's' && (next == "'" || next == '`') && _at(latin, i + 2) == 'h') {
      out.write('sh'); // Is'hoq → Ishoq
      i += 3;
    } else if (c == 's' && next == 'h') {
      out.write('ş');
      i += 2;
    } else if (c == 'c' && next == 'h') {
      out.write('ç');
      i += 2;
    } else if ((c == 'o' || c == 'g') && (next == "'" || next == '`')) {
      out.write(c == 'o' ? 'ö' : 'ğ');
      i += 2;
    } else {
      out.write(c == '`' ? "'" : c);
      i += 1;
    }
  }
  return out.toString();
}

/// Lug'atda "sh" alohida s+h, "o'"/"g'" esa tutuq bo'lgan so'zlarni ajratadi.
final RegExp _ambiguousCyr = RegExp('сҳ|[ог]ъ');

/// Amaldagi lotin → yangi alifbo (Ishoq, ashob kabi istisnolar lug'atdan).
String lotinWordToYangi(String latin, Lexicon lexicon) {
  final hit = _lookupLexicon(lexicon, toKey(latin));
  if (hit == null || !_ambiguousCyr.hasMatch(hit.cyr)) return _naiveLotinToYangi(latin);
  return cyrWordToLatin(hit.cyr, Alphabet.yangi) + _naiveLotinToYangi(latin.substring(hit.length));
}

/// Yangi alifbo → amaldagi lotin (ichki ko'rinish). Har doim bir qiymatli.
String yangiWordToLotin(String word) {
  final out = StringBuffer();
  for (var i = 0; i < word.length; i++) {
    final c = word[i];
    if (c == 'ş') {
      out.write('sh');
    } else if (c == 'ç') {
      out.write('ch');
    } else if (c == 'ö') {
      out.write('o`');
    } else if (c == 'ğ') {
      out.write('g`');
    } else if (c == 's' && _at(word, i + 1) == 'h') {
      out.write("s'");
    } else if (apostrophes.contains(c)) {
      out.write("'");
    } else {
      out.write(c);
    }
  }
  return out.toString();
}

// --- Matn darajasi ---

const String _latinLetters = 'A-Za-zÇçŞşÖöĞğ';
final RegExp _latinWordRe = RegExp(
  '[$_latinLetters]+(?:[$apostrophes][$_latinLetters]+)*(?:(?<=[oOgG])[$apostrophes])?',
);
final RegExp _cyrWordRe = RegExp('[Ѐ-ӿ]+');

/// Havola va elektron pochta manzillari o'zgartirilmaydi.
final RegExp _skipRe = RegExp(r'(https?://\S+|www\.\S+|\S+@\S+\.\S+)');

/// Asl so'zning bosh/kichik harf ko'rinishini natijaga ko'chiradi.
String _applyCase(String source, String out) {
  final letters = source.replaceAll(_apostropheRe, '');
  if (letters.length > 1 && letters == letters.toUpperCase() && letters != letters.toLowerCase()) {
    return out.toUpperCase();
  }
  if (letters.isNotEmpty && letters[0] != letters[0].toLowerCase() && out.isNotEmpty) {
    return out[0].toUpperCase() + out.substring(1);
  }
  return out;
}

/// Ichki ko'rinishdagi belgilarni chiqish uchun haqiqiy belgilarga almashtiradi.
String _renderLatin(String latin, bool plainApostrophe) => plainApostrophe
    ? latin.replaceAll(RegExp("[`']"), "'")
    : latin.replaceAll('`', _modifier).replaceAll("'", _tutuq);

String _convertWord(String word, Alphabet from, Alphabet to, Lexicon lexicon, bool plainApostrophe) {
  final lower = word.toLowerCase();
  String out;
  if (from == Alphabet.kirill) {
    out = _renderLatin(cyrWordToLatin(lower, to == Alphabet.yangi ? Alphabet.yangi : Alphabet.lotin), plainApostrophe);
  } else if (from == Alphabet.lotin) {
    final latin = toKey(lower);
    out = to == Alphabet.kirill
        ? lotinWordToCyr(latin, lexicon)
        : _renderLatin(lotinWordToYangi(latin, lexicon), plainApostrophe);
  } else {
    final lotin = yangiWordToLotin(lower);
    out = to == Alphabet.kirill
        ? lotinWordToCyr(lotin, lexicon, true, toKey(lower))
        : _renderLatin(lotin, plainApostrophe);
  }
  return _applyCase(word, out);
}

/// Matnni bir yozuvdan ikkinchisiga o'giradi; so'z bo'lmagan qismlar o'zgarmaydi.
/// [plainApostrophe] — oʻ, gʻ va tutuq belgisi o'rniga oddiy apostrof (').
String transliterate(
  String text,
  Alphabet from,
  Alphabet to,
  Lexicon lexicon, {
  bool plainApostrophe = false,
}) {
  if (from == to) return text;
  final wordRe = from == Alphabet.kirill ? _cyrWordRe : _latinWordRe;
  String convert(String part) =>
      part.replaceAllMapped(wordRe, (m) => _convertWord(m[0]!, from, to, lexicon, plainApostrophe));

  final out = StringBuffer();
  var last = 0;
  for (final match in _skipRe.allMatches(text)) {
    out.write(convert(text.substring(last, match.start)));
    out.write(match[0]);
    last = match.end;
  }
  out.write(convert(text.substring(last)));
  return out.toString();
}

/// `lexicon.txt` mazmunini o'qiydi: har qatorda "kalit kirillcha".
Lexicon parseLexicon(String text) {
  final lexicon = <String, String>{};
  for (final line in text.split('\n')) {
    final space = line.indexOf(' ');
    if (space > 0) lexicon[line.substring(0, space)] = line.substring(space + 1).trim();
  }
  return lexicon;
}
