import 'package:dication/src/ui/pages/main_page.dart';
import 'package:flutter/material.dart';

const appName = "Imlo Go";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dictation App',
      theme: ThemeData(),
      home: MainPage(),
    );
  }
}
