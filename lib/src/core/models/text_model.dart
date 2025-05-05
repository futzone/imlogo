class TextModel {
  final String id;
  final String title;
  final String text;
  final String className;
  final String ageName;
  final int length;
  final int time;
  final String? url;

  TextModel({
    required this.id,
    this.url,
    required this.text,
    required this.time,
    required this.title,
    required this.length,
    required this.ageName,
    required this.className,
  });

  factory TextModel.fromJson(map) {
    return TextModel(
      id: map['id'].toString(),
      text: map['text'],
      time: map['time'],
      title: map['title'],
      length: map['length'],
      ageName: map['ageName'],
      className: map['className'],
      url: map['url'],
    );
  }

  static List<TextModel> asList(List<dynamic> list) {
    List<TextModel> kList = [];
    for (final item in list) {
      kList.add(TextModel.fromJson(item));
    }

    return kList;
  }
}
