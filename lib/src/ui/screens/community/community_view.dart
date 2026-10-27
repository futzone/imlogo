import 'dart:async';

import 'package:dication/src/core/services/account_service.dart';
import 'package:dication/src/core/theme/app_theme.dart';
import 'package:dication/src/providers/account_provider.dart';
import 'package:dication/src/ui/screens/account/auth_sheet.dart';
import 'package:dication/src/ui/widgets/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reyting ko'rsatkichi (veb-saytdagi `CommunityView` bilan bir xil).
class LeaderMetric {
  final String value;
  final String label;
  final String hint;

  /// Reytingda qatnashish sharti (PocketBase filtri).
  final String filter;
  final String Function(LeaderRow row) format;

  const LeaderMetric({
    required this.value,
    required this.label,
    required this.hint,
    required this.filter,
    required this.format,
  });

  static const accuracyMinGames = 10;
  static const bahoMinDictations = 3;

  static final Map<Board, List<LeaderMetric>> all = {
    Board.typing: [
      LeaderMetric(
        value: 'best_wpm',
        label: 'Eng tez',
        hint: 'Eng yaxşi natija (daqiqasiga söz). Aniqligi 75% dan past maşqlar hisobga olinmaydi.',
        filter: 'best_wpm > 0',
        format: (row) => '${row.value('best_wpm').round()} WPM',
      ),
      LeaderMetric(
        value: 'games',
        label: 'Eng faol',
        hint: 'Bajarilgan maşqlar soni.',
        filter: 'games > 0',
        format: (row) => '${row.value('games').round()} ta',
      ),
      LeaderMetric(
        value: 'total_seconds',
        label: 'Köp vaqt',
        hint: 'Maşq qilişga sarflangan umumiy vaqt.',
        filter: 'total_seconds > 0',
        format: (row) => formatDuration(row.value('total_seconds')),
      ),
      LeaderMetric(
        value: 'avg_accuracy',
        label: 'Eng aniq',
        hint: 'Örtaça aniqlik. Kamida $accuracyMinGames ta maşq bajarganlar qatnaşadi.',
        filter: 'games >= $accuracyMinGames',
        format: (row) => '${row.value('avg_accuracy').round()}%',
      ),
    ],
    Board.dictation: [
      LeaderMetric(
        value: 'total_ball',
        label: 'Eng köp ball',
        hint: 'Barça diktantlardan töplangan ball (har bir diktant böyiça oxirgi natija).',
        filter: 'total_ball > 0',
        format: (row) => '${row.value('total_ball').round()} ball',
      ),
      LeaderMetric(
        value: 'dictations',
        label: 'Eng faol',
        hint: 'Topşirilgan diktantlar soni.',
        filter: 'dictations > 0',
        format: (row) => '${row.value('dictations').round()} ta',
      ),
      LeaderMetric(
        value: 'avg_ball',
        label: 'Eng savodli',
        hint: 'Örtaça ball. Kamida $bahoMinDictations ta diktant topşirganlar qatnaşadi.',
        filter: 'dictations >= $bahoMinDictations',
        format: (row) => '${row.value('avg_ball').round()} ball',
      ),
    ],
  };

  static String formatDuration(double seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) return '$minutes daq';
    return '${minutes ~/ 60} soat ${minutes % 60} daq';
  }

  static String details(Board board, LeaderRow row) => board == Board.typing
      ? '${row.value('games').round()} ta maşq · örtaça ${row.value('avg_wpm').round()} WPM · ${row.value('avg_accuracy').round()}%'
      : '${row.value('dictations').round()} ta diktant · örtaça baho ${row.value('avg_baho').toStringAsFixed(1)} · ${row.value('avg_ball').round()} ball';
}

typedef LeaderboardQuery = ({Board board, LeaderboardPeriod period, int metric, int limit});

/// Reyting qatorlari (so'rov kaliti bo'yicha keshlanadi).
final leaderboardProvider = FutureProvider.autoDispose.family<List<LeaderRow>, LeaderboardQuery>((ref, q) {
  final metric = LeaderMetric.all[q.board]![q.metric];
  return AccountService.fetchLeaderboard(q.board, q.period, metric.value, metric.filter, limit: q.limit);
});

final myRankProvider =
    FutureProvider.autoDispose.family<({int rank, LeaderRow row})?, LeaderboardQuery>((ref, q) async {
  final userId = ref.watch(authProvider.select((a) => a?.id));
  if (userId == null) return null;
  final metric = LeaderMetric.all[q.board]![q.metric];
  try {
    return await AccountService.fetchMyRank(q.board, q.period, metric.value, metric.filter, userId);
  } catch (_) {
    return null;
  }
});

/// "Hamjamiyat": tez yozish va diktant bo'yicha reytinglar hamda haftalik musobaqa.
class CommunityView extends ConsumerStatefulWidget {
  const CommunityView({super.key});

  @override
  ConsumerState<CommunityView> createState() => _CommunityViewState();
}

class _CommunityViewState extends ConsumerState<CommunityView> {
  Board _board = Board.typing;
  int _metric = 0;
  LeaderboardPeriod _period = LeaderboardPeriod.week;

  LeaderboardQuery get _query => (board: _board, period: _period, metric: _metric, limit: 50);

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(authProvider);
    final metric = LeaderMetric.all[_board]![_metric];
    final rows = ref.watch(leaderboardProvider(_query));
    final me = ref.watch(myRankProvider(_query)).valueOrNull;

    return SectionScroll(
      onRefresh: () async {
        ref.invalidate(leaderboardProvider);
        ref.invalidate(myRankProvider);
      },
      children: [
        const PageHeading(
          title: 'Hamjamiyat',
          subtitle:
              'Imlo Go foydalanuvçilari reytingi va haftalik musobaqa. Hisobingizga kiring — natijalaringiz reytingga avtomatik qöşiladi.',
        ),
        const SizedBox(height: 20),
        WeeklyBanner(board: _board),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Segmented<Board>(
              options: const {Board.typing: 'Tez yoziş', Board.dictation: 'Diktant'},
              value: _board,
              onChanged: (board) => setState(() {
                _board = board;
                _metric = 0;
              }),
            ),
            Segmented<LeaderboardPeriod>(
              options: const {LeaderboardPeriod.week: 'Şu hafta', LeaderboardPeriod.all: 'Hamma vaqt'},
              value: _period,
              onChanged: (period) => setState(() => _period = period),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Segmented<int>(
            options: {
              for (var i = 0; i < LeaderMetric.all[_board]!.length; i++) i: LeaderMetric.all[_board]![i].label,
            },
            value: _metric,
            onChanged: (index) => setState(() => _metric = index),
          ),
        ),
        const SizedBox(height: 8),
        Text(metric.hint, style: AppText.body(12, color: AppColors.muted)),
        if (account == null) ...[
          const SizedBox(height: 16),
          NoticeCard(
            icon: Icons.emoji_events_outlined,
            text: 'Reytingda qatnaşiş uçun hisobingizga kiring.',
            action: SmallButton(label: 'Kiriş', onPressed: () => AuthSheet.show(context)),
          ),
        ],
        const SizedBox(height: 16),
        rows.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => EmptyState(
            icon: Icons.groups_outlined,
            color: AppColors.error,
            text: 'Reytingni yuklab bölmadi. Birozdan söng qayta urinib köring.',
            action: SmallButton(label: 'Qayta uriniş', onPressed: () => ref.invalidate(leaderboardProvider)),
          ),
          data: (rows) {
            if (rows.isEmpty) {
              return const EmptyState(
                icon: Icons.emoji_events_outlined,
                text: 'Bu reytingda hali heç kim yöq. Birinçi böling!',
              );
            }
            final meOutside = me != null && !rows.any((row) => row.id == me.row.id);
            return Column(
              children: [
                if (meOutside) ...[
                  LeaderItem(rank: me.rank, row: me.row, board: _board, metric: metric, highlight: true),
                  const SizedBox(height: 12),
                ],
                for (var i = 0; i < rows.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: LeaderItem(
                      rank: i + 1,
                      row: rows[i],
                      board: _board,
                      metric: metric,
                      highlight: rows[i].id == account?.id,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Haftalik musobaqa dushanba 00:00 (Toshkent, UTC+5) da yangilanadi.
DateTime weekEnd(DateTime now) {
  final local = now.toUtc().add(const Duration(hours: 5));
  final daysToMonday = (8 - local.weekday) % 7 == 0 ? 7 : (8 - local.weekday) % 7;
  final monday = DateTime.utc(local.year, local.month, local.day + daysToMonday);
  return monday.subtract(const Duration(hours: 5));
}

String formatCountdown(Duration left) {
  final minutes = left.inMinutes < 0 ? 0 : left.inMinutes;
  final days = minutes ~/ 1440;
  final hours = (minutes % 1440) ~/ 60;
  return days > 0 ? '$days kun $hours soat' : '$hours soat ${minutes % 60} daq';
}

/// Haftalik musobaqa: tugashiga qolgan vaqt va o'tgan hafta g'oliblari.
class WeeklyBanner extends ConsumerStatefulWidget {
  final Board board;

  const WeeklyBanner({super.key, required this.board});

  @override
  ConsumerState<WeeklyBanner> createState() => _WeeklyBannerState();
}

class _WeeklyBannerState extends ConsumerState<WeeklyBanner> {
  late final Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metric = LeaderMetric.all[widget.board]![0];
    final winners = ref
            .watch(leaderboardProvider((board: widget.board, period: LeaderboardPeriod.prevWeek, metric: 0, limit: 3)))
            .valueOrNull ??
        const [];
    final white70 = Colors.white.withValues(alpha: 0.75);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.glow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HAFTALIK MUSOBAQA', style: AppText.label(color: white70)),
          const SizedBox(height: 4),
          Text(
            widget.board == Board.typing ? 'Hafta eng tezkori kim?' : 'Hafta eng savodlisi kim?',
            style: AppText.heading(22, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Har duşanba 00:00 da (Toşkent vaqti) yangi hafta boşlanadi.',
            style: AppText.body(14, color: Colors.white.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hourglass_bottom, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Tugaşiga: ${formatCountdown(weekEnd(_now).difference(_now))}',
                  style: AppText.mono(13, color: Colors.white),
                ),
              ],
            ),
          ),
          if (winners.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text('ÖTGAN HAFTA ĞOLIBLARI', style: AppText.label(color: white70)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < winners.length; i++)
                  Container(
                    padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 13,
                          backgroundColor: Colors.white,
                          child: Text('${i + 1}', style: AppText.mono(12, color: AppColors.primary)),
                        ),
                        const SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 140),
                          child: Text(
                            winners[i].name,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(14, weight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(metric.format(winners[i]), style: AppText.mono(12, color: white70)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Reytingdagi bitta qator.
class LeaderItem extends StatelessWidget {
  final int rank;
  final LeaderRow row;
  final Board board;
  final LeaderMetric metric;
  final bool highlight;
  final bool compact;

  const LeaderItem({
    super.key,
    required this.rank,
    required this.row,
    required this.board,
    required this.metric,
    this.highlight = false,
    this.compact = false,
  });

  Widget _rankBadge() {
    const colors = {1: Color(0xFFE0A800), 2: Color(0xFF9AA3B2), 3: Color(0xFFC27C4E)};
    if (rank <= 3) {
      return Icon(rank == 1 ? Icons.workspace_premium : Icons.military_tech, size: 22, color: colors[rank]);
    }
    return Text('$rank', style: AppText.mono(14, color: AppColors.muted));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: compact ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        gradient: rank <= 3 && !compact
            ? LinearGradient(colors: [AppColors.tertiary.withValues(alpha: 0.25), Colors.white])
            : null,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: highlight ? AppColors.primary.withValues(alpha: 0.6) : AppColors.line),
        boxShadow: highlight ? AppShadows.glowCard : const [],
      ),
      child: Row(
        children: [
          SizedBox(width: 28, child: Center(child: _rankBadge())),
          const SizedBox(width: 10),
          UserAvatar(name: row.name, size: compact ? 30 : 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        row.name,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(15, weight: FontWeight.w600, height: 1.2),
                      ),
                    ),
                    if (highlight) ...[
                      const SizedBox(width: 8),
                      Text('SIZ', style: AppText.label(size: 10, color: AppColors.primary)),
                    ],
                  ],
                ),
                if (!compact) ...[
                  const SizedBox(height: 2),
                  Text(
                    LeaderMetric.details(board, row),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.mono(11, color: AppColors.muted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(metric.format(row), style: AppText.mono(compact ? 15 : 18, color: AppColors.primary)),
        ],
      ),
    );
  }
}
