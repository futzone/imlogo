import 'package:dication/src/core/config/app_device.dart';
import 'package:dication/src/core/models/text_model.dart';
import 'package:dication/src/core/theme/app_theme.dart';
import 'package:dication/src/ui/screens/main_screens/before_start_screen.dart';
import 'package:dication/src/ui/widgets/app_badge.dart';
import 'package:dication/src/ui/widgets/app_card.dart';
import 'package:flutter/material.dart';

class MainCard extends StatelessWidget {
  final TextModel text;
  final bool issDone;

  const MainCard({super.key, required this.text, required this.issDone});

  @override
  Widget build(BuildContext context) {
    final action = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Boşlaş",
          style: AppText.body(15,
              weight: FontWeight.w600, color: AppColors.primary),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.arrow_forward, size: 18, color: AppColors.primary),
      ],
    );

    return AppCard(
      onTap: () => BeforeStartScreen.show(context, text),
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconNode(
                icon: issDone ? Icons.check : Icons.headphones_outlined,
                color: issDone ? AppColors.success : AppColors.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text.title,
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
                          label: "Davomiyligi: ${text.time} min",
                        ),
                        MetaChip(
                          icon: Icons.text_fields,
                          label: "Sözlar soni: ${text.length} ta",
                        ),
                        MetaChip(
                          icon: Icons.accessibility,
                          label:
                              "Yoş çegarasi: ${text.ageName} yoş, (${text.className})",
                        ),
                        if (text.formattedDate.isNotEmpty)
                          MetaChip(
                            icon: Icons.calendar_today_outlined,
                            label: "Qöşilgan vaqti: ${text.formattedDate}",
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
