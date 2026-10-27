import 'package:dication/src/core/config/app_device.dart';
import 'package:dication/src/core/config/app_router.dart';
import 'package:dication/src/core/models/detected_error.dart';
import 'package:dication/src/core/models/error_type.dart';
import 'package:dication/src/core/models/work.dart';
import 'package:dication/src/core/theme/app_theme.dart';
import 'package:dication/src/core/utils/get_rate_color.dart';
import 'package:dication/src/ui/pages/main_page.dart';
import 'package:dication/src/ui/widgets/app_badge.dart';
import 'package:dication/src/ui/widgets/app_buttons.dart';
import 'package:dication/src/ui/widgets/app_card.dart';
import 'package:dication/src/ui/widgets/app_scaffold.dart';
import 'package:dication/src/ui/widgets/stat_tile.dart';
import 'package:flutter/material.dart';

class DictationResultPage extends StatelessWidget {
  final Work work;
  final bool useBack;

  const DictationResultPage({super.key, this.useBack = false, required this.work});

  void _goHome(BuildContext context) => AppRouter.open(context, MainPage());

  @override
  Widget build(BuildContext context) {
    final page = _buildBody(context);
    if (useBack) return page;

    // Diktantdan keyin "orqaga" bosilsa, yozish sahifasiga emas, bosh sahifaga qaytiladi.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goHome(context);
      },
      child: page,
    );
  }

  Widget _buildBody(BuildContext context) {
    final gutter = context.isMobile ? 16.0 : 24.0;
    final rateColor = getRateColor(work.baho);
    final tileWidth = context.isMobile
        ? (MediaQuery.of(context).size.width - gutter * 2 - 12) / 2
        : 190.0;

    return AppPageScaffold(
      title: "Natija",
      onBack: useBack ? null : () => _goHome(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              corners: true,
              color: Colors.white.withValues(alpha: 0.85),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppBadge(label: 'Diktant natijasi'),
                        const SizedBox(height: 12),
                        Text(
                          work.text.title,
                          style: AppText.heading(context.isDesktop ? 28 : 22),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text("Ball:", style: AppText.body(15, color: AppColors.muted)),
                            Text(
                              work.ball.toStringAsFixed(1),
                              style: AppText.mono(16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    children: [
                      Text(
                        work.baho.toStringAsFixed(1),
                        maxLines: 1,
                        softWrap: false,
                        style: AppText.mono(
                          context.isMobile ? 48 : 64,
                          color: rateColor,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text("BAHO", style: AppText.label()),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                StatTile(
                  label: "Imloviy xatoliklar",
                  value: "${work.imloErrorCount} ta",
                  width: tileWidth,
                ),
                StatTile(
                  label: "Punktuatsion xatoliklar",
                  value: "${work.punktuatsionErrorCount} ta",
                  width: tileWidth,
                ),
                StatTile(
                  label: "Uslubiy xatoliklar",
                  value: "${work.uslubiyErrorCount} ta",
                  width: tileWidth,
                ),
                StatTile(
                  label: "Grafik xatoliklar",
                  value: "${work.grafikErrorCount} ta",
                  width: tileWidth,
                ),
              ],
            ),
            if (work.errors.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text("Xatoliklar", style: AppText.heading(20, weight: FontWeight.w600)),
              const SizedBox(height: 12),
              for (final item in work.errors) _ErrorCard(error: item),
            ],
            const SizedBox(height: 24),
            Center(
              child: AppButton(
                label: "Boş sahifaga",
                icon: Icons.home_outlined,
                onPressed: () => _goHome(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final DetectedError error;

  const _ErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          _row("Aslida:", error.originalFragment, AppColors.success),
          _row("Siz kiritgan:", error.userFragment, AppColors.error),
          _row("Xatolik turi:", error.type.toName, AppColors.primary),
          _row("Xatolik:", error.description, AppColors.foreground),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(label, style: AppText.body(13, color: AppColors.muted)),
          ),
          Expanded(
            child: Text(
              value,
              style: AppText.body(14, weight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
