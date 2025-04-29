import 'package:dication/src/core/config/app_device.dart';
import 'package:dication/src/core/config/app_fonts.dart';
import 'package:dication/src/ui/screens/main_screens/app_bar.dart';
import 'package:dication/src/ui/screens/main_screens/main_card.dart';
import 'package:dication/src/ui/widgets/app_buttons.dart';
import 'package:dication/src/ui/widgets/hovered_widget.dart';
import 'package:flutter/material.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppBarMain(),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              childCount: 45,
              (context, index) => MainCard(),
            ),
          ),
          SliverPadding(padding: EdgeInsets.all(24)),
        ],
      ),
    );
  }
}
