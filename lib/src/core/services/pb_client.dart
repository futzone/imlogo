import 'package:hive_flutter/hive_flutter.dart';
import 'package:pocketbase/pocketbase.dart';

const String pbBaseUrl = 'https://admin.imlogo.uz';

const _authBox = 'auth';
const _authKey = 'pocketbase_auth';

late final PocketBase pb;

/// PocketBase mijozini yaratadi. Kirish sessiyasi Hive'da saqlanadi —
/// ilova qayta ochilganda foydalanuvchi qayta kirishi shart emas.
Future<void> initPocketBase() async {
  final box = await Hive.openBox(_authBox);
  final store = AsyncAuthStore(
    save: (data) => box.put(_authKey, data),
    clear: () => box.delete(_authKey),
    initial: box.get(_authKey) as String?,
  );
  pb = PocketBase(pbBaseUrl, authStore: store);
}
