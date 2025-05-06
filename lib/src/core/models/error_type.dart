enum ErrorType {
  IMLO,
  PUNKTUATSION,
  USLUBIY,
  GRAFIK,
}

extension ToStringXato on ErrorType {
  String get toName {

    if (name == ErrorType.IMLO.name) return "Imloviy";
    if (name == ErrorType.PUNKTUATSION.name) return "Punktuatsion";
    if (name == ErrorType.USLUBIY.name) return "Uslubiy";
    return "Grafik";
  }
}
ErrorType errorTypeFromString(String type) {
  return ErrorType.values.firstWhere((e) => e.toString().split('.').last == type);
}

String errorTypeToString(ErrorType type) {
  return type.toString().split('.').last;
}