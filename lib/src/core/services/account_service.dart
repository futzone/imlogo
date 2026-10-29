import 'package:dication/src/core/models/typing_result.dart';
import 'package:dication/src/core/models/work.dart';
import 'package:dication/src/core/services/pb_client.dart';
import 'package:dication/src/core/services/profile_service.dart';
import 'package:dication/src/core/typing/typing_config.dart';
import 'package:dication/src/core/typing/typing_engine.dart';
import 'package:dication/src/core/typing/typing_guard.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:url_launcher/url_launcher.dart';

/// Server bergan mashq: identifikator va so'zlar.
class TypingTest {
  final String id;
  final List<String> words;

  const TypingTest({required this.id, required this.words});
}

/// Server qayta hisoblagan natija.
class TypingVerdict {
  final TypingResult result;

  /// Natija reytingga kirdimi.
  final bool ranked;

  const TypingVerdict({required this.result, required this.ranked});
}

/// Hisob (ixtiyoriy): kirish, natijalarni serverda saqlash, umumiy reyting
/// va murojaatlar. Veb-saytdagi `src/lib/app/account.ts` bilan bir xil server
/// sxemasidan foydalanadi (`imlogo-uz/pocketbase/`).
class Account {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;

  /// Ro'yxatdan o'tgan sana.
  final DateTime? createdAt;

  const Account({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.createdAt,
  });

  factory Account.fromRecord(RecordModel record) {
    final email = record.get<String>('email');
    final name = record.get<String>('name');
    final avatar = record.get<String>('avatar');
    return Account(
      id: record.id,
      email: email,
      name: name.isNotEmpty ? name : email.split('@').first,
      avatarUrl: avatar.isEmpty ? null : pb.files.getURL(record, avatar, thumb: '100x100').toString(),
      // PocketBase sanani "2026-02-25 05:27:05.102Z" ko'rinishida beradi.
      createdAt: DateTime.tryParse(record.get<String>('created').replaceFirst(' ', 'T')),
    );
  }

  /// Ism bosh harflari (avatar rasmi bo'lmaganda).
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    return parts.length > 1 ? '$first${parts[1][0]}'.toUpperCase() : first.toUpperCase();
  }
}

/// Server xatosini foydalanuvchiga tushunarli matnga aylantiradi.
String accountErrorMessage(Object error) {
  if (error is! ClientException) return 'Kutilmagan xatolik yuz berdi';
  if (error.isAbort) return 'Sörov bekor qilindi';
  if (error.statusCode == 0) return 'Server bilan aloqa yöq. Internetni tekşiring';
  final data = error.response['data'];
  final fields = data is Map ? data : const {};
  final email = fields['email'];
  if (email is Map && email['code'] == 'validation_not_unique') {
    return 'Bu email bilan allaqaçon röyxatdan ötilgan';
  }
  if (email != null) return 'Email manzili notöğri';
  if (fields['password'] != null) return 'Parol kamida 8 ta belgidan iborat bölişi kerak';
  if (fields['oldPassword'] != null) return 'Joriy parol notöğri';
  if (fields['name'] != null) return 'Ism juda uzun';
  if (fields['avatar'] != null) return 'Rasm 2 MB dan kiçik JPG, PNG yoki WEBP bölişi kerak';
  if (error.statusCode == 400 && (error.url?.path.contains('auth-with-password') ?? false)) {
    return 'Email yoki parol notöğri';
  }
  if (error.statusCode == 429) return 'Juda köp uriniş. Birozdan söng qayta urinib köring';
  final message = error.response['message'];
  return message is String && message.isNotEmpty ? message : 'Kutilmagan xatolik yuz berdi';
}

RecordService get _users => pb.collection('users');

class AccountService {
  static Future<RecordAuth> signIn(String email, String password) =>
      _users.authWithPassword(email.trim(), password);

  static Future<RecordAuth> signUp(String name, String email, String password) async {
    await _users.create(body: {
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
      'passwordConfirm': password,
      'emailVisibility': false,
    });
    return signIn(email, password);
  }

  /// Google orqali kirish: PocketBase brauzerda Google sahifasini ochadi va
  /// natijani realtime ulanish orqali qaytaradi.
  static Future<RecordAuth> signInWithGoogle() => _users.authWithOAuth2('google', (url) async {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      });

  static void signOut() => pb.authStore.clear();

  static Future<RecordModel> updateName(String id, String name) =>
      _users.update(id, body: {'name': name.trim()});

  /// Parolni almashtirish. Muvaffaqiyatdan so'ng PocketBase sessiyani bekor qiladi — qayta kiriladi.
  static Future<RecordAuth> changePassword(Account account, String oldPassword, String password) async {
    await _users.update(account.id, body: {
      'oldPassword': oldPassword,
      'password': password,
      'passwordConfirm': password,
    });
    return signIn(account.email, password);
  }

  /// Parolni tiklash havolasini emailga yuboradi.
  static Future<void> requestPasswordReset(String email) => _users.requestPasswordReset(email.trim());

  // --- Tez yozish natijalari ---

  static Future<RecordModel> uploadTypingResult(String userId, TypingResult result) {
    final config = result.config;
    double round1(double v) => (v * 10).round() / 10;
    return pb.collection('typing_results').create(body: {
      'user': userId,
      'local_id': result.id,
      'mode': config.mode.name,
      'amount': config.amount,
      'punctuation': config.punctuation,
      'numbers': config.numbers,
      'alphabet': config.alphabet.name,
      'wpm': result.wpm,
      'raw': result.raw,
      'accuracy': result.accuracy,
      'consistency': result.consistency,
      'correct_chars': result.correctChars,
      'incorrect_chars': result.incorrectChars,
      'extra_chars': result.extraChars,
      'missed_chars': result.missedChars,
      'seconds': result.seconds,
      // Grafik kesimlari ixcham ko'rinishda: [soniya, wpm, xom, xatolar].
      'samples': [for (final s in result.samples) [s.second, round1(s.wpm), s.raw, s.errors]],
    });
  }

  static TypingResult _typingFromRecord(RecordModel record) {
    final data = record.data;
    double d(String key) => (data[key] as num? ?? 0).toDouble();
    int i(String key) => (data[key] as num? ?? 0).toInt();
    final localId = record.get<String>('local_id');
    return TypingResult(
      id: localId.isNotEmpty ? localId : record.id,
      createdAt: DateTime.tryParse(record.get<String>('created').replaceFirst(' ', 'T')) ?? DateTime.now(),
      config: TypingConfig.fromJson(data),
      wpm: d('wpm'),
      raw: d('raw'),
      accuracy: d('accuracy'),
      consistency: d('consistency'),
      correctChars: i('correct_chars'),
      incorrectChars: i('incorrect_chars'),
      extraChars: i('extra_chars'),
      missedChars: i('missed_chars'),
      seconds: d('seconds'),
      samples: [
        for (final s in (data['samples'] as List? ?? const []))
          if (s is List && s.length >= 4) TypingSample.fromJson(s),
      ],
      flags: [for (final flag in (data['flag_reasons'] as List? ?? const [])) flag.toString()],
    );
  }

  /// Server tekshiradigan mashq: so'zlarni server beradi, natijani esa bosishlar
  /// logidan o'zi hisoblaydi (`imlogo-uz/pocketbase/pb_hooks/typing_api.pb.js`).
  /// Faqat shunday natijalar reytingga kiradi; [uploadTypingResult] orqali
  /// yuklangani (kirishdan oldingi yoki yuborilmay qolgan natijalar) faqat tarixda saqlanadi.
  static Future<TypingTest> startTypingTest(TypingConfig config) async {
    final json = await pb.send<Map<String, dynamic>>(
      '/api/imlogo/typing/start',
      method: 'POST',
      body: config.toJson(),
    );
    return TypingTest(
      id: json['id'] as String,
      words: [for (final word in json['words'] as List) word as String],
    );
  }

  /// Natijani server qayta hisoblaydi va reytingga kiritish-kiritmasligini hal qiladi.
  static Future<TypingVerdict> submitTypingTest(String testId, String localId, List<TypingLogEntry> log) async {
    final json = await pb.send<Map<String, dynamic>>(
      '/api/imlogo/typing/submit',
      method: 'POST',
      body: {
        'testId': testId,
        'localId': localId,
        'log': [for (final entry in log) entry.toJson()],
      },
    );
    final record = RecordModel.fromJson(Map<String, dynamic>.from(json['record'] as Map));
    final flags = [for (final flag in (json['flags'] as List? ?? const [])) flag.toString()];
    return TypingVerdict(
      result: _typingFromRecord(record).withFlags(flags),
      ranked: json['ranked'] == true,
    );
  }

  /// Foydalanuvchining serverdagi natijalari, eng yangisi birinchi.
  static Future<List<TypingResult>> fetchMyTypingResults(String userId) async {
    final list = await pb.collection('typing_results').getList(
          perPage: 500,
          filter: pb.filter('user = {:id}', {'id': userId}),
          sort: '-created',
        );
    return list.items.map(_typingFromRecord).toList();
  }

  // --- Diktantlar ---

  /// Har bir diktant uchun oxirgi natija saqlanadi (qurilmadagi kabi).
  static Future<RecordModel> uploadWork(String userId, Work work) async {
    final body = {
      'user': userId,
      'dictation_id': work.id,
      'ball': work.ball,
      'baho': work.baho.round(),
      'worktime': work.worktime,
      'work': work.toJson(),
    };
    final works = pb.collection('dictation_works');
    try {
      final existing = await works.getFirstListItem(
        pb.filter('user = {:user} && dictation_id = {:id}', {'user': userId, 'id': work.id}),
        fields: 'id',
      );
      return works.update(existing.id, body: body);
    } on ClientException catch (error) {
      if (error.statusCode == 404) return works.create(body: body);
      rethrow;
    }
  }

  static Future<List<Work>> fetchMyWorks(String userId) async {
    final list = await pb.collection('dictation_works').getList(
          perPage: 500,
          filter: pb.filter('user = {:id}', {'id': userId}),
          sort: '-updated',
        );
    final works = <Work>[];
    for (final record in list.items) {
      try {
        works.add(Work.fromJson(Map<String, dynamic>.from(record.data['work'] as Map)));
      } catch (_) {
        // Buzilgan yozuv tashlab ketiladi.
      }
    }
    return works;
  }

  // --- Reyting ---

  static RecordService _leaderboard(Board board, LeaderboardPeriod period) =>
      pb.collection('${board.name}_leaderboard${period.suffix}');

  /// Reyting: [metric] bo'yicha kamayish tartibida. [filter] — qatnashish sharti.
  static Future<List<LeaderRow>> fetchLeaderboard(
    Board board,
    LeaderboardPeriod period,
    String metric,
    String filter, {
    int limit = 50,
  }) async {
    final list = await _leaderboard(board, period).getList(
      perPage: limit,
      filter: filter,
      sort: '-$metric',
      skipTotal: true,
    );
    return list.items.map(LeaderRow.fromRecord).toList();
  }

  /// Foydalanuvchining shu reytingdagi o'rni (qatnashmagan bo'lsa — `null`).
  static Future<({int rank, LeaderRow row})?> fetchMyRank(
    Board board,
    LeaderboardPeriod period,
    String metric,
    String filter,
    String userId,
  ) async {
    final collection = _leaderboard(board, period);
    final mine = await collection.getList(
      perPage: 1,
      filter: '($filter) && ${pb.filter('id = {:id}', {'id': userId})}',
      skipTotal: true,
    );
    if (mine.items.isEmpty) return null;
    final row = LeaderRow.fromRecord(mine.items.first);
    final ahead = await collection.getList(
      perPage: 1,
      filter: '($filter) && $metric > ${row.value(metric)}',
    );
    return (rank: ahead.totalItems + 1, row: row);
  }

  // --- Murojaatlar ---

  static Future<RecordModel> sendFeedback(String userId, FeedbackKind kind, String message, String page) =>
      pb.collection('feedback').create(body: {
        'user': userId,
        'kind': kind.name,
        'message': message.trim(),
        'page': page,
      });
}

enum Board { typing, dictation }

/// `week` — joriy hafta (dushanbadan, Toshkent vaqti), `prevWeek` — o'tgan hafta.
enum LeaderboardPeriod {
  all(''),
  week('_week'),
  prevWeek('_prev_week');

  final String suffix;

  const LeaderboardPeriod(this.suffix);
}

/// Reyting view'idagi qator: ism va son ko'rsatkichlar (email kelmaydi).
class LeaderRow {
  final String id;
  final String name;
  final Map<String, dynamic> data;

  const LeaderRow({required this.id, required this.name, required this.data});

  factory LeaderRow.fromRecord(RecordModel record) {
    final name = record.get<String>('name').trim();
    return LeaderRow(id: record.id, name: name.isEmpty ? 'Foydalanuvçi' : name, data: record.data);
  }

  /// Profil rasmi (reyting view'idagi `avatar` ustunidan).
  String? get avatarUrl => avatarUrlFor(id, data['avatar'] is String ? data['avatar'] as String : '');

  /// Serverdan kelgan qiymat bo'lmasligi ham mumkin — 0 deb olinadi.
  double value(String key) {
    final v = data[key];
    return v is num && v.isFinite ? v.toDouble() : 0;
  }
}

enum FeedbackKind {
  xatolik('Xatolik'),
  taklif('Taklif'),
  savol('Savol'),
  boshqa('Boşqa');

  final String label;

  const FeedbackKind(this.label);
}
