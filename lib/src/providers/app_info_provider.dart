import 'package:dication/src/core/models/app_info_model.dart';
import 'package:dication/src/core/services/pocketbase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appInfoProvider = FutureProvider<AppInfoModel>((ref) async {
  return PocketBaseService.fetchAppInfo();
});
