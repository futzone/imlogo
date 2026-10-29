import 'package:dication/src/core/translit/translit.dart';
import 'package:dication/src/core/typing/typing_compose.dart';
import 'package:dication/src/core/typing/typing_engine.dart';

/// Yangi alifbo: "s" terilib, "h" kutilayotgan harf o'rni (qarang: [composeYangi]).
class TypingInputState {
  int? pending;
}

/// Kiritish maydonidagi yangi qiymatni dvigatelga uzatadi. Ilova ham, server
/// ham (bosishlar logini qayta o'ynaganda) aynan shu mantiqdan foydalanadi —
/// saytdagi `src/lib/app/typing/input.ts` (applyTypingValue) bilan bir xil,
/// shuning uchun natija ikkala tomonda bir xil chiqadi.
///
/// [value] — maydondagi matn (ko'rinmas boshlang'ich belgisiz) yoki `null`:
/// o'sha belgi o'chirildi, ya'ni bo'sh holatda "o'chirish" bosildi.
void applyTypingValue(TypingEngine engine, TypingInputState state, String? value, Duration elapsed) {
  if (value == null) {
    state.pending = null;
    engine.backToPreviousWord();
    return;
  }
  final space = value.indexOf(RegExp(r'\s'));
  var word = space >= 0 ? value.substring(0, space) : value;
  if (engine.config.alphabet == Alphabet.yangi) {
    final composed = composeYangi(engine.current, word, engine.target, state.pending, finalize: space >= 0);
    word = composed.value;
    state.pending = composed.pending;
  }
  engine.setCurrent(word, elapsed: elapsed);
  if (space >= 0) {
    state.pending = null;
    engine.commitWord(elapsed: elapsed);
  }
}
