import 'dart:math';

import 'package:dication/src/core/models/detected_error.dart';
import 'package:dication/src/core/models/error_type.dart';

enum AlignedPairType { match, substitution, deletion, insertion }

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

  static const double _dissimilarityLengthRatio = 0.3;
  static const int _dissimilarityMinUserTokens = 3;
  static const double _dissimilarityMatchRatio = 0.1;
  static const int _catastrophicMinOrigTokens = 5;
  static const int _significantMissingWords = 5;

  // Yonma-yon klaviatura tugmalari
  static const Map<String, List<String>> _adjacentKeys = {
    'q': ['w', 'a'],
    'w': ['q', 'e', 's', 'a'],
    'e': ['w', 'r', 'd', 's'],
    'r': ['e', 't', 'f', 'd'],
    't': ['r', 'y', 'g', 'f'],
    'y': ['t', 'u', 'h', 'g'],
    'u': ['y', 'i', 'j', 'h'],
    'i': ['u', 'o', 'k', 'j'],
    'o': ['i', 'p', 'l', 'k'],
    'p': ['o', 'l'],
    'a': ['q', 'w', 's', 'z'],
    's': ['a', 'w', 'e', 'd', 'x', 'z'],
    'd': ['s', 'e', 'r', 'f', 'c', 'x'],
    'f': ['d', 'r', 't', 'g', 'v', 'c'],
    'g': ['f', 't', 'y', 'h', 'b', 'v'],
    'h': ['g', 'y', 'u', 'j', 'n', 'b'],
    'j': ['h', 'u', 'i', 'k', 'm', 'n'],
    'k': ['j', 'i', 'o', 'l', 'm'],
    'l': ['k', 'o', 'p'],
    'z': ['a', 's', 'x'],
    'x': ['z', 's', 'd', 'c'],
    'c': ['x', 'd', 'f', 'v'],
    'v': ['c', 'f', 'g', 'b'],
    'b': ['v', 'g', 'h', 'n'],
    'n': ['b', 'h', 'j', 'm'],
    'm': ['n', 'j', 'k'],
  };

  // O'zbekcha apostrof normalizatsiya jadvali
  static const String _apostrophe = '\u2018'; // ' — o'zbek tilidagi asosiy belgi

  DiktantEvaluator({
    required this.originalText,
    required this.userText,
  });

  // --- Tokenizatsiya ---

  static final RegExp _tokenRegex = RegExp(
    r'([a-zA-Z\u00C0-\u024F\u0400-\u04FF]+'
    r"(?:['\u2018\u2019\u02BB'][a-zA-Z\u00C0-\u024F\u0400-\u04FF]+)*)"
    r'|([.,;:!?\-\u2013\u2014()«»"\u201C\u201D\u2026]+)',
  );

  List<String> _tokenize(String text) {
    if (text.trim().isEmpty) return [];
    final normalized = _normalizeText(text);
    final tokens = <String>[];
    for (final match in _tokenRegex.allMatches(normalized)) {
      final token = match.group(1) ?? match.group(2);
      if (token != null && token.isNotEmpty) {
        tokens.add(token);
      }
    }
    if (tokens.isEmpty && normalized.trim().isNotEmpty) {
      return normalized.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    }
    return tokens;
  }

  String _normalizeText(String text) {
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(_normalizeChar(text[i]));
    }
    return buffer.toString();
  }

  String _normalizeChar(String char) {
    switch (char) {
      case '\u2019': // '
      case '\u02BB': // ʻ
      case '\u0027': // '
        return '\u2018'; // ' — standart apostrof
      case '\u201C': // "
      case '\u201D': // "
      case '\u00AB': // «
      case '\u00BB': // »
        return '"';
      case '\u045E': // ў (Cyrillic)
        return 'o\u2018';
      case '\u040E': // Ў
        return 'O\u2018';
      case '\u0493': // ғ
        return 'g\u2018';
      case '\u0492': // Ғ
        return 'G\u2018';
      default:
        return char;
    }
  }

  String _normalizeLower(String token) {
    return _normalizeText(token).toLowerCase();
  }

  bool _isPunctuation(String? token) {
    if (token == null || token.isEmpty) return false;
    return RegExp(r'^[.,;:!?\-\u2013\u2014()«»"\u201C\u201D\u2026\u2018\u2019\u0027]+$')
            .hasMatch(token) &&
        !RegExp(r'[a-zA-Z\u00C0-\u024F\u0400-\u04FF]').hasMatch(token);
  }

  // --- Alignment (Levenshtein DP) ---

  List<AlignedPair> _alignTokens(List<String> orig, List<String> user) {
    final int n = orig.length;
    final int m = user.length;

    // Xotira optimizatsiyasi: faqat 2 qator kerak forward pass uchun
    // Lekin traceback uchun to'liq matritsa kerak — shuning uchun
    // kichik matnlar uchun to'liq, katta matnlar uchun Hirschberg bo'linishi
    if (n == 0) {
      return user
          .map((u) => AlignedPair(userToken: u, type: AlignedPairType.insertion))
          .toList();
    }
    if (m == 0) {
      return orig
          .map((o) => AlignedPair(originalToken: o, type: AlignedPairType.deletion))
          .toList();
    }

    // To'liq DP matritsasi (tokenlar soni odatda < 300)
    final dp = List.generate(n + 1, (_) => List.filled(m + 1, 0));
    for (int i = 0; i <= n; i++) dp[i][0] = i;
    for (int j = 0; j <= m; j++) dp[0][j] = j;

    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        final cost = _tokensMatch(orig[i - 1], user[j - 1]) ? 0 : 1;
        dp[i][j] = min(
          dp[i - 1][j] + 1,
          min(dp[i][j - 1] + 1, dp[i - 1][j - 1] + cost),
        );
      }
    }

    // Traceback
    final aligned = <AlignedPair>[];
    int i = n, j = m;
    while (i > 0 || j > 0) {
      if (i > 0 && j > 0) {
        final cost = _tokensMatch(orig[i - 1], user[j - 1]) ? 0 : 1;
        if (dp[i][j] == dp[i - 1][j - 1] + cost) {
          aligned.add(AlignedPair(
            originalToken: orig[i - 1],
            userToken: user[j - 1],
            type: cost == 0 ? AlignedPairType.match : AlignedPairType.substitution,
          ));
          i--;
          j--;
          continue;
        }
      }
      if (j > 0 && dp[i][j] == dp[i][j - 1] + 1) {
        aligned.add(AlignedPair(
          userToken: user[j - 1],
          type: AlignedPairType.insertion,
        ));
        j--;
      } else if (i > 0) {
        aligned.add(AlignedPair(
          originalToken: orig[i - 1],
          type: AlignedPairType.deletion,
        ));
        i--;
      } else {
        break;
      }
    }
    return aligned.reversed.toList();
  }

  bool _tokensMatch(String a, String b) {
    if (a == b) return true;
    return _normalizeLower(a) == _normalizeLower(b);
  }

  // --- Xato qo'shish ---

  void _addError(DetectedError error) {
    _detectedErrors.add(error);
    _uniqueErrorCodes[error.type]?.add(error.specificRuleCode);
  }

  List<DetectedError> getDetailedErrors() => List.unmodifiable(_detectedErrors);

  // --- Grafik xatolarni tekshirish ---

  /// o' va g' belgilarining to'g'ri ishlatilganini tekshiradi
  bool _checkGraphicError(String origToken, String userToken) {
    final normOrig = _normalizeText(origToken);
    final normUser = _normalizeText(userToken);

    // o' belgi tushib qolgan (ko'p -> kop)
    if (normOrig.contains('o\u2018') && !normUser.contains('o\u2018')) {
      if (normOrig.replaceAll('o\u2018', 'o') == normUser) {
        _addError(DetectedError(
          type: ErrorType.GRAFIK,
          description: "o\u2018 harfidagi belgi tuşib qolgan",
          originalFragment: origToken,
          userFragment: userToken,
          specificRuleCode: "grafik_o_belgi_tushgan",
        ));
        return true;
      }
    }
    if (normOrig.contains('O\u2018') && !normUser.contains('O\u2018')) {
      if (normOrig.replaceAll('O\u2018', 'O') == normUser) {
        _addError(DetectedError(
          type: ErrorType.GRAFIK,
          description: "O\u2018 harfidagi belgi tuşib qolgan",
          originalFragment: origToken,
          userFragment: userToken,
          specificRuleCode: "grafik_o_belgi_tushgan",
        ));
        return true;
      }
    }

    // g' belgi tushib qolgan (g'amxo'r -> gamxor)
    if (normOrig.contains('g\u2018') && !normUser.contains('g\u2018')) {
      if (normOrig.replaceAll('g\u2018', 'g') == normUser) {
        _addError(DetectedError(
          type: ErrorType.GRAFIK,
          description: "g\u2018 harfidagi belgi tuşib qolgan",
          originalFragment: origToken,
          userFragment: userToken,
          specificRuleCode: "grafik_g_belgi_tushgan",
        ));
        return true;
      }
    }
    if (normOrig.contains('G\u2018') && !normUser.contains('G\u2018')) {
      if (normOrig.replaceAll('G\u2018', 'G') == normUser) {
        _addError(DetectedError(
          type: ErrorType.GRAFIK,
          description: "G\u2018 harfidagi belgi tuşib qolgan",
          originalFragment: origToken,
          userFragment: userToken,
          specificRuleCode: "grafik_g_belgi_tushgan",
        ));
        return true;
      }
    }

    return false;
  }

  // --- Klaviatura yaqinligi ---

  bool _isAdjacentKeyError(String normOrig, String normUser) {
    if (normOrig.length != normUser.length) return false;
    int diffs = 0;
    for (int k = 0; k < normOrig.length; k++) {
      if (normOrig[k] != normUser[k]) {
        diffs++;
        if (diffs > 1) return false;
        final neighbors = _adjacentKeys[normOrig[k]];
        if (neighbors == null || !neighbors.contains(normUser[k])) return false;
      }
    }
    return diffs == 1;
  }

  // --- Tutuq belgisi tekshiruvi ---

  bool _checkApostropheError(String normOrig, String normUser, String origToken, String userToken) {
    // o' va g' ni alohida ajratib, haqiqiy tutuq belgisini tekshirish
    final placeholder = '\u0000';
    final origBase = normOrig.replaceAll("o\u2018", "o$placeholder").replaceAll("g\u2018", "g$placeholder");
    final userBase = normUser.replaceAll("o\u2018", "o$placeholder").replaceAll("g\u2018", "g$placeholder");

    final origHasApostrophe = origBase.contains('\u2018');
    final userHasApostrophe = userBase.contains('\u2018');

    final origClean = origBase.replaceAll('\u2018', '').replaceAll(placeholder, '\u2018');
    final userClean = userBase.replaceAll('\u2018', '').replaceAll(placeholder, '\u2018');

    if (origClean == userClean) {
      if (origHasApostrophe && !userHasApostrophe) {
        _addError(DetectedError(
          type: ErrorType.IMLO,
          description: "Tutuq belgisi tuşib qolgan",
          originalFragment: origToken,
          userFragment: userToken,
          specificRuleCode: 'imlo_tutuq_tushibqolgan',
        ));
        return true;
      } else if (!origHasApostrophe && userHasApostrophe) {
        _addError(DetectedError(
          type: ErrorType.IMLO,
          description: "Örinsiz tutuq belgisi işlatilgan",
          originalFragment: origToken,
          userFragment: userToken,
          specificRuleCode: 'imlo_tutuq_orinsiz',
        ));
        return true;
      }
    }
    return false;
  }

  // --- h/x almashinuvi ---

  bool _checkHXSwap(String normOrig, String normUser, String origToken, String userToken) {
    if (normOrig.contains('h') && normUser.contains('x') && normOrig.replaceAll('h', 'x') == normUser) {
      _addError(DetectedError(
        type: ErrorType.IMLO,
        description: "h örniga x yozilgan",
        originalFragment: origToken,
        userFragment: userToken,
        specificRuleCode: 'imlo_h_x_almashinuvi',
      ));
      return true;
    }
    if (normOrig.contains('x') && normUser.contains('h') && normOrig.replaceAll('x', 'h') == normUser) {
      _addError(DetectedError(
        type: ErrorType.IMLO,
        description: "x örniga h yozilgan",
        originalFragment: origToken,
        userFragment: userToken,
        specificRuleCode: 'imlo_h_x_almashinuvi',
      ));
      return true;
    }
    return false;
  }

  // --- Uslubiy xatolar ---

  void _findUslubiyErrors(List<AlignedPair> alignedList) {
    for (final pair in alignedList) {
      if (pair.originalToken == null || pair.userToken == null) continue;
      if (pair.type != AlignedPairType.match && pair.type != AlignedPairType.substitution) continue;

      final origNorm = _normalizeLower(pair.originalToken!);
      final userNorm = _normalizeLower(pair.userToken!);

      // Paronimik xatolar
      if (_isParonymPair(origNorm, userNorm)) {
        final code = 'uslubiy_paronim_${origNorm}_$userNorm';
        if (!_uniqueErrorCodes[ErrorType.USLUBIY]!.contains(code)) {
          _addError(DetectedError(
            type: ErrorType.USLUBIY,
            description: 'Paronimik xato ($origNorm/$userNorm)',
            originalFragment: pair.originalToken!,
            userFragment: pair.userToken!,
            specificRuleCode: code,
          ));
        }
      }
    }
  }

  bool _isParonymPair(String a, String b) {
    if (a == b) return false;
    const paronyms = [
      ['abzal', 'afzal'],
      ['sher', 'she\u2018r'],
      ['hol', 'xol'],
      ['haq', 'xaq'],
    ];
    for (final pair in paronyms) {
      if ((a == pair[0] && b == pair[1]) || (a == pair[1] && b == pair[0])) {
        return true;
      }
    }
    return false;
  }

  // --- Asosiy tahlil ---

  void analyze() {
    _detectedErrors.clear();
    for (final set in _uniqueErrorCodes.values) {
      set.clear();
    }

    final originalTokens = _tokenize(originalText);
    final userTokens = _tokenize(userText);

    // Ikkalasi ham bo'sh
    if (originalTokens.isEmpty && userTokens.isEmpty) return;

    // Original bo'sh — foydalanuvchi ortiqcha yozgan
    if (originalTokens.isEmpty) {
      for (final token in userTokens) {
        _addError(DetectedError(
          type: _isPunctuation(token) ? ErrorType.PUNKTUATSION : ErrorType.IMLO,
          description: _isPunctuation(token)
              ? "Ortiqça tiniş belgisi"
              : "Ortiqça söz",
          originalFragment: '',
          userFragment: token,
          specificRuleCode: _isPunctuation(token)
              ? 'punkt_ortiqcha_umumiy'
              : 'imlo_ortiqcha_soz_umumiy',
        ));
      }
      return;
    }

    // Foydalanuvchi hech narsa yozmagan
    if (userTokens.isEmpty) {
      _addError(DetectedError(
        type: ErrorType.IMLO,
        description: "Barça sözlar tuşib qolgan",
        originalFragment: originalText,
        userFragment: '',
        specificRuleCode: 'imlo_barcha_soz_tushibqolgan',
      ));
      for (final token in originalTokens) {
        if (_isPunctuation(token)) {
          _addError(DetectedError(
            type: ErrorType.PUNKTUATSION,
            description: "Tiniş belgisi tuşib qolgan",
            originalFragment: token,
            userFragment: '',
            specificRuleCode: 'punkt_tushibqolgan_umumiy',
          ));
        }
      }
      return;
    }

    // Alignment
    final alignedList = _alignTokens(originalTokens, userTokens);
    final matchCount = alignedList.where((p) => p.type == AlignedPairType.match).length;
    final matchRatio = originalTokens.isNotEmpty ? matchCount / originalTokens.length : 0.0;

    // Katastrofik nomuvofiqlik tekshiruvi
    if (_isCatastrophicMismatch(originalTokens, userTokens, matchRatio, matchCount)) {
      _addError(DetectedError(
        type: ErrorType.IMLO,
        description: "Matn originalga umuman mos kelmaydi",
        originalFragment: originalTokens.take(5).join(" ") + "...",
        userFragment: userTokens.join(" "),
        specificRuleCode: 'imlo_katastrofik_nomuvofiqlik',
      ));
      for (final token in originalTokens) {
        if (_isPunctuation(token)) {
          _addError(DetectedError(
            type: ErrorType.PUNKTUATSION,
            description: "Tiniş belgisi tuşib qolgan",
            originalFragment: token,
            userFragment: '',
            specificRuleCode: 'punkt_tushibqolgan_katastrofik',
          ));
        }
      }
      _findUslubiyErrors(alignedList);
      return;
    }

    // Asosiy tahlil
    _analyzeAlignedPairs(alignedList);
    _findUslubiyErrors(alignedList);
  }

  bool _isCatastrophicMismatch(
    List<String> originalTokens,
    List<String> userTokens,
    double matchRatio,
    int matchCount,
  ) {
    // Foydalanuvchi bitta so'z yozgan, original katta matn
    if (userTokens.length == 1 &&
        !_isPunctuation(userTokens.first) &&
        originalTokens.length > _catastrophicMinOrigTokens &&
        matchRatio < _dissimilarityMatchRatio) {
      return true;
    }
    // Foydalanuvchi juda kam yozgan va moslik past
    if (userTokens.length <= _dissimilarityMinUserTokens &&
        userTokens.length < originalTokens.length * _dissimilarityLengthRatio &&
        matchRatio < _dissimilarityMatchRatio &&
        matchCount < 2) {
      return true;
    }
    return false;
  }

  void _analyzeAlignedPairs(List<AlignedPair> alignedList) {
    final deletedWordBuffer = <String>[];
    final insertedWordBuffer = <String>[];

    void flushDeletedBuffer() {
      if (deletedWordBuffer.isNotEmpty) {
        final desc = deletedWordBuffer.length >= _significantMissingWords
            ? "Matnning katta qismi yozilmagan"
            : "Söz(lar) tuşib qolgan";
        final code = deletedWordBuffer.length >= _significantMissingWords
            ? 'imlo_katta_hajm_tushibqolgan'
            : 'imlo_tushibqolgan_guruh';
        _addError(DetectedError(
          type: ErrorType.IMLO,
          description: desc,
          originalFragment: deletedWordBuffer.join(' '),
          userFragment: '',
          specificRuleCode: code,
        ));
        deletedWordBuffer.clear();
      }
    }

    void flushInsertedBuffer() {
      if (insertedWordBuffer.isNotEmpty) {
        _addError(DetectedError(
          type: ErrorType.IMLO,
          description: "Ortiqça söz(lar)",
          originalFragment: '',
          userFragment: insertedWordBuffer.join(' '),
          specificRuleCode: 'imlo_ortiqcha_guruh',
        ));
        insertedWordBuffer.clear();
      }
    }

    void flushBuffers() {
      flushDeletedBuffer();
      flushInsertedBuffer();
    }

    /// Deletion + Substitution juftligida qo'shib yozilgan so'zni aniqlash.
    /// Misol: original "raqamli tarzda", user "raqamlitarzda"
    /// Alignment: raqamli→deleted, tarzda↔raqamlitarzda(substitution)
    /// Yoki: raqamli↔raqamlitarzda(substitution), tarzda→deleted
    bool _tryDetectMergedWords(String origToken, String userToken) {
      if (deletedWordBuffer.isEmpty && insertedWordBuffer.isEmpty) return false;
      final userNorm = _normalizeLower(userToken);

      // Deletion buffer + joriy orig = user token (qo'shib yozilgan)
      if (deletedWordBuffer.isNotEmpty) {
        // Buferdagi so'zlar + joriy orig = user?
        final combined = [...deletedWordBuffer, origToken];
        final combinedNorm = combined.map(_normalizeLower).join('');
        if (combinedNorm == userNorm) {
          _addError(DetectedError(
            type: ErrorType.IMLO,
            description: "Sözlar qöşib yozilgan",
            originalFragment: combined.join(' '),
            userFragment: userToken,
            specificRuleCode: 'imlo_sozlar_qoshib_yozilgan',
          ));
          deletedWordBuffer.clear();
          return true;
        }
        // Faqat buferdagi so'zlar = user? (orig alohida deletion bo'lishi mumkin)
        if (deletedWordBuffer.length >= 2) {
          final bufferNorm = deletedWordBuffer.map(_normalizeLower).join('');
          if (bufferNorm == userNorm) {
            _addError(DetectedError(
              type: ErrorType.IMLO,
              description: "Sözlar qöşib yozilgan",
              originalFragment: deletedWordBuffer.join(' '),
              userFragment: userToken,
              specificRuleCode: 'imlo_sozlar_qoshib_yozilgan',
            ));
            deletedWordBuffer.clear();
            return true;
          }
        }
      }

      // Insertion buffer + joriy user tekshiruvi (ajratib yozilgan)
      if (insertedWordBuffer.isNotEmpty) {
        final combined = [...insertedWordBuffer, userToken];
        final combinedNorm = combined.map(_normalizeLower).join('');
        final origNorm = _normalizeLower(origToken);
        if (combinedNorm == origNorm) {
          _addError(DetectedError(
            type: ErrorType.IMLO,
            description: "Söz ajratib yozilgan",
            originalFragment: origToken,
            userFragment: combined.join(' '),
            specificRuleCode: 'imlo_soz_ajratib_yozilgan',
          ));
          insertedWordBuffer.clear();
          return true;
        }
      }

      return false;
    }

    for (final pair in alignedList) {
      final orig = pair.originalToken;
      final user = pair.userToken;

      // Match da bufferlarni tozalash
      if (pair.type == AlignedPairType.match) {
        flushBuffers();
      }

      // Substitution da avval qo'shib/ajratib yozilgan so'zni tekshirish
      if (pair.type == AlignedPairType.substitution) {
        if (orig != null && user != null && !_isPunctuation(orig) && !_isPunctuation(user)) {
          if (_tryDetectMergedWords(orig, user)) {
            continue;
          }
        }
        flushBuffers();
      }

      switch (pair.type) {
        case AlignedPairType.deletion:
          if (orig == null) continue;
          if (_isPunctuation(orig)) {
            _addError(DetectedError(
              type: ErrorType.PUNKTUATSION,
              description: "Tiniş belgisi tuşib qolgan",
              originalFragment: orig,
              userFragment: '',
              specificRuleCode: 'punkt_tushibqolgan_umumiy',
            ));
          } else {
            deletedWordBuffer.add(orig);
          }
          break;

        case AlignedPairType.insertion:
          if (user == null) continue;
          if (_isPunctuation(user)) {
            _addError(DetectedError(
              type: ErrorType.PUNKTUATSION,
              description: "Ortiqça tiniş belgisi",
              originalFragment: '',
              userFragment: user,
              specificRuleCode: 'punkt_ortiqcha_umumiy',
            ));
          } else {
            insertedWordBuffer.add(user);
          }
          break;

        case AlignedPairType.match:
          if (orig == null || user == null) continue;
          _checkMatchPairErrors(orig, user);
          break;

        case AlignedPairType.substitution:
          if (orig == null || user == null) continue;
          _checkSubstitutionErrors(orig, user);
          break;
      }
    }

    // Oxirgi bufferlarni tozalash
    flushBuffers();
  }

  /// Match juftlikda ham bosh harf va grafik xatolar bo'lishi mumkin
  void _checkMatchPairErrors(String orig, String user) {
    if (orig == user) return; // To'liq mos — xato yo'q
    if (_isPunctuation(orig)) return;

    // Bosh harf xatosi (normalized match, lekin original case farqli)
    if (orig.toLowerCase() == user.toLowerCase() && orig != user) {
      _addError(DetectedError(
        type: ErrorType.IMLO,
        description: "Boş harf imlosida xato",
        originalFragment: orig,
        userFragment: user,
        specificRuleCode: 'imlo_bosh_harf_umumiy',
      ));
    }

    // Grafik xato (o'/g' variantlari)
    _checkGraphicError(orig, user);
  }

  void _checkSubstitutionErrors(String orig, String user) {
    final origIsPunct = _isPunctuation(orig);
    final userIsPunct = _isPunctuation(user);

    // Ikkisi ham tinish belgisi
    if (origIsPunct && userIsPunct) {
      if (orig != user) {
        _addError(DetectedError(
          type: ErrorType.PUNKTUATSION,
          description: "Tiniş belgisi notöğri qöllanilgan",
          originalFragment: orig,
          userFragment: user,
          specificRuleCode: 'punkt_belgi_almashgan_umumiy',
        ));
      }
      return;
    }

    // Biri tinish belgisi, biri so'z
    if (origIsPunct != userIsPunct) {
      _addError(DetectedError(
        type: ErrorType.IMLO,
        description: origIsPunct
            ? "Tiniş belgisi örniga söz yozilgan"
            : "Söz örniga tiniş belgisi yozilgan",
        originalFragment: orig,
        userFragment: user,
        specificRuleCode: 'imlo_soz_va_punkt_almashuvi_umumiy',
      ));
      return;
    }

    // Ikkisi ham so'z — batafsil tekshirish
    final normOrig = _normalizeText(orig);
    final normUser = _normalizeText(user);
    final normOrigLower = normOrig.toLowerCase();
    final normUserLower = normUser.toLowerCase();

    // 1. Grafik xato tekshiruvi (o'/g' bilan bog'liq)
    if (_checkGraphicError(orig, user)) return;

    // 2. Bosh harf xatosi
    if (normOrigLower == normUserLower && orig != user) {
      _addError(DetectedError(
        type: ErrorType.IMLO,
        description: "Boş harf imlosida xato",
        originalFragment: orig,
        userFragment: user,
        specificRuleCode: 'imlo_bosh_harf_umumiy',
      ));
      return;
    }
    if (normOrigLower == normUserLower) return; // Faqat case farqi — yuqorida hal qilindi

    // 3. h/x almashinuvi
    if (_checkHXSwap(normOrigLower, normUserLower, orig, user)) return;

    // 4. Tutuq belgisi xatosi
    if (_checkApostropheError(normOrigLower, normUserLower, orig, user)) return;

    // 5. Klaviatura yaqinligi
    if (_isAdjacentKeyError(normOrigLower, normUserLower)) {
      _addError(DetectedError(
        type: ErrorType.IMLO,
        description: "Klaviatura yaqinligi xatosi",
        originalFragment: orig,
        userFragment: user,
        specificRuleCode: 'imlo_klaviatura_yaqinlik',
        penaltyMultiplier: 0.5,
      ));
      return;
    }

    // 6. Umumiy imlo xatosi
    _addError(DetectedError(
      type: ErrorType.IMLO,
      description: "Sözni notöğri yoziş",
      originalFragment: orig,
      userFragment: user,
      specificRuleCode: 'imlo_soz_almashtirish_${normOrigLower}_vs_$normUserLower',
    ));
  }

  // --- Xato hisoblash ---

  int get imloErrorCount => _uniqueErrorCodes[ErrorType.IMLO]?.length ?? 0;
  int get punktuatsionErrorCount => _uniqueErrorCodes[ErrorType.PUNKTUATSION]?.length ?? 0;
  int get uslubiyErrorCount => _uniqueErrorCodes[ErrorType.USLUBIY]?.length ?? 0;
  int get grafikErrorCount => _uniqueErrorCodes[ErrorType.GRAFIK]?.length ?? 0;

  // --- Baholash ---

  bool get _hasCriticalError =>
      _uniqueErrorCodes[ErrorType.IMLO]!.contains('imlo_katastrofik_nomuvofiqlik') ||
      _uniqueErrorCodes[ErrorType.IMLO]!.contains('imlo_katta_hajm_tushibqolgan') ||
      _uniqueErrorCodes[ErrorType.IMLO]!.contains('imlo_barcha_soz_tushibqolgan');

  int evaluate5PointScale({int changesCount = 0}) {
    if (_hasCriticalError) return 1;

    final imlo = imloErrorCount;
    final punkt = punktuatsionErrorCount;
    final uslub = uslubiyErrorCount;
    final grafik = grafikErrorCount;
    final ishorat = punkt + uslub + grafik;
    final totalErrors = imlo + ishorat;

    if (totalErrors == 0) {
      return changesCount >= 3 ? 4 : 5;
    }
    if (totalErrors == 1 && (imlo <= 1 && punkt <= 1)) {
      return changesCount >= 3 ? 4 : 5;
    }
    if (imlo <= 2 && totalErrors <= 4) return 4;
    if (imlo <= 4 && totalErrors <= 8) return 3;
    if (imlo <= 7 && totalErrors <= 14) return 2;
    return 1;
  }

  double evaluate100PointScaleMethod3() {
    if (_hasCriticalError) return 0.0;

    double score = 100.0;
    for (final error in _detectedErrors) {
      switch (error.type) {
        case ErrorType.IMLO:
          score -= 2.5 * error.penaltyMultiplier;
          break;
        case ErrorType.PUNKTUATSION:
          score -= 2.0 * error.penaltyMultiplier;
          break;
        case ErrorType.USLUBIY:
          score -= 1.5 * error.penaltyMultiplier;
          break;
        case ErrorType.GRAFIK:
          score -= 1.5 * error.penaltyMultiplier;
          break;
      }
    }
    return score.clamp(0.0, 100.0);
  }
}
