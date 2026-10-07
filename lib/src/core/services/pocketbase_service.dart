import 'package:pocketbase/pocketbase.dart';
import 'package:dication/src/core/constants/app_constants.dart';
import 'package:dication/src/core/models/app_info_model.dart';
import 'package:dication/src/core/models/text_model.dart';

final _pb = PocketBase('https://admin.imlogo.uz');

class PocketBaseService {
  static const int perPage = 20;

  static Future<({List<TextModel> items, int totalPages})> fetchDictations({
    int page = 1,
  }) async {
    final result = await _pb.collection('dictations').getList(
          page: page,
          perPage: perPage,
          sort: '-created',
        );

    final items = result.items.map((record) {
      final audioFileName = record.data['audio'] as String?;
      String? audioUrl;
      if (audioFileName != null && audioFileName.isNotEmpty) {
        audioUrl = _pb.files.getUrl(record, audioFileName).toString();
      }

      final text = record.data['text'] as String? ?? '';

      return TextModel(
        id: record.id,
        title: record.data['title'] ?? '',
        text: text,
        className: record.data['class'] ?? '',
        ageName: record.data['age'] ?? '',
        length: text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length,
        time: record.data['time'] ?? 0,
        url: audioUrl,
        createdDate: DateTime.tryParse(record.created),
      );
    }).toList();

    return (items: items, totalPages: result.totalPages);
  }

  static Future<AppInfoModel> fetchAppInfo() async {
    final record = await _pb.collection('app').getFirstListItem('');
    final data = record.data;

    String? _nonEmpty(String? val) =>
        (val != null && val.isNotEmpty) ? val : null;

    return AppInfoModel(
      about: data['about'] ?? '',
      // Kanal manzili serverdagi qiymatga bog'liq emas.
      telegram: AppConstants.telegramChannel,
      website: _nonEmpty(data['website']),
      github: _nonEmpty(data['github']),
      docs: _nonEmpty(data['docs']),
      license: _nonEmpty(data['license']),
    );
  }
}
