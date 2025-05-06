import 'package:audioplayers/audioplayers.dart';
import 'package:dication/src/core/config/app_device.dart';
import 'package:dication/src/core/config/app_fonts.dart';
import 'package:dication/src/core/config/app_router.dart';
import 'package:dication/src/core/controllers/dictation_controller.dart';
import 'package:dication/src/core/models/text_model.dart';
import 'package:dication/src/core/models/work.dart';
import 'package:dication/src/core/services/dictation_manager.dart';
import 'package:dication/src/ui/widgets/app_buttons.dart';
import 'package:dication/src/ui/widgets/audio_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/countdown_widget.dart';
import 'dictation_result_page.dart';

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
    _startPlayAudio();
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  void _completeDictation() {
    DictationController dictationController = DictationController(context: context, ref: ref);
    dictationController.showLoading();

    var evaluator1 = DiktantEvaluator(
      originalText: widget.model.text,
      userText: _textEditingController.text.trim(),
    );

    evaluator1.analyze();
    Work work = Work(
      id: '',
      createdDate: '',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontFamily: boldFamily,
          fontSize: 20,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(widget.model.title),
        actions: [
          CountdownTimer(
            seconds: widget.model.time,
            onUpdateTime: (int time) {
              setState(() {
                _time = time;
              });
            },
          ),
          SizedBox(width: 24)
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(left: 24, right: 24, top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                children: [
                  if (!context.isMobile)
                    Row(
                      spacing: 16,
                      children: [
                        Text(
                          formatTime(_position.inSeconds),
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: mediumFamily,
                            color: Colors.white,
                          ),
                        ),
                        Expanded(
                          child: AudioProgressBar(
                            position: _position,
                            duration: _duration,
                            onChanged: (dur) async {
                              await _player.seek(dur);
                            },
                          ),
                        ),
                        Text(
                          formatTime(_duration.inSeconds),
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: mediumFamily,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(),
                        SimpleButton(
                          onPressed: () async {
                            final seconds = (_position.inSeconds - 15);
                            Duration newPosition = Duration(seconds: seconds <= 0 ? 0 : seconds);
                            await _player.seek(newPosition);
                          },
                          child: SizedBox(
                            height: 36,
                            width: 36,
                            child: Stack(
                              children: [
                                Center(
                                  child: Icon(
                                    Icons.settings_backup_restore_outlined,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  child: Container(
                                    padding: EdgeInsets.only(
                                      left: 2,
                                      right: 2,
                                      top: 2,
                                      bottom: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    child: Text(
                                      "15s",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontFamily: boldFamily,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        SizedBox(),
                        SimpleButton(
                          onPressed: () async {
                            if (_isPlaying) {
                              await _player.pause().then((_) => setState(() => _isPlaying = false));
                            } else {
                              await _player.resume().then((_) => setState(() => _isPlaying = true));
                            }
                          },
                          child: Icon(
                            _isPlaying ? Icons.pause_circle_outline : Icons.play_circle_outline,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        AudioProgressBar(
                          position: _position,
                          duration: _duration,
                          onChanged: (dur) async {
                            await _player.seek(dur);
                          },
                        ),
                        Row(
                          spacing: 16,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formatTime(_position.inSeconds),
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: mediumFamily,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              formatTime(_duration.inSeconds),
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: mediumFamily,
                                color: Colors.white,
                              ),
                            ),
                            SimpleButton(
                              onPressed: () async {
                                final seconds = (_position.inSeconds - 15);
                                Duration newPosition = Duration(seconds: seconds <= 0 ? 0 : seconds);
                                await _player.seek(newPosition);
                              },
                              child: SizedBox(
                                height: 36,
                                width: 36,
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Icon(
                                        Icons.settings_backup_restore_outlined,
                                        size: 32,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      child: Container(
                                        padding: EdgeInsets.only(
                                          left: 2,
                                          right: 2,
                                          top: 2,
                                          bottom: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(4),
                                          color: Theme.of(context).primaryColor,
                                        ),
                                        child: Text(
                                          "15s",
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontFamily: boldFamily,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            SimpleButton(
                              onPressed: () async {
                                if (_isPlaying) {
                                  await _player.pause().then((_) => setState(() => _isPlaying = false));
                                } else {
                                  await _player.resume().then((_) => setState(() => _isPlaying = true));
                                }
                              },
                              child: Icon(
                                _isPlaying ? Icons.pause_circle_outline : Icons.play_circle_outline,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                ],
              ),
            ),
            SizedBox(height: 24),
            Text(
              "Diktant matnini kiritish",
              style: TextStyle(fontSize: 18, fontFamily: mediumFamily),
            ),
            SizedBox(height: 8),
            TextField(
              style: TextStyle(fontSize: 16, fontFamily: boldFamily),
              controller: _textEditingController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: EdgeInsets.all(16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                hintText: 'Matn kiriting',
              ),
              maxLines: null,
              minLines: 8,
            ),
            SizedBox(height: 24),
            if (!context.isMobile)
              Row(
                spacing: 24,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SimpleButton(
                    onPressed: () {
                      AppRouter.close(context);
                    },
                    child: Container(
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(48), border: Border.all(color: Colors.red)),
                      padding: EdgeInsets.only(
                        left: 32,
                        right: 32,
                        top: 12,
                        bottom: 12,
                      ),
                      child: Text(
                        "Bekor Qilish".toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: mediumFamily,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                  SimpleButton(
                    onPressed: () {
                      _completeDictation();
                    },
                    child: Container(
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(48),
                        gradient: LinearGradient(
                          colors: [Colors.blue, Colors.red],
                        ),
                      ),
                      padding: EdgeInsets.only(
                        left: 32,
                        right: 32,
                        top: 12,
                        bottom: 12,
                      ),
                      child: Text(
                        "Diktantni Yakunlash".toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: mediumFamily,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Center(
                child: Column(
                  spacing: 24,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SimpleButton(
                      onPressed: () {
                        _completeDictation();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(48),
                          gradient: LinearGradient(
                            colors: [Colors.blue, Colors.red],
                          ),
                        ),
                        padding: EdgeInsets.only(
                          left: 32,
                          right: 32,
                          top: 12,
                          bottom: 12,
                        ),
                        child: Text(
                          "Diktantni Yakunlash".toUpperCase(),
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: mediumFamily,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SimpleButton(
                      onPressed: () {
                        AppRouter.close(context);
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(48), border: Border.all(color: Colors.red)),
                        padding: EdgeInsets.only(
                          left: 32,
                          right: 32,
                          top: 12,
                          bottom: 12,
                        ),
                        child: Text(
                          "Bekor Qilish".toUpperCase(),
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: mediumFamily,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}
