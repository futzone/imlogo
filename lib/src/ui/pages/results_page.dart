import 'package:dication/src/core/config/app_device.dart';
import 'package:dication/src/core/models/typing_result.dart';
import 'package:dication/src/core/theme/app_theme.dart';
import 'package:dication/src/providers/account_provider.dart';
import 'package:dication/src/ui/screens/account/auth_sheet.dart';
import 'package:dication/src/ui/screens/main_screens/app_header.dart';
import 'package:dication/src/ui/screens/main_screens/result_card.dart';
import 'package:dication/src/ui/screens/typing/typing_result_view.dart';
import 'package:dication/src/ui/widgets/app_badge.dart';
import 'package:dication/src/ui/widgets/app_card.dart';
import 'package:dication/src/ui/widgets/app_scaffold.dart';
import 'package:dication/src/ui/widgets/app_ui.dart';
import 'package:dication/src/ui/widgets/stat_tile.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ResultsPage extends StatefulHookConsumerWidget {
  /// 0 — diktantlar, 1 — tez yozish.
  final int initialTab;

  const ResultsPage({super.key, this.initialTab = 0});

  @override
  ConsumerState<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends ConsumerState<ResultsPage> {
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final gutter = context.isMobile ? 16.0 : 24.0;

    return AppPageScaffold(
      title: "Mening natijalarim",
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 0),
            child: const _SyncNotice(),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 0),
            child: GlassBar(
              padding: const EdgeInsets.all(6),
              child: SectionTabs(
                index: _tab,
                onChanged: (index) => setState(() => _tab = index),
                expand: context.isMobile,
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                _buildDictations(gutter),
                _buildTyping(gutter),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDictations(double gutter) {
    return ref.watch(userHistoryProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _Empty(text: "$error"),
          data: (history) {
            final works = history.works;
            if (works.isEmpty) {
              return const _Empty(text: "Sizda topşirilgan diktantlar yöq");
            }

            return ListView.builder(
              itemCount: works.length,
              padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 24),
              itemBuilder: (context, index) {
                return ResultCard(model: works[index]);
              },
            );
          },
        );
  }

  Widget _buildTyping(double gutter) {
    return ref.watch(userHistoryProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _Empty(text: "$error"),
          data: (history) {
            final results = history.typing;
            if (results.isEmpty) {
              return const _Empty(
                text: "Hali tez yoziş maşqini bajarmagansiz",
              );
            }

            final best = results.map((r) => r.wpm).reduce((a, b) => a > b ? a : b);
            final average =
                results.map((r) => r.wpm).reduce((a, b) => a + b) / results.length;
            final accuracy = results.map((r) => r.accuracy).reduce((a, b) => a + b) /
                results.length;

            return ListView.builder(
              itemCount: results.length + 1,
              padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 24),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      StatTile(
                        label: 'Eng yaxşi (WPM)',
                        value: best.round().toString(),
                        valueColor: AppColors.primary,
                      ),
                      StatTile(
                        label: 'Örtaça (WPM)',
                        value: average.round().toString(),
                      ),
                      StatTile(
                        label: 'Örtaça aniqlik',
                        value: '${accuracy.round()}%',
                      ),
                      StatTile(
                        label: 'Maşqlar',
                        value: '${results.length} ta',
                      ),
                    ],
                  );
                }
                return _TypingResultCard(result: results[index - 1]);
              },
            );
          },
        );
  }
}

class _Empty extends StatelessWidget {
  final String text;

  const _Empty({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const IconNode(icon: Icons.inbox_outlined),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppText.body(15, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingResultCard extends StatelessWidget {
  final TypingResult result;

  const _TypingResultCard({required this.result});

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: TypingResultView(result: result),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = result.config;
    final flags = [
      config.label,
      config.alphabetLabel,
      if (config.punctuation) 'tiniş belgilari',
      if (config.numbers) 'raqamlar',
    ].join(' · ');

    return AppCard(
      onTap: () => _showDetails(context),
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GradientText(
                  result.wpm.round().toString(),
                  style: AppText.mono(28, height: 1),
                ),
                const SizedBox(height: 4),
                Text('WPM', style: AppText.label(size: 10)),
              ],
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                MetaChip(
                  icon: Icons.track_changes,
                  label: 'Aniqlik: ${result.accuracy.round()}%',
                ),
                MetaChip(icon: Icons.tune, label: flags),
                MetaChip(
                  icon: Icons.calendar_today_outlined,
                  label: result.formattedDate,
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward, size: 18, color: AppColors.primary),
        ],
      ),
    );
  }
}

/// Hisob holati: mehmonga — natijalar faqat shu qurilmada; kirganga —
/// hisobga yuklanmagan natijalarni yuklash taklifi.
class _SyncNotice extends ConsumerStatefulWidget {
  const _SyncNotice();

  @override
  ConsumerState<_SyncNotice> createState() => _SyncNoticeState();
}

class _SyncNoticeState extends ConsumerState<_SyncNotice> {
  bool _syncing = false;

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(authProvider);
    final history = ref.watch(userHistoryProvider).valueOrNull;

    if (account == null) {
      return NoticeCard(
        icon: Icons.phone_android,
        text: 'Natijalar şu qurilmada saqlanadi. Hisobingizga kirsangiz, istalgan qurilmada körasiz.',
        action: SmallButton(label: 'Kiriş', onPressed: () => AuthSheet.show(context)),
      );
    }
    if (history == null || history.unsyncedCount == 0) return const SizedBox.shrink();
    return NoticeCard(
      icon: Icons.cloud_upload_outlined,
      text: 'Şu qurilmada hisobingizga yuklanmagan ${history.unsyncedCount} ta natija bor.',
      action: SmallButton(
        label: _syncing ? 'Yuklanmoqda…' : 'Hisobga yuklaş',
        onPressed: _syncing
            ? null
            : () async {
                setState(() => _syncing = true);
                await syncHistory(ref, account.id, history);
                if (mounted) setState(() => _syncing = false);
              },
      ),
    );
  }
}
