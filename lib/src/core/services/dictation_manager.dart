import 'dart:math';

import 'package:dication/src/core/models/detected_error.dart';
import 'package:dication/src/core/models/error_type.dart';

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
  static const int DISSIMILARITY_MIN_USER_TOKENS = 3;
  static const double DISSIMILARITY_MATCH_RATIO_THRESHOLD = 0.1;

  DiktantEvaluator({
    required this.originalText,
    required this.userText,
  });

  List<String> _tokenize(String text) {
    if (text.trim().isEmpty) return [];
    final RegExp punctuationRegex = RegExp(r"""([,\.:;!\?()\"'`‘’“”«»]|(?<!\w)'(?!\w))""");
    String spacedText = text.replaceAllMapped(punctuationRegex, (match) => " ${match.group(0)} ");
    return spacedText.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  }

  String _normalizeChar(String char) {
    String normalized = char;
    normalized = normalized.replaceAll(RegExp(r'[‘’ʻ]'), "'");
    normalized = normalized.replaceAll(RegExp(r'[“”«»]'), '"');
    normalized = normalized.replaceAll('ў', 'o‘').replaceAll('Ў', 'O‘');
    normalized = normalized.replaceAll('ғ', 'g‘').replaceAll('Ғ', 'G‘');
    return normalized;
  }

  String _normalizeTokenForComparison(String token) {
    return token.toLowerCase().split('').map(_normalizeChar).join('');
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

        dp[i][j] = min(
          dp[i - 1][j] + 1, // Deletion of originalTokens[i-1]
          min(
            dp[i][j - 1] + 1, // Insertion of userTokens[j-1]
            dp[i - 1][j - 1] + substitutionCost, // Substitution or Match
          ),
        );
      }
    }

    // Backtrack to find the alignment
    List<AlignedPair> aligned = [];
    int i = n, j = m;
    while (i > 0 || j > 0) {
      String? currentOrig = i > 0 ? originalTokens[i - 1] : null;
      String? currentUser = j > 0 ? userTokens[j - 1] : null;

      int substitutionCost = (i > 0 && j > 0)
          ? ((_normalizeTokenForComparison(currentOrig!) == _normalizeTokenForComparison(currentUser!)) ? 0 : 1)
          : 1; // If one is null, cost is 1 for substitution logic
      if (i > 0 && j > 0 && currentOrig == currentUser) substitutionCost = 0;

      if (i > 0 && j > 0 && dp[i][j] == dp[i - 1][j - 1] + substitutionCost) {
        aligned.add(AlignedPair(
          originalToken: currentOrig,
          userToken: currentUser,
          type: substitutionCost == 0 ? AlignedPairType.MATCH : AlignedPairType.SUBSTITUTION,
        ));
        i--;
        j--;
      } else if (j > 0 && dp[i][j] == dp[i][j - 1] + 1) {
        // Prefer insertion if costs are equal with deletion
        aligned.add(AlignedPair(
          originalToken: null,
          userToken: currentUser,
          type: AlignedPairType.INSERTION,
        ));
        j--;
      } else if (i > 0 && dp[i][j] == dp[i - 1][j] + 1) {
        aligned.add(AlignedPair(
          originalToken: currentOrig,
          userToken: null,
          type: AlignedPairType.DELETION,
        ));
        i--;
      } else {
        // Fallback for safety, should ideally not be reached if DP table is correct
        if (i > 0 && j > 0) {
          // Assume substitution if stuck
          aligned.add(AlignedPair(originalToken: currentOrig, userToken: currentUser, type: AlignedPairType.SUBSTITUTION));
          i--;
          j--;
        } else if (i > 0) {
          aligned.add(AlignedPair(originalToken: currentOrig, userToken: null, type: AlignedPairType.DELETION));
          i--;
        } else if (j > 0) {
          aligned.add(AlignedPair(originalToken: null, userToken: currentUser, type: AlignedPairType.INSERTION));
          j--;
        } else {
          break;
        }
      }
    }
    return aligned.reversed.toList();
  }

  void _addError(DetectedError error) {
    _detectedErrors.add(error);
    // Using the enum directly as key
    _uniqueErrorCodes[error.type]?.add(error.specificRuleCode);
  }

  List<DetectedError> getDetailedErrors() {
    // Return a copy to prevent external modification
    return List.from(_detectedErrors);
  }

  void _findUslubiyErrors() {
    // This function should ideally analyze the whole text or aligned pairs
    // For now, it's a placeholder or uses _detectedErrors which might be too late
    // Example (very basic, needs proper implementation):
    List<String> userWords = _tokenize(userText).where((t) => !_isPunctuation(t)).toList();
    if (userWords.contains("abzal") && originalText.contains("afzal")) {
      _addError(DetectedError(
        type: ErrorType.USLUBIY,
        description: 'Paronimik xato (abzal/afzal)',
        originalFragment: "afzal",
        // Assuming "afzal" was expected
        userFragment: "abzal",
        specificRuleCode: 'uslubiy_paronim_abzal_afzal',
      ));
    }

    // Your "sher" vs "she'r" logic:
    // This should be more robust, checking aligned pairs rather than all detected IMLO errors.
    // For now, let's adapt it slightly.
    for (final pair in _alignTokens(_tokenize(originalText), _tokenize(userText))) {
      // Re-align for this specific check or pass alignedList
      if (pair.type == AlignedPairType.SUBSTITUTION || pair.type == AlignedPairType.MATCH) {
        if (pair.originalToken != null && pair.userToken != null) {
          String origNorm = _normalizeTokenForComparison(pair.originalToken!);
          String userNorm = _normalizeTokenForComparison(pair.userToken!);
          if ((origNorm == 'sher' && userNorm == "she'r") || (origNorm == "she'r" && userNorm == 'sher')) {
            // Check if this error (based on fragments) is already added as USLUBIY
            bool alreadyAdded = _uniqueErrorCodes[ErrorType.USLUBIY]!.contains('uslubiy_paronim_sher_sher');
            if (!alreadyAdded) {
              _addError(DetectedError(
                type: ErrorType.USLUBIY,
                description: 'Paronimik xato (sher/she\'r)',
                originalFragment: pair.originalToken!,
                userFragment: pair.userToken!,
                specificRuleCode: 'uslubiy_paronim_sher_sher', // One code for this type
              ));
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
        _addError(DetectedError(
            type: _isPunctuation(userToken) ? ErrorType.PUNKTUATSION : ErrorType.IMLO,
            description: _isPunctuation(userToken) ? 'Ortiqcha tinish belgisi (original bo\'sh)' : 'Ortiqcha so\'z (original bo\'sh)',
            originalFragment: '',
            userFragment: userToken,
            specificRuleCode: _isPunctuation(userToken) ? 'punkt_ortiqcha_umumiy' : 'imlo_ortiqcha_soz_umumiy'));
      });
      return;
    }
    if (userTokens.isEmpty) {
      // All original words/punctuations are considered missing
      bool imloMissingWordsAdded = false;
      for (String origToken in originalTokens) {
        if (_isPunctuation(origToken)) {
          _addError(DetectedError(
              type: ErrorType.PUNKTUATSION,
              description: 'Tinish belgisi tushib qolgan (foydalanuvchi matni bo\'sh)',
              originalFragment: origToken,
              userFragment: '',
              specificRuleCode: 'punkt_tushibqolgan_umumiy'));
        } else {
          if (!imloMissingWordsAdded) {
            // Add "missing words" error only once
            _addError(DetectedError(
                type: ErrorType.IMLO,
                description: 'Barcha so\'zlar tushib qolgan',
                originalFragment: originalText,
                userFragment: '',
                specificRuleCode: 'imlo_barcha_soz_tushibqolgan'));
            imloMissingWordsAdded = true;
          }
        }
      }
      return;
    }

    List<AlignedPair> alignedList = _alignTokens(originalTokens, userTokens);

    // Heuristic for highly dissimilar texts based on alignment results
    int matchCount = alignedList.where((p) => p.type == AlignedPairType.MATCH).length;
    double matchRatio = originalTokens.isNotEmpty ? matchCount / originalTokens.length : 0;

    // If user text is "wiukdgfusyikjdhfiksujvh" (1 token) vs long original.
    // matchCount will be 0 or 1 (if by chance that gibberish matches a short original word normalized).
    // matchRatio will be very low.
    if (userTokens.length <= DISSIMILARITY_MIN_USER_TOKENS &&
        (userTokens.length < originalTokens.length * DISSIMILARITY_LENGTH_RATIO_THRESHOLD || matchRatio < DISSIMILARITY_MATCH_RATIO_THRESHOLD)) {
      // Option 1: Treat all user tokens as incorrect substitutions or insertions, and all unmatched original tokens as deletions.
      // Option 2: Simpler - Mark as a "catastrophic mismatch"

      // For "wiukdgfusyikjdhfiksujvh":
      if (userTokens.length == 1 && !_isPunctuation(userTokens.first) && originalTokens.length > 5 /* arbitrary threshold */) {
        _addError(DetectedError(
            type: ErrorType.IMLO,
            description: 'Matn originalga umuman mos kelmaydi (ma\'nosiz so\'z kiritilgan)',
            originalFragment: originalTokens.join(" "),
            // Show a part of original
            userFragment: userTokens.first,
            specificRuleCode: 'imlo_katastrofik_nomuvofiqlik'));
        // Add all original punctuations as missed (if any) to be fair
        originalTokens.where(_isPunctuation).forEach((p) {
          _addError(DetectedError(
              type: ErrorType.PUNKTUATSION,
              description: "Tinish belgisi tushib qolgan (katastrofik nomuvofiqlik)",
              originalFragment: p,
              userFragment: "",
              specificRuleCode: "punkt_tushibqolgan_katastrofik"));
        });
        _findUslubiyErrors(); // Call it, though it might not find much
        return; // Stop further analysis
      }
    }

    // Proceed with detailed error analysis for normally aligned texts
    List<String> deletedWordBuffer = [];
    List<String> insertedWordBuffer = [];

    for (final pair in alignedList) {
      final String? originalToken = pair.originalToken;
      final String? userToken = pair.userToken;

      // Process buffered deletions/insertions before a MATCH or SUBSTITUTION
      if (pair.type == AlignedPairType.MATCH || pair.type == AlignedPairType.SUBSTITUTION) {
        if (deletedWordBuffer.isNotEmpty) {
          _addError(DetectedError(
              type: ErrorType.IMLO,
              description: 'So\'z(lar) tushib qolgan',
              originalFragment: deletedWordBuffer.join(' '),
              userFragment: '',
              specificRuleCode: 'imlo_tushibqolgan_guruh'));
          deletedWordBuffer.clear();
        }
        if (insertedWordBuffer.isNotEmpty) {
          _addError(DetectedError(
              type: ErrorType.IMLO,
              description: 'Ortiqcha so\'z(lar)',
              originalFragment: '',
              userFragment: insertedWordBuffer.join(' '),
              specificRuleCode: 'imlo_ortiqcha_guruh'));
          insertedWordBuffer.clear();
        }
      }

      switch (pair.type) {
        case AlignedPairType.DELETION:
          if (originalToken == null) continue; // Should not happen
          if (_isPunctuation(originalToken)) {
            _addError(DetectedError(
                type: ErrorType.PUNKTUATSION,
                description: 'Tinish belgisi tushib qolgan',
                originalFragment: originalToken,
                userFragment: '',
                specificRuleCode: 'punkt_tushibqolgan_umumiy'));
          } else {
            deletedWordBuffer.add(originalToken);
          }
          break;
        case AlignedPairType.INSERTION:
          if (userToken == null) continue; // Should not happen
          if (_isPunctuation(userToken)) {
            _addError(DetectedError(
                type: ErrorType.PUNKTUATSION,
                description: 'Ortiqcha tinish belgisi',
                originalFragment: '',
                userFragment: userToken,
                specificRuleCode: 'punkt_ortiqcha_umumiy'));
          } else {
            insertedWordBuffer.add(userToken);
          }
          break;
        case AlignedPairType.MATCH:
          if (originalToken == null || userToken == null) continue;
          // Even in a MATCH (normalized tokens are same), check for original case or minor diffs if not caught by normalization
          // Example: Bosh harf xatosi, agar normallashtirish faqat lowerCase qilsa.
          if (originalToken.toLowerCase() == userToken.toLowerCase() && originalToken != userToken && !_isPunctuation(originalToken)) {
            _addError(DetectedError(
                type: ErrorType.IMLO,
                description: 'Bosh harf imlosida xato',
                originalFragment: originalToken,
                userFragment: userToken,
                specificRuleCode: 'imlo_bosh_harf_umumiy'));
          }
          // Check for subtle graphic errors if `_normalizeTokenForComparison` doesn't catch them but `originalToken != userToken`
          // For o‘/g‘, normalization should handle it. If `o'` vs `o‘` is a graphic error, it implies normalization makes them same.
          // But if `originalToken` was `salom` and `userToken` was `sаlom` (cyrillic 'a'), normalization might make them different.
          // If `originalToken != userToken` despite `MATCH` type, it means `_normalizeTokenForComparison` made them equal.
          // This could be a subtle graphic or character encoding issue.
          if (originalToken != userToken && !_isPunctuation(originalToken) && !_isPunctuation(userToken)) {
            // Check for subtle graphic errors for `o'` vs `o‘` type issues if not already a case error
            bool graphicErrorFound = false;
            if ((originalToken.contains('o‘') || originalToken.contains('O‘')) && (userToken.contains("o'") || userToken.contains("O'"))) {
              if (_normalizeTokenForComparison(originalToken.replaceAll(RegExp("[oO]‘"), "o'")) == _normalizeTokenForComparison(userToken)) {
                // Simplified check
                _addError(DetectedError(
                    type: ErrorType.GRAFIK,
                    description: "O‘ harfi o'rniga o' ishlatilgan",
                    originalFragment: originalToken,
                    userFragment: userToken,
                    specificRuleCode: "grafik_o_apostrof"));
                graphicErrorFound = true;
              }
            }
            if (!graphicErrorFound &&
                (originalToken.contains('g‘') || originalToken.contains('G‘')) &&
                (userToken.contains("g'") || userToken.contains("G'"))) {
              if (_normalizeTokenForComparison(originalToken.replaceAll(RegExp("[gG]‘"), "g'")) == _normalizeTokenForComparison(userToken)) {
                _addError(DetectedError(
                    type: ErrorType.GRAFIK,
                    description: "G‘ harfi o'rniga g' ishlatilgan",
                    originalFragment: originalToken,
                    userFragment: userToken,
                    specificRuleCode: "grafik_g_apostrof"));
                graphicErrorFound = true;
              }
            }
            // If no specific graphic/case error but tokens differ, it's a subtle imlo issue (e.g. invisible char)
            // if (!graphicErrorFound && !(originalToken.toLowerCase() == userToken.toLowerCase() && originalToken != userToken)) {
            //    _addError(DetectedError(type: ErrorType.IMLO, description: 'So\'zda nozik farq (normallashtirishdan keyin mos)', originalFragment: originalToken, userFragment: userToken, specificRuleCode: 'imlo_nozik_farq_normallashtirilgan'));
            // }
          }
          break;
        case AlignedPairType.SUBSTITUTION:
          if (originalToken == null || userToken == null) continue;

          bool origIsPunct = _isPunctuation(originalToken);
          bool userIsPunct = _isPunctuation(userToken);

          if (origIsPunct && userIsPunct) {
            if (originalToken != userToken) {
              // Should always be true for SUBSTITUTION of punct
              _addError(DetectedError(
                  type: ErrorType.PUNKTUATSION,
                  description: 'Tinish belgisi noto\'g\'ri qo\'llanilgan',
                  originalFragment: originalToken,
                  userFragment: userToken,
                  specificRuleCode: 'punkt_belgi_almashgan_umumiy'));
            }
          } else if (origIsPunct != userIsPunct) {
            _addError(DetectedError(
                type: ErrorType.IMLO,
                description: origIsPunct ? 'Tinish belgisi o\'rniga so\'z yozilgan' : 'So\'z o\'rniga tinish belgisi yozilgan',
                originalFragment: originalToken,
                userFragment: userToken,
                specificRuleCode: 'imlo_soz_va_punkt_almashuvi_umumiy'));
          } else {
            // Both are words, and they are different (SUBSTITUTION)
            bool errorProcessed = false;
            // 1. Grafik xatolar (agar bu almashtirishga sabab bo'lsa)
            if ((originalToken.contains('o‘') || originalToken.contains('O‘')) && (userToken.contains("o'") || userToken.contains("O'"))) {
              // If substitution was due to this, and normalized forms (after this fix) would match
              if (_normalizeTokenForComparison(originalToken.replaceAll(RegExp("[oO]‘"), "o'")) == _normalizeTokenForComparison(userToken)) {
                _addError(DetectedError(
                    type: ErrorType.GRAFIK,
                    description: "O‘ harfi o'rniga o' ishlatilgan",
                    originalFragment: originalToken,
                    userFragment: userToken,
                    specificRuleCode: "grafik_o_apostrof"));
                errorProcessed = true;
              }
            }
            if (!errorProcessed &&
                (originalToken.contains('g‘') || originalToken.contains('G‘')) &&
                (userToken.contains("g'") || userToken.contains("G'"))) {
              if (_normalizeTokenForComparison(originalToken.replaceAll(RegExp("[gG]‘"), "g'")) == _normalizeTokenForComparison(userToken)) {
                _addError(DetectedError(
                    type: ErrorType.GRAFIK,
                    description: "G‘ harfi o'rniga g' ishlatilgan",
                    originalFragment: originalToken,
                    userFragment: userToken,
                    specificRuleCode: "grafik_g_apostrof"));
                errorProcessed = true;
              }
            }
            if (errorProcessed) break; // Grafik xato topildi, boshqa imlo qidirmaymiz

            // 2. Bosh harf xatosi (agar faqat shu farq bo'lsa)
            if (originalToken.toLowerCase() == userToken.toLowerCase() && originalToken != userToken) {
              _addError(DetectedError(
                  type: ErrorType.IMLO,
                  description: 'Bosh harf imlosida xato',
                  originalFragment: originalToken,
                  userFragment: userToken,
                  specificRuleCode: 'imlo_bosh_harf_umumiy'));
              errorProcessed = true;
            }
            // if (errorProcessed) break; // Agar faqat bosh harf xatosi bo'lsa va boshqa xato bo'lmasa, to'xtash mumkin.
            // Lekin "Salom" vs "selom" ham bosh harf, ham imlo bo'lishi mumkin.
            // Qoidalar imlo asosiy deydi.

            // 3. Asosiy imlo xatolari
            if (!errorProcessed) {
              // Agar grafik yoki faqat bosh harf xatosi bo'lmasa
              double penaltyMultiplier = 1.0;
              String errorDesc = 'So\'zni noto\'g\'ri yozish';
              // Unique code for each substitution pair if not a special case
              String specificCode =
                  'imlo_soz_almashtirish_${_normalizeTokenForComparison(originalToken)}_vs_${_normalizeTokenForComparison(userToken)}';

              final Map<String, List<String>> adjacentKeys = {
                // Simplified for example
                'z': ['x', 's', 'a'], 'x': ['z', 'c', 's', 'd'], 's': ['a', 'd', 'x', 'w'], /* ... more ...*/
              };

              String normOrig = _normalizeTokenForComparison(originalToken);
              String normUser = _normalizeTokenForComparison(userToken);

              if (normOrig.length == normUser.length) {
                int diffs = 0;
                String? dO, dU;
                for (int k = 0; k < normOrig.length; k++) {
                  if (normOrig[k] != normUser[k]) {
                    diffs++;
                    dO = normOrig[k];
                    dU = normUser[k];
                  }
                }
                if (diffs == 1 && dO != null && dU != null && (adjacentKeys[dO]?.contains(dU) ?? false)) {
                  penaltyMultiplier = 0.5;
                  errorDesc = 'Klaviatura yaqinligi xatosi';
                  specificCode = 'imlo_klaviatura_yaqinlik'; // Umumiy kod
                }
              }

              if (normOrig == 'zamon') {
                if (normUser == 'ramon') {
                  specificCode = 'imlo_zamon_ramon';
                  errorDesc = "So'zni noto'g'ri yozish (Zamon vs Ramon)";
                } else if (normUser == 'xamon') {
                  penaltyMultiplier = 0.5;
                  errorDesc = 'Klaviatura yaqinligi (Zamon vs Xamon)';
                  specificCode = 'imlo_zamon_xamon_yaqinlik';
                }
              } else if (normOrig.contains('h') && normUser.contains('x') && normOrig.replaceAll('h', 'x') == normUser) {
                errorDesc = 'h o\'rniga x yozilgan';
                specificCode = 'imlo_h_x_almashinuvi';
              } else if (normOrig.contains('x') && normUser.contains('h') && normOrig.replaceAll('x', 'h') == normUser) {
                errorDesc = 'x o\'rniga h yozilgan';
                specificCode = 'imlo_h_x_almashinuvi';
              }

              String origWithoutTutuq = normOrig.replaceAll(RegExp("['ʼ‘’]"), "");
              String userWithoutTutuq = normUser.replaceAll(RegExp("['ʼ‘’]"), "");
              if (origWithoutTutuq == userWithoutTutuq) {
                // Asos bir xil
                if (normOrig.contains(RegExp("['ʼ‘’]")) && !normUser.contains(RegExp("['ʼ‘’]"))) {
                  errorDesc = 'Tutuq belgisi tushib qolgan';
                  specificCode = 'imlo_tutuq_tushibqolgan_umumiy';
                } else if (!normOrig.contains(RegExp("['ʼ‘’]")) && normUser.contains(RegExp("['ʼ‘’]"))) {
                  errorDesc = 'O\'rinsiz tutuq belgisi ishlatilgan';
                  specificCode = 'imlo_tutuq_orinsiz_umumiy';
                }
              }
              _addError(DetectedError(
                  type: ErrorType.IMLO,
                  description: errorDesc,
                  originalFragment: originalToken,
                  userFragment: userToken,
                  specificRuleCode: specificCode,
                  penaltyMultiplier: penaltyMultiplier));
            }
          }
          break;
      }
    }
    // Qolgan bufferlarni tozalash
    if (deletedWordBuffer.isNotEmpty) {
      _addError(DetectedError(
          type: ErrorType.IMLO,
          description: 'So\'z(lar) tushib qolgan',
          originalFragment: deletedWordBuffer.join(' '),
          userFragment: '',
          specificRuleCode: 'imlo_tushibqolgan_guruh'));
    }
    if (insertedWordBuffer.isNotEmpty) {
      _addError(DetectedError(
          type: ErrorType.IMLO,
          description: 'Ortiqcha so\'z(lar)',
          originalFragment: '',
          userFragment: insertedWordBuffer.join(' '),
          specificRuleCode: 'imlo_ortiqcha_guruh'));
    }

    _findUslubiyErrors();
  }

  int get imloErrorCount => _uniqueErrorCodes[ErrorType.IMLO]!.length;

  int get punktuatsionErrorCount => _uniqueErrorCodes[ErrorType.PUNKTUATSION]!.length;

  int get uslubiyErrorCount => _uniqueErrorCodes[ErrorType.USLUBIY]!.length;

  int get grafikErrorCount => _uniqueErrorCodes[ErrorType.GRAFIK]!.length;

  // Baholash metodlari sizning avvalgi kodingizdan olingan va o'zgartirilmagan
  // Ularni ham qayta ko'rib chiqish kerak bo'lishi mumkin, ayniqsa "katastrofik nomuvofiqlik" holati uchun.
  // Masalan, agar `imlo_katastrofik_nomuvofiqlik` xatosi bo'lsa, baho avtomatik 1 yoki 0 bo'lishi kerak.

  int calculate5Point(int imloErrors, int punktErrors, int totalDetectedErrorsCount, int changesCount /*bu qayerdan keladi?*/) {
    // Agar katastrofik xato bo'lsa
    if (_uniqueErrorCodes[ErrorType.IMLO]!.contains('imlo_katastrofik_nomuvofiqlik')) {
      return 1; // Eng past baho
    }

    // Sizning qoidalaringiz asosida (biroz o'zgartirilgan va soddalashtirilgan)
    // «5» ball: a) mutlaqo xatosiz; b) qo‘pol bo‘lmagan bitta imlo yoki bitta punktuatsion xatosi
    if (imloErrors == 0 && punktErrors == 0) {
      if (changesCount >= 3) return 4; // "Agar diktantda uch va undan ortiq tuzatish bo‘lsa, «5» ball qo‘yilmaydi."
      return 5;
    }
    if ((imloErrors == 1 && punktErrors == 0) || (imloErrors == 0 && punktErrors == 1)) {
      // "qo'pol bo'lmagan" shartini hozircha soddalashtiramiz
      if (changesCount >= 3) return 4;
      return 5;
    }

    // «4» ball: ikkita imlo va ikkita ishorat xatosi. Umumiy <= 4, imlo <= 2.
    // "ishorat" = punktuatsion + uslubiy + grafik
    int ishoratErrors = punktErrors + uslubiyErrorCount + grafikErrorCount;
    if (imloErrors <= 2 && (imloErrors + ishoratErrors) <= 4) {
      return 4;
    }

    // «3» ball: to‘rtta imlo hamda to‘rtta punktuatsion. Umumiy <= 8 (3 imlo+5 punkt), imlo <= 4.
    if (imloErrors <= 4 && (imloErrors + ishoratErrors) <= 8) {
      return 3;
    }
    // «2» ball: yetti tagacha imlo va yettita punktuatsion. Umumiy <=14.
    if (imloErrors <= 7 && (imloErrors + ishoratErrors) <= 14) {
      return 2;
    }
    // «1» ball: xatolar miqdori o‘n beshtadan oshganda qo‘yiladi.
    return 1;
  }

  int evaluate5PointScale({int changesCount = 0}) {
    // changesCount ni DiktantEvaluator ga o'tkazish kerak
    int imlo = imloErrorCount;
    int punkt = punktuatsionErrorCount;
    // Eslatma: Agar diktantdagi tuzatishlar miqdori beshtadan ortiq bo‘lsa, baho bir ballga pasayadi.
    int baseMark = calculate5Point(imlo, punkt, _detectedErrors.length, changesCount);
    if (changesCount > 5 && baseMark > 1) {
      baseMark--;
    }
    return baseMark;
  }

  int evaluate100PointScaleMethod2() {
    if (_uniqueErrorCodes[ErrorType.IMLO]!.contains('imlo_katastrofik_nomuvofiqlik')) {
      return 0;
    }

    int imlo = imloErrorCount;
    int ishoraviy = punktuatsionErrorCount + uslubiyErrorCount + grafikErrorCount;

    if (imlo >= 10) return 0;

    if (imlo <= 2 && ishoraviy <= 2) return 100;
    if (imlo <= 4 && ishoraviy <= 3) return 80; // "3-4 tagacha imloviy" -> imlo <= 4
    if (imlo <= 7 && ishoraviy <= 5) return 60; // "5-7 tagacha imloviy" -> imlo <= 7
    if (imlo <= 9 && ishoraviy <= 7) return 50; // "8-9 tagacha imloviy" -> imlo <= 9

    // Agar yuqoridagilarga tushmasa, lekin imlo < 10 (qoidada bu holat uchun aniq ko'rsatma yo'q)
    // Eng yaqin past ballni berish mumkin yoki 0.
    // Misol: imlo = 5, ishoraviy = 6. 60 ga tushmaydi, 50 ga ham.
    // Hozirgi qoidalar bo'yicha 0 qaytaradi.
    return 0;
  }

  double evaluate100PointScaleMethod3() {
    if (_uniqueErrorCodes[ErrorType.IMLO]!.contains('imlo_katastrofik_nomuvofiqlik')) {
      return 0.0;
    }
    // Bu metod har bir *aniqlangan xato instansi* uchun ball ayiradi, "Bir tipdagi xato" qoidasini chetlab o'tadi.
    // Qoidada "eng kichik xatolik uchun quyidagi formula bo’yicha hisob kitob amalga oshiriladi" deyilgan.
    // Keyin esa foizlar berilgan. Bu foizlar har bir *unikal tipdagi xato* uchunmi yoki har bir xato instansi uchunmi?
    // Agar "Bir tipdagi xatolarning hammasi bitta xato sanaladi" degan umumiy qoida 3-usulga ham tegishli bo'lsa,
    // unda _uniqueErrorCodes dagi har bir xato turi uchun foiz ayirish kerak.
    // Hozirgi kodingiz _detectedErrors (ya'ni har bir instansiya) uchun ayiradi.
    // Keling, qoidaga moslab, *unikal xato kodlari soni* emas, balki *har bir aniqlangan xato instansi* uchun foiz ayiramiz,
    // chunki "eng kichik xatolik uchun" degan jumla shunga ishora qilayotgandek.
    // Agar "Zamon" vs "Xamon" bo'lsa, "imlo_zamon_xamon_yaqinlik" xatosi uchun penaltyMultiplier ishlaydi.

    double score = 100.0;
    for (var error in _detectedErrors) {
      // Har bir aniqlangan xato instansi uchun
      switch (error.type) {
        case ErrorType.IMLO:
          score -= 2.5 * error.penaltyMultiplier;
          break;
        case ErrorType.PUNKTUATSION:
          score -= 2.0 * error.penaltyMultiplier; // Punktuatsiyaga ham multiplier qo'shish mumkin
          break;
        case ErrorType.USLUBIY:
          score -= 1.5 * error.penaltyMultiplier;
          break;
        case ErrorType.GRAFIK:
          score -= 1.5 * error.penaltyMultiplier;
          break;
      }
    }
    return score.clamp(0.0, 100.0); // Skorni 0 dan 100 gacha cheklash
  }

  void printDetailedErrors() {
    print('Aniqlangan xatolar (${_detectedErrors.length} ta):');
    // for (var error in _detectedErrors) { // Hamma xatolarni ko'rsatish
    //   print(error);
    // }
    Set<DetectedError> uniquePrintableErrors = Set.from(_detectedErrors);
    for (var error in uniquePrintableErrors) {
      // Faqat unikal xatolarni (tavsif va fragmentlari bilan)
      print(error);
    }

    print('\n--- Xulosaviy hisobot (unikal xato KODLARI bo\'yicha) ---');
    print('Jami unikal imlo xato kodlari: $imloErrorCount');
    print('Jami unikal punktuatsion xato kodlari: $punktuatsionErrorCount');
    print('Jami unikal uslubiy xato kodlari: $uslubiyErrorCount');
    print('Jami unikal grafik xato kodlari: $grafikErrorCount');
    // print("Kiritilgan tuzatishlar soni: $_changesCount"); // Bu classga o'tkazilmagan
  }
}

void main() {
  String original1 =
      "Toshkent ko‘p millatli ulkan shahar bo‘lib, hozir unda 3 millionga yaqin aholi yashaydi. Uning chiroyi kundan-kunga ortib boryapti.";
  String user1 = "wiukdgfusyikjdhfiksujvh"; // Juda yomon xato

  print("--- FOYDALANUVCHI 1 (Juda yomon xato) ---");
  var evaluator1 = DiktantEvaluator(originalText: original1, userText: user1);
  evaluator1.analyze();
  evaluator1.printDetailedErrors();
  print("5 ballik baho: ${evaluator1.evaluate5PointScale()}");
  print("100 ballik (usul 2) baho: ${evaluator1.evaluate100PointScaleMethod2()}");
  print("100 ballik (usul 3) baho: ${evaluator1.evaluate100PointScaleMethod3().toStringAsFixed(2)}%");

  String original2 = "Salom, dunyo! Bu test.";
  String user2 = "salom dunyo bu test"; // Punktuatsiya tushib qolgan, bosh harf xatosi
  print("\n--- FOYDALANUVCHI 2 ---");
  var evaluator2 = DiktantEvaluator(originalText: original2, userText: user2);
  evaluator2.analyze();
  evaluator2.printDetailedErrors();
  print("5 ballik baho: ${evaluator2.evaluate5PointScale()}");
  print("100 ballik (usul 2) baho: ${evaluator2.evaluate100PointScaleMethod2()}");
  print("100 ballik (usul 3) baho: ${evaluator2.evaluate100PointScaleMethod3().toStringAsFixed(2)}%");

  String original3 = "Mening kitobim qani? U yerda, stol ustida turibdi.";
  String user3 = "Mening kitobim qani. U yerda stol ustida turibdi."; // ? vs .
  print("\n--- FOYDALANUVCHI 3 ---");
  var evaluator3 = DiktantEvaluator(originalText: original3, userText: user3);
  evaluator3.analyze();
  evaluator3.printDetailedErrors();
  print("5 ballik baho: ${evaluator3.evaluate5PointScale()}");
  print("100 ballik (usul 2) baho: ${evaluator3.evaluate100PointScaleMethod2()}");
  print("100 ballik (usul 3) baho: ${evaluator3.evaluate100PointScaleMethod3().toStringAsFixed(2)}%");

  String original4 = "Test uchun matn";
  String user4 = ""; // Butunlay bo'sh
  print("\n--- FOYDALANUVCHI 4 (Bo'sh matn) ---");
  var evaluator4 = DiktantEvaluator(originalText: original4, userText: user4);
  evaluator4.analyze();
  evaluator4.printDetailedErrors();
  print("5 ballik baho: ${evaluator4.evaluate5PointScale()}");
  print("100 ballik (usul 2) baho: ${evaluator4.evaluate100PointScaleMethod2()}");
  print("100 ballik (usul 3) baho: ${evaluator4.evaluate100PointScaleMethod3().toStringAsFixed(2)}%");

  String original5 = "Men sher yozdim."; // 'sher'
  String user5 = "Men she'r yozdim."; // "she'r"
  print("\n--- FOYDALANUVCHI 5 (sher vs she'r) ---");
  var evaluator5 = DiktantEvaluator(originalText: original5, userText: user5);
  evaluator5.analyze();
  evaluator5.printDetailedErrors(); // Uslubiy xato chiqishi kerak
  print("Uslubiy xato: ${evaluator5.uslubiyErrorCount}");
  print("5 ballik baho: ${evaluator5.evaluate5PointScale()}");

  String original6 = "Zamon o'zgardi.";
  String user6 = "Xamon o'zgardi."; // Klaviatura yaqinligi
  print("\n--- FOYDALANUVCHI 6 (Zamon vs Xamon) ---");
  var evaluator6 = DiktantEvaluator(originalText: original6, userText: user6);
  evaluator6.analyze();
  evaluator6.printDetailedErrors();
  print("100 ballik (usul 3) baho: ${evaluator6.evaluate100PointScaleMethod3().toStringAsFixed(2)}%");

  String original7 = "hamma xursand";
  String user7 = "xamma hursant"; // h/x va d/t
  print("\n--- FOYDALANUVCHI 7 (h/x) ---");
  var evaluator7 = DiktantEvaluator(originalText: original7, userText: user7);
  evaluator7.analyze();
  evaluator7.printDetailedErrors();
  print("Imlo xato: ${evaluator7.imloErrorCount}");
}
