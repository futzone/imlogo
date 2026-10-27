class TextModel {
  final String id;
  final String title;
  final String text;
  final String className;
  final String ageName;
  final int length;
  final int time;
  final String? url;
  final DateTime? createdDate;

  TextModel({
    required this.id,
    this.url,
    required this.text,
    required this.time,
    required this.title,
    required this.length,
    required this.ageName,
    required this.className,
    this.createdDate,
  });

  factory TextModel.fromJson(map) {
    return TextModel(
      id: map['id'].toString(),
      text: map['text'] ?? '',
      time: (map['time'] as num? ?? 0).toInt(),
      title: map['title'] ?? '',
      length: (map['length'] as num? ?? 0).toInt(),
      ageName: map['ageName'] ?? '',
      className: map['className'] ?? '',
      url: map['url'],
      createdDate: map['createdDate'] != null
          ? DateTime.tryParse(map['createdDate'])
          : null,
    );
  }

  static List<TextModel> asList(List<dynamic> list) {
    List<TextModel> kList = [];
    for (final item in list) {
      kList.add(TextModel.fromJson(item));
    }
    return kList;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'text': text,
      'className': className,
      'ageName': ageName,
      'length': length,
      'time': time,
      'url': url,
      'createdDate': createdDate?.toIso8601String(),
    };
  }

  String get formattedDate {
    if (createdDate == null) return '';
    final d = createdDate!.toLocal();
    final year = d.year;
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$year.$month.$day, $hour:$minute';
  }
}
