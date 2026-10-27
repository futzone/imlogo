import 'dart:ui';

import 'package:dication/src/core/config/app_device.dart';
import 'package:dication/src/core/theme/app_theme.dart';
import 'package:dication/src/ui/widgets/app_background.dart';
import 'package:dication/src/ui/widgets/app_buttons.dart';
import 'package:flutter/material.dart';

/// Shaffof "shisha" pill panel — sarlavha va navigatsiya uchun.
class GlassBar extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const GlassBar({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: AppShadows.glowSoft,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.line),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Ichki sahifalar uchun umumiy qolip: fon, orqaga tugmasi bo'lgan shisha
/// sarlavha va markazlashtirilgan, kengligi cheklangan kontent.
class AppPageScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final double maxWidth;

  const AppPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.onBack,
    this.maxWidth = 960,
  });

  @override
  Widget build(BuildContext context) {
    final gutter = context.isMobile ? 16.0 : 24.0;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 0),
                    child: GlassBar(
                      child: Row(
                        children: [
                          AppIconButton(
                            icon: Icons.arrow_back,
                            tooltip: 'Orqaga',
                            onPressed:
                                onBack ?? () => Navigator.of(context).maybePop(),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.heading(
                                context.isMobile ? 16 : 18,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ),
                          ...actions,
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                  Expanded(child: body),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pastdan chiqadigan oyna (bottom sheet) uchun umumiy qolip.
class AppSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const AppSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
  });

  static Future<T?> show<T>(BuildContext context, Widget sheet) {
    return showModalBottomSheet<T>(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.primaryAccent.withValues(alpha: 0.25),
      constraints: const BoxConstraints(maxWidth: 600),
      context: context,
      builder: (context) => sheet,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: AppShadows.glowCard,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppText.heading(context.isMobile ? 20 : 26),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: AppText.body(14, color: AppColors.muted),
                ),
              ],
              const SizedBox(height: 20),
              ...children,
              const SizedBox(height: 8),
              Center(
                child: AppButton(
                  label: 'Yopiş',
                  variant: AppButtonVariant.ghost,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
