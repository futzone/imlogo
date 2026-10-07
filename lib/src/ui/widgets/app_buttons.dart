import 'package:dication/src/core/theme/app_theme.dart';
import 'package:dication/src/ui/widgets/hovered_widget.dart';
import 'package:flutter/material.dart';

class SimpleButton extends StatelessWidget {
  final void Function()? onPressed;
  final void Function()? onLongPress;
  final Widget child;

  const SimpleButton({
    super.key,
    this.onLongPress,
    this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: onLongPress,
      onTap: onPressed,
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: child,
    );
  }
}

enum AppButtonVariant { primary, outline, ghost, danger }

/// Pill shaklidagi tugma. `primary` — gradient va yorug'lik bilan,
/// `outline` — chegarali, `ghost` — fonsiz, `danger` — qizil chegarali.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final AppButtonVariant variant;
  final bool expand;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.variant = AppButtonVariant.primary,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == AppButtonVariant.primary;

    return HoveredWidget(
      onPressed: onPressed,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      builder: (hovered) {
        final Color foreground = switch (variant) {
          AppButtonVariant.primary => Colors.white,
          AppButtonVariant.outline => AppColors.foreground,
          AppButtonVariant.ghost =>
            hovered ? AppColors.primary : AppColors.foreground,
          AppButtonVariant.danger => AppColors.error,
        };
        final Color? background = switch (variant) {
          AppButtonVariant.primary => null,
          AppButtonVariant.outline =>
            hovered ? AppColors.primary.withValues(alpha: 0.05) : null,
          AppButtonVariant.ghost =>
            hovered ? AppColors.primary.withValues(alpha: 0.1) : null,
          AppButtonVariant.danger =>
            hovered ? AppColors.error.withValues(alpha: 0.06) : null,
        };
        final BoxBorder? border = switch (variant) {
          AppButtonVariant.outline => Border.all(
              width: 2,
              color: hovered
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.25),
            ),
          AppButtonVariant.danger => Border.all(
              width: 2,
              color: AppColors.error.withValues(alpha: hovered ? 1 : 0.5),
            ),
          _ => null,
        };

        return AnimatedScale(
          scale: isPrimary && hovered ? 1.04 : 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              gradient: isPrimary ? AppColors.brandGradient : null,
              color: background,
              border: border,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: isPrimary
                  ? (hovered ? AppShadows.glowLarge : AppShadows.glow)
                  : const [],
            ),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: foreground),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    isPrimary ? label.toUpperCase() : label,
                    textAlign: TextAlign.center,
                    style: AppText.body(
                      14,
                      weight: FontWeight.w600,
                      color: foreground,
                      height: 1.2,
                    ).copyWith(letterSpacing: isPrimary ? 0.8 : null),
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 10),
                  Icon(trailingIcon, size: 18, color: foreground),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Dumaloq ikonka-tugma (sarlavha panelida ishlatiladi).
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final String? label;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label == null ? tooltip : '',
      child: HoveredWidget(
        onPressed: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        builder: (hovered) {
          final color = hovered ? AppColors.primary : AppColors.foreground;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 44,
            constraints: const BoxConstraints(minWidth: 44),
            padding: EdgeInsets.symmetric(horizontal: label == null ? 0 : 14),
            decoration: BoxDecoration(
              color: hovered
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: color),
                if (label != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    label!,
                    style: AppText.body(14, weight: FontWeight.w500, color: color),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
