import 'package:dication/src/core/database/static_database.dart';
import 'package:dication/src/core/models/text_model.dart';
import 'package:dication/src/ui/screens/main_screens/app_bar.dart';
import 'package:dication/src/ui/screens/main_screens/main_card.dart';
import 'package:flutter/material.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  List<TextModel> get list => StaticDatabase.texts;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppBarMain(),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              childCount: list.length,
              (context, index) => MainCard(text: list[index]),
            ),
          ),
          SliverPadding(padding: EdgeInsets.all(24)),
        ],
      ),
    );
  }
}
