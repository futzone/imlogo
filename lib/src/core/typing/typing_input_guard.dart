import 'package:dication/src/core/typing/untrusted_events_stub.dart'
    if (dart.library.js_interop) 'package:dication/src/core/typing/untrusted_events_web.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Tez yozish mashqida kiritishni kuzatish (saytdagi `TypingView.tsx` bilan
/// bir xil g'oya):
///
/// * kompyuterda (Windows, macOS, Linux, shu jumladan brauzerda) har bir
///   kiritilgan belgidan oldin haqiqiy klavish bosilgan bo'lishi kerak va bir
///   hodisada faqat bitta belgi qo'shiladi — qo'yish (paste), script yozgan
///   qiymat qabul qilinmaydi. Telefon ekran klaviaturasi klavish hodisasini
///   yubormaydi, shuning uchun u yerda bu tekshiruv yo'q;
/// * brauzerda JS yuborgan soxta hodisalar qabul qilinmaydi;
/// * har bir qabul qilingan o'zgarish uchun oxirgi bosilgan klavish
///   ([takeKey]) logga yoziladi — server shu log bo'yicha natijani tekshiradi
///   (qarang: `typing_guard.dart` analyzeTyping).
class TypingInputGuard {
  static const Set<TargetPlatform> _desktop = {
    TargetPlatform.macOS,
    TargetPlatform.windows,
    TargetPlatform.linux,
  };

  /// Ekran klaviaturasidan kiritilgan o'zgarish uchun klavish o'rniga yoziladi:
  /// u klavish hodisasini yubormaydi (aks holda har bir telefon natijasi
  /// `no_keydown` bo'lib qolardi).
  static const String softKeyboard = 'soft';

  /// Klavish talab qilinadimi (kompyuter). Testlar uchun almashtirsa bo'ladi.
  final bool strict;
  final UntrustedEvents _untrusted = UntrustedEvents();

  String? _lastKey;
  int _untrustedSeen = 0;

  TypingInputGuard({bool? strict}) : strict = strict ?? _desktop.contains(defaultTargetPlatform) {
    HardwareKeyboard.instance.addHandler(_onKey);
    _untrustedSeen = _untrusted.count;
  }

  bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      final label = event.character ?? event.logicalKey.keyLabel;
      _lastKey = (label.isEmpty ? event.logicalKey.debugName ?? 'key' : label);
      if (_lastKey!.length > 16) _lastKey = _lastKey!.substring(0, 16);
    }
    return false;
  }

  /// Yangi mashq boshlanganda.
  void reset() {
    _lastKey = null;
    _untrustedSeen = _untrusted.count;
  }

  /// Kiritish maydoni o'zgarganini qabul qilish kerakmi. [added] — qo'shilgan
  /// belgilar soni (o'chirishda manfiy), [composing] — IME so'z yig'ayapti.
  /// Rad etilganda oxirgi klavish ham bekor bo'ladi.
  bool accept(int added, {required bool composing}) {
    if (_untrusted.count != _untrustedSeen) {
      _untrustedSeen = _untrusted.count;
      _lastKey = null;
      return false;
    }
    if (added <= 0 || composing || !strict) return true;
    final ok = _lastKey != null && added == 1;
    if (!ok) _lastKey = null;
    return ok;
  }

  /// Qabul qilingan o'zgarish uchun logdagi klavish: oxirgi bosilgani,
  /// kompyuterda bosilmagan bo'lsa — `null`, telefonda — [softKeyboard].
  String? takeKey() {
    final key = _lastKey ?? (strict ? null : softKeyboard);
    _lastKey = null;
    return key;
  }

  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _untrusted.dispose();
  }
}
