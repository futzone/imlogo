import 'package:dication/src/core/config/app_device.dart';
import 'package:dication/src/core/theme/app_theme.dart';
import 'package:dication/src/ui/widgets/hovered_widget.dart';
import 'package:flutter/material.dart';

/// "Natijalarim" sahifasidagi yorliqlar.
class AppSection {
  final String label;
  final IconData icon;

  const AppSection(this.label, this.icon);

  static const List<AppSection> all = [
    AppSection('Diktant', Icons.headphones_outlined),
    AppSection('Tez yoziş', Icons.keyboard_outlined),
  ];
}

/// Imlo Go logotipi: Fredoka Bold, "IMLO" binafsha, "GO" qora
/// (landing sahifadagi `logo.svg` bilan bir xil).
class AppLogo extends StatelessWidget {
  final double? size;

  const AppLogo({super.key, this.size});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Imlo Go',
      child: ExcludeSemantics(
        child: Text.rich(
          const TextSpan(
            children: [
              TextSpan(text: 'IMLO', style: TextStyle(color: AppColors.logoPurple)),
              TextSpan(text: 'GO', style: TextStyle(color: AppColors.logoBlack)),
            ],
          ),
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: size ?? (context.isMobile ? 24 : 28),
            fontWeight: FontWeight.w700,
            fontVariations: const [FontVariation('wght', 700)],
            height: 1,
          ),
          textScaler: TextScaler.noScaling,
        ),
      ),
    );
  }
}

/// Bo'limlar orasida almashtirgich. Keng ekranda sarlavhada, telefonda —
/// ekran pastida ko'rsatiladi.
class SectionTabs extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final bool expand;

  const SectionTabs({
    super.key,
    required this.index,
    required this.onChanged,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        for (var i = 0; i < AppSection.all.length; i++)
          expand ? Expanded(child: _tab(i)) : _tab(i),
      ],
    );
  }

  Widget _tab(int i) {
    final section = AppSection.all[i];
    final selected = i == index;
    return Semantics(
      button: true,
      selected: selected,
      child: HoveredWidget(
        onPressed: () => onChanged(i),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        builder: (hovered) {
          final color = selected
              ? Colors.white
              : hovered
                  ? AppColors.primary
                  : AppColors.muted;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: selected ? AppColors.brandGradient : null,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: selected ? AppShadows.glow : const [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(section.icon, size: 18, color: color),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    section.label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: AppText.mono(12, color: color, letterSpacing: 1.2),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
