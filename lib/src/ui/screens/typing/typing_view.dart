import 'dart:async';

import 'package:dication/src/core/config/app_device.dart';
import 'package:dication/src/core/config/app_router.dart';
import 'package:dication/src/core/models/typing_result.dart';
import 'package:dication/src/core/theme/app_theme.dart';
import 'package:dication/src/core/translit/translit.dart';
import 'package:dication/src/core/typing/typing_compose.dart';
import 'package:dication/src/core/typing/typing_config.dart';
import 'package:dication/src/core/typing/typing_engine.dart';
import 'package:dication/src/core/typing/typing_words.dart';
import 'package:dication/src/core/services/account_service.dart';
import 'package:dication/src/providers/account_provider.dart';
import 'package:dication/src/providers/typing_provider.dart';
import 'package:dication/src/ui/pages/results_page.dart';
import 'package:dication/src/ui/screens/typing/typing_config_bar.dart';
import 'package:dication/src/ui/screens/typing/typing_result_view.dart';
import 'package:dication/src/ui/screens/typing/typing_words_view.dart';
import 'package:dication/src/ui/widgets/app_badge.dart';
import 'package:dication/src/ui/widgets/app_buttons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tez yozish mashqi (monkeytype uslubida, o'zbekcha so'zlar bilan).
class TypingView extends ConsumerStatefulWidget {
  /// Bo'lim hozir ekranda ko'rinib turibdimi (klaviatura fokusi uchun).
  final bool active;

  const TypingView({super.key, required this.active});

  @override
  ConsumerState<TypingView> createState() => _TypingViewState();
}

class _TypingViewState extends ConsumerState<TypingView> {
  /// Yashirin kiritish maydoni hech qachon bo'sh bo'lmasligi uchun boshiga
  /// qo'yiladigan ko'rinmas belgi: u o'chsa, demak bo'sh holatda "o'chirish"
  /// bosilgan (mobil klaviaturada buni boshqacha aniqlab bo'lmaydi).
  static const String _sentinel = '​';

  final FocusNode _focusNode = FocusNode();
  final TextEditingController _input = TextEditingController(text: _sentinel);
  final Stopwatch _watch = Stopwatch();
  Timer? _timer;

  TypingConfig _config = const TypingConfig();
  bool _configLoaded = false;
  List<String>? _pool;

  /// [_pool] qaysi yozuvdagi so'zlar.
  Alphabet? _poolAlphabet;

  /// Yangi alifbo: "s" terilib, "h" kutilayotgan harf o'rni (qarang: [composeYangi]).
  int? _pending;
  TypingEngine? _engine;
  TypingResult? _result;
  double? _previousBest;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
    TypingStorage.loadConfig().then((config) {
      if (!mounted) return;
      _config = config;
      _configLoaded = true;
      _restart();
    });
  }

  @override
  void didUpdateWidget(covariant TypingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active == oldWidget.active) return;
    if (widget.active) {
      if (_result == null) _focusNode.requestFocus();
    } else {
      // Boshqa bo'limga o'tilganda tugallanmagan mashq bekor qilinadi.
      _focusNode.unfocus();
      if (_engine?.started == true && _result == null) _restart(focus: false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focusNode.dispose();
    _input.dispose();
    super.dispose();
  }

  void _restart({bool focus = true}) {
    _timer?.cancel();
    _watch
      ..stop()
      ..reset();
    _pending = null;
    final pool = _poolAlphabet == _config.alphabet ? _pool : null;
    setState(() {
      _result = null;
      _previousBest = null;
      if (pool != null && pool.isNotEmpty && _configLoaded) {
        final generator = TypingWordGenerator(pool: pool, config: _config);
        _engine = TypingEngine(config: _config, nextWord: generator.next);
      }
    });
    _syncInput();
    if (focus && widget.active) _focusNode.requestFocus();
  }

  void _changeConfig(TypingConfig config) {
    final alphabetChanged = config.alphabet != _config.alphabet;
    _config = config;
    TypingStorage.saveConfig(config);
    if (alphabetChanged) {
      // Yangi yozuvdagi so'zlar yuklangach `build` mashqni qayta boshlaydi.
      _timer?.cancel();
      _watch
        ..stop()
        ..reset();
      setState(() {
        _engine = null;
        _result = null;
      });
      return;
    }
    _restart();
  }

  void _syncInput() {
    final text = '$_sentinel${_engine?.current ?? ''}';
    if (_input.text == text && _input.selection.baseOffset == text.length) {
      return;
    }
    _input.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _onInputChanged(String value) {
    final engine = _engine;
    if (engine == null || engine.finished) return;
    final elapsed = _watch.elapsed;

    if (!value.startsWith(_sentinel)) {
      _pending = null;
      engine.backToPreviousWord();
    } else {
      final text = value.substring(_sentinel.length);
      final space = text.indexOf(RegExp(r'\s'));
      var word = space >= 0 ? text.substring(0, space) : text;
      if (engine.config.alphabet == Alphabet.yangi) {
        final composed = composeYangi(
          engine.current,
          word,
          engine.target,
          _pending,
          finalize: space >= 0,
        );
        word = composed.value;
        _pending = composed.pending;
      }
      engine.setCurrent(word, elapsed: elapsed);
      if (space >= 0) {
        _pending = null;
        engine.commitWord(elapsed: elapsed);
      }
    }

    if (engine.started && !_watch.isRunning && !engine.finished) {
      _watch.start();
      _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
    }
    _syncInput();
    engine.finished ? _finish() : setState(() {});
  }

  void _tick() {
    final engine = _engine;
    if (engine == null) return;
    engine.tick(_watch.elapsed);
    engine.finished ? _finish() : setState(() {});
  }

  Future<void> _finish() async {
    final engine = _engine;
    if (engine == null || _result != null) return;
    _timer?.cancel();
    _watch.stop();
    _focusNode.unfocus();

    final result = TypingResult.fromEngine(engine);
    final history = ref.read(userHistoryProvider).valueOrNull?.typing ??
        ref.read(typingHistoryProvider).valueOrNull ??
        [];
    final sameConfig = history.where((r) => r.config.isSameAs(result.config));
    setState(() {
      _result = result;
      _previousBest = sameConfig.isEmpty
          ? null
          : sameConfig.map((r) => r.wpm).reduce((a, b) => a > b ? a : b);
    });

    // Hech narsa terilmagan mashq tarixga yozilmaydi.
    if (result.correctChars + result.incorrectChars == 0) return;
    await TypingStorage.saveResult(result);
    // Kirgan foydalanuvchi natijasi serverga ham yoziladi; yozilmasa, qurilmada
    // qoladi va "Natijalarim" sahifasidan keyinroq yuklanadi.
    final account = ref.read(authProvider);
    if (account != null) {
      await AccountService.uploadTypingResult(account.id, result).then((_) {}, onError: (_) {});
    }
    if (mounted) invalidateHistory(ref);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final restart = key == LogicalKeyboardKey.tab ||
        key == LogicalKeyboardKey.escape ||
        (key == LogicalKeyboardKey.enter && _result != null);
    if (!restart) return KeyEventResult.ignored;
    _restart();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final words = ref.watch(typingWordsProvider(_config.alphabet));
    // Tarix oldindan yuklab qo'yiladi — rekordni aniqlash uchun kerak.
    ref.watch(userHistoryProvider);

    return words.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          'Sözlar töplamini yuklab bölmadi',
          style: AppText.body(15, color: AppColors.muted),
        ),
      ),
      data: (pool) {
        if (_poolAlphabet != _config.alphabet || _pool == null) {
          _pool = pool;
          _poolAlphabet = _config.alphabet;
          if (_configLoaded && _engine == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _restart();
            });
          }
        }
        final engine = _engine;
        if (engine == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return Focus(
          onKeyEvent: _onKey,
          child: _buildContent(context, engine),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, TypingEngine engine) {
    final running = engine.started && _result == null;
    final gutter = context.isMobile ? 16.0 : 24.0;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Padding(
          padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 8),
          child: Column(
            children: [
              // Yozish paytida sozlamalar xiralashadi — diqqat matnda qoladi.
              IgnorePointer(
                ignoring: running,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: running ? 0.25 : 1,
                  child: TypingConfigBar(
                    config: _config,
                    onChanged: _changeConfig,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: _result != null
                        ? Focus(
                            autofocus: true,
                            child: TypingResultView(
                              result: _result!,
                              previousBest: _previousBest,
                              onRestart: _restart,
                              onOpenHistory: () => AppRouter.go(
                                context,
                                const ResultsPage(initialTab: 1),
                              ),
                            ),
                          )
                        : _buildTest(context, engine),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _wordsLabel => switch (_config.alphabet) {
        Alphabet.kirill => 'Ўзбекча сўзлар',
        Alphabet.yangi => 'Özbekça sözlar',
        Alphabet.lotin => 'O‘zbekcha so‘zlar',
      };

  String get _hint => switch (_config.alphabet) {
        Alphabet.lotin => 'o‘, g‘ uçun istalgan tutuq belgisi qabul qilinadi',
        Alphabet.yangi => 'ş, ç, ö, ğ — sh, ch, o‘, g‘ deb ham teriş mumkin',
        Alphabet.kirill => 'kirill klaviatura tartibini yoqing',
      };

  Widget _buildTest(BuildContext context, TypingEngine engine) {
    final fontSize = context.isMobile
        ? 20.0
        : context.isTablet
            ? 24.0
            : 28.0;
    final focused = _focusNode.hasFocus;
    final elapsed = _watch.elapsed;

    final String counter;
    if (_config.mode == TypingMode.time) {
      final left = _config.amount - elapsed.inSeconds;
      counter = '${left < 0 ? 0 : left}';
    } else {
      counter = '${engine.typed.length}/${engine.words.length}';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!engine.started)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppBadge(label: _wordsLabel, pulse: true),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GradientText(counter, style: AppText.mono(fontSize * 1.3, height: 1)),
            const SizedBox(width: 16),
            if (engine.started)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '${engine.stats(elapsed).wpm.round()} wpm',
                  style: AppText.mono(14, color: AppColors.muted),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _focusNode.requestFocus,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: focused ? 1 : 0.3,
                child: TypingWordsView(
                  engine: engine,
                  fontSize: fontSize,
                  focused: focused,
                ),
              ),
              // Klaviaturadan kiritishni qabul qiladigan ko'rinmas maydon.
              Positioned(
                left: 0,
                top: 0,
                width: 1,
                height: 1,
                child: Opacity(
                  opacity: 0,
                  child: TextField(
                    controller: _input,
                    focusNode: _focusNode,
                    onChanged: _onInputChanged,
                    autofocus: widget.active,
                    autocorrect: false,
                    enableSuggestions: false,
                    enableInteractiveSelection: false,
                    showCursor: false,
                    smartDashesType: SmartDashesType.disabled,
                    smartQuotesType: SmartQuotesType.disabled,
                    textCapitalization: TextCapitalization.none,
                    // Android klaviaturasi so'zni "taxmin qilib" o'zgartirmasligi uchun.
                    keyboardType: defaultTargetPlatform == TargetPlatform.android
                        ? TextInputType.visiblePassword
                        : TextInputType.text,
                    textInputAction: TextInputAction.none,
                    maxLines: 1,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                  ),
                ),
              ),
              if (!focused)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                    boxShadow: AppShadows.glow,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.touch_app_outlined,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'BOŞLAŞ UÇUN ŞU YERGA BOSING',
                          style: AppText.label(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIconButton(
              icon: Icons.refresh,
              tooltip: 'Qayta boşlaş',
              onPressed: _restart,
            ),
            if (!context.isMobile) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'tab — qayta boşlaş  ·  $_hint',
                  style: AppText.mono(11, color: AppColors.muted),
                ),
              ),
            ],
          ],
        ),
        if (context.isMobile) ...[
          const SizedBox(height: 4),
          Text(
            _hint,
            textAlign: TextAlign.center,
            style: AppText.mono(11, color: AppColors.muted),
          ),
        ],
      ],
    );
  }
}
