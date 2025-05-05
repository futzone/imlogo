import 'package:flutter/material.dart';
import 'dart:math';

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
    // Calculate max duration in milliseconds. Ensure it's at least 0.0.
    final double maxMilliseconds = max(0.0, duration.inMilliseconds.toDouble());

    // Calculate current position in milliseconds.
    // Clamp the value between 0.0 and the maxMilliseconds.
    // This prevents the value from exceeding the max, especially when duration is 0.
    final double currentMilliseconds = position.inMilliseconds
        .toDouble()
        .clamp(0.0, maxMilliseconds);

    return Slider(
      min: 0.0, // Explicitly set min for clarity
      value: currentMilliseconds,
      max: maxMilliseconds,
      onChanged: (value) {
        // Only trigger onChanged if the duration is valid (greater than 0)
        if (maxMilliseconds > 0) {
          onChanged(Duration(milliseconds: value.toInt()));
        }
      },
      activeColor: Colors.blue,
      inactiveColor: Colors.grey,
    );
  }
}