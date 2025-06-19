import 'dart:developer';

import 'package:dication/src/core/database/static_database.dart';
import 'package:dication/src/core/models/text_model.dart';
import 'package:dication/src/providers/history_provider.dart';
import 'package:dication/src/ui/screens/main_screens/app_bar.dart';
import 'package:dication/src/ui/screens/main_screens/main_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainPage extends ConsumerWidget {
  const MainPage({super.key});

  List<TextModel> get list => StaticDatabase.texts;

  @override
  Widget build(BuildContext context, ref) {
    return Scaffold(
      body: ref.watch(historyProvider).when(
            error: (_, __) => Text("Xatolik yuz berdi"),
            loading: () => Center(
              child: CircularProgressIndicator(),
            ),
            data: (history) {
              log(history.toString());
              return CustomScrollView(
                slivers: [
                  AppBarMain(),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      childCount: list.length,
                      (context, index) {
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
              );
            },
          ),
    );
  }
}
