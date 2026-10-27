import 'package:dication/src/core/translit/translit.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Istisnolar lug'ati (`assets/translit/lexicon.txt`) — translator va
/// tez yozishning yangi alifbo/kirill rejimlari uchun bir marta o'qiladi.
final lexiconProvider = FutureProvider<Lexicon>((ref) async {
  final raw = await rootBundle.loadString('assets/translit/lexicon.txt');
  return parseLexicon(raw);
});
