import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/config/app_fonts.dart';

class CountdownTimer extends StatefulWidget {
  final int seconds;
  final VoidCallback? onFinished;

  const CountdownTimer({
    super.key,
    required this.seconds,
    this.onFinished,
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
    return Row(
      spacing: 8,
      children: [
        Icon(Icons.timelapse_outlined, color: Colors.white),
        Text(
          formatTime(remainingSeconds),
          style: TextStyle(fontFamily: mediumFamily, color: Colors.white, fontSize: 18),
        ),
      ],
    );
  }
}
