import 'package:dication/src/core/theme/app_theme.dart';
import 'package:dication/src/core/typing/typing_config.dart';
import 'package:dication/src/ui/widgets/hovered_widget.dart';
import 'package:flutter/material.dart';

/// Mashq sozlamalari: yozuv, tinish belgilari, raqamlar, rejim va miqdor.
class TypingConfigBar extends StatelessWidget {
  final TypingConfig config;
  final ValueChanged<TypingConfig> onChanged;

  const TypingConfigBar({
    super.key,
    required this.config,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Bitta qatorga sig'masa (telefon, tor oyna) ikki qatorga bo'linadi.
    return LayoutBuilder(
      builder: (context, constraints) =>
          _build(compact: constraints.maxWidth < _singleRowWidth),
    );
  }

  static const double _singleRowWidth = 900;

  Widget _build({required bool compact}) {
    final alphabets = [
      for (final entry in TypingConfig.alphabetOptions.entries)
        _Option(
          label: entry.value,
          selected: config.alphabet == entry.key,
          onTap: () => onChanged(config.copyWith(alphabet: entry.key)),
        ),
    ];
    // Gaplar rejimida qo'shimchalar o'chiriladi: gaplarda tinish belgilari va raqamlar o'zi bor.
    final extras = config.hasExtras;
    final toggles = [
      _Option(
        icon: Icons.alternate_email,
        label: 'tiniş belgilari',
        selected: extras && config.punctuation,
        onTap: extras
            ? () => onChanged(config.copyWith(punctuation: !config.punctuation))
            : null,
      ),
      _Option(
        icon: Icons.tag,
        label: 'raqamlar',
        selected: extras && config.numbers,
        onTap: extras
            ? () => onChanged(config.copyWith(numbers: !config.numbers))
            : null,
      ),
    ];
    final modes = [
      _Option(
        icon: compact ? null : Icons.timer_outlined,
        label: 'vaqt',
        selected: config.mode == TypingMode.time,
        onTap: () => onChanged(config.withMode(TypingMode.time)),
      ),
      _Option(
        icon: compact ? null : Icons.text_fields,
        label: 'sözlar',
        selected: config.mode == TypingMode.words,
        onTap: () => onChanged(config.withMode(TypingMode.words)),
      ),
      _Option(
        icon: compact ? null : Icons.format_quote,
        label: 'gaplar',
        selected: config.mode == TypingMode.sentences,
        onTap: () => onChanged(config.withMode(TypingMode.sentences)),
      ),
    ];
    final amounts = [
      for (final option in config.options)
        _Option(
          label: '$option',
          selected: config.amount == option,
          onTap: () => onChanged(config.copyWith(amount: option)),
        ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.glowSoft,
      ),
      child: compact
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Juda tor ekranda qator kichrayadi, lekin toshib chiqmaydi.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [...alphabets, const _Divider(), ...toggles],
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [...modes, const _Divider(), ...amounts],
                  ),
                ),
              ],
            )
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 6, right: 2),
                    child: Icon(Icons.translate, size: 15, color: AppColors.muted),
                  ),
                  ...alphabets,
                  const _Divider(),
                  ...toggles,
                  const _Divider(),
                  ...modes,
                  const _Divider(),
                  ...amounts,
                ],
              ),
            ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: AppColors.primary.withValues(alpha: 0.2),
    );
  }
}

class _Option extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool selected;

  /// `null` — tanlov o'chirilgan (xira ko'rinadi, bosilmaydi).
  final VoidCallback? onTap;

  const _Option({
    this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Semantics(
      button: true,
      enabled: !disabled,
      selected: selected,
      child: Opacity(
        opacity: disabled ? 0.4 : 1,
        child: HoveredWidget(
        onPressed: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        builder: (hovered) {
          final color = selected
              ? AppColors.primary
              : hovered
                  ? AppColors.foreground
                  : AppColors.muted;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            constraints: const BoxConstraints(minHeight: 40, minWidth: 40),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 15, color: color),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: AppText.mono(
                    13,
                    color: color,
                    weight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      ),
    );
  }
}
