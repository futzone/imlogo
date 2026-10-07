import 'package:dication/src/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Kichik statistik katak: tepada mono yorliq, pastda qiymat.
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final String? hint;
  final double width;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = AppColors.foreground,
    this.hint,
    this.width = 150,
  });

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppText.label(size: 10)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: AppText.mono(22, color: valueColor)),
          ),
        ],
      ),
    );
    return hint == null ? tile : Tooltip(message: hint!, child: tile);
  }
}
