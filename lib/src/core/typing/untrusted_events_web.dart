import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Brauzerda JS yuborgan (foydalanuvchi emas) klaviatura va kiritish
/// hodisalarini sanaydi: `isTrusted == false`. Script yashirin kiritish
/// maydoniga qiymat yozib, `input`/`keydown` hodisasini qo'lda yuborsa, ular
/// shu yerda ko'rinadi.
class UntrustedEvents {
  static const List<String> _types = ['keydown', 'keypress', 'keyup', 'beforeinput', 'input'];

  int _count = 0;
  late final JSFunction _listener = ((web.Event event) {
    if (!event.isTrusted) _count++;
  }).toJS;

  UntrustedEvents() {
    // Capture bosqichi: hodisa Flutter'ning o'z ishlovchilariga yetmasdan oldin.
    for (final type in _types) {
      web.window.addEventListener(type, _listener, true.toJS);
    }
  }

  int get count => _count;

  void dispose() {
    for (final type in _types) {
      web.window.removeEventListener(type, _listener, true.toJS);
    }
  }
}
