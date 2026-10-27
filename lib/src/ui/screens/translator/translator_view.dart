import 'package:dication/src/core/config/app_device.dart';
import 'package:dication/src/core/translit/directions.dart';
import 'package:dication/src/core/translit/translit.dart';
import 'package:dication/src/core/theme/app_theme.dart';
import 'package:dication/src/providers/translit_provider.dart';
import 'package:dication/src/ui/widgets/app_buttons.dart';
import 'package:dication/src/ui/widgets/app_card.dart';
import 'package:dication/src/ui/widgets/app_ui.dart';
import 'package:dication/src/ui/widgets/hovered_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Maxsus harflar paneli: oddiy klaviaturada yo'q harflar.
const Map<Alphabet, List<String>> _specialChars = {
  Alphabet.yangi: ['Ş', 'ş', 'Ç', 'ç', 'Ö', 'ö', 'Ğ', 'ğ', 'ʼ'],
  Alphabet.lotin: ['Oʻ', 'oʻ', 'Gʻ', 'gʻ', 'ʼ'],
  Alphabet.kirill: ['Ў', 'ў', 'Қ', 'қ', 'Ғ', 'ғ', 'Ҳ', 'ҳ', 'ъ'],
};

const Map<Alphabet, String> _placeholders = {
  Alphabet.lotin: 'Matnni kiriting… Masalan: O‘zbekiston, shahar, choyxona, Is’hoq',
  Alphabet.yangi: 'Matnni kiriting… Masalan: Özbekiston, şahar, çoyxona, Ishoq',
  Alphabet.kirill: 'Матнни киритинг… Масалан: Ўзбекистон, шаҳар, чойхона, Исҳоқ',
};

const _box = 'translator';

/// Kirill, amaldagi lotin va yangi alifbo orasida o'girish (6 yo'nalish).
/// Kiritilgan matn va sozlamalar qurilmada saqlanadi.
class TranslatorView extends ConsumerStatefulWidget {
  const TranslatorView({super.key});

  @override
  ConsumerState<TranslatorView> createState() => _TranslatorViewState();
}

class _TranslatorViewState extends ConsumerState<TranslatorView> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  TranslitDirection _direction = defaultDirection;
  bool _plainApostrophe = false;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    Hive.openBox(_box).then((box) {
      if (!mounted) return;
      final from = Alphabet.values.asNameMap()[box.get('from')];
      final to = Alphabet.values.asNameMap()[box.get('to')];
      setState(() {
        if (from != null && to != null && from != to) _direction = TranslitDirection(from, to);
        _plainApostrophe = box.get('plain') == true;
        _input.text = box.get('text') as String? ?? '';
      });
    });
    _input.addListener(() {
      setState(() => _copied = false);
      _save();
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _save() {
    if (!Hive.isBoxOpen(_box)) return;
    Hive.box(_box).putAll({
      'from': _direction.from.name,
      'to': _direction.to.name,
      'plain': _plainApostrophe,
      'text': _input.text,
    });
  }

  void _setDirection(TranslitDirection direction, {String? text}) {
    setState(() => _direction = direction);
    if (text != null) _input.text = text;
    _save();
  }

  /// Yo'nalishni teskarisiga o'giradi: natija yangi kiritish matni bo'ladi.
  void _swap(String output) => _setDirection(_direction.reversed, text: output);

  void _insert(String char) {
    final selection = _input.selection;
    final text = _input.text;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    _input.value = TextEditingValue(
      text: text.replaceRange(start, end, char),
      selection: TextSelection.collapsed(offset: start + char.length),
    );
    _focus.requestFocus();
  }

  Future<void> _copy(String output) async {
    await Clipboard.setData(ClipboardData(text: output));
    if (mounted) setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    final lexicon = ref.watch(lexiconProvider).valueOrNull;
    final text = _input.text;
    final output = lexicon == null
        ? ''
        : transliterate(text, _direction.from, _direction.to, lexicon, plainApostrophe: _plainApostrophe);
    final words = RegExp(r'\S+').allMatches(text).length;
    final wide = !context.isMobile;

    final source = _Panel(
      header: _AlphabetPicker(
        value: _direction.from,
        onChanged: (from) => _setDirection(
          from == _direction.to ? _direction.reversed : TranslitDirection(from, _direction.to),
        ),
      ),
      footer: Row(
        children: [
          Expanded(child: Text('$words söz · ${text.length} belgi', style: AppText.mono(12, color: AppColors.muted))),
          if (text.isNotEmpty)
            AppIconButton(icon: Icons.close, tooltip: 'Tozalaş', onPressed: _input.clear),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _input,
            focusNode: _focus,
            minLines: wide ? 10 : 6,
            maxLines: null,
            autocorrect: false,
            enableSuggestions: false,
            style: AppText.body(16, height: 1.6),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: _placeholders[_direction.from],
              hintStyle: AppText.body(16, color: AppColors.muted.withValues(alpha: 0.6)),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final char in _specialChars[_direction.from]!) _CharKey(char: char, onTap: () => _insert(char))],
          ),
        ],
      ),
    );

    final target = _Panel(
      header: _AlphabetPicker(
        value: _direction.to,
        onChanged: (to) => _setDirection(
          to == _direction.from ? _direction.reversed : TranslitDirection(_direction.from, to),
        ),
      ),
      footer: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          if (_direction.to != Alphabet.kirill)
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: () {
                setState(() => _plainApostrophe = !_plainApostrophe);
                _save();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _plainApostrophe,
                    activeColor: AppColors.primary,
                    visualDensity: VisualDensity.compact,
                    onChanged: (value) {
                      setState(() => _plainApostrophe = value ?? false);
                      _save();
                    },
                  ),
                  Flexible(
                    child: Text('Oddiy apostrof (\') işlatilsin', style: AppText.body(13, color: AppColors.muted)),
                  ),
                ],
              ),
            ),
          SmallButton(
            label: _copied ? 'Nusxalandi' : 'Nusxalaş',
            icon: _copied ? Icons.check : Icons.copy,
            outline: true,
            onPressed: output.isEmpty ? null : () => _copy(output),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: wide ? 240 : 120),
        child: lexicon == null
            ? const Center(child: CircularProgressIndicator())
            : output.isEmpty
                ? Text('Natija şu yerda çiqadi', style: AppText.body(16, color: AppColors.muted.withValues(alpha: 0.6)))
                : SelectableText(output, style: AppText.body(16, height: 1.6)),
      ),
    );

    final swap = Center(
      child: Tooltip(
        message: 'Yönalişni almaştiriş',
        child: HoveredWidget(
          onPressed: () => _swap(output),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          builder: (hovered) => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: hovered ? AppColors.primary : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.line),
              boxShadow: AppShadows.glowSoft,
            ),
            child: Icon(
              wide ? Icons.swap_horiz : Icons.swap_vert,
              color: hovered ? Colors.white : AppColors.primary,
            ),
          ),
        ),
      ),
    );

    return SectionScroll(
      maxWidth: 1100,
      children: [
        PageHeading(
          title: _direction.title,
          subtitle: 'Matn kiritilişi bilan ögiriladi. Ishoq, ashob (s+h) kabi istisnolar va tutuq belgisi luğat asosida hisobga olinadi.',
        ),
        const SizedBox(height: 20),
        if (wide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: source),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: swap),
                Expanded(child: target),
              ],
            ),
          )
        else ...[
          source,
          Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: swap),
          target,
        ],
        const SizedBox(height: 24),
        const _AlphabetInfo(),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget header;
  final Widget child;
  final Widget footer;

  const _Panel({required this.header, required this.child, required this.footer});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 6), child: header),
          Container(height: 1, color: AppColors.line),
          Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), child: child),
          Container(height: 1, color: AppColors.line),
          Padding(padding: const EdgeInsets.fromLTRB(12, 4, 8, 4), child: footer),
        ],
      ),
    );
  }
}

class _AlphabetPicker extends StatelessWidget {
  final Alphabet value;
  final ValueChanged<Alphabet> onChanged;

  const _AlphabetPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Segmented<Alphabet>(
      options: alphabetNames,
      value: value,
      onChanged: onChanged,
    );
  }
}

class _CharKey extends StatelessWidget {
  final String char;
  final VoidCallback onTap;

  const _CharKey({required this.char, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return HoveredWidget(
      onPressed: onTap,
      borderRadius: BorderRadius.circular(8),
      builder: (hovered) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minWidth: 38),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: hovered ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.line),
        ),
        // JetBrains Mono'da ʻ va ʼ belgilari yo'q — Inter ishlatiladi.
        child: Text(char, textAlign: TextAlign.center, style: AppText.body(16, weight: FontWeight.w600, color: AppColors.primary, height: 1.4)),
      ),
    );
  }
}

/// Yangi alifbo haqida qisqa ma'lumot (veb-saytdagi kabi).
class _AlphabetInfo extends StatelessWidget {
  const _AlphabetInfo();

  @override
  Widget build(BuildContext context) {
    Widget row(String from, String to) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              SizedBox(width: 64, child: Text(from, style: AppText.body(15, color: AppColors.muted))),
              const Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(to, style: AppText.body(17, weight: FontWeight.w600, color: AppColors.primary)),
            ],
          ),
        );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Yangi alifboda nima özgaradi?', style: AppText.heading(18)),
          const SizedBox(height: 12),
          row('Oʻ oʻ', 'Ö ö'),
          row('Gʻ gʻ', 'Ğ ğ'),
          row('Sh sh', 'Ş ş'),
          row('Ch ch', 'Ç ç'),
          const SizedBox(height: 8),
          Text(
            '«ng» mustaqil harf sifatida alifbodan çiqariladi — n va g alohida yoziladi (tong, singil), şuning uçun özgarmaydi. Tutuq belgisi (ʼ) saqlanadi: sanʼat, maʼno.',
            style: AppText.body(14, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
