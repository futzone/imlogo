import 'package:dication/src/core/config/app_device.dart';
import 'package:dication/src/core/models/typing_result.dart';
import 'package:dication/src/core/theme/app_theme.dart';
import 'package:dication/src/ui/screens/typing/typing_chart.dart';
import 'package:dication/src/ui/widgets/app_badge.dart';
import 'package:dication/src/ui/widgets/app_buttons.dart';
import 'package:dication/src/ui/widgets/app_card.dart';
import 'package:dication/src/ui/widgets/stat_tile.dart';
import 'package:flutter/material.dart';

/// Mashq yakunidagi natija: tezlik, aniqlik, grafik va batafsil ko'rsatkichlar.
class TypingResultView extends StatelessWidget {
  final TypingResult result;

  /// Shu sozlamadagi avvalgi eng yaxshi natija (bo'lmasa `null`).
  final double? previousBest;
  final VoidCallback? onRestart;
  final VoidCallback? onOpenHistory;

  const TypingResultView({
    super.key,
    required this.result,
    this.previousBest,
    this.onRestart,
    this.onOpenHistory,
  });

  bool get _isRecord =>
      previousBest != null && result.wpm > previousBest! && result.wpm > 0;

  @override
  Widget build(BuildContext context) {
    final big = context.isMobile ? 56.0 : 80.0;
    final config = result.config;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            AppBadge(label: config.label),
            if (config.punctuation) const AppBadge(label: 'tinish belgilari'),
            if (config.numbers) const AppBadge(label: 'raqamlar'),
            if (_isRecord)
              const AppBadge(
                label: 'Yangi rekord',
                pulse: true,
                color: AppColors.success,
              ),
          ],
        ),
        const SizedBox(height: 20),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Headline(
                value: GradientText(
                  result.wpm.round().toString(),
                  style: AppText.mono(big, height: 1),
                ),
                label: 'so‘z/daqiqa (WPM)',
              ),
              SizedBox(width: context.isMobile ? 32 : 64),
              _Headline(
                value: Text(
                  '${result.accuracy.round()}%',
                  style: AppText.mono(big, height: 1),
                ),
                label: 'aniqlik',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AppCard(
          corners: true,
          color: Colors.white.withValues(alpha: 0.8),
          padding: const EdgeInsets.fromLTRB(16, 16, 20, 12),
          child: SizedBox(
            height: context.isMobile ? 140 : 180,
            child: TypingChart(samples: result.samples),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            StatTile(
              label: 'Xom tezlik',
              value: result.raw.round().toString(),
              hint: 'Xatolar hisobga olinmagan tezlik',
            ),
            StatTile(
              label: 'Belgilar',
              value:
                  '${result.correctChars}/${result.incorrectChars}/${result.extraChars}/${result.missedChars}',
              hint: 'to‘g‘ri / xato / ortiqcha / tushib qolgan',
            ),
            StatTile(
              label: 'Barqarorlik',
              value: '${result.consistency.round()}%',
              hint: 'Tezlik mashq davomida qanchalik bir tekis bo‘lgani',
            ),
            StatTile(
              label: 'Vaqt',
              value: '${result.seconds.round()}s',
            ),
            if (previousBest != null)
              StatTile(
                label: 'Avvalgi rekord',
                value: previousBest!.round().toString(),
                valueColor: AppColors.primary,
              ),
          ],
        ),
        if (onRestart != null || onOpenHistory != null) ...[
          const SizedBox(height: 28),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              if (onRestart != null)
                AppButton(
                  label: 'Qayta boshlash',
                  icon: Icons.refresh,
                  onPressed: onRestart,
                ),
              if (onOpenHistory != null)
                AppButton(
                  label: 'Natijalar tarixi',
                  icon: Icons.history,
                  variant: AppButtonVariant.outline,
                  onPressed: onOpenHistory,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Headline extends StatelessWidget {
  final Widget value;
  final String label;

  const _Headline({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        value,
        const SizedBox(height: 8),
        Text(label.toUpperCase(), style: AppText.label()),
      ],
    );
  }
}
