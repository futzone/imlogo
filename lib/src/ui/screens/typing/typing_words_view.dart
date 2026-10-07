import 'dart:math';

import 'package:dication/src/core/theme/app_theme.dart';
import 'package:dication/src/core/typing/typing_engine.dart';
import 'package:dication/src/core/typing/typing_text.dart';
import 'package:flutter/material.dart';

/// Teriladigan so'zlar maydoni: uch qator ko'rinadi, joriy so'z doim
/// ikkinchi qatorda turadi (birinchi qatordan tashqari).
class TypingWordsView extends StatefulWidget {
  final TypingEngine engine;
  final double fontSize;
  final bool focused;

  const TypingWordsView({
    super.key,
    required this.engine,
    required this.fontSize,
    required this.focused,
  });

  static const int visibleLines = 3;
  static double lineHeightFor(double fontSize) => fontSize * 1.9;

  @override
  State<TypingWordsView> createState() => _TypingWordsViewState();
}

class _TypingWordsViewState extends State<TypingWordsView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 530),
  )..repeat(reverse: true);

  double? _charWidth;
  double? _measuredFor;

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  TextStyle get _style => AppText.mono(widget.fontSize, weight: FontWeight.w400);

  /// Mono shriftda barcha belgilar eni bir xil — bir marta o'lchanadi.
  double get _charW {
    if (_charWidth == null || _measuredFor != widget.fontSize) {
      final painter = TextPainter(
        text: TextSpan(text: '0' * 20, style: _style),
        textDirection: TextDirection.ltr,
      )..layout();
      _charWidth = painter.width / 20;
      _measuredFor = widget.fontSize;
      painter.dispose();
    }
    return _charWidth!;
  }

  String _inputFor(int index) {
    final engine = widget.engine;
    if (index < engine.typed.length) return engine.typed[index];
    if (index == engine.index) return engine.current;
    return '';
  }

  /// So'zlarni qatorlarga bo'ladi va ko'rinadigan uch qatorni qaytaradi.
  List<List<int>> _visibleLines(double maxWidth) {
    final engine = widget.engine;
    final charW = _charW;
    final lines = <List<int>>[];
    var line = <int>[];
    var x = 0.0;
    int? currentLine;

    for (var i = 0; i < engine.words.length; i++) {
      final length = max(engine.words[i].length, _inputFor(i).length);
      final width = length * charW;
      // Har bir so'zdan keyin bitta belgi enidagi bo'sh joy ham qatorga sig'ishi kerak.
      if (line.isNotEmpty && x + width + charW > maxWidth) {
        lines.add(line);
        line = <int>[];
        x = 0;
        if (currentLine != null &&
            lines.length > currentLine + TypingWordsView.visibleLines) {
          break;
        }
      }
      if (i == engine.index) currentLine = lines.length;
      line.add(i);
      x += width + charW;
    }
    if (line.isNotEmpty) lines.add(line);

    final first = max(0, (currentLine ?? 0) - 1);
    return lines.skip(first).take(TypingWordsView.visibleLines).toList();
  }

  @override
  Widget build(BuildContext context) {
    final lineHeight = TypingWordsView.lineHeightFor(widget.fontSize);

    return LayoutBuilder(
      builder: (context, constraints) {
        final lines = _visibleLines(constraints.maxWidth);
        return SizedBox(
          height: lineHeight * TypingWordsView.visibleLines,
          width: constraints.maxWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final line in lines)
                // Qatordan uzun bitta so'z (tor ekran + ortiqcha belgilar) ham
                // xatolik bermasdan, chetidan kesilib ko'rinadi.
                SizedBox(
                  height: lineHeight,
                  width: constraints.maxWidth,
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.centerLeft,
                      minWidth: 0,
                      maxWidth: double.infinity,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final index in line)
                            Padding(
                              padding: EdgeInsets.only(right: _charW),
                              child: _buildWord(index),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWord(int index) {
    final engine = widget.engine;
    final word = engine.words[index];
    final pretty = prettifyTypingWord(word);
    final input = _inputFor(index);
    final isActive = index == engine.index && !engine.finished;
    final hasError =
        index < engine.typed.length && !isTypedWordCorrect(input, word);

    final spans = <TextSpan>[];
    for (var j = 0; j < word.length; j++) {
      final Color color;
      if (j >= input.length) {
        color = AppColors.muted.withValues(alpha: 0.45);
      } else if (isSameTypingChar(input[j], word[j])) {
        color = AppColors.foreground;
      } else {
        color = AppColors.error;
      }
      spans.add(TextSpan(text: pretty[j], style: TextStyle(color: color)));
    }
    if (input.length > word.length) {
      spans.add(TextSpan(
        text: input.substring(word.length),
        style: TextStyle(color: AppColors.errorDeep.withValues(alpha: 0.7)),
      ));
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                width: 2,
                color: hasError ? AppColors.error : Colors.transparent,
              ),
            ),
          ),
          child: Text.rich(
            TextSpan(children: spans),
            style: _style,
            maxLines: 1,
            softWrap: false,
            textScaler: TextScaler.noScaling,
          ),
        ),
        if (isActive && widget.focused)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOut,
            left: input.length * _charW - 1,
            top: widget.fontSize * 0.1,
            bottom: widget.fontSize * 0.1,
            child: FadeTransition(
              // Yozish boshlangach kursor miltillamaydi.
              opacity: engine.started
                  ? const AlwaysStoppedAnimation(1)
                  : _blink,
              child: Container(
                width: 2.5,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: AppShadows.glow,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
