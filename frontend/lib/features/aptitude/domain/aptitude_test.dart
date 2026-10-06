class AptitudeTest {
  final String id;
  final String moduleId;
  final String testType; // 'practice' or 'assignment'
  final String title;
  final String? description;
  final String difficulty;
  final int durationMinutes;
  final int totalQuestions;
  final int passingScore;
  final String? instructions;
  final bool negativeMarking;
  final bool shuffleQuestions;
  final bool showResultsImmediately;
  final bool showCorrectAnswers;
  final bool isActive;

  AptitudeTest({
    required this.id,
    required this.moduleId,
    required this.testType,
    required this.title,
    this.description,
    required this.difficulty,
    required this.durationMinutes,
    required this.totalQuestions,
    this.passingScore = 60,
    this.instructions,
    this.negativeMarking = false,
    this.shuffleQuestions = true,
    this.showResultsImmediately = true,
    this.showCorrectAnswers = true,
    this.isActive = true,
  });

  factory AptitudeTest.fromJson(Map<String, dynamic> json) {
    return AptitudeTest(
      id: json['id'] as String,
      moduleId: json['module_id'] as String,
      testType: json['test_type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      difficulty: json['difficulty'] as String,
      durationMinutes: json['duration_minutes'] as int,
      totalQuestions: json['total_questions'] as int,
      passingScore: json['passing_score'] as int? ?? 60,
      instructions: json['instructions'] as String?,
      negativeMarking: json['negative_marking'] as bool? ?? false,
      shuffleQuestions: json['shuffle_questions'] as bool? ?? true,
      showResultsImmediately: json['show_results_immediately'] as bool? ?? true,
      showCorrectAnswers: json['show_correct_answers'] as bool? ?? true,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'module_id': moduleId,
      'test_type': testType,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'duration_minutes': durationMinutes,
      'total_questions': totalQuestions,
      'passing_score': passingScore,
      'instructions': instructions,
      'negative_marking': negativeMarking,
      'shuffle_questions': shuffleQuestions,
      'show_results_immediately': showResultsImmediately,
      'show_correct_answers': showCorrectAnswers,
      'is_active': isActive,
    };
  }
}
