import 'package:flutter/material.dart';

class AudioProgressBar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final Function(Duration) onChanged;

  const AudioProgressBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: position.inMilliseconds.toDouble(),
      max: duration.inMilliseconds.toDouble(),
      onChanged: (value) {
        onChanged(Duration(milliseconds: value.toInt()));
      },
      activeColor: Colors.blue,
      inactiveColor: Colors.grey,
    );
  }
}
