import 'package:dication/src/core/models/error_type.dart';

class DetectedError {
  ErrorType type;
  String description;
  String originalFragment;
  String userFragment;
  String specificRuleCode;
  double penaltyMultiplier;

  DetectedError({
    required this.type,
    required this.description,
    this.originalFragment = '',
    this.userFragment = '',
    required this.specificRuleCode,
    this.penaltyMultiplier = 1.0,
  });

  @override
  String toString() {
    return 'Xato: $type, Tavsif: $description, Original: "$originalFragment", Kiritilgan: "$userFragment", Qoida Kodi: $specificRuleCode';
  }
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
    text = text.replaceAllMapped(RegExp(r"([,\.:;!\?()])"), (match) => " ${match.group(1)} ");
    return text.trim().split(RegExp(r'\s+'));
  }

  String _normalizeChar(String char) {
    if (char == 'o' || char == 'O') return char;
    if (char == 'g' || char == 'G') return char;

    if (char == 'o‘' || char == 'O‘' || char == 'oʻ' || char == 'Oʻ' || char == 'ў' || char == 'Ў') return 'o‘';
    if (char == 'g‘' || char == 'G‘' || char == 'gʻ' || char == 'Gʻ' || char == 'ғ' || char == 'Ғ') return 'g‘';
    return char.toLowerCase();
  }

  void analyze() {
    _detectedErrors.clear();
    _uniqueErrorCodes.forEach((key, value) => value.clear());

    List<String> originalWords = _tokenize(originalText);
    List<String> userWords = _tokenize(userText);

    int len = originalWords.length < userWords.length ? originalWords.length : userWords.length;

    for (int i = 0; i < len; i++) {
      String originalWord = originalWords[i];
      String userWord = userWords[i];

      bool graficErrorFoundForWord = false;
      if ((originalWord.contains('o‘') || originalWord.contains('O‘') || originalWord.contains('ў') || originalWord.contains('Ў')) &&
          (userWord.contains("o'") || userWord.contains("O'"))) {
        _addError(DetectedError(
            type: ErrorType.GRAFIK,
            description: "O‘ harfi o'rniga o' ishlatilgan",
            originalFragment: originalWord,
            userFragment: userWord,
            specificRuleCode: "grafik_o_apostrof"));
        graficErrorFoundForWord = true;
      }
      if ((originalWord.contains('g‘') || originalWord.contains('G‘') || originalWord.contains('ғ') || originalWord.contains('Ғ')) &&
          (userWord.contains("g'") || userWord.contains("G'"))) {
        _addError(DetectedError(
            type: ErrorType.GRAFIK,
            description: "G‘ harfi o'rniga g' ishlatilgan",
            originalFragment: originalWord,
            userFragment: userWord,
            specificRuleCode: "grafik_g_apostrof"));
        graficErrorFoundForWord = true;
      }

      String origPunct = originalWord.replaceAll(RegExp(r'[\w‘’ʻʼ]'), '');
      String userPunct = userWord.replaceAll(RegExp(r'[\w‘’ʻʼ]'), '');
      String origWordStem = originalWord.replaceAll(RegExp(r'[^\w‘’ʻʼ]'), '');
      String userWordStem = userWord.replaceAll(RegExp(r'[^\w‘’ʻʼ]'), '');

      if (origPunct != userPunct && _normalizeChar(origWordStem) == _normalizeChar(userWordStem)) {
        String punctCode = "punkt_umumiy_${origPunct}_vs_${userPunct}";
        if (origPunct.isEmpty && userPunct.isNotEmpty) punctCode = "punkt_ortiqcha_$userPunct";
        if (origPunct.isNotEmpty && userPunct.isEmpty) punctCode = "punkt_yetishmaydi_$origPunct";

        _addError(DetectedError(
            type: ErrorType.PUNKTUATSION,
            description: "Tinish belgisida xato",
            originalFragment: originalWord,
            userFragment: userWord,
            specificRuleCode: punctCode));
      }

      String normOrigWord = _normalizeWordForImlo(originalWord);
      String normUserWord = _normalizeWordForImlo(userWord);

      if (normOrigWord != normUserWord) {
        double penaltyMultiplier = 1.0;
        String errorDesc = "So'zni noto'g'ri yozish";
        String specificCode = "imlo_${normOrigWord}_vs_$normUserWord";

        if (normOrigWord.toLowerCase() == "zamon") {
          if (normUserWord.toLowerCase() == "ramon") {
            specificCode = "imlo_zamon_ramon";
          } else if (normUserWord.toLowerCase() == "xamon") {
            penaltyMultiplier = 0.5;
            errorDesc = "So'zni yozishda klaviatura yaqinligi (Z vs X)";
            specificCode = "imlo_zamon_xamon_yaqinlik";
          }
        }

        if (normOrigWord.contains('h') && normUserWord.contains('x') && normOrigWord.replaceAll('h', 'x') == normUserWord) {
          errorDesc = "h o'rniga x yozilgan";
          specificCode = "imlo_h_x_almashinuvi";
        } else if (normOrigWord.contains('x') && normUserWord.contains('h') && normOrigWord.replaceAll('x', 'h') == normUserWord) {
          errorDesc = "x o'rniga h yozilgan";
          specificCode = "imlo_x_h_almashinuvi";
        }

        if ((normOrigWord.contains("'") || normOrigWord.contains("ʼ") || normOrigWord.contains("‘") || normOrigWord.contains("’")) &&
            !(normUserWord.contains("'") || normUserWord.contains("ʼ") || normUserWord.contains("‘") || normUserWord.contains("’")) &&
            (normOrigWord.replaceAll(RegExp("['ʼ‘]"), "") == normUserWord)) {
          errorDesc = "Tutuq belgisi tushib qolgan";
          specificCode = "imlo_tutuq_tushibqolgan_$normOrigWord";
        } else if (!(normOrigWord.contains("'") || normOrigWord.contains("ʼ") || normOrigWord.contains("‘") || normOrigWord.contains("’")) &&
            (normUserWord.contains("'") || normUserWord.contains("ʼ") || normUserWord.contains("‘") || normUserWord.contains("’")) &&
            (normOrigWord == normUserWord.replaceAll(RegExp("['ʼ‘]"), ""))) {
          errorDesc = "O'rinsiz tutuq belgisi ishlatilgan";
          specificCode = "imlo_tutuq_orinsiz_$normOrigWord";
        }

        if (originalWord.toLowerCase() == userWord.toLowerCase() && originalWord != userWord) {
          errorDesc = "Bosh harf imlosida xato";
          specificCode = "imlo_bosh_harf_$originalWord";
        }

        _addError(DetectedError(
            type: ErrorType.IMLO,
            description: errorDesc,
            originalFragment: originalWord,
            userFragment: userWord,
            specificRuleCode: specificCode,
            penaltyMultiplier: penaltyMultiplier));
      }
    }
    if (originalWords.length != userWords.length) {
      int diff = (originalWords.length - userWords.length).abs();
      bool userTextLonger = userWords.length > originalWords.length;
      String diffDesc = userTextLonger ? "Ortiqcha so'zlar" : "Yetishmayotgan so'zlar";

      List<String> diffWords = userTextLonger ? userWords.sublist(originalWords.length) : originalWords.sublist(userWords.length);

      for (String dw in diffWords) {
        _addError(DetectedError(
            type: ErrorType.IMLO,
            description: diffDesc,
            originalFragment: userTextLonger ? "" : dw,
            userFragment: userTextLonger ? dw : "",
            specificRuleCode: "imlo_soz_${userTextLonger ? 'ortiqcha' : 'yetishmaydi'}_$dw"));
      }
    }

    _findUslubiyErrors();
  }

  String _normalizeWordForImlo(String word) {
    String tempWord = "";
    for (int i = 0; i < word.length; i++) {
      tempWord += _normalizeChar(word[i]);
    }
    return tempWord.replaceAll(RegExp(r'[^\w‘’ʻʼ]'), '').toLowerCase();
  }

  void _findUslubiyErrors() {
    Map<String, String> paronyms = {
      "abzal": "afzal",
      "asil": "asl",
    };

    List<String> userWords = _tokenize(userText.toLowerCase());
    for (String userWord in userWords) {
      String cleanedUserWord = userWord.replaceAll(RegExp(r'[^\w]'), '');
      if (paronyms.containsKey(cleanedUserWord)) {
        if (originalText.toLowerCase().contains(paronyms[cleanedUserWord]!)) {
          if (userText.toLowerCase().contains(cleanedUserWord) && !userText.toLowerCase().contains(paronyms[cleanedUserWord]!)) {
            _addError(DetectedError(
                type: ErrorType.USLUBIY,
                description: "Paronim noto'g'ri qo'llanilgan",
                originalFragment: paronyms[cleanedUserWord]!,
                userFragment: cleanedUserWord,
                specificRuleCode: "uslubiy_paronim_${cleanedUserWord}_vs_${paronyms[cleanedUserWord]}"));
          }
        }
      }
    }

    String userTextLower = userText.toLowerCase();
    String originalTextLower = originalText.toLowerCase();

    if (userTextLower.contains("o'qiyopti") && originalTextLower.contains("o'qiyapti")) {
      _addError(DetectedError(
          type: ErrorType.USLUBIY,
          description: "Sheva so'zi o'rinsiz qo'llanilgan",
          originalFragment: "o'qiyapti",
          userFragment: "o'qiyopti",
          specificRuleCode: "uslubiy_sheva_oqiyopti"));
    }
  }

  int get imloErrorCount => _uniqueErrorCodes[ErrorType.IMLO]?.length ?? 0;

  int get punktuatsionErrorCount => _uniqueErrorCodes[ErrorType.PUNKTUATSION]?.length ?? 0;

  int get uslubiyErrorCount => _uniqueErrorCodes[ErrorType.USLUBIY]?.length ?? 0;

  int get grafikErrorCount => _uniqueErrorCodes[ErrorType.GRAFIK]?.length ?? 0;

  int evaluate5PointScale() {
    int imlo = imloErrorCount;
    int punkt = punktuatsionErrorCount;
    int aloBaho;

    if (imlo == 0 && punkt == 0) {
      aloBaho = 5;
    } else if ((imlo == 1 && punkt == 0) || (imlo == 0 && punkt == 1)) {
      if (imlo == 1) {
        aloBaho = 5;
      } else {
        aloBaho = 5;
      }
    } else if (imlo <= 2 && (imlo + punkt) <= 4) {
      aloBaho = 4;
    } else if (imlo <= 4 && (imlo + punkt) <= 8) {
      aloBaho = 3;
    } else if (imlo <= 7 && (imlo + punkt) <= 14) {
      aloBaho = 2;
    } else {
      aloBaho = 1;
    }

    if (_changesCount >= 3 && aloBaho == 5) {
      aloBaho = 4;
    }

    if (_changesCount > 5) {
      if (aloBaho > 1) aloBaho--;
    }

    return aloBaho;
  }

  int evaluate100PointScaleMethod2() {
    int imlo = imloErrorCount;
    int ishoraviy = punktuatsionErrorCount + uslubiyErrorCount + grafikErrorCount; // Barcha imlo bo'lmaganlar ishoraviy

    if (imlo >= 10) return 0;

    if (imlo <= 2 && ishoraviy <= 2) return 100;
    if (imlo <= 4 && ishoraviy <= 3) return 80;
    if (imlo <= 7 && ishoraviy <= 5) return 60;
    if (imlo <= 9 && ishoraviy <= 7) return 50;

    if (imlo < 10) return 50;

    return 0;
  }

  double evaluate100PointScaleMethod3() {
    int totalWords = _tokenize(originalText).length;
    if (totalWords == 0) return 0.0;

    double currentScore = 100.0;

    currentScore -= imloErrorCount * 2.5;
    currentScore -= punktuatsionErrorCount * 2.0;
    currentScore -= uslubiyErrorCount * 1.5;
    currentScore -= grafikErrorCount * 1.5;

    bool zamonXamonFound = _uniqueErrorCodes[ErrorType.IMLO]!.contains("imlo_zamon_xamon_yaqinlik");
    if (zamonXamonFound) {
      currentScore += 2.5;
      currentScore -= (2.5 * 0.5);
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
    ///  print("--- FOYDALANUVCHI 1 ---");
    //                       var evaluator1 = DiktantEvaluator(
    //                         originalText: widget.model.text,
    //                         userText: _textEditingController.text.trim(),
    //                       );
    //                       evaluator1.analyze();
    //                       evaluator1.printDetailedErrors();
    //                       print("5 ballik baho: ${evaluator1.evaluate5PointScale()}");
    //                       print("100 ballik (usul 2) baho: ${evaluator1.evaluate100PointScaleMethod2()}");
    //                       print("100 ballik (usul 3) baho: ${evaluator1.evaluate100PointScaleMethod3().toStringAsFixed(2)}%");
  }
}
