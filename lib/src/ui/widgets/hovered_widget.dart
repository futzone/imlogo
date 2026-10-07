import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class HoveredWidget extends HookWidget {
  final Widget Function(bool hovered) builder;
  final void Function()? onPressed;
  final BorderRadius? borderRadius;

  const HoveredWidget({
    super.key,
    required this.builder,
    this.onPressed,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isHovered = useState(false);
    return MouseRegion(
      onExit: (_) => isHovered.value = false,
      onEnter: (_) => isHovered.value = true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: borderRadius,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: builder(isHovered.value),
      ),
    );
  }
}
