import 'dart:math';

import 'package:dication/src/core/theme/app_theme.dart';
import 'package:dication/src/core/typing/typing_engine.dart';
import 'package:flutter/material.dart';

/// Mashq davomidagi tezlik grafigi: WPM (gradient chiziq), xom tezlik
/// (kulrang chiziq) va xato qilingan soniyalar (qizil nuqtalar).
class TypingChart extends StatelessWidget {
  final List<TypingSample> samples;

  const TypingChart({super.key, required this.samples});

  @override
  Widget build(BuildContext context) {
    if (samples.length < 2) {
      return Center(
        child: Text(
          'Grafik uchun mashq juda qisqa bo‘ldi',
          style: AppText.mono(12, color: AppColors.muted),
        ),
      );
    }
    return CustomPaint(
      painter: _ChartPainter(samples),
      size: Size.infinite,
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<TypingSample> samples;

  _ChartPainter(this.samples);

  static const double _left = 34;
  static const double _bottom = 20;
  static const double _top = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(_left, _top, size.width, size.height - _bottom);
    final peak = samples.map((s) => max(s.wpm, s.raw)).reduce(max);
    final maxY = max(20.0, (peak * 1.15 / 10).ceil() * 10.0);

    double xFor(int i) =>
        plot.left + plot.width * i / (samples.length - 1);
    double yFor(double value) =>
        plot.bottom - plot.height * (value / maxY).clamp(0, 1);

    // Gorizontal yo'naltiruvchi chiziqlar va qiymatlar
    final gridPaint = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    for (var step = 0; step <= 2; step++) {
      final value = maxY * step / 2;
      final y = yFor(value);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      _label(canvas, value.round().toString(), Offset(0, y - 6), _left - 8,
          TextAlign.right);
    }
    _label(canvas, '1s', Offset(plot.left, plot.bottom + 6), 40, TextAlign.left);
    _label(canvas, '${samples.last.second}s',
        Offset(plot.right - 40, plot.bottom + 6), 40, TextAlign.right);

    Path lineOf(double Function(TypingSample) value) {
      final path = Path();
      for (var i = 0; i < samples.length; i++) {
        final point = Offset(xFor(i), yFor(value(samples[i])));
        i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
      }
      return path;
    }

    canvas.drawPath(
      lineOf((s) => s.raw),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.muted.withValues(alpha: 0.35),
    );

    final wpmLine = lineOf((s) => s.wpm);
    final area = Path.from(wpmLine)
      ..lineTo(plot.right, plot.bottom)
      ..lineTo(plot.left, plot.bottom)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.22),
            AppColors.primary.withValues(alpha: 0),
          ],
        ).createShader(plot),
    );
    canvas.drawPath(
      wpmLine,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..shader = AppColors.brandGradient.createShader(plot),
    );

    final errorPaint = Paint()..color = AppColors.error;
    for (var i = 0; i < samples.length; i++) {
      if (samples[i].errors > 0) {
        canvas.drawCircle(Offset(xFor(i), plot.bottom), 3, errorPaint);
      }
    }
  }

  void _label(Canvas canvas, String text, Offset offset, double width,
      TextAlign align) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: AppText.mono(10, color: AppColors.muted)),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: width, maxWidth: width);
    painter.paint(canvas, offset);
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      oldDelegate.samples != samples;
}
