import 'dart:async';

import 'package:dication/src/core/models/typing_result.dart';
import 'package:dication/src/core/models/work.dart';
import 'package:dication/src/core/services/account_service.dart';
import 'package:dication/src/core/services/pb_client.dart';
import 'package:dication/src/core/services/profile_service.dart';
import 'package:dication/src/providers/history_provider.dart';
import 'package:dication/src/providers/typing_provider.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';

/// Joriy foydalanuvchi (`null` — mehmon). PocketBase sessiyasi o'zgarganda
/// (kirish, chiqish, ism o'zgarishi) yangilanadi.
class AuthNotifier extends StateNotifier<Account?> {
  late final StreamSubscription _subscription;

  /// Oxirgi faollik vaqti (profilda "oxirgi marta onlayn") shu oraliqda yangilanadi.
  static const _pingInterval = Duration(minutes: 5);
  late final Timer _pingTimer;
  late final AppLifecycleListener _lifecycle;

  AuthNotifier() : super(_current()) {
    _subscription = pb.authStore.onChange.listen((_) => state = _current());
    _pingTimer = Timer.periodic(_pingInterval, (_) => _ping());
    _lifecycle = AppLifecycleListener(onResume: _ping);
    _refresh();
  }

  void _ping() {
    if (state == null || SchedulerBinding.instance.lifecycleState == AppLifecycleState.paused) return;
    ProfileService.ping().catchError((_) {});
  }

  static Account? _current() {
    final record = pb.authStore.record;
    return pb.authStore.isValid && record != null ? Account.fromRecord(record) : null;
  }

  /// Saqlangan sessiyani yangilaydi: hisob o'chirilgan yoki token eskirgan bo'lsa, chiqariladi.
  Future<void> _refresh() async {
    if (!pb.authStore.isValid) return;
    try {
      await pb.collection('users').authRefresh();
    } on ClientException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 404) pb.authStore.clear();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    _pingTimer.cancel();
    _lifecycle.dispose();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, Account?>((ref) => AuthNotifier());

/// Foydalanuvchining barcha natijalari: qurilmadagi va (kirgan bo'lsa)
/// serverdagi natijalar birlashtiriladi.
class UserHistory {
  final List<TypingResult> typing;
  final List<Work> works;

  /// Hisobga hali yuklanmagan, faqat shu qurilmadagi natijalar.
  final List<TypingResult> unsyncedTyping;
  final List<Work> unsyncedWorks;

  const UserHistory({
    required this.typing,
    required this.works,
    this.unsyncedTyping = const [],
    this.unsyncedWorks = const [],
  });

  int get unsyncedCount => unsyncedTyping.length + unsyncedWorks.length;
}

final userHistoryProvider = FutureProvider<UserHistory>((ref) async {
  final account = ref.watch(authProvider.select((a) => a?.id));
  final localTyping = await ref.watch(typingHistoryProvider.future);
  final localWorks = List.of(await ref.watch(historyProvider.future))
    ..sort((a, b) => b.createdDate.compareTo(a.createdDate));
  if (account == null) return UserHistory(typing: localTyping, works: localWorks);

  try {
    final (remoteTyping, remoteWorks) = await (
      AccountService.fetchMyTypingResults(account),
      AccountService.fetchMyWorks(account),
    ).wait;
    final typingIds = remoteTyping.map((r) => r.id).toSet();
    final unsyncedTyping = localTyping.where((r) => !typingIds.contains(r.id)).toList();
    // Diktant bo'yicha qurilmadagi natija serverdagidan yangiroq bo'lsa, u ham yuklanmagan hisoblanadi.
    final remoteDates = {for (final w in remoteWorks) w.id: w.createdDate};
    final unsyncedWorks = localWorks.where((w) {
      final remote = remoteDates[w.id];
      return remote == null || remote.compareTo(w.createdDate) < 0;
    }).toList();
    final unsyncedIds = unsyncedWorks.map((w) => w.id).toSet();

    return UserHistory(
      typing: [...remoteTyping, ...unsyncedTyping]..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      works: [...remoteWorks.where((w) => !unsyncedIds.contains(w.id)), ...unsyncedWorks]
        ..sort((a, b) => b.createdDate.compareTo(a.createdDate)),
      unsyncedTyping: unsyncedTyping,
      unsyncedWorks: unsyncedWorks,
    );
  } catch (_) {
    // Server javob bermasa, hech bo'lmaganda qurilmadagi natijalar ko'rsatiladi.
    return UserHistory(typing: localTyping, works: localWorks);
  }
});

/// Natija qo'shilgandan keyin tarixni qayta o'qitadi.
void invalidateHistory(WidgetRef ref) {
  ref.invalidate(typingHistoryProvider);
  ref.invalidate(historyProvider);
  ref.invalidate(userHistoryProvider);
}

/// Qurilmadagi natijalarni hisobga yuklaydi (ketma-ket — server so'rovlar chastotasini cheklaydi).
Future<void> syncHistory(WidgetRef ref, String userId, UserHistory history) async {
  for (final result in history.unsyncedTyping) {
    await AccountService.uploadTypingResult(userId, result).then((_) {}, onError: (_) {});
  }
  for (final work in history.unsyncedWorks) {
    await AccountService.uploadWork(userId, work).then((_) {}, onError: (_) {});
  }
  invalidateHistory(ref);
}

// --- Ketma-ket kunlar (streak) ---

class Streak {
  /// Bugun yoki kechagacha uzilmagan ketma-ket faol kunlar.
  final int current;
  final int best;
  final bool activeToday;

  const Streak({required this.current, required this.best, required this.activeToday});
}

DateTime _day(DateTime date) => DateTime(date.year, date.month, date.day);

/// Mashq yoki diktant bajarilgan kunlar asosida (mahalliy vaqt bo'yicha).
Streak computeStreak(UserHistory history) {
  final days = <DateTime>{
    for (final r in history.typing) _day(r.createdAt.toLocal()),
    for (final w in history.works)
      if (DateTime.tryParse(w.createdDate) case final date?) _day(date.toLocal()),
  };
  DateTime shift(DateTime date, int by) => DateTime(date.year, date.month, date.day + by);

  final today = _day(DateTime.now());
  final activeToday = days.contains(today);
  var current = 0;
  for (var day = activeToday ? today : shift(today, -1); days.contains(day); day = shift(day, -1)) {
    current++;
  }

  var best = 0;
  for (final date in days) {
    // Faqat ketma-ketlik boshidan sanaladi.
    if (days.contains(shift(date, -1))) continue;
    var length = 0;
    while (days.contains(shift(date, length))) {
      length++;
    }
    if (length > best) best = length;
  }
  return Streak(current: current, best: best, activeToday: activeToday);
}
