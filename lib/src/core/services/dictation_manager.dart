import 'dart:math';

import '../models/detected_error.dart';
import '../models/error_type.dart';

enum AlignedPairType { MATCH, SUBSTITUTION, DELETION, INSERTION }

class AlignedPair {
  final String? originalToken;
  final String? userToken;
  final AlignedPairType type;

  AlignedPair({
    this.originalToken,
    this.userToken,
    required this.type,
  });
}

class DiktantEvaluator {
  final String originalText;
  final String userText;
  final List<DetectedError> _detectedErrors = [];
  final Map<ErrorType, Set<String>> _uniqueErrorCodes = {
    ErrorType.IMLO: {},
    ErrorType.PUNKTUATSION: {},
    ErrorType.USLUBIY: {},
    ErrorType.GRAFIK: {},
  };

  static const double DISSIMILARITY_LENGTH_RATIO_THRESHOLD = 0.3;
  static const int DISSIMILARITY_MIN_USER_TOKENS = 3; // Agar user tokenlari bundan kam bo'lsa, length_ratio ga qaramasdan tekshiriladi
  static const double DISSIMILARITY_MATCH_RATIO_THRESHOLD = 0.1;
  static const int CATASTROPHIC_MIN_ORIGINAL_TOKENS = 5; // Agar original tokenlar bundan kam bo'lsa, katastrofik deb topilmaydi

  DiktantEvaluator({
    required this.originalText,
    required this.userText,
  });

  List<String> _tokenize(String text) {
    if (text.trim().isEmpty) return [];

    String textToTokenize = text.split('').map(_normalizeChar).join('');

    List<String> tokens = [];
    final RegExp lexerRule = RegExp(
        r"""([a-zA-Zа-яА-ЯўЎғҒҳҲқҚчЧшШo‘O‘g‘G‘]+(?:['’‘ʻ][a-zA-Zа-яА-ЯўЎғҒҳҲқҚчЧшШo‘O‘g‘G‘]+)*[a-zA-Zа-яА-ЯўЎғҒҳҲқҚчЧшШo‘O‘g‘G‘]*)|([.,;:!?()\[\]{}<>"\-'`‘’“”«»~@#$%^&*_\-+=\|\/\\]+)""");

    lexerRule.allMatches(textToTokenize).forEach((match) {
      String? matchedToken = match.group(1) ?? match.group(2);
      if (matchedToken != null && matchedToken.isNotEmpty) {
        tokens.add(matchedToken);
      }
    });

    if (tokens.isEmpty && textToTokenize.isNotEmpty) {
      return textToTokenize.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    }
    return tokens;
  }

  String _normalizeChar(String char) {
    String normalized = char;
    normalized = normalized.replaceAll(RegExp(r'[‘’ʻ]'), "'");
    normalized = normalized.replaceAll(RegExp(r'[“”«»]'), '"');

    if (normalized == 'ў') return 'o‘';
    if (normalized == 'Ў') return 'O‘';
    if (normalized == 'ғ') return 'g‘';
    if (normalized == 'Ғ') return 'G‘';

    return normalized;
  }

  String _normalizeTokenForComparison(String token) {
    String partiallyNormalized = token.split('').map(_normalizeChar).join('');
    return partiallyNormalized.toLowerCase();
  }

  bool _isPunctuation(String? token) {
    if (token == null || token.isEmpty) return false;
    return RegExp(r"""^[.,;:!?()\[\]{}<>"\''`‘’“”«»~@#$%^&*_\-+=\|\/\\]+$""").hasMatch(token);
  }

  List<AlignedPair> _alignTokens(List<String> originalTokens, List<String> userTokens) {
    final int n = originalTokens.length;
    final int m = userTokens.length;
    List<List<int>> dp = List.generate(n + 1, (_) => List.filled(m + 1, 0));

    for (int i = 0; i <= n; i++) dp[i][0] = i;
    for (int j = 0; j <= m; j++) dp[0][j] = j;

    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        int substitutionCost = (_normalizeTokenForComparison(originalTokens[i - 1]) == _normalizeTokenForComparison(userTokens[j - 1])) ? 0 : 1;
        if (originalTokens[i - 1] == userTokens[j - 1]) substitutionCost = 0;

        dp[i][j] = min(dp[i - 1][j] + 1, min(dp[i][j - 1] + 1, dp[i - 1][j - 1] + substitutionCost));
      }
    }

    List<AlignedPair> aligned = [];
    int i = n, j = m;
    while (i > 0 || j > 0) {
      String? currentOrig = i > 0 ? originalTokens[i - 1] : null;
      String? currentUser = j > 0 ? userTokens[j - 1] : null;

      int substitutionCost = 1;
      if (i > 0 && j > 0) {
        substitutionCost = (_normalizeTokenForComparison(currentOrig!) == _normalizeTokenForComparison(currentUser!)) ? 0 : 1;
        if (currentOrig == currentUser) substitutionCost = 0;
      }

      if (i > 0 && j > 0 && dp[i][j] == dp[i - 1][j - 1] + substitutionCost) {
        aligned.add(AlignedPair(
            originalToken: currentOrig, userToken: currentUser,
            type: substitutionCost == 0 ? AlignedPairType.MATCH : AlignedPairType.SUBSTITUTION));
        i--; j--;
      } else if (j > 0 && dp[i][j] == dp[i][j - 1] + 1) {
        aligned.add(AlignedPair(originalToken: null, userToken: currentUser, type: AlignedPairType.INSERTION));
        j--;
      } else if (i > 0 && dp[i][j] == dp[i - 1][j] + 1) {
        aligned.add(AlignedPair(originalToken: currentOrig, userToken: null, type: AlignedPairType.DELETION));
        i--;
      } else {
        if (i > 0 && j > 0) {
          aligned.add(AlignedPair(originalToken: currentOrig, userToken: currentUser, type: AlignedPairType.SUBSTITUTION));
          i--; j--;
        } else if (i > 0) {
          aligned.add(AlignedPair(originalToken: currentOrig, userToken: null, type: AlignedPairType.DELETION)); i--;
        } else if (j > 0) {
          aligned.add(AlignedPair(originalToken: null, userToken: currentUser, type: AlignedPairType.INSERTION)); j--;
        } else { break; }
      }
    }
    return aligned.reversed.toList();
  }

  void _addError(DetectedError error) {
    _detectedErrors.add(error);
    _uniqueErrorCodes[error.type]?.add(error.specificRuleCode);
  }

  List<DetectedError> getDetailedErrors() {
    return List.from(_detectedErrors);
  }

  void _findUslubiyErrors() {
    List<String> userWords = _tokenize(userText).where((t) => !_isPunctuation(t)).toList();
    if (userWords.contains("abzal") && originalText.contains("afzal")) {
      _addError(DetectedError(type: ErrorType.USLUBIY, description: 'Paronimik xato (abzal/afzal)', originalFragment: "afzal", userFragment: "abzal", specificRuleCode: 'uslubiy_paronim_abzal_afzal'));
    }

    List<AlignedPair> tempAlignedForUslubiy = _alignTokens(_tokenize(originalText), _tokenize(userText));
    for (final pair in tempAlignedForUslubiy) {
      if (pair.type == AlignedPairType.SUBSTITUTION || pair.type == AlignedPairType.MATCH) {
        if (pair.originalToken != null && pair.userToken != null) {
          String origNorm = _normalizeTokenForComparison(pair.originalToken!);
          String userNorm = _normalizeTokenForComparison(pair.userToken!);
          if ((origNorm == 'sher' && userNorm == "she'r") || (origNorm == "she'r" && userNorm == 'sher')) {
            if (!_uniqueErrorCodes[ErrorType.USLUBIY]!.contains('uslubiy_paronim_sher_sher')) {
              _addError(DetectedError(type: ErrorType.USLUBIY, description: 'Paronimik xato (sher/she\'r)', originalFragment: pair.originalToken!, userFragment: pair.userToken!, specificRuleCode: 'uslubiy_paronim_sher_sher'));
            }
          }
        }
      }
    }
  }

  void analyze() {
    _detectedErrors.clear();
    _uniqueErrorCodes.forEach((key, value) => value.clear());

    List<String> originalTokens = _tokenize(originalText);
    List<String> userTokens = _tokenize(userText);

    if (originalTokens.isEmpty && userTokens.isEmpty) return;

    if (originalTokens.isEmpty) {
      userTokens.forEach((userToken) {
        _addError(DetectedError(type: _isPunctuation(userToken) ? ErrorType.PUNKTUATSION : ErrorType.IMLO, description: _isPunctuation(userToken) ? 'Ortiqcha tinish belgisi (original bo\'sh)' : 'Ortiqcha so\'z (original bo\'sh)', originalFragment: '', userFragment: userToken, specificRuleCode: _isPunctuation(userToken) ? 'punkt_ortiqcha_umumiy' : 'imlo_ortiqcha_soz_umumiy'));
      });
      return;
    }
    if (userTokens.isEmpty) {
      bool imloMissingWordsAdded = false;
      for (String origToken in originalTokens) {
        if (_isPunctuation(origToken)) {
          _addError(DetectedError(type: ErrorType.PUNKTUATSION, description: 'Tinish belgisi tushib qolgan (foydalanuvchi matni bo\'sh)', originalFragment: origToken, userFragment: '', specificRuleCode: 'punkt_tushibqolgan_umumiy'));
        } else {
          if (!imloMissingWordsAdded) {
            _addError(DetectedError(type: ErrorType.IMLO, description: 'Barcha so\'zlar tushib qolgan', originalFragment: originalText, userFragment: '', specificRuleCode: 'imlo_barcha_soz_tushibqolgan'));
            imloMissingWordsAdded = true;
          }
        }
      }
      return;
    }

    List<AlignedPair> alignedList = _alignTokens(originalTokens, userTokens);
    int matchCount = alignedList.where((p) => p.type == AlignedPairType.MATCH).length;
    double matchRatio = originalTokens.isNotEmpty ? matchCount / originalTokens.length : 0.0;

    bool isDissimilarGibberish = userTokens.length == 1 &&
        !_isPunctuation(userTokens.first) &&
        originalTokens.length > CATASTROPHIC_MIN_ORIGINAL_TOKENS &&
        matchRatio < DISSIMILARITY_MATCH_RATIO_THRESHOLD;

    bool isGenerallyDissimilar = userTokens.length <= DISSIMILARITY_MIN_USER_TOKENS &&
        (userTokens.length < originalTokens.length * DISSIMILARITY_LENGTH_RATIO_THRESHOLD || matchRatio < DISSIMILARITY_MATCH_RATIO_THRESHOLD);


    if (isDissimilarGibberish || (isGenerallyDissimilar && userTokens.length < originalTokens.length * 0.5 && matchCount < 2) ) { // Stricter condition for general dissimilarity
      _addError(DetectedError(type: ErrorType.IMLO, description: 'Matn originalga umuman mos kelmaydi', originalFragment: originalTokens.take(5).join(" ") + "...", userFragment: userTokens.join(" "), specificRuleCode: 'imlo_katastrofik_nomuvofiqlik'));
      originalTokens.where(_isPunctuation).forEach((p) {
        _addError(DetectedError(type: ErrorType.PUNKTUATSION, description: "Tinish belgisi tushib qolgan (katastrofik nomuvofiqlik)", originalFragment: p, userFragment: "", specificRuleCode: "punkt_tushibqolgan_katastrofik"));
      });
      _findUslubiyErrors();
      return;
    }

    List<String> deletedWordBuffer = [];
    List<String> insertedWordBuffer = [];

    for (final pair in alignedList) {
      final String? originalToken = pair.originalToken;
      final String? userToken = pair.userToken;

      if (pair.type == AlignedPairType.MATCH || pair.type == AlignedPairType.SUBSTITUTION) {
        if (deletedWordBuffer.isNotEmpty) {
          _addError(DetectedError(type: ErrorType.IMLO, description: 'So\'z(lar) tushib qolgan', originalFragment: deletedWordBuffer.join(' '), userFragment: '', specificRuleCode: 'imlo_tushibqolgan_guruh'));
          deletedWordBuffer.clear();
        }
        if (insertedWordBuffer.isNotEmpty) {
          _addError(DetectedError(type: ErrorType.IMLO, description: 'Ortiqcha so\'z(lar)', originalFragment: '', userFragment: insertedWordBuffer.join(' '), specificRuleCode: 'imlo_ortiqcha_guruh'));
          insertedWordBuffer.clear();
        }
      }

      switch (pair.type) {
        case AlignedPairType.DELETION:
          if (originalToken == null) continue;
          if (_isPunctuation(originalToken)) {
            _addError(DetectedError(type: ErrorType.PUNKTUATSION, description: 'Tinish belgisi tushib qolgan', originalFragment: originalToken, userFragment: '', specificRuleCode: 'punkt_tushibqolgan_umumiy'));
          } else {
            deletedWordBuffer.add(originalToken);
          }
          break;
        case AlignedPairType.INSERTION:
          if (userToken == null) continue;
          if (_isPunctuation(userToken)) {
            _addError(DetectedError(type: ErrorType.PUNKTUATSION, description: 'Ortiqcha tinish belgisi', originalFragment: '', userFragment: userToken, specificRuleCode: 'punkt_ortiqcha_umumiy'));
          } else {
            insertedWordBuffer.add(userToken);
          }
          break;
        case AlignedPairType.MATCH:
          if (originalToken == null || userToken == null) continue;
          if (originalToken.toLowerCase() == userToken.toLowerCase() && originalToken != userToken && !_isPunctuation(originalToken)) {
            _addError(DetectedError(type: ErrorType.IMLO, description: 'Bosh harf imlosida xato', originalFragment: originalToken, userFragment: userToken, specificRuleCode: 'imlo_bosh_harf_umumiy'));
          }
          if (originalToken != userToken && !_isPunctuation(originalToken) && !_isPunctuation(userToken)) {
            bool graphicErrorFound = false;
            if ((originalToken.contains('o‘') || originalToken.contains('O‘')) && (userToken.contains("o'") || userToken.contains("O'"))) {
              if (_normalizeTokenForComparison(originalToken.replaceAll(RegExp("[oO](?:‘|ʻ)"), "o'")) == _normalizeTokenForComparison(userToken)) {
                _addError(DetectedError(type: ErrorType.GRAFIK, description: "O‘ harfi o'rniga o' ishlatilgan", originalFragment: originalToken, userFragment: userToken, specificRuleCode: "grafik_o_apostrof"));
                graphicErrorFound = true;
              }
            }
            if (!graphicErrorFound && (originalToken.contains('g‘') || originalToken.contains('G‘')) && (userToken.contains("g'") || userToken.contains("G'"))) {
              if (_normalizeTokenForComparison(originalToken.replaceAll(RegExp("[gG](?:‘|ʻ)"), "g'")) == _normalizeTokenForComparison(userToken)) {
                _addError(DetectedError(type: ErrorType.GRAFIK, description: "G‘ harfi o'rniga g' ishlatilgan", originalFragment: originalToken, userFragment: userToken, specificRuleCode: "grafik_g_apostrof"));
                graphicErrorFound = true;
              }
            }
          }
          break;
        case AlignedPairType.SUBSTITUTION:
          if (originalToken == null || userToken == null) continue;
          bool origIsPunct = _isPunctuation(originalToken);
          bool userIsPunct = _isPunctuation(userToken);

          if (origIsPunct && userIsPunct) {
            if (originalToken != userToken) {
              _addError(DetectedError(type: ErrorType.PUNKTUATSION, description: 'Tinish belgisi noto\'g\'ri qo\'llanilgan', originalFragment: originalToken, userFragment: userToken, specificRuleCode: 'punkt_belgi_almashgan_umumiy'));
            }
          } else if (origIsPunct != userIsPunct) {
            _addError(DetectedError(type: ErrorType.IMLO, description: origIsPunct ? 'Tinish belgisi o\'rniga so\'z yozilgan' : 'So\'z o\'rniga tinish belgisi yozilgan', originalFragment: originalToken, userFragment: userToken, specificRuleCode: 'imlo_soz_va_punkt_almashuvi_umumiy'));
          } else {
            bool errorProcessed = false;
            if ((originalToken.contains('o‘') || originalToken.contains('O‘')) && (userToken.contains("o'") || userToken.contains("O'"))) {
              if (_normalizeTokenForComparison(originalToken.replaceAll(RegExp("[oO](?:‘|ʻ)"), "o'")) == _normalizeTokenForComparison(userToken)) {
                _addError(DetectedError(type: ErrorType.GRAFIK, description: "O‘ harfi o'rniga o' ishlatilgan", originalFragment: originalToken, userFragment: userToken, specificRuleCode: "grafik_o_apostrof"));
                errorProcessed = true;
              }
            }
            if (!errorProcessed && (originalToken.contains('g‘') || originalToken.contains('G‘')) && (userToken.contains("g'") || userToken.contains("G'"))) {
              if (_normalizeTokenForComparison(originalToken.replaceAll(RegExp("[gG](?:‘|ʻ)"), "g'")) == _normalizeTokenForComparison(userToken)) {
                _addError(DetectedError(type: ErrorType.GRAFIK, description: "G‘ harfi o'rniga g' ishlatilgan", originalFragment: originalToken, userFragment: userToken, specificRuleCode: "grafik_g_apostrof"));
                errorProcessed = true;
              }
            }
            if (errorProcessed) break;

            if (originalToken.toLowerCase() == userToken.toLowerCase() && originalToken != userToken) {
              _addError(DetectedError(type: ErrorType.IMLO, description: 'Bosh harf imlosida xato', originalFragment: originalToken, userFragment: userToken, specificRuleCode: 'imlo_bosh_harf_umumiy'));
              errorProcessed = true;
            }

            if (!errorProcessed) {
              double penaltyMultiplier = 1.0;
              String errorDesc = 'So\'zni noto\'g\'ri yozish';
              String specificCode = 'imlo_soz_almashtirish_${_normalizeTokenForComparison(originalToken)}_vs_${_normalizeTokenForComparison(userToken)}';
              final Map<String, List<String>> adjacentKeys = { 'z': ['x', 's', 'a'], 'x': ['z', 'c', 's', 'd'], 's':['a','d','x','w'],};

              String normOrig = _normalizeTokenForComparison(originalToken);
              String normUser = _normalizeTokenForComparison(userToken);

              if (normOrig.length == normUser.length) {
                int diffs = 0; String? dO, dU;
                for(int k=0; k<normOrig.length; k++) { if(normOrig[k] != normUser[k]) {diffs++; dO=normOrig[k]; dU=normUser[k];}}
                if (diffs == 1 && dO != null && dU != null && (adjacentKeys[dO]?.contains(dU) ?? false)) {
                  penaltyMultiplier = 0.5; errorDesc = 'Klaviatura yaqinligi xatosi'; specificCode = 'imlo_klaviatura_yaqinlik';
                }
              }

              if (normOrig == 'zamon') {
                if (normUser == 'ramon') {specificCode = 'imlo_zamon_ramon'; errorDesc = "So'zni noto'g'ri yozish (Zamon vs Ramon)";}
                else if (normUser == 'xamon') {penaltyMultiplier = 0.5; errorDesc = 'Klaviatura yaqinligi (Zamon vs Xamon)'; specificCode = 'imlo_zamon_xamon_yaqinlik';}
              } else if (normOrig.contains('h') && normUser.contains('x') && normOrig.replaceAll('h', 'x') == normUser) {
                errorDesc = 'h o\'rniga x yozilgan'; specificCode = 'imlo_h_x_almashinuvi';
              } else if (normOrig.contains('x') && normUser.contains('h') && normOrig.replaceAll('x', 'h') == normUser) {
                errorDesc = 'x o\'rniga h yozilgan'; specificCode = 'imlo_h_x_almashinuvi';
              }

              String origWithoutTutuq = normOrig.replaceAll(RegExp("['ʼ‘’]"), "");
              String userWithoutTutuq = normUser.replaceAll(RegExp("['ʼ‘’]"), "");
              if (origWithoutTutuq == userWithoutTutuq) {
                if (normOrig.contains(RegExp("['ʼ‘’]")) && !normUser.contains(RegExp("['ʼ‘’]"))) {
                  errorDesc = 'Tutuq belgisi tushib qolgan'; specificCode = 'imlo_tutuq_tushibqolgan_umumiy';
                } else if (!normOrig.contains(RegExp("['ʼ‘’]")) && normUser.contains(RegExp("['ʼ‘’]"))) {
                  errorDesc = 'O\'rinsiz tutuq belgisi ishlatilgan'; specificCode = 'imlo_tutuq_orinsiz_umumiy';
                }
              }
              _addError(DetectedError(type: ErrorType.IMLO, description: errorDesc, originalFragment: originalToken, userFragment: userToken, specificRuleCode: specificCode, penaltyMultiplier: penaltyMultiplier));
            }
          }
          break;
      }
    }
    if (deletedWordBuffer.isNotEmpty) {
      _addError(DetectedError(type: ErrorType.IMLO, description: 'So\'z(lar) tushib qolgan', originalFragment: deletedWordBuffer.join(' '), userFragment: '', specificRuleCode: 'imlo_tushibqolgan_guruh'));
    }
    if (insertedWordBuffer.isNotEmpty) {
      _addError(DetectedError(type: ErrorType.IMLO, description: 'Ortiqcha so\'z(lar)', originalFragment: '', userFragment: insertedWordBuffer.join(' '), specificRuleCode: 'imlo_ortiqcha_guruh'));
    }
    _findUslubiyErrors();
  }

  int get imloErrorCount => _uniqueErrorCodes[ErrorType.IMLO]?.length ?? 0;
  int get punktuatsionErrorCount => _uniqueErrorCodes[ErrorType.PUNKTUATSION]?.length ?? 0;
  int get uslubiyErrorCount => _uniqueErrorCodes[ErrorType.USLUBIY]?.length ?? 0;
  int get grafikErrorCount => _uniqueErrorCodes[ErrorType.GRAFIK]?.length ?? 0;

  int _calculate5PointInternal(int imloErrors, int punktErrors, int uslubiyErrors, int grafikErrors, int changesCount) {
    if (_uniqueErrorCodes[ErrorType.IMLO]!.contains('imlo_katastrofik_nomuvofiqlik')) return 1;

    if (imloErrors == 0 && punktErrors == 0 && uslubiyErrors == 0 && grafikErrors == 0) {
      if (changesCount >= 3) return 4;
      return 5;
    }
    if ((imloErrors == 1 && punktErrors == 0 && uslubiyErrors == 0 && grafikErrors == 0) || (imloErrors == 0 && punktErrors == 1 && uslubiyErrors == 0 && grafikErrors == 0)) {
      // Qoidada faqat imlo va punktuatsiya deyilgan "bitta xato" uchun.
      // "qo'pol bo'lmagan bitta imlo YOKI bitta punktuatsion xatosi bo'lgan"
      if (changesCount >= 3) return 4;
      return 5;
    }

    int ishoratErrors = punktErrors + uslubiyErrors + grafikErrors;
    if (imloErrors <= 2 && (imloErrors + ishoratErrors) <= 4) return 4;
    if (imloErrors <= 4 && (imloErrors + ishoratErrors) <= 8) return 3;
    if (imloErrors <= 7 && (imloErrors + ishoratErrors) <= 14) return 2;
    return 1;
  }

  int evaluate5PointScale({int changesCount = 0}) {
    int baseMark = _calculate5PointInternal(imloErrorCount, punktuatsionErrorCount, uslubiyErrorCount, grafikErrorCount, changesCount);
    if (changesCount > 5 && baseMark > 1) baseMark--;
    return baseMark;
  }

  int evaluate100PointScaleMethod2() {
    if (_uniqueErrorCodes[ErrorType.IMLO]!.contains('imlo_katastrofik_nomuvofiqlik')) return 0;
    int imlo = imloErrorCount;
    int ishoraviy = punktuatsionErrorCount + uslubiyErrorCount + grafikErrorCount;
    if (imlo >= 10) return 0;
    if (imlo <= 2 && ishoraviy <= 2) return 100;
    if (imlo <= 4 && ishoraviy <= 3) return 80;
    if (imlo <= 7 && ishoraviy <= 5) return 60;
    if (imlo <= 9 && ishoraviy <= 7) return 50;
    return 0;
  }

  double evaluate100PointScaleMethod3() {
    if (_uniqueErrorCodes[ErrorType.IMLO]!.contains('imlo_katastrofik_nomuvofiqlik')) return 0.0;
    double score = 100.0;
    for (var error in _detectedErrors) {
      switch (error.type) {
        case ErrorType.IMLO: score -= 2.5 * error.penaltyMultiplier; break;
        case ErrorType.PUNKTUATSION: score -= 2.0 * error.penaltyMultiplier; break;
        case ErrorType.USLUBIY: score -= 1.5 * error.penaltyMultiplier; break;
        case ErrorType.GRAFIK: score -= 1.5 * error.penaltyMultiplier; break;
      }
    }
    return score.clamp(0.0, 100.0);
  }

  void printDetailedErrors() {
    print('Aniqlangan xatolar (${_detectedErrors.length} ta):');
    Set<DetectedError> uniquePrintableErrors = Set.from(_detectedErrors);
    for (var error in uniquePrintableErrors) print(error);
    print('\n--- Xulosaviy hisobot (unikal xato KODLARI bo\'yicha) ---');
    print('Jami unikal imlo xato kodlari: $imloErrorCount');
    print('Jami unikal punktuatsion xato kodlari: $punktuatsionErrorCount');
    print('Jami unikal uslubiy xato kodlari: $uslubiyErrorCount');
    print('Jami unikal grafik xato kodlari: $grafikErrorCount');
  }
}
