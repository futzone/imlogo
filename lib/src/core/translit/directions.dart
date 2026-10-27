import 'package:dication/src/core/translit/translit.dart';

const Map<Alphabet, String> alphabetNames = {
  Alphabet.lotin: 'Lotin',
  Alphabet.yangi: 'Yangi lotin',
  Alphabet.kirill: 'Kirill',
};

/// Sahifa sarlavhalari uchun: "...dan" shakli.
const Map<Alphabet, String> _fromNames = {
  Alphabet.lotin: 'Lotinçadan',
  Alphabet.yangi: 'Yangi alifbodan',
  Alphabet.kirill: 'Kirillçadan',
};
const Map<Alphabet, String> _toNames = {
  Alphabet.lotin: 'lotinçaga',
  Alphabet.yangi: 'yangi alifboga',
  Alphabet.kirill: 'kirillçaga',
};

/// Translator yo'nalishi (veb-saytdagi `directions.ts` bilan bir xil).
class TranslitDirection {
  final Alphabet from;
  final Alphabet to;

  const TranslitDirection(this.from, this.to);

  String get slug => '${from.name}-${to.name}';

  String get label => '${alphabetNames[from]} → ${alphabetNames[to]}';

  String get title => '${_fromNames[from]} ${_toNames[to]} ögiriş';

  TranslitDirection get reversed => TranslitDirection(to, from);

  @override
  bool operator ==(Object other) => other is TranslitDirection && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

/// Tanlash ro'yxatida ko'rsatiladigan tartibda.
const List<TranslitDirection> translitDirections = [
  TranslitDirection(Alphabet.yangi, Alphabet.lotin),
  TranslitDirection(Alphabet.yangi, Alphabet.kirill),
  TranslitDirection(Alphabet.lotin, Alphabet.yangi),
  TranslitDirection(Alphabet.kirill, Alphabet.yangi),
  TranslitDirection(Alphabet.kirill, Alphabet.lotin),
  TranslitDirection(Alphabet.lotin, Alphabet.kirill),
];

const TranslitDirection defaultDirection = TranslitDirection(Alphabet.lotin, Alphabet.yangi);
