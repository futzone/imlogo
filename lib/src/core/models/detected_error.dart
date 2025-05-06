import 'package:dication/src/core/models/error_type.dart';

class DetectedError {
  ErrorType type;
  String description;
  String originalFragment;
  String userFragment;
  String specificRuleCode;
  double penaltyMultiplier;

  DetectedError({
    required this.type,
    required this.description,
    this.originalFragment = '',
    this.userFragment = '',
    required this.specificRuleCode,
    this.penaltyMultiplier = 1.0,
  });

  factory DetectedError.fromJson(Map<String, dynamic> json) {
    return DetectedError(
      type: errorTypeFromString(json['type']),
      description: json['description'],
      originalFragment: json['originalFragment'] ?? '',
      userFragment: json['userFragment'] ?? '',
      specificRuleCode: json['specificRuleCode'],
      penaltyMultiplier: (json['penaltyMultiplier'] ?? 1.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': errorTypeToString(type),
      'description': description,
      'originalFragment': originalFragment,
      'userFragment': userFragment,
      'specificRuleCode': specificRuleCode,
      'penaltyMultiplier': penaltyMultiplier,
    };
  }
}
