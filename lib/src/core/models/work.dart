import 'package:dication/src/core/models/text_model.dart';
import 'detected_error.dart';

class Work {
  String id;
  String createdDate;
  double ball;
  double baho;
  List<DetectedError> errors;
  TextModel text;
  int imloErrorCount;
  int punktuatsionErrorCount;
  int uslubiyErrorCount;
  int grafikErrorCount;
  int worktime;
  String input;

  Work({
    required this.id,
    required this.createdDate,
    required this.ball,
    required this.baho,
    required this.errors,
    required this.text,
    required this.imloErrorCount,
    required this.punktuatsionErrorCount,
    required this.uslubiyErrorCount,
    required this.grafikErrorCount,
    required this.worktime,
    required this.input,
  });

  /// Qurilmadagi va serverdagi (veb-sayt yozgan) natijani o'qiydi — ikkalasi bir xil shaklda.
  factory Work.fromJson(Map<String, dynamic> json) {
    return Work(
      input: json['input'] ?? '',
      id: json['id'],
      createdDate: json['createdDate'],
      ball: (json['ball'] ?? 0).toDouble(),
      baho: (json['baho'] ?? 0).toDouble(),
      errors: (json['errors'] as List).map((e) => DetectedError.fromJson(e)).toList(),
      text: TextModel.fromJson(json['text']),
      imloErrorCount: (json['imloErrorCount'] as num? ?? 0).toInt(),
      punktuatsionErrorCount: (json['punktuatsionErrorCount'] as num? ?? 0).toInt(),
      uslubiyErrorCount: (json['uslubiyErrorCount'] as num? ?? 0).toInt(),
      grafikErrorCount: (json['grafikErrorCount'] as num? ?? 0).toInt(),
      worktime: (json['worktime'] as num? ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdDate': createdDate,
      'ball': ball,
      'baho': baho,
      'errors': errors.map((e) => e.toJson()).toList(),
      'text': text.toJson(),
      'imloErrorCount': imloErrorCount,
      'punktuatsionErrorCount': punktuatsionErrorCount,
      'uslubiyErrorCount': uslubiyErrorCount,
      'grafikErrorCount': grafikErrorCount,
      'worktime': worktime,
      'input': input,
    };
  }
}
