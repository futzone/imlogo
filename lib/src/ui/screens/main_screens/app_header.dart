import 'package:dication/src/core/config/app_device.dart';
import 'package:dication/src/core/config/app_router.dart';
import 'package:dication/src/core/theme/app_theme.dart';
import 'package:dication/src/ui/pages/results_page.dart';
import 'package:dication/src/ui/screens/additional_screens/about_app_screen.dart';
import 'package:dication/src/ui/screens/additional_screens/app_info_screen.dart';
import 'package:dication/src/ui/widgets/app_buttons.dart';
import 'package:dication/src/ui/widgets/app_scaffold.dart';
import 'package:dication/src/ui/widgets/hovered_widget.dart';
import 'package:flutter/material.dart';

/// Ilova bo'limlari (bosh sahifadagi yorliqlar).
class AppSection {
  final String label;
  final IconData icon;

  const AppSection(this.label, this.icon);

  static const List<AppSection> all = [
    AppSection('Diktant', Icons.headphones_outlined),
    AppSection('Tez yozish', Icons.keyboard_outlined),
  ];
}

/// Bosh sahifaning shisha sarlavha paneli: logotip, bo'limlar va amallar.
class AppHeader extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  /// Bo'limlar yorliqlari sarlavhada ko'rsatilsinmi (tor ekranda ular
  /// ekran pastiga ko'chadi).
  final bool showTabs;

  const AppHeader({
    super.key,
    required this.index,
    required this.onChanged,
    this.showTabs = true,
  });

  /// Shu kenglikdan boshlab yorliqlar sarlavhaga sig'adi.
  static const double tabsBreakpoint = 760;

  @override
  Widget build(BuildContext context) {
    final showLabels = context.isDesktop;

    return GlassBar(
      padding: const EdgeInsets.fromLTRB(20, 6, 8, 6),
      child: Row(
        children: [
          // Chap guruh sig'masa kichrayadi, o'ngdagi tugmalar o'lchami saqlanadi.
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppLogo(),
                    if (showTabs) ...[
                      const SizedBox(width: 20),
                      SectionTabs(index: index, onChanged: onChanged),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AppIconButton(
            icon: Icons.app_shortcut_outlined,
            tooltip: 'Ilovalarimiz',
            label: showLabels ? 'Ilovalarimiz' : null,
            onPressed: () => AboutAppScreen.show(context),
          ),
          AppIconButton(
            icon: Icons.info_outline,
            tooltip: 'Dastur haqida',
            label: showLabels ? 'Dastur haqida' : null,
            onPressed: () => AppInfoScreen.show(context),
          ),
          AppIconButton(
            icon: Icons.history,
            tooltip: 'Natijalarim',
            label: showLabels ? 'Natijalarim' : null,
            onPressed: () => AppRouter.go(
              context,
              ResultsPage(initialTab: index),
            ),
          ),
        ],
      ),
    );
  }
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
