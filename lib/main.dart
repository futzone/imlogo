import 'package:dication/src/core/services/pb_client.dart';
import 'package:dication/src/core/theme/app_theme.dart';
import 'package:dication/src/ui/pages/main_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';

const appName = "Imlo Go";
const appVersion = "v1.1.0";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await initPocketBase();
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Imlo Go',
      theme: buildAppTheme(),
      home: MainPage(),
    );
  }
}
