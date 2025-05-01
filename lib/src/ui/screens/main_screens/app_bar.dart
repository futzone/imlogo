import 'package:dication/main.dart';
import 'package:dication/src/core/config/app_device.dart';
import 'package:dication/src/core/config/app_fonts.dart';
import 'package:dication/src/core/config/app_router.dart';
import 'package:dication/src/ui/pages/results_page.dart';
import 'package:dication/src/ui/screens/additional_screens/app_info_screen.dart';
import 'package:dication/src/ui/widgets/app_buttons.dart';
import 'package:flutter/material.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../additional_screens/about_app_screen.dart';

class AppBarMain extends StatelessWidget {
  const AppBarMain({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPinnedHeader(
      child: Container(
        padding: EdgeInsets.only(left: 24, right: 24),
        height: context.isMobile ? 64 : 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
          color: Theme.of(context).primaryColor,
        ),
        child: Row(
          spacing: context.isMobile ? 16 : 24,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              appName,
              style: TextStyle(
                color: Colors.white,
                fontSize: context.isDesktop ? 32 : 20,
                fontFamily: boldFamily,
              ),
            ),
            Spacer(),
            SimpleButton(
              onPressed: () => AboutAppScreen.show(context),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(80),
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
                padding: EdgeInsets.all(context.isDesktop ? 16 : 8),
                child: Row(
                  spacing: 16,
                  children: [
                    Icon(Icons.app_shortcut),
                    if (context.isDesktop)
                      Text(
                        "Ilovalarimiz",
                        style: TextStyle(
                          fontSize: !context.isMobile ? 16 : 14,
                          fontFamily: mediumFamily,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SimpleButton(
              onPressed: () => AppInfoScreen.show(context),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(80),
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
                padding: EdgeInsets.all(context.isDesktop ? 16 : 8),
                child: Row(
                  spacing: 16,
                  children: [
                    Icon(Icons.info_outline),
                    if (context.isDesktop)
                      Text(
                        "Dastur haqida",
                        style: TextStyle(
                          fontSize: !context.isMobile ? 16 : 14,
                          fontFamily: mediumFamily,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SimpleButton(
              onPressed: () => AppRouter.go(context, ResultsPage()),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(80),
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
                padding: EdgeInsets.all(context.isDesktop ? 16 : 8),
                child: Row(
                  spacing: 16,
                  children: [
                    Icon(Icons.history),
                    if (context.isDesktop)
                      Text(
                        "Natijalarim",
                        style: TextStyle(
                          fontSize: !context.isMobile ? 16 : 14,
                          fontFamily: mediumFamily,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
