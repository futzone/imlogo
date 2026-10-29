import 'package:dication/src/core/services/account_service.dart';
import 'package:dication/src/core/services/pb_client.dart';
import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';

/// PocketBase sanasi ("2026-02-25 05:27:05.102Z"); bo'sh bo'lsa — `null`.
DateTime? _date(RecordModel record, String key) {
  final value = record.get<String>(key);
  return value.isEmpty ? null : DateTime.tryParse(value.replaceFirst(' ', 'T'));
}

/// Foydalanuvchi rasmi manzili. Rasm `users` kolleksiyasida saqlanadi — view
/// (reyting, profil) qatorlari uchun ham shu yerdan olinadi.
String? avatarUrlFor(String userId, String avatar, {String thumb = '100x100'}) {
  if (avatar.isEmpty) return null;
  return pb.buildURL('/api/files/_pb_users_auth_/$userId/${Uri.encodeComponent(avatar)}', {'thumb': thumb}).toString();
}

/// Boshqa foydalanuvchining ochiq ma'lumotlari (email kelmaydi).
class PublicProfile {
  final String id;
  final String name;
  final String? avatarUrl;
  final DateTime? createdAt;

  /// Oxirgi faollik; hali belgilanmagan bo'lsa — `null`.
  final DateTime? lastSeen;

  const PublicProfile({required this.id, required this.name, this.avatarUrl, this.createdAt, this.lastSeen});
}

class PublicTypingResult {
  final String id;
  final String mode;
  final int amount;
  final double wpm;
  final double accuracy;
  final DateTime? createdAt;

  const PublicTypingResult({
    required this.id,
    required this.mode,
    required this.amount,
    required this.wpm,
    required this.accuracy,
    this.createdAt,
  });

  String get modeLabel => switch (mode) {
        'time' => '$amount soniya',
        'sentences' => '$amount ta gap',
        _ => '$amount ta söz',
      };
}

class PublicDictationResult {
  final String id;
  final String title;
  final double ball;
  final int baho;
  final DateTime? updatedAt;

  const PublicDictationResult({
    required this.id,
    required this.title,
    required this.ball,
    required this.baho,
    this.updatedAt,
  });
}

class ProfileDetails {
  final PublicProfile profile;

  /// Hamma vaqt reytingidagi qatorlar (qatnashmagan bo'lsa — `null`).
  final LeaderRow? typing;
  final LeaderRow? dictation;

  /// Reytingdagi o'rni: eng tez (WPM) va eng ko'p ball.
  final int? typingRank;
  final int? dictationRank;
  final List<PublicTypingResult> bestTyping;
  final List<PublicDictationResult> recentDictations;

  const ProfileDetails({
    required this.profile,
    this.typing,
    this.dictation,
    this.typingRank,
    this.dictationRank,
    this.bestTyping = const [],
    this.recentDictations = const [],
  });
}

/// Diktantlarda eng ko'p xato qilinadigan so'z.
class MistakeWord {
  final String word;

  /// Jami xatolar soni.
  final int mistakes;

  /// Shu so'zda xato qilgan foydalanuvchilar soni.
  final int users;

  /// Eng ko'p uchraydigan noto'g'ri yozilishi.
  final String variant;

  const MistakeWord({required this.word, required this.mistakes, required this.users, required this.variant});
}

/// Ochiq profillar, profil rasmi, faollik vaqti va xato so'zlar
/// (veb-saytdagi `src/lib/app/account.ts` bilan bir xil; server sxemasi —
/// `imlogo-uz/pocketbase/pb_migrations/1793130000_public_profiles.js`).
class ProfileService {
  /// Oxirgi faollik vaqtini yangilash (`pb_hooks/profiles.pb.js`).
  static Future<void> ping() => pb.send('/api/imlogo/ping', method: 'POST');

  /// Profil rasmini o'rnatish (`bytes == null` — o'chirish).
  static Future<RecordModel> updateAvatar(String userId, List<int>? bytes, {String filename = 'avatar.jpg'}) {
    final users = pb.collection('users');
    if (bytes == null) return users.update(userId, body: {'avatar': null});
    return users.update(userId, files: [http.MultipartFile.fromBytes('avatar', bytes, filename: filename)]);
  }

  static Future<RecordModel?> _orNull(Future<RecordModel> future) async {
    try {
      return await future;
    } on ClientException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  static Future<int> _rankBy(String collection, String metric, double value) async {
    final ahead = await pb.collection(collection).getList(
          perPage: 1,
          filter: pb.filter('$metric > {:value}', {'value': value}),
        );
    return ahead.totalItems + 1;
  }

  /// Foydalanuvchi profili: ochiq ma'lumotlar, reytingdagi o'rni va natijalari.
  static Future<ProfileDetails?> fetchProfile(String userId) async {
    final byUser = pb.filter('user = {:id}', {'id': userId});
    final (record, typingRecord, dictationRecord, bestTyping, recentDictations) = await (
      _orNull(pb.collection('profiles').getOne(userId)),
      _orNull(pb.collection('typing_leaderboard').getOne(userId)),
      _orNull(pb.collection('dictation_leaderboard').getOne(userId)),
      pb
          .collection('typing_public')
          .getList(perPage: 5, filter: '$byUser && accuracy >= 75', sort: '-wpm', skipTotal: true),
      pb.collection('dictation_public').getList(perPage: 5, filter: byUser, sort: '-updated', skipTotal: true),
    ).wait;
    if (record == null) return null;

    final typing = typingRecord == null ? null : LeaderRow.fromRecord(typingRecord);
    final dictation = dictationRecord == null ? null : LeaderRow.fromRecord(dictationRecord);
    final (typingRank, dictationRank) = await (
      typing != null && typing.value('best_wpm') > 0
          ? _rankBy('typing_leaderboard', 'best_wpm', typing.value('best_wpm'))
          : Future<int?>.value(),
      dictation != null && dictation.value('total_ball') > 0
          ? _rankBy('dictation_leaderboard', 'total_ball', dictation.value('total_ball'))
          : Future<int?>.value(),
    ).wait;

    final name = record.get<String>('name').trim();
    return ProfileDetails(
      profile: PublicProfile(
        id: record.id,
        name: name.isEmpty ? 'Foydalanuvçi' : name,
        avatarUrl: avatarUrlFor(record.id, record.get<String>('avatar'), thumb: '256x256'),
        createdAt: _date(record, 'created'),
        lastSeen: _date(record, 'last_seen'),
      ),
      typing: typing,
      dictation: dictation,
      typingRank: typingRank,
      dictationRank: dictationRank,
      bestTyping: [
        for (final item in bestTyping.items)
          PublicTypingResult(
            id: item.id,
            mode: item.get<String>('mode'),
            amount: item.get<int>('amount'),
            wpm: item.get<double>('wpm'),
            accuracy: item.get<double>('accuracy'),
            createdAt: _date(item, 'created'),
          ),
      ],
      recentDictations: [
        for (final item in recentDictations.items)
          PublicDictationResult(
            id: item.id,
            title: item.get<String>('title').isEmpty ? 'Diktant' : item.get<String>('title'),
            ball: item.get<double>('ball'),
            baho: item.get<int>('baho'),
            updatedAt: _date(item, 'updated'),
          ),
      ],
    );
  }

  /// Diktantlarda eng ko'p xato qilinadigan so'zlar (`mistake_words` view).
  static Future<List<MistakeWord>> fetchMistakeWords({int limit = 50}) async {
    final list =
        await pb.collection('mistake_words').getList(perPage: limit, sort: '-mistakes,-users', skipTotal: true);
    return [
      for (final item in list.items)
        MistakeWord(
          word: item.get<String>('word'),
          mistakes: item.get<int>('mistakes'),
          users: item.get<int>('users'),
          variant: item.get<String>('variant'),
        ),
    ];
  }
}

/// Oxirgi faollik: "Hozir onlayn", "12 daqiqa oldin", "keça, 18:40" va h.k.
/// Ping har 5 daqiqada yuboriladi — shundan yangiroq faollik "onlayn" hisoblanadi.
String formatLastSeen(DateTime? lastSeen, {DateTime? now}) {
  if (lastSeen == null) return 'Ma’lum emas';
  final current = now ?? DateTime.now();
  final diff = current.difference(lastSeen);
  if (diff < const Duration(minutes: 6)) return 'Hozir onlayn';
  if (diff.inMinutes < 60) return '${diff.inMinutes} daqiqa oldin';
  if (diff.inHours < 24) return '${diff.inHours} soat oldin';
  final local = lastSeen.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  if (diff.inDays == 1) return 'keça, ${two(local.hour)}:${two(local.minute)}';
  if (diff.inDays < 7) return '${diff.inDays} kun oldin';
  return '${local.year}.${two(local.month)}.${two(local.day)}';
}
