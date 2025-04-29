import 'package:dication/src/core/config/app_device.dart';
import 'package:dication/src/core/config/app_fonts.dart';
import 'package:dication/src/core/config/app_router.dart';
import 'package:dication/src/core/constants/app_constants.dart';
import 'package:dication/src/ui/pages/dictation_page.dart';
import 'package:dication/src/ui/widgets/app_buttons.dart';
import 'package:flutter/material.dart';

class AppInfoScreen extends StatelessWidget {
  const AppInfoScreen({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) {
        return AppInfoScreen();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.isMobile ? null : 600,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(left: 16, right: 16, top: 8),
        child: Column(
          spacing: 8,
          children: [
            SizedBox(height: 8),
            Text(
              "Imlo Go haqida",
              style: TextStyle(
                fontSize: context.isMobile ? 16 : 24,
                fontFamily: extraBoldFamily,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              AppConstants.aboutText,
              style: TextStyle(
                fontSize: 14,
                fontFamily: mediumFamily,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              "Barcha huquqlar himoyalangan!",
              style: TextStyle(
                fontSize: 14,
                fontFamily: mediumFamily,
              ),
              textAlign: TextAlign.center,
            ),
            Container(
              width: double.infinity,
              color: Colors.grey,
              height: 1,
              margin: EdgeInsets.symmetric(vertical: 16),
            ),
            Text(
              "Loyihaga oid yangiliklardan doimiy xabardor bo'lish uchun bizning Imlo Go Telegram kanaliga a'zo bo'ling 👇",
              style: TextStyle(
                fontSize: 14,
                fontFamily: mediumFamily,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(),
            SimpleButton(
              onPressed: () async => await AppConstants.launchAppFor(AppConstants.telegramChannel),
              child: Container(
                margin: EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(48),
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.red],
                  ),
                ),
                padding: EdgeInsets.only(
                  left: 32,
                  right: 32,
                  top: 12,
                  bottom: 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 16,
                  children: [
                    Icon(Icons.telegram_outlined, color: Colors.white),
                    Text(
                      "Telegram Kanal",
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: mediumFamily,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SimpleButton(
              onPressed: () async => await AppConstants.launchAppFor(AppConstants.website),
              child: Container(
                margin: EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(48),
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.red],
                  ),
                ),
                padding: EdgeInsets.only(
                  left: 32,
                  right: 32,
                  top: 12,
                  bottom: 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 16,
                  children: [
                    Icon(Icons.language_outlined, color: Colors.white),
                    Text(
                      "ImloGo.uz",
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: mediumFamily,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () => AppRouter.close(context),
                child: Text(
                  "Yopish",
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: regularFamily,
                  ),
                ),
              ),
            ),
            SizedBox(height: 0),
          ],
        ),
      ),
    );
  }
}
