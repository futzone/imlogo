
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

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

class WebButton extends HookWidget {
  final void Function()? onPressed;
  final void Function()? onEnter;
  final void Function()? onExit;
  final Widget Function(bool focused) builder;

  const WebButton({
    super.key,
    this.onPressed,
    required this.builder,
    this.onEnter,
    this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final focused = useState(false);
    return MouseRegion(
      onEnter: (_) {
        focused.value = true;
        if (onEnter != null) onEnter!();
      },
      onExit: (_) {
        focused.value = false;
        if (onExit != null) onExit!();
      },
      child: SimpleButton(onPressed: onPressed, child: builder(focused.value)),
    );
  }
}
