import 'package:dication/src/core/config/app_device.dart';
import 'package:dication/src/core/services/account_service.dart';
import 'package:dication/src/core/theme/app_theme.dart';
import 'package:dication/src/ui/widgets/app_badge.dart';
import 'package:dication/src/ui/widgets/hovered_widget.dart';
import 'package:flutter/material.dart';

/// Bo'lim sahifasining sarlavhasi (veb-saytdagi `DashboardPage` kabi).
class PageHeading extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const PageHeading({super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.heading(context.isMobile ? 24 : 32)),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!, style: AppText.body(15, color: AppColors.muted)),
        ],
      ],
    );
    if (trailing == null) return heading;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Expanded(child: heading), const SizedBox(width: 12), trailing!],
    );
  }
}

/// Bo'lim kontenti: markazlashgan, kengligi cheklangan va aylantiriladigan.
class SectionScroll extends StatelessWidget {
  final List<Widget> children;
  final double maxWidth;
  final Future<void> Function()? onRefresh;

  const SectionScroll({super.key, required this.children, this.maxWidth = 960, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final gutter = context.isMobile ? 16.0 : 24.0;
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 32),
      children: [
        for (final child in children)
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SizedBox(width: double.infinity, child: child),
            ),
          ),
      ],
    );
    if (onRefresh == null) return list;
    return RefreshIndicator(color: AppColors.primary, onRefresh: onRefresh!, child: list);
  }
}

/// Foydalanuvchi rasmi yoki ism bosh harflari.
class UserAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;

  const UserAvatar({super.key, required this.name, this.imageUrl, this.size = 40});

  factory UserAvatar.of(Account account, {double size = 40}) =>
      UserAvatar(name: account.name, imageUrl: account.avatarUrl, size: size);

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final initials = parts.isEmpty
        ? '?'
        : (parts.length > 1 ? '${parts[0][0]}${parts[1][0]}' : parts[0][0]).toUpperCase();
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.brandGradient),
      child: Text(initials, style: AppText.heading(size * 0.38, color: Colors.white)),
    );
    if (imageUrl == null) return fallback;
    return ClipOval(
      child: Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

/// Bir nechta variantdan birini tanlash (pill shaklidagi yorliqlar).
class Segmented<T> extends StatelessWidget {
  final Map<T, String> options;
  final T value;
  final ValueChanged<T> onChanged;
  final bool expand;

  const Segmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      for (final entry in options.entries)
        _segment(entry.key, entry.value),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.line),
      ),
      child: expand
          ? Row(children: [for (final item in items) Expanded(child: item)])
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(mainAxisSize: MainAxisSize.min, children: items),
            ),
    );
  }

  Widget _segment(T key, String label) {
    final selected = key == value;
    return Semantics(
      button: true,
      selected: selected,
      child: HoveredWidget(
        onPressed: () => onChanged(key),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        builder: (hovered) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 38),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? AppColors.brandGradient : null,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(
              14,
              weight: FontWeight.w600,
              color: selected
                  ? Colors.white
                  : hovered
                      ? AppColors.primary
                      : AppColors.muted,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

/// Matn kiritish maydoni (yorliq bilan).
class AppTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? hint;
  final int maxLines;
  final int? maxLength;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.obscure = false,
    this.keyboardType,
    this.hint,
    this.maxLines = 1,
    this.maxLength,
    this.autofillHints,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: color, width: width),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.body(13, weight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          maxLines: obscure ? 1 : maxLines,
          maxLength: maxLength,
          autofillHints: autofillHints,
          onSubmitted: onSubmitted,
          style: AppText.body(15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppText.body(15, color: AppColors.muted.withValues(alpha: 0.6)),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            enabledBorder: border(AppColors.line),
            focusedBorder: border(AppColors.primary, 1.5),
            border: border(AppColors.line),
          ),
        ),
      ],
    );
  }
}

/// Bo'sh yoki xato holat: ikonka, matn va ixtiyoriy tugma.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;
  final Color color;

  const EmptyState({
    super.key,
    required this.icon,
    required this.text,
    this.action,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconNode(icon: icon, color: color),
          const SizedBox(height: 16),
          Text(text, textAlign: TextAlign.center, style: AppText.body(15, color: AppColors.muted)),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

/// Xabar chizig'i: ikonka, matn va o'ngda tugma (masalan, "Kirish").
class NoticeCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;

  const NoticeCard({super.key, required this.icon, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppText.body(14))),
          if (action != null) ...[const SizedBox(width: 12), action!],
        ],
      ),
    );
  }
}

/// Kichik gradient tugma (kartalar ichida).
class SmallButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outline;

  const SmallButton({super.key, required this.label, this.onPressed, this.icon, this.outline = false});

  @override
  Widget build(BuildContext context) {
    return HoveredWidget(
      onPressed: onPressed,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      builder: (hovered) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minHeight: 38),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: outline ? null : AppColors.brandGradient,
          color: outline && hovered ? AppColors.primary.withValues(alpha: 0.06) : null,
          border: outline ? Border.all(color: AppColors.primary.withValues(alpha: hovered ? 0.8 : 0.3)) : null,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: outline ? const [] : AppShadows.glow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: outline ? AppColors.primary : Colors.white),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppText.body(13, weight: FontWeight.w600, color: outline ? AppColors.primary : Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

/// Karta sarlavhasi: mono yorliq va o'ngda ixtiyoriy havola.
class CardTitle extends StatelessWidget {
  final String label;
  final String? action;
  final VoidCallback? onAction;

  const CardTitle({super.key, required this.label, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label.toUpperCase(), style: AppText.label(color: AppColors.primary))),
        if (action != null)
          HoveredWidget(
            onPressed: onAction,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            builder: (hovered) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    action!,
                    style: AppText.body(13,
                        weight: FontWeight.w600, color: hovered ? AppColors.primaryAccent : AppColors.primary),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
