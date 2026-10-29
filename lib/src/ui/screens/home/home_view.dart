import 'package:dication/src/core/config/app_device.dart';
import 'package:dication/src/core/config/app_router.dart';
import 'package:dication/src/core/models/typing_result.dart';
import 'package:dication/src/core/models/work.dart';
import 'package:dication/src/core/services/account_service.dart';
import 'package:dication/src/core/theme/app_theme.dart';
import 'package:dication/src/providers/account_provider.dart';
import 'package:dication/src/ui/pages/dictation_result_page.dart';
import 'package:dication/src/ui/pages/results_page.dart';
import 'package:dication/src/ui/screens/account/auth_sheet.dart';
import 'package:dication/src/ui/screens/community/community_view.dart';
import 'package:dication/src/ui/shell/app_tab.dart';
import 'package:dication/src/ui/widgets/app_badge.dart';
import 'package:dication/src/ui/widgets/app_card.dart';
import 'package:dication/src/ui/widgets/app_ui.dart';
import 'package:dication/src/ui/widgets/stat_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String _formatDate(DateTime date) {
  final d = date.toLocal();
  final today = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  final time = '${two(d.hour)}:${two(d.minute)}';
  final days = DateTime(today.year, today.month, today.day).difference(DateTime(d.year, d.month, d.day)).inDays;
  if (days == 0) return 'Bugun, $time';
  if (days == 1) return 'Keça, $time';
  return '${d.year}.${two(d.month)}.${two(d.day)}, $time';
}

/// "Asosiy": ketma-ket kunlar, oxirgi natijalar, hamjamiyat reytingi va
/// oxirgi harakatlar.
class HomeView extends ConsumerWidget {
  final OpenTab onOpen;

  const HomeView({super.key, required this.onOpen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(authProvider);
    final history = ref.watch(userHistoryProvider).valueOrNull;
    final wide = !context.isMobile;

    final streakCard = _StreakCard(history: history);
    final lastResults = _LastResults(history: history, onOpen: onOpen);

    return SectionScroll(
      onRefresh: () async {
        invalidateHistory(ref);
        ref.invalidate(leaderboardProvider);
      },
      children: [
        PageHeading(
          title: account == null ? 'Xuş kelibsiz!' : 'Salom, ${account.name.split(' ').first}!',
          subtitle: 'Bugun ham ozgina maşq qiling — har kuni yoziş savodxonlikni oşiradi.',
        ),
        if (account == null) ...[
          const SizedBox(height: 16),
          NoticeCard(
            icon: Icons.cloud_sync_outlined,
            text: 'Kirsangiz, natijalaringiz saqlanadi va reytingda qatnaşasiz.',
            action: SmallButton(label: 'Kiriş', onPressed: () => AuthSheet.show(context)),
          ),
        ],
        const SizedBox(height: 20),
        if (wide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [Expanded(child: streakCard), const SizedBox(width: 16), Expanded(child: lastResults)],
            ),
          )
        else ...[
          streakCard,
          const SizedBox(height: 16),
          lastResults,
        ],
        const SizedBox(height: 16),
        _QuickActions(onOpen: onOpen),
        const SizedBox(height: 16),
        _CommunityTop(onOpen: onOpen),
        const SizedBox(height: 16),
        _RecentActions(history: history),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  final UserHistory? history;

  const _StreakCard({required this.history});

  @override
  Widget build(BuildContext context) {
    final history = this.history;
    final streak = history == null ? null : computeStreak(history);
    final typing = history?.typing ?? const <TypingResult>[];
    final works = history?.works ?? const <Work>[];
    // Shubhali natijalar rekordga kirmaydi.
    final bestWpm = TypingResult.bestWpm(typing) ?? 0;
    const flame = Color(0xFFF97316);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(label: 'Ketma-ket kunlar'),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.local_fire_department, size: 40, color: flame),
              const SizedBox(width: 8),
              Text('${streak?.current ?? 0}', style: AppText.mono(44, color: flame, height: 1)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('kun', style: AppText.body(16, color: AppColors.muted)),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('ENG UZUN', style: AppText.label(size: 10)),
                  Text('${streak?.best ?? 0} kun', style: AppText.mono(18)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            streak == null || streak.current == 0
                ? 'Har kuni kamida bitta maşq yoki diktant bajaring.'
                : streak.activeToday
                    ? 'Bugungi maşq bajarildi — ertaga ham davom eting!'
                    : 'Bugun maşq qilmasangiz, ketma-ketlik uziladi.',
            style: AppText.body(14, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              StatTile(label: 'Eng yaxşi WPM', value: '${bestWpm.round()}', valueColor: AppColors.primary, width: 130),
              StatTile(label: 'Maşqlar', value: '${typing.length} ta', width: 130),
              StatTile(label: 'Diktantlar', value: '${works.length} ta', width: 130),
            ],
          ),
        ],
      ),
    );
  }
}

class _LastResults extends StatelessWidget {
  final UserHistory? history;
  final OpenTab onOpen;

  const _LastResults({required this.history, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final typing = history?.typing.firstOrNull;
    final work = history?.works.firstOrNull;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardTitle(
            label: 'Oxirgi natijalar',
            action: 'Hammasi',
            onAction: () => AppRouter.go(context, const ResultsPage()),
          ),
          const SizedBox(height: 12),
          if (history == null)
            const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
          else ...[
            _ResultTile(
              icon: Icons.keyboard_outlined,
              title: 'Tez yoziş',
              value: typing == null ? '—' : '${typing.wpm.round()} WPM',
              details: typing == null
                  ? 'Hali maşq bajarilmagan'
                  : '${typing.accuracy.round()}% aniqlik · ${typing.config.label} · ${_formatDate(typing.createdAt)}',
              onTap: () => typing == null ? onOpen(AppTab.typing) : AppRouter.go(context, const ResultsPage(initialTab: 1)),
            ),
            const SizedBox(height: 10),
            _ResultTile(
              icon: Icons.headphones_outlined,
              title: 'Diktant',
              value: work == null ? '—' : '${work.ball.round()} ball',
              details: work == null
                  ? 'Hali diktant topşirilmagan'
                  : '${work.text.title} · baho ${work.baho.round()}',
              onTap: () => work == null
                  ? onOpen(AppTab.dictation)
                  : AppRouter.go(context, DictationResultPage(useBack: true, work: work)),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String details;
  final VoidCallback onTap;

  const _ResultTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.details,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      color: AppColors.surface,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          IconNode(icon: icon, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.body(15, weight: FontWeight.w600, height: 1.2)),
                const SizedBox(height: 2),
                Text(details,
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.body(12, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GradientText(value, style: AppText.mono(18)),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final OpenTab onOpen;

  const _QuickActions({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    Widget action(AppTab tab, String title, String text) => Expanded(
          child: AppCard(
            onTap: () => onOpen(tab),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconNode(icon: tab.icon, size: 40),
                const SizedBox(height: 10),
                Text(title, style: AppText.heading(16, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(text, style: AppText.body(13, color: AppColors.muted)),
              ],
            ),
          ),
        );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          action(AppTab.typing, 'Maşqni boşlaş', 'Tezlik va aniqlik'),
          const SizedBox(width: 12),
          action(AppTab.dictation, 'Diktant yoziş', 'Audio eşitib yozing'),
          if (!context.isMobile) ...[
            const SizedBox(width: 12),
            action(AppTab.translator, 'Translator', 'Kirill ↔ lotin ↔ yangi'),
          ],
        ],
      ),
    );
  }
}

class _CommunityTop extends ConsumerWidget {
  final OpenTab onOpen;

  const _CommunityTop({required this.onOpen});

  static const _query = (board: Board.typing, period: LeaderboardPeriod.week, metric: 0, limit: 5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(authProvider);
    final rows = ref.watch(leaderboardProvider(_query));
    final metric = LeaderMetric.all[Board.typing]![0];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardTitle(label: 'Hafta eng tezkorlari', action: 'Reyting', onAction: () => onOpen(AppTab.community)),
          const SizedBox(height: 12),
          rows.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => Text('Reytingni yuklab bölmadi', style: AppText.body(14, color: AppColors.muted)),
            data: (rows) => rows.isEmpty
                ? Text('Bu hafta hali heç kim qatnaşmadi. Birinçi böling!',
                    style: AppText.body(14, color: AppColors.muted))
                : Column(
                    children: [
                      for (var i = 0; i < rows.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: LeaderItem(
                            rank: i + 1,
                            row: rows[i],
                            board: Board.typing,
                            metric: metric,
                            highlight: rows[i].id == account?.id,
                            compact: true,
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _RecentActions extends StatelessWidget {
  final UserHistory? history;

  const _RecentActions({required this.history});

  @override
  Widget build(BuildContext context) {
    final items = <({DateTime date, IconData icon, String text, VoidCallback onTap})>[
      for (final r in history?.typing.take(8) ?? const <TypingResult>[])
        (
          date: r.createdAt,
          icon: Icons.keyboard_outlined,
          text: 'Tez yoziş: ${r.wpm.round()} WPM · ${r.accuracy.round()}% · ${r.config.alphabetLabel}',
          onTap: () => AppRouter.go(context, const ResultsPage(initialTab: 1)),
        ),
      for (final w in history?.works.take(8) ?? const <Work>[])
        if (DateTime.tryParse(w.createdDate) case final date?)
          (
            date: date,
            icon: Icons.headphones_outlined,
            text: 'Diktant «${w.text.title}»: ${w.ball.round()} ball',
            onTap: () => AppRouter.go(context, DictationResultPage(useBack: true, work: w)),
          ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardTitle(
            label: 'Oxirgi harakatlar',
            action: items.isEmpty ? null : 'Tarix',
            onAction: () => AppRouter.go(context, const ResultsPage()),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Hali harakatlar yöq', style: AppText.body(14, color: AppColors.muted)),
            )
          else
            for (final item in items.take(6))
              InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(AppRadius.input),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  child: Row(
                    children: [
                      Icon(item.icon, size: 18, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(item.text,
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body(14, height: 1.3)),
                      ),
                      const SizedBox(width: 8),
                      Text(_formatDate(item.date), style: AppText.mono(11, color: AppColors.muted)),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
