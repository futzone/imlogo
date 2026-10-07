/// O'zbek lotin yozuvida o‘, g‘ va tutuq belgisi turli klaviaturalarda
/// turlicha teriladi: ' ’ ‘ ʻ ʼ ` ´. Tez yozish mashqida ularning barchasi
/// bitta belgi sifatida qabul qilinadi ("yumshoq" tekshiruv).
const Set<String> typingApostrophes = {
  "'",
  '‘', // ‘
  '’', // ’
  'ʻ', // ʻ
  'ʼ', // ʼ
  '`',
  '´', // ´
  '′', // ′
  'ʹ', // ʹ
};

String normalizeTypingChar(String char) =>
    typingApostrophes.contains(char) ? "'" : char;

String normalizeTypingText(String text) =>
    text.split('').map(normalizeTypingChar).join();

bool isSameTypingChar(String a, String b) =>
    normalizeTypingChar(a) == normalizeTypingChar(b);

/// So'z to'liq va xatosiz terilganmi.
bool isTypedWordCorrect(String input, String target) {
  if (input.length != target.length) return false;
  for (var i = 0; i < target.length; i++) {
    if (!isSameTypingChar(input[i], target[i])) return false;
  }
  return true;
}

/// Ekranda ko'rsatish uchun: o/g dan keyin ‘ (o‘, g‘), qolgan hollarda ’
/// (tutuq belgisi). So'z uzunligi o'zgarmaydi.
String prettifyTypingWord(String word) {
  final buffer = StringBuffer();
  for (var i = 0; i < word.length; i++) {
    final char = word[i];
    if (char == "'" && i > 0) {
      final prev = word[i - 1].toLowerCase();
      buffer.write(prev == 'o' || prev == 'g' ? '‘' : '’');
    } else {
      buffer.write(char);
    }
  }
  return buffer.toString();
}
