import 'package:dication/src/core/constants/app_constants.dart';
import 'package:dication/src/ui/widgets/app_buttons.dart';
import 'package:dication/src/ui/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  static void show(BuildContext context) {
    AppSheet.show(context, const AboutAppScreen());
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: "Imlo Go-ni istalgan qurilmada sinab ko'ring",
      subtitle:
          "Ilovalarimizni yuklab oling va istalgan qurilmada, istalgan paytda «Imlo Go» orqali o'zbek tili imlosi bo'yicha o'z bilimlaringizni orttiring!",
      children: [
        AppButton(
          label: "Android Ilova",
          icon: Icons.android_outlined,
          variant: AppButtonVariant.outline,
          expand: true,
          onPressed: () => AppConstants.launchAppFor(AppConstants.androidApp),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: "iOS uchun Ilova",
          icon: Icons.apple_outlined,
          variant: AppButtonVariant.outline,
          expand: true,
          onPressed: () => AppConstants.launchAppFor(AppConstants.iOSApp),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: "Windows uchun Ilova",
          icon: Icons.desktop_windows_outlined,
          variant: AppButtonVariant.outline,
          expand: true,
          onPressed: () => AppConstants.launchAppFor(AppConstants.windowsApp),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
