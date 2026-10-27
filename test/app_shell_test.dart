import 'dart:io';

import 'package:dication/src/core/services/pb_client.dart';
import 'package:dication/src/ui/pages/main_page.dart';
import 'package:dication/src/ui/shell/app_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Ilova qolipi telefon va keng ekranda har bir bo'limda toshib chiqmasdan chiziladi.
void main() {
  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync('imlogo_test').path);
    await initPocketBase();
  });

  for (final size in const [Size(320, 640), Size(390, 844), Size(800, 1000), Size(1280, 800), Size(1600, 900)]) {
    final wide = size.width >= MainPage.sidebarBreakpoint;
    for (final tab in wide ? AppTab.values : AppTab.mobile) {
      testWidgets('${size.width.toInt()}px: ${tab.label}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.runAsync(() async {
          await tester.pumpWidget(ProviderScope(child: MaterialApp(home: MainPage(initialTab: tab))));
          await Future.delayed(const Duration(milliseconds: 300));
        });
        await tester.pump(const Duration(milliseconds: 100));
        final error = tester.takeException();
        if (error is FlutterError) debugPrint(error.diagnostics.take(6).map((d) => d.toString()).join("\n"));
        expect(error, isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
