import 'package:dication/src/core/config/app_device.dart';
import 'package:dication/src/core/config/app_fonts.dart';
import 'package:dication/src/core/config/app_router.dart';
import 'package:dication/src/providers/app_info_provider.dart';
import 'package:dication/src/ui/widgets/app_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AppInfoScreen extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncInfo = ref.watch(appInfoProvider);

    return Container(
      width: context.isMobile ? null : 600,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: asyncInfo.when(
        loading: () => Padding(
          padding: EdgeInsets.all(48),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, _) => Padding(
          padding: EdgeInsets.all(48),
          child: Center(child: Text("Ma'lumotlarni yuklashda xatolik")),
        ),
        data: (info) => SingleChildScrollView(
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
                info.about,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: mediumFamily,
                ),
                textAlign: TextAlign.center,
              ),
              if (info.license != null)
                Text(
                  info.license!,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: mediumFamily,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (info.telegram != null || info.website != null || info.github != null || info.docs != null) ...[
                Container(
                  width: double.infinity,
                  color: Colors.grey,
                  height: 1,
                  margin: EdgeInsets.symmetric(vertical: 16),
                ),
                if (info.telegram != null)
                  Text(
                    "Loyihaga oid yangiliklardan doimiy xabardor bo\u2018lish uchun bizning Imlo Go Telegram kanaliga a\u2018zo bo\u2018ling \u{1F447}",
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: mediumFamily,
                    ),
                    textAlign: TextAlign.center,
                  ),
                SizedBox(),
                if (info.telegram != null)
                  _LinkButton(
                    url: info.telegram!,
                    icon: Icons.telegram_outlined,
                    label: "Telegram Kanal",
                  ),
                if (info.website != null)
                  _LinkButton(
                    url: info.website!,
                    icon: Icons.language_outlined,
                    label: "ImloGo.uz",
                  ),
                if (info.github != null)
                  _LinkButton(
                    url: info.github!,
                    icon: Icons.code_outlined,
                    label: "GitHub",
                  ),
                if (info.docs != null)
                  _LinkButton(
                    url: info.docs!,
                    icon: Icons.description_outlined,
                    label: "Hujjatlar",
                  ),
              ],
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
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  final String url;
  final IconData icon;
  final String label;

  const _LinkButton({
    required this.url,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleButton(
      onPressed: () async => await launchUrlString(url),
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
            Icon(icon, color: Colors.white),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontFamily: mediumFamily,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
