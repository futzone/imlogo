class AppInfoModel {
  final String about;
  final String? telegram;
  final String? website;
  final String? github;
  final String? docs;
  final String? license;

  AppInfoModel({
    required this.about,
    this.telegram,
    this.website,
    this.github,
    this.docs,
    this.license,
  });
}
