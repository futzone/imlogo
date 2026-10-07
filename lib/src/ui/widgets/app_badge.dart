import 'package:dication/src/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Bosh harfli mono yorliq. [pulse] — chapda "jonli" pulsatsiyalanuvchi nuqta.
class AppBadge extends StatelessWidget {
  final String label;
  final bool pulse;
  final Color color;

  const AppBadge({
    super.key,
    required this.label,
    this.pulse = false,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulse) ...[
            PulseDot(color: color),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label.toUpperCase(),
              style: AppText.label(color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class PulseDot extends StatefulWidget {
  final Color color;

  const PulseDot({super.key, this.color = AppColors.primary});

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Harakatni kamaytirish yoqilgan bo'lsa, nuqta pulsatsiyalanmaydi.
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 8,
      height: 8,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = Curves.easeOut.transform(_controller.value);
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 1 + t * 1.6,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: 0.6 * (1 - t)),
                  ),
                ),
              ),
              child!,
            ],
          );
        },
        child: Container(
          decoration:
              BoxDecoration(shape: BoxShape.circle, color: widget.color),
        ),
      ),
    );
  }
}

/// Ikonka uchun yorug'lanuvchi "tugun" konteyneri.
class IconNode extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const IconNode({
    super.key,
    required this.icon,
    this.color = AppColors.primary,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Icon(icon, size: size * 0.5, color: color),
    );
  }
}

/// Mono shriftdagi kichik ma'lumot bo'lagi: ikonka + matn.
class MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const MetaChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: 6),
        Flexible(
          child: Text(label, style: AppText.mono(12, color: AppColors.muted)),
        ),
      ],
    );
  }
}

/// Gradient bilan bo'yalgan matn (sarlavhadagi aksent so'zlar uchun).
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const GradientText(this.text, {super.key, required this.style});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => AppColors.brandGradient.createShader(bounds),
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}
