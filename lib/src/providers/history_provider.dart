import 'dart:convert';

import 'package:dication/src/core/models/work.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final historyProvider = FutureProvider((ref) async {
  final List<Work> list = [];
  final box = await Hive.openBox("works");
  for (final item in box.values) {
    list.add(Work.fromJson(jsonDecode(item)));
  }
  return list;
});
