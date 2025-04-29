import 'dart:math';

import 'package:dication/src/core/constants/uzbek_constants.dart';
import 'package:flutter/material.dart';

class MovingLettersPage extends StatefulWidget {
  final Widget child;
  const MovingLettersPage({super.key, required this.child});

  @override
  _MovingLettersPageState createState() => _MovingLettersPageState();
}

class _MovingLettersPageState extends State<MovingLettersPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Random random = Random();
  List<Letter> letters = [];

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < 30; i++) {
      letters.add(Letter(
        char: _randomLetter(),
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 30 + 20,
        speedX: (random.nextDouble() - 0.5) / 150,
        speedY: (random.nextDouble() - 0.5) / 150,
        color: Colors.primaries[random.nextInt(Colors.primaries.length)],
      ));
    }

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 10000),
    )..repeat();

    _controller.addListener(() {
      setState(() {
        for (var letter in letters) {
          letter.x += letter.speedX;
          letter.y += letter.speedY;

          if (letter.x > 1 || letter.x < 0) {
            letter.speedX *= -1;
          }
          if (letter.y > 1 || letter.y < 0) {
            letter.speedY *= -1;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _randomLetter() {
    final allLetters = UzbekConstants.letters;
    return allLetters[random.nextInt(allLetters.length)];
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          ...letters.map((letter) {
            return Positioned(
              left: letter.x * size.width,
              top: letter.y * size.height,
              child: Text(
                letter.char,
                style: TextStyle(
                  fontSize: letter.size,
                  fontWeight: FontWeight.bold,
                  color: letter.color,
                ),
              ),
            );
          }),
          Center(
            child: SizedBox(
              child: widget.child,
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
            ),
          )
        ],
      ),
    );
  }
}

class Letter {
  String char;
  double x;
  double y;
  double size;
  double speedX;
  double speedY;
  Color color;

  Letter({
    required this.char,
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.color,
  });
}
