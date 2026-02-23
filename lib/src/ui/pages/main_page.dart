import 'dart:developer';

import 'package:dication/src/providers/dictation_provider.dart';
import 'package:dication/src/providers/history_provider.dart';
import 'package:dication/src/ui/screens/main_screens/app_bar.dart';
import 'package:dication/src/ui/screens/main_screens/main_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainPage extends ConsumerWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final state = ref.watch(dictationProvider);
    final historyAsync = ref.watch(historyProvider);

    if (state.isInitialLoading) {
      return SafeArea(
        child: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (state.error != null && state.items.isEmpty) {
      return SafeArea(
        child: Scaffold(
          body: Center(child: Text("Xatolik yuz berdi: ${state.error}")),
        ),
      );
    }

    final list = state.items;
    final history = historyAsync.valueOrNull ?? [];

    return SafeArea(
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            ref.read(dictationProvider.notifier).refresh();
            ref.invalidate(historyProvider);
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
            child: CustomScrollView(
              slivers: [
                AppBarMain(),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    childCount: list.length + (state.hasMore ? 1 : 0),
                    (context, index) {
                      if (index >= list.length) {
                        return Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final dictItem = list[index];
                      final isDone = history.where((el) {
                        log("Checking item: ${el.id} against dictItem: ${dictItem.id}");
                        return el.id == dictItem.id;
                      }).isNotEmpty;
                      log("isDone: $isDone, id: ${dictItem.id}");

                      return MainCard(
                        text: dictItem,
                        issDone: isDone,
                      );
                    },
                  ),
                ),
                SliverPadding(padding: EdgeInsets.all(24)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
