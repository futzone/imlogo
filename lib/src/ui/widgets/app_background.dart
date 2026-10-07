import 'package:dication/src/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Sahifa foni: chetlarga qarab so'nuvchi katak naqsh va yumshoq rangli
/// yorug'lik dog'lari (landing sahifadagi hero foni bilan bir xil g'oya).
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: _BackgroundPainter()),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  const _BackgroundPainter();

  static const double _cell = 50;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = AppColors.background);

    _blob(canvas, Offset(size.width * 0.08, size.height * 0.05),
        size.shortestSide * 0.75, AppColors.primary.withValues(alpha: 0.16));
    _blob(canvas, Offset(size.width * 0.95, size.height * 0.9),
        size.shortestSide * 0.7, AppColors.tertiary.withValues(alpha: 0.35));
    _blob(canvas, Offset(size.width * 0.9, size.height * 0.15),
        size.shortestSide * 0.5, AppColors.secondary.withValues(alpha: 0.07));

    // Katak chiziqlari markazdan chetga qarab so'nadi.
    final gridPaint = Paint()
      ..strokeWidth = 1
      ..shader = RadialGradient(
        radius: 0.85,
        colors: [
          AppColors.primary.withValues(alpha: 0.10),
          AppColors.primary.withValues(alpha: 0.0),
        ],
        stops: const [0.4, 1.0],
      ).createShader(rect);

    for (double x = 0; x <= size.width; x += _cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += _cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _blob(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
          .createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
