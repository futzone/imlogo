import 'package:dication/src/core/models/detected_error.dart';
import 'package:dication/src/core/models/error_type.dart'; // O'zingizning ErrorType enum faylingizga yo'lni to'g'rilang


class AlignedPair {
  final String? originalWord;
  final String? userWord;

  AlignedPair(this.originalWord, this.userWord);
}

class DiktantEvaluator {
  final String originalText;
  final String userText;
  final int userAge;
  final int _changesCount;

  final List<DetectedError> _detectedErrors = [];

  final Map<ErrorType, Set<String>> _uniqueErrorCodes = {
    ErrorType.IMLO: <String>{},
    ErrorType.PUNKTUATSION: <String>{},
    ErrorType.USLUBIY: <String>{},
    ErrorType.GRAFIK: <String>{},
  };

  DiktantEvaluator({
    required this.originalText,
    required this.userText,
    this.userAge = 10,
    int changesCount = 0,
  }) : _changesCount = changesCount;

  void _addError(DetectedError error) {
    _detectedErrors.add(error);
    _uniqueErrorCodes[error.type]?.add(error.specificRuleCode);
  }

  List<String> _tokenize(String text) {
    if (text.trim().isEmpty) return [];
    // Tinish belgilarini so'zlardan ajratish (o'zbekcha apostroflarni saqlagan holda)
    // Regex takomillashtirilishi mumkin, masalan, "so'z-so'z" kabi chiziqchali so'zlarni ajratmaslik uchun.
    // Hozirgi variant ko'p tinish belgilarini to'g'ri ajratadi.
    text = text.replaceAllMapped(RegExp(r"([,\.:;!\?()])(?=\s|$)"), (match) => " ${match.group(1)} ");
    // Agar tinish belgisi so'zga yopishgan bo'lsa (oxirida): "so'z." -> "so'z ."
    text = text.replaceAllMapped(RegExp(r"(\w)([,\.:;!\?()])(?=\w|$)"), (match) => "${match.group(1)} ${match.group(2)} ");
    // Agar tinish belgisi so'zga yopishgan bo'lsa (boshida): ".so'z" -> ". so'z"
    text = text.replaceAllMapped(RegExp(r"(^|\s)([,\.:;!\?()])(\w)"), (match) => "${match.group(1)}${match.group(2)} ${match.group(3)}");

    return text.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  }


  String _normalizeChar(String char) {
    if (char == 'o' || char == 'O') return char;
    if (char == 'g' || char == 'G') return char;

    if (char == 'o‘' || char == 'O‘' || char == 'oʻ' || char == 'Oʻ' || char == 'ў' || char == 'Ў') return 'o‘';
    if (char == 'g‘' || char == 'G‘' || char == 'gʻ' || char == 'Gʻ' || char == 'ғ' || char == 'Ғ') return 'g‘';
    return char.toLowerCase();
  }

  // So'zlarni imloviy tekshiruv uchun normallashtirish
  // Punktuatsiyani olib tashlamaydi, chunki punktuatsiyalar alohida token sifatida keladi.
  String _normalizeWordForImloCheck(String word) {
    String tempWord = "";
    for (int i = 0; i < word.length; i++) {
      tempWord += _normalizeChar(word[i]);
    }
    return tempWord.toLowerCase(); // Faqatgina harf регистрини ва 'o‘' kabilarni normallashtiradi
  }

  List<AlignedPair> _alignWords(List<String> seq1, List<String> seq2) {
    final int len1 = seq1.length;
    final int len2 = seq2.length;
    final List<List<int>> lcsTable = List.generate(len1 + 1, (_) => List.filled(len2 + 1, 0));

    for (int i = 0; i <= len1; i++) {
      for (int j = 0; j <= len2; j++) {
        if (i == 0 || j == 0) {
          lcsTable[i][j] = 0;
        } else if (seq1[i - 1] == seq2[j - 1] || _normalizeWordForImloCheck(seq1[i-1]) == _normalizeWordForImloCheck(seq2[j-1])) { // Imlo xatosi bo'lsa ham juftlashga yordam beradi
          lcsTable[i][j] = lcsTable[i - 1][j - 1] + 1;
        } else {
          lcsTable[i][j] = (lcsTable[i - 1][j] > lcsTable[i][j - 1]) ? lcsTable[i - 1][j] : lcsTable[i][j - 1];
        }
      }
    }

    final List<AlignedPair> alignedPairs = [];
    int i = len1, j = len2;
    while (i > 0 || j > 0) {
      String? s1Val = (i > 0) ? seq1[i - 1] : null;
      String? s2Val = (j > 0) ? seq2[j - 1] : null;

      if (i > 0 && j > 0 && (seq1[i-1] == seq2[j-1] || _normalizeWordForImloCheck(seq1[i-1]) == _normalizeWordForImloCheck(seq2[j-1]))) {
        alignedPairs.add(AlignedPair(s1Val, s2Val));
        i--;
        j--;
      } else if (j > 0 && (i == 0 || lcsTable[i][j - 1] >= lcsTable[i - 1][j])) {
        alignedPairs.add(AlignedPair(null, s2Val));
        j--;
      } else if (i > 0 && (j == 0 || lcsTable[i - 1][j] > lcsTable[i][j - 1])) {
        alignedPairs.add(AlignedPair(s1Val, null));
        i--;
      } else {
        break;
      }
    }
    return alignedPairs.reversed.toList();
  }

  bool _isPunctuation(String s) {
    return s.length == 1 && RegExp(r'^[,\.:;!\?()]$').hasMatch(s);
  }

  void analyze() {
    _detectedErrors.clear();
    _uniqueErrorCodes.forEach((key, value) => value.clear());

    List<String> originalTokens = _tokenize(originalText);
    List<String> userTokens = _tokenize(userText);

    List<AlignedPair> alignedList = _alignWords(originalTokens, userTokens);

    for (final pair in alignedList) {
      final String? originalWord = pair.originalWord;
      final String? userWord = pair.userWord;

      if (originalWord != null && userWord == null) {
        bool isPunct = _isPunctuation(originalWord);
        _addError(DetectedError(
            type: isPunct ? ErrorType.PUNKTUATSION : ErrorType.IMLO,
            description: isPunct ? "Tinish belgisi tushib qolgan" : "So'z tushib qolgan",
            originalFragment: originalWord,
            userFragment: "",
            specificRuleCode: "${isPunct ? 'punkt' : 'imlo'}_tushib_qolgan" // Umumiy kod
        ));
        continue;
      }

      if (originalWord == null && userWord != null) {
        bool isPunct = _isPunctuation(userWord);
        _addError(DetectedError(
            type: isPunct ? ErrorType.PUNKTUATSION : ErrorType.IMLO,
            description: isPunct ? "Ortiqcha tinish belgisi" : "Ortiqcha so'z",
            originalFragment: "",
            userFragment: userWord,
            specificRuleCode: "${isPunct ? 'punkt' : 'imlo'}_ortiqcha" // Umumiy kod
        ));
        continue;
      }

      if (originalWord != null && userWord != null) {
        // Grafik xatolar (o‘/g‘ vs o'/g')
        if ((originalWord.contains('o‘') || originalWord.contains('O‘') || originalWord.contains('ў') || originalWord.contains('Ў')) &&
            (userWord.contains("o'") || userWord.contains("O'"))) {
          _addError(DetectedError(
              type: ErrorType.GRAFIK,
              description: "O‘ harfi o'rniga o' ishlatilgan",
              originalFragment: originalWord,
              userFragment: userWord,
              specificRuleCode: "grafik_o_apostrof"));
        }
        if ((originalWord.contains('g‘') || originalWord.contains('G‘') || originalWord.contains('ғ') || originalWord.contains('Ғ')) &&
            (userWord.contains("g'") || userWord.contains("G'"))) {
          _addError(DetectedError(
              type: ErrorType.GRAFIK,
              description: "G‘ harfi o'rniga g' ishlatilgan",
              originalFragment: originalWord,
              userFragment: userWord,
              specificRuleCode: "grafik_g_apostrof"));
        }

        bool origIsPunct = _isPunctuation(originalWord);
        bool userIsPunct = _isPunctuation(userWord);

        if (origIsPunct && userIsPunct) { // Ikkalasi ham punktuatsiya
          if (originalWord != userWord) {
            _addError(DetectedError(
                type: ErrorType.PUNKTUATSION,
                description: "Tinish belgisi noto'g'ri qo'llanilgan",
                originalFragment: originalWord,
                userFragment: userWord,
                specificRuleCode: "punkt_belgi_almashgan")); // Umumiy kod
          }
          continue; // Bu juftlik tekshirildi
        } else if (origIsPunct != userIsPunct) {
          // Biri punktuatsiya, ikkinchisi emas. Bu alignmentda tushib qolgan/ortiqcha sifatida chiqishi kerak edi.
          // Agar shu yerga kelsa, bu "so'z punktuatsiyaga almashgan" yoki aksincha degan ma'noni anglatadi.
          // Buni imloviy xato sifatida baholaymiz.
          _addError(DetectedError(
              type: ErrorType.IMLO, // Yoki PUNKTUATSION, kontekstga qarab
              description: "So'z va tinish belgisi almashib qolgan",
              originalFragment: originalWord,
              userFragment: userWord,
              specificRuleCode: "imlo_soz_punkt_almashuvi"
          ));
          continue;
        }

        // Bu yergacha kelsa, ikkalasi ham so'z (punktuatsiya emas)

        // Bosh harf imlosi xatosi
        // Normallashtirilmagan so'zlarni solishtiramiz
        if (originalWord.toLowerCase() == userWord.toLowerCase() && originalWord != userWord) {
          _addError(DetectedError(
              type: ErrorType.IMLO,
              description: "Bosh harf imlosida xato",
              originalFragment: originalWord,
              userFragment: userWord,
              specificRuleCode: "imlo_bosh_harf")); // Umumiy kod
        }

        // Asosiy imloviy xatolar (normallashtirilgan so'zlarni solishtirish)
        String normOrigWord = _normalizeWordForImloCheck(originalWord);
        String normUserWord = _normalizeWordForImloCheck(userWord);

        if (normOrigWord != normUserWord) {
          double penaltyMultiplier = 1.0;
          String errorDesc = "So'zni noto'g'ri yozish";
          // So'zlar farq qilganda umumiy specific code beramiz, chunki har bir noto'g'ri so'z alohida xato.
          // Agar maxsus qoidalar (h/x, tutuq) bo'lsa, ular ustunlik qiladi.
          String specificCode = "imlo_soz_noto'g'ri_${normOrigWord}";


          if (normOrigWord == "zamon") { // Faqat kichik harflarda tekshiramiz, bosh harf xatosi alohida
            if (normUserWord == "ramon") {
              specificCode = "imlo_zamon_ramon"; // Maxsus kod
            } else if (normUserWord == "xamon") {
              penaltyMultiplier = 0.5;
              errorDesc = "So'zni yozishda klaviatura yaqinligi (Zamon vs Xamon)";
              specificCode = "imlo_zamon_xamon_yaqinlik"; // Maxsus kod
            }
          }

          // h vs x (agar butun so'z faqat shu bilan farq qilsa)
          if (normOrigWord.replaceAll('h', 'x') == normUserWord && normOrigWord.contains('h')) {
            errorDesc = "h o'rniga x yozilgan";
            specificCode = "imlo_h_x_almashinuvi";
          } else if (normOrigWord.replaceAll('x', 'h') == normUserWord && normOrigWord.contains('x')) {
            errorDesc = "x o'rniga h yozilgan";
            specificCode = "imlo_x_h_almashinuvi"; // Bu ham yuqoridagi bilan bir tipda bo'lishi mumkin: "imlo_h_x_harf_almashinuvi"
          }

          // Tutuq belgisi xatolari
          // Bu yerda originalWord va userWord dan tutuq belgisini olib tashlab solishtirish kerak
          String origWithoutTutuq = normOrigWord.replaceAll(RegExp("['ʼ‘’]"), "");
          String userWithoutTutuq = normUserWord.replaceAll(RegExp("['ʼ‘’]"), "");

          bool origHasTutuq = normOrigWord.contains(RegExp("['ʼ‘’]"));
          bool userHasTutuq = normUserWord.contains(RegExp("['ʼ‘’]"));

          if (origWithoutTutuq == userWithoutTutuq) { // So'z asosi bir xil
            if (origHasTutuq && !userHasTutuq) {
              errorDesc = "Tutuq belgisi tushib qolgan";
              specificCode = "imlo_tutuq_tushibqolgan";
            } else if (!origHasTutuq && userHasTutuq) {
              errorDesc = "O'rinsiz tutuq belgisi ishlatilgan";
              specificCode = "imlo_tutuq_orinsiz";
            }
          } // else: agar asos ham farq qilsa, bu yuqoridagi "imlo_soz_noto'g'ri" xatosi bo'ladi

          _addError(DetectedError(
              type: ErrorType.IMLO,
              description: errorDesc,
              originalFragment: originalWord,
              userFragment: userWord,
              specificRuleCode: specificCode,
              penaltyMultiplier: penaltyMultiplier));
        }
      }
    }

    _findUslubiyErrors();
  }


  void _findUslubiyErrors() {
    // Bu funksiya butun matnni tahlil qilishi mumkin va hozircha o'zgarishsiz qoladi.
    // Alignmentdan keyin bu funksiyani ham takomillashtirish mumkin.
    Map<String, String> paronyms = {
      "abzal": "afzal",
      "asil": "asl",
    };

    // userText ni qayta tokenizatsiya qilish yoki alignedList dan foydalanuvchi so'zlarini olish
    List<String> userWordsOnly = _tokenize(userText.toLowerCase()).where((word) => !_isPunctuation(word)).toList();

    for (String userWord in userWordsOnly) {
      String cleanedUserWord = userWord.replaceAll(RegExp(r'[^\w]'), ''); // Faqat harflar
      if (paronyms.containsKey(cleanedUserWord)) {
        if (originalText.toLowerCase().contains(paronyms[cleanedUserWord]!)) {
          if (!userText.toLowerCase().contains(paronyms[cleanedUserWord]!)) { // Foydalanuvchi to'g'ri variantni ishlatmagan bo'lsa
            _addError(DetectedError(
                type: ErrorType.USLUBIY,
                description: "Paronim noto'g'ri qo'llanilgan: '$cleanedUserWord' o'rniga '${paronyms[cleanedUserWord]}' bo'lishi mumkin",
                originalFragment: paronyms[cleanedUserWord]!,
                userFragment: cleanedUserWord,
                specificRuleCode: "uslubiy_paronim")); // Umumiy kod
          }
        }
      }
    }

    String userTextLower = userText.toLowerCase();
    String originalTextLower = originalText.toLowerCase();

    if (userTextLower.contains("o'qiyopti") && originalTextLower.contains("o'qiyapti") && !userTextLower.contains("o'qiyapti")) {
      _addError(DetectedError(
          type: ErrorType.USLUBIY,
          description: "Sheva so'zi o'rinsiz qo'llanilgan ('o'qiyopti' o'rniga 'o'qiyapti')",
          originalFragment: "o'qiyapti", // Originaldagi to'g'ri variant
          userFragment: "o'qiyopti",   // Foydalanuvchi yozgani
          specificRuleCode: "uslubiy_sheva_sozi")); // Umumiy kod
    }
  }

  int get imloErrorCount => _uniqueErrorCodes[ErrorType.IMLO]?.length ?? 0;
  int get punktuatsionErrorCount => _uniqueErrorCodes[ErrorType.PUNKTUATSION]?.length ?? 0;
  int get uslubiyErrorCount => _uniqueErrorCodes[ErrorType.USLUBIY]?.length ?? 0;
  int get grafikErrorCount => _uniqueErrorCodes[ErrorType.GRAFIK]?.length ?? 0;

  int evaluate5PointScale() {
    int imlo = imloErrorCount;
    int punkt = punktuatsionErrorCount; // Uslubiy va grafik bu yerda hisobga olinmaydi
    int currentMark;

    if (imlo == 0 && punkt == 0) {
      currentMark = 5;
    } else if ((imlo == 1 && punkt == 0) || (imlo == 0 && punkt == 1)) {
      // Qo'pol bo'lmagan xato shartini avtomatik aniqlash qiyin.
      // Hozircha bitta xatoni "qo'pol emas" deb hisoblaymiz.
      currentMark = 5;
    } else if (imlo <= 2 && (imlo + punkt) <= 4) {
      currentMark = 4;
    } else if (imlo <= 4 && (imlo + punkt) <= 8) {
      currentMark = 3;
    } else if (imlo <= 7 && (imlo + punkt) <= 14) {
      currentMark = 2;
    } else { // 15 va undan ko'p xato
      currentMark = 1;
    }

    if (_changesCount >= 3 && currentMark == 5) {
      currentMark = 4;
    }

    if (_changesCount > 5) {
      if (currentMark > 1) currentMark--;
    }
    return currentMark;
  }

  int evaluate100PointScaleMethod2() {
    int imlo = imloErrorCount;
    // Ishoraviy xatolarga punktuatsion, uslubiy va grafik xatolar kiradi
    int ishoraviy = punktuatsionErrorCount + uslubiyErrorCount + grafikErrorCount;

    if (imlo >= 10) return 0;

    if (imlo <= 2 && ishoraviy <= 2) return 100; // 1-2 ta imloviy degani <=2
    if (imlo >=3 && imlo <= 4 && ishoraviy <= 3) return 80;
    if (imlo >=5 && imlo <= 7 && ishoraviy <= 5) return 60;
    if (imlo >=8 && imlo <= 9 && ishoraviy <= 7) return 50;

    // Agar yuqoridagilarga tushmasa, lekin imlo < 10
    // Bu holat uchun qoidada aniq ko'rsatma yo'q, eng yaqin past ballni beramiz yoki 0.
    // Masalan, 5 imlo va 6 ishoraviy bo'lsa, 60 ga tushmaydi, 50 ga ham.
    // Bu shartlarni qat'iy "va" bilan tekshiramiz.
    // Agar hech biriga tushmasa 0 qaytaramiz.

    return 0; // Agar yuqoridagi shartlarga mos kelmasa
  }

  double evaluate100PointScaleMethod3() {
    // originalText tokenlar soni, faqat so'zlar emas.
    // int totalWords = _tokenize(originalText).where((token) => !_isPunctuation(token)).length;
    // Qoidalarda "diktantdagi barcha so'zlar soni" deyilgan, bu punktuatsiyani hisobga olmaydi.
    // Lekin xatoliklar punktuatsiya uchun ham ayiriladi. Bu qismni aniqlashtirish kerak.
    // Hozircha umumiy token sonini olamiz, chunki foizlar imlo, punkt., uslub., grafik uchun alohida.

    double currentScore = 100.0;

    currentScore -= imloErrorCount * 2.5;
    currentScore -= punktuatsionErrorCount * 2.0;
    currentScore -= uslubiyErrorCount * 1.5;
    currentScore -= grafikErrorCount * 1.5;

    bool zamonXamonFound = _uniqueErrorCodes[ErrorType.IMLO]!.contains("imlo_zamon_xamon_yaqinlik");
    if (zamonXamonFound) {
      // Bu xato uchun standart 2.5% ayirilgan edi. Endi uni 0.5 * 2.5% ga to'g'rilaymiz.
      currentScore += 2.5; // Qaytarib qo'shamiz
      currentScore -= (2.5 * 0.5); // To'g'rilangan qiymatni ayiramiz
    }

    return currentScore < 0 ? 0.0 : currentScore;
  }

  List<DetectedError> getDetailedErrors () => _detectedErrors;

  void printDetailedErrors() {
    if (_detectedErrors.isEmpty) {
      print("Xatolar topilmadi.");
      return;
    }
    print("Aniqlangan xatolar ro'yxati:");
    _detectedErrors.forEach(print);
    print("\n--- Xulosaviy hisobot ---");
    print("Jami unikal imlo xatolari: $imloErrorCount");
    print("Jami unikal punktuatsion xatolari: $punktuatsionErrorCount");
    print("Jami unikal uslubiy xatolari: $uslubiyErrorCount");
    print("Jami unikal grafik xatolari: $grafikErrorCount");
    print("Kiritilgan tuzatishlar soni: $_changesCount");
  }
}