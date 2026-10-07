import 'package:dication/src/core/config/app_device.dart';
import 'package:dication/src/ui/screens/main_screens/app_header.dart';
import 'package:dication/src/ui/screens/main_screens/dictation_list.dart';
import 'package:dication/src/ui/screens/typing/typing_view.dart';
import 'package:dication/src/ui/widgets/app_background.dart';
import 'package:dication/src/ui/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';

/// Bosh sahifa: "Diktant" va "Tez yozish" bo'limlari.
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _index = 0;

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final gutter = context.isMobile ? 16.0 : 24.0;
    // Klaviatura ochiq bo'lganda pastki navigatsiya joy egallamasin.
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final tabsInHeader =
        MediaQuery.of(context).size.width >= AppHeader.tabsBreakpoint;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 0),
                    child: AppHeader(
                      index: _index,
                      onChanged: _select,
                      showTabs: tabsInHeader,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _index,
                  children: [
                    const DictationList(),
                    TypingView(active: _index == 1),
                  ],
                ),
              ),
              if (!tabsInHeader && !keyboardOpen)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: GlassBar(
                      padding: const EdgeInsets.all(6),
                      child: SectionTabs(
                        index: _index,
                        onChanged: _select,
                        expand: true,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
