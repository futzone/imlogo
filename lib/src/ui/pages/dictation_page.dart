import 'package:audioplayers/audioplayers.dart';
import 'package:dication/src/core/config/app_device.dart';
import 'package:dication/src/core/theme/app_theme.dart';
import 'package:dication/src/core/config/app_router.dart';
import 'package:dication/src/core/controllers/dictation_controller.dart';
import 'package:dication/src/core/models/text_model.dart';
import 'package:dication/src/core/models/work.dart';
import 'package:dication/src/core/services/dictation_manager.dart';
import 'package:dication/src/ui/widgets/app_buttons.dart';
import 'package:dication/src/ui/widgets/app_scaffold.dart';
import 'package:dication/src/ui/widgets/audio_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/countdown_widget.dart';

class DictationPage extends ConsumerStatefulWidget {
  final TextModel model;

  const DictationPage({super.key, required this.model});

  @override
  ConsumerState<DictationPage> createState() => _DictationPageState();
}

class _DictationPageState extends ConsumerState<DictationPage> {
  int _time = 0;

  get _source => UrlSource(widget.model.url ?? "");

  final TextEditingController _textEditingController = TextEditingController();

  bool _isPlaying = true;

  final AudioPlayer _player = AudioPlayer();
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  void _startPlayAudio() async {
    await _player.play(_source).then((_) async {
      final data = await _player.getDuration();

      if (data != null) {
        _duration = data;
        setState(() {});
      }
    });

    _player.onPositionChanged.listen((p) {
      setState(() {
        _position = p;
      });
    });

    _player.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
        _duration = Duration.zero;
        _position = Duration.zero;
      });
    });
  }

  String formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      _time = widget.model.time * 60;
    });
    _startPlayAudio();
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  Future<bool> _showExitWarning() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Diktantni bekor qilish",
          style: AppText.heading(18),
        ),
        content: Text(
          "Diktant hali yakunlanmagan. Chiqib ketsangiz, natijalar saqlanmaydi. Chiqishni xohlaysizmi?",
          style: AppText.body(15, color: AppColors.muted),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          AppButton(
            label: "Yo'q, davom etish",
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          AppButton(
            label: "Ha, chiqish",
            variant: AppButtonVariant.danger,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _handleCancel() async {
    final shouldExit = await _showExitWarning();
    if (shouldExit && mounted) {
      AppRouter.close(context);
    }
  }

  void _completeDictation() {
    DictationController dictationController =
        DictationController(context: context, ref: ref);
    dictationController.showLoading();

    var evaluator1 = DiktantEvaluator(
      originalText: widget.model.text,
      userText: _textEditingController.text.trim(),
    );

    evaluator1.analyze();
    Work work = Work(
      id: widget.model.id,
      createdDate: DateTime.now().toIso8601String(),
      ball: evaluator1.evaluate100PointScaleMethod3(),
      baho: evaluator1.evaluate5PointScale().toDouble(),
      errors: evaluator1.getDetailedErrors(),
      text: widget.model,
      imloErrorCount: evaluator1.imloErrorCount,
      punktuatsionErrorCount: evaluator1.punktuatsionErrorCount,
      uslubiyErrorCount: evaluator1.uslubiyErrorCount,
      grafikErrorCount: evaluator1.grafikErrorCount,
      worktime: _time,
      input: _textEditingController.text.trim(),
    );

    dictationController.onCreate(work, evaluator1);
  }

  Future<void> _toggleSpeed() async {
    await _player.setPlaybackRate(_player.playbackRate != 1.0 ? 1.0 : 0.5);
    if (mounted) setState(() {});
  }

  Future<void> _rewind() async {
    final seconds = _position.inSeconds - 15;
    await _player.seek(Duration(seconds: seconds <= 0 ? 0 : seconds));
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
      if (mounted) setState(() => _isPlaying = false);
    } else {
      await _player.resume();
      if (mounted) setState(() => _isPlaying = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gutter = context.isMobile ? 16.0 : 24.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldExit = await _showExitWarning();
        if (shouldExit && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: AppPageScaffold(
        title: widget.model.title,
        onBack: _handleCancel,
        actions: [
          CountdownTimer(
            seconds: widget.model.time * 60,
            onUpdateTime: (int time) {
              setState(() {
                _time = time;
              });
            },
          ),
        ],
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPlayer(context),
              const SizedBox(height: 24),
              Text("DIKTANT MATNINI KIRITISH", style: AppText.label()),
              const SizedBox(height: 10),
              TextField(
                style: AppText.body(16, height: 1.6),
                controller: _textEditingController,
                cursorColor: AppColors.primary,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.85),
                  contentPadding: const EdgeInsets.all(16),
                  hintText: 'Matn kiriting',
                  hintStyle: AppText.body(16,
                      color: AppColors.muted.withValues(alpha: 0.6)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                maxLines: null,
                minLines: 8,
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment:
                    context.isMobile ? WrapAlignment.center : WrapAlignment.end,
                spacing: 16,
                runSpacing: 12,
                verticalDirection: context.isMobile
                    ? VerticalDirection.up
                    : VerticalDirection.down,
                children: [
                  AppButton(
                    label: "Bekor qilish",
                    variant: AppButtonVariant.danger,
                    onPressed: _handleCancel,
                  ),
                  AppButton(
                    label: "Diktantni yakunlash",
                    trailingIcon: Icons.check,
                    onPressed: _completeDictation,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Audio pleyer paneli: gradient fon, vaqt, tezlik, orqaga qaytarish.
  Widget _buildPlayer(BuildContext context) {
    final timeStyle = AppText.mono(15, color: Colors.white);
    final progress = AudioProgressBar(
      position: _position,
      duration: _duration,
      onChanged: (dur) async {
        await _player.seek(dur);
      },
    );
    final controls = [
      _PlayerButton(
        icon: Icons.speed_outlined,
        badge: "0.5x",
        tooltip: "Tezlik: 0.5x / 1x",
        active: _player.playbackRate != 1.0,
        onPressed: _toggleSpeed,
      ),
      _PlayerButton(
        icon: Icons.settings_backup_restore_outlined,
        badge: "15s",
        tooltip: "15 soniya orqaga",
        onPressed: _rewind,
      ),
      _PlayerButton(
        icon: _isPlaying ? Icons.pause : Icons.play_arrow,
        tooltip: _isPlaying ? "To'xtatish" : "Davom ettirish",
        filled: true,
        onPressed: _togglePlay,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.glow,
      ),
      child: context.isMobile
          ? Column(
              children: [
                progress,
                Row(
                  children: [
                    // Tor ekranda vaqt yozuvi kichrayadi, tugmalar o'lchami saqlanadi.
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "${formatTime(_position.inSeconds)} / ${formatTime(_duration.inSeconds)}",
                          style: timeStyle,
                        ),
                      ),
                    ),
                    ...controls,
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Text(formatTime(_position.inSeconds), style: timeStyle),
                Expanded(child: progress),
                Text(formatTime(_duration.inSeconds), style: timeStyle),
                const SizedBox(width: 12),
                ...controls,
              ],
            ),
    );
  }
}

class _PlayerButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final String? badge;
  final bool filled;
  final bool active;
  final VoidCallback onPressed;

  const _PlayerButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badge,
    this.filled = false,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SimpleButton(
        onPressed: onPressed,
        child: Container(
          width: 44,
          height: 44,
          margin: const EdgeInsets.only(left: 6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled
                ? Colors.white
                : Colors.white.withValues(alpha: active ? 0.3 : 0.12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: filled ? AppColors.primary : Colors.white,
              ),
              if (badge != null)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.white,
                    ),
                    child: Text(
                      badge!,
                      style: AppText.mono(8,
                          weight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
