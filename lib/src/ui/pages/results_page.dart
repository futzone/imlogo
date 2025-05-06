import 'package:dication/src/core/config/app_fonts.dart';
import 'package:dication/src/core/database/static_database.dart';
import 'package:dication/src/providers/history_provider.dart';
import 'package:dication/src/ui/screens/main_screens/result_card.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ResultsPage extends HookConsumerWidget {
  const ResultsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0.0,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          "Mening natijalarim",
          style: TextStyle(
            fontSize: 18,
            fontFamily: mediumFamily,
            color: Colors.white,
          ),
        ),
      ),
      body: ref.watch(historyProvider).when(
            loading: () => Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Text("$error"),
            data: (works) {
              if(works.isEmpty) {
                return Center(child: Text("Sizda topshirilgan diktantlar yo'q"));
              }

              return ListView.builder(
                itemCount: works.length,
                padding: EdgeInsets.only(bottom: 24),
                itemBuilder: (context, index) {
                  return ResultCard(model: works[index]);
                },
              );
            },
          ),
    );
  }
}
