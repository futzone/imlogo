import 'dart:convert';

import 'package:dication/src/core/config/app_router.dart';
import 'package:dication/src/core/models/work.dart';
import 'package:dication/src/core/services/dictation_manager.dart';
import 'package:dication/src/providers/history_provider.dart';
import 'package:dication/src/ui/pages/main_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../ui/pages/dictation_result_page.dart';

class DictationController {
  WidgetRef ref;
  BuildContext context;
  final String _boxName = "works";

  DictationController({required this.context, required this.ref});

  void onCreate(Work work, DiktantEvaluator evaluator) async {
    final box = await Hive.openBox(_boxName);
    work.id = "${DateTime.now().millisecondsSinceEpoch}";
    work.createdDate = DateTime.now().toIso8601String();
    await box.put(work.id, jsonEncode(work.toJson())).then((_) {
      ref.invalidate(historyProvider);
      AppRouter.go(context, DictationResultPage(work: work));
    });
  }

  void showLoading() {
    showDialog(context: context, builder: (context) => Center(child: CircularProgressIndicator()));
  }

  void closeDialog() => AppRouter.close(context);
}
