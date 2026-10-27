import 'package:dication/src/core/config/app_device.dart';
import 'package:dication/src/core/theme/app_theme.dart';
import 'package:dication/src/providers/dictation_provider.dart';
import 'package:dication/src/providers/account_provider.dart';
import 'package:dication/src/ui/screens/main_screens/main_card.dart';
import 'package:dication/src/ui/widgets/app_badge.dart';
import 'package:dication/src/ui/widgets/app_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Diktantlar ro'yxati (sahifalab yuklanadi).
class DictationList extends ConsumerWidget {
  const DictationList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dictationProvider);
    final history = ref.watch(userHistoryProvider).valueOrNull?.works ?? [];

    if (state.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const IconNode(icon: Icons.cloud_off_outlined, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                "Xatolik yuz berdi: ${state.error}",
                textAlign: TextAlign.center,
                style: AppText.body(14, color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Qayta uriniş',
                icon: Icons.refresh,
                variant: AppButtonVariant.outline,
                onPressed: () => ref.read(dictationProvider.notifier).refresh(),
              ),
            ],
          ),
        ),
      );
    }

    final list = state.items;
    final doneIds = history.map((work) => work.id).toSet();
    final gutter = context.isMobile ? 16.0 : 24.0;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.read(dictationProvider.notifier).refresh();
        invalidateHistory(ref);
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent - 200 &&
              state.hasMore &&
              !state.isLoadingMore) {
            ref.read(dictationProvider.notifier).fetchNextPage();
          }
          return false;
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(gutter, 24, gutter, 32),
              itemCount: list.length + 1 + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == 0) return _Intro(done: doneIds.length);
                final itemIndex = index - 1;
                if (itemIndex >= list.length) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final dictItem = list[itemIndex];
                return MainCard(
                  text: dictItem,
                  issDone: doneIds.contains(dictItem.id),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  final int done;

  const _Intro({required this.done});

  @override
  Widget build(BuildContext context) {
    final titleStyle = AppText.heading(context.isMobile ? 26 : 36);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppBadge(
            label: done == 0 ? 'Audio diktantlar' : 'Bajarilgan: $done ta',
            pulse: true,
          ),
          const SizedBox(height: 12),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Text('Diktantni tanlang va ', style: titleStyle),
              GradientText('yozişni boşlang', style: titleStyle),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Audio eşitasiz, matnni yozasiz, tizim esa imlo xatolarni avtomatik tekşiradi.',
            style: AppText.body(15, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
