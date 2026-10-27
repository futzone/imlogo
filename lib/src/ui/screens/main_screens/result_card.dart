import 'package:dication/src/core/config/app_device.dart';
import 'package:dication/src/core/config/app_router.dart';
import 'package:dication/src/core/models/work.dart';
import 'package:dication/src/core/theme/app_theme.dart';
import 'package:dication/src/core/utils/get_rate_color.dart';
import 'package:dication/src/core/utils/time_utils.dart';
import 'package:dication/src/ui/widgets/app_badge.dart';
import 'package:dication/src/ui/widgets/app_card.dart';
import 'package:flutter/material.dart';

import '../../pages/dictation_result_page.dart';

class ResultCard extends StatelessWidget {
  final Work model;

  const ResultCard({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final rateColor = getRateColor(model.baho);
    final action = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Batafsil",
          style: AppText.body(15,
              weight: FontWeight.w600, color: AppColors.primary),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.arrow_forward, size: 18, color: AppColors.primary),
      ],
    );

    return AppCard(
      onTap: () {
        AppRouter.go(context, DictationResultPage(useBack: true, work: model));
      },
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rateColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: rateColor.withValues(alpha: 0.35)),
                ),
                child: Text(
                  "${model.baho.round()}",
                  style: AppText.mono(22, color: rateColor),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.text.title,
                      style: AppText.heading(
                        context.isDesktop ? 20 : 17,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 20,
                      runSpacing: 8,
                      children: [
                        MetaChip(
                          icon: Icons.timelapse_outlined,
                          label: "Sarflangan vaqt: ${formatTime(model.worktime)}",
                        ),
                        MetaChip(
                          icon: Icons.text_fields,
                          label: "Sözlar soni: ${model.text.length} ta",
                        ),
                        MetaChip(
                          icon: Icons.accessibility,
                          label:
                              "Yoş çegarasi: ${model.text.ageName} yoş, (${model.text.className})",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!context.isMobile) ...[
                const SizedBox(width: 16),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: action,
                ),
              ],
            ],
          ),
          if (context.isMobile) ...[
            const SizedBox(height: 12),
            action,
          ],
        ],
      ),
    );
  }
}
