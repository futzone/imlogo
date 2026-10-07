import 'package:dication/src/core/theme/app_theme.dart';
import 'package:dication/src/ui/widgets/hovered_widget.dart';
import 'package:flutter/material.dart';

/// Asosiy karta: 1px chegara, 16px radius. Bosiladigan bo'lsa, hover holatida
/// biroz ko'tariladi, chegarasi binafsha tusga kiradi va yorug'lanadi.
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  /// Burchaklardagi binafsha aksent chiziqlar.
  final bool corners;
  final Color color;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.corners = false,
    this.color = AppColors.background,
  });

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return _build(false);
    return HoveredWidget(onPressed: onTap, builder: _build);
  }

  Widget _build(bool hovered) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: margin,
      transform: Matrix4.translationValues(0, hovered ? -4 : 0, 0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: hovered
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.line,
        ),
        boxShadow: hovered ? AppShadows.glowCard : const [],
      ),
      foregroundDecoration: corners ? const _CornerAccents() : null,
      padding: padding,
      child: child,
    );
  }
}

class _CornerAccents extends Decoration {
  const _CornerAccents();

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _CornerPainter();
}

class _CornerPainter extends BoxPainter {
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size!;
    final rect = offset & size;
    const r = AppRadius.card;
    const arm = 8.0;
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final topLeft = Path()
      ..moveTo(rect.left, rect.top + r + arm)
      ..lineTo(rect.left, rect.top + r)
      ..arcToPoint(Offset(rect.left + r, rect.top),
          radius: const Radius.circular(r))
      ..lineTo(rect.left + r + arm, rect.top);
    final bottomRight = Path()
      ..moveTo(rect.right, rect.bottom - r - arm)
      ..lineTo(rect.right, rect.bottom - r)
      ..arcToPoint(Offset(rect.right - r, rect.bottom),
          radius: const Radius.circular(r))
      ..lineTo(rect.right - r - arm, rect.bottom);

    canvas.drawPath(topLeft, paint);
    canvas.drawPath(bottomRight, paint);
  }
}
