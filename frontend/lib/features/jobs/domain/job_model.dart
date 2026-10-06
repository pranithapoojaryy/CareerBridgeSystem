import 'package:freezed_annotation/freezed_annotation.dart';

part 'job_model.freezed.dart';
part 'job_model.g.dart';

@freezed
class Job with _$Job {
  const Job._();

  const factory Job({
    required String id,
    @JsonKey(name: 'recruiter_id') required String recruiterId,
    @JsonKey(name: 'organization_id') String? organizationId,
    required String title,
    required String description,
    String? requirements,
    String? location,
    @JsonKey(name: 'salary_range') String? salaryRange,
    @JsonKey(name: 'job_type') String? jobType,
    @JsonKey(name: 'is_featured') @Default(false) bool isFeatured,
    @Default('open') String status,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'screening_questions', fromJson: normalizeScreeningQuestions) List<Map<String, dynamic>>? screeningQuestions,
    Map<String, dynamic>? organization, // For joined data
  }) = _Job;

  factory Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);
}

List<Map<String, dynamic>>? normalizeScreeningQuestions(dynamic json) {
  if (json == null) return null;
  if (json is List) {
    return json.map((item) {
      if (item is String) {
        // Backward compatibility for old string-based questions
        return {'question': item, 'type': 'text'};
      }
      if (item is Map) {
        return Map<String, dynamic>.from(item);
      }
      return {'question': item.toString(), 'type': 'text'};
    }).toList();
  }
  return null;
}
