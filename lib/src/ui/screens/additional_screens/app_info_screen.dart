import 'package:dication/main.dart';
import 'package:dication/src/core/theme/app_theme.dart';
import 'package:dication/src/providers/app_info_provider.dart';
import 'package:dication/src/ui/widgets/app_buttons.dart';
import 'package:dication/src/ui/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AppInfoScreen extends ConsumerWidget {
  const AppInfoScreen({super.key});

  static void show(BuildContext context) {
    AppSheet.show(context, const AppInfoScreen());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncInfo = ref.watch(appInfoProvider);

    return asyncInfo.when(
      loading: () => const AppSheet(
        title: "Imlo Go haqida",
        children: [
          Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
      error: (err, _) => AppSheet(
        title: "Imlo Go haqida",
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              "Ma'lumotlarni yuklashda xatolik",
              textAlign: TextAlign.center,
              style: AppText.body(14, color: AppColors.muted),
            ),
          ),
        ],
      ),
      data: (info) {
        final links = <Widget>[
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
        ];

        return AppSheet(
          title: "Imlo Go haqida",
          children: [
            Text(
              info.about,
              textAlign: TextAlign.center,
              style: AppText.body(14),
            ),
            if (info.license != null) ...[
              const SizedBox(height: 8),
              Text(
                info.license!,
                textAlign: TextAlign.center,
                style: AppText.body(14, color: AppColors.muted),
              ),
            ],
            if (links.isNotEmpty) ...[
              Container(
                height: 1,
                color: AppColors.line,
                margin: const EdgeInsets.symmetric(vertical: 20),
              ),
              if (info.telegram != null) ...[
                Text(
                  "Loyihaga oid yangiliklardan doimiy xabardor bo‘lish uchun bizning Imlo Go Telegram kanaliga a’zo bo‘ling \u{1F447}",
                  textAlign: TextAlign.center,
                  style: AppText.body(14, color: AppColors.muted),
                ),
                const SizedBox(height: 16),
              ],
              ...links,
            ],
            const SizedBox(height: 4),
            Center(
              child: Text(
                '$appName $appVersion',
                style: AppText.label(),
              ),
            ),
            const SizedBox(height: 4),
          ],
        );
      },
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppButton(
        label: label,
        icon: icon,
        variant: AppButtonVariant.outline,
        expand: true,
        onPressed: () => launchUrlString(url),
      ),
    );
  }
}
