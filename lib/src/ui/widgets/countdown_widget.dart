import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class CountdownTimer extends StatefulWidget {
  final int seconds;
  final VoidCallback? onFinished;
  final void Function(int time) onUpdateTime;

  const CountdownTimer({
    super.key,
    required this.seconds,
    this.onFinished,
    required this.onUpdateTime,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late int remainingSeconds;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    remainingSeconds = widget.seconds;
    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
        });

        widget.onUpdateTime(remainingSeconds);
      } else {
        timer.cancel();
        if (widget.onFinished != null) {
          widget.onFinished!();
        }
      }
    });
  }

  String formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Oxirgi daqiqada taymer qizil rangga o'tadi.
    final color = remainingSeconds <= 60 ? AppColors.error : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timelapse_outlined, color: color, size: 18),
          const SizedBox(width: 6),
          Text(formatTime(remainingSeconds), style: AppText.mono(15, color: color)),
        ],
      ),
    );
  }
}
