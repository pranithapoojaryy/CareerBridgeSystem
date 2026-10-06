class AptitudeQuestion {
  final String id;
  final String moduleId;
  final String questionText;
  final List<String> options;
  final int? correctAnswer; // null when taking test, populated after submission
  final String? explanation;
  final String difficulty;
  final List<String>? tags;

  AptitudeQuestion({
    required this.id,
    required this.moduleId,
    required this.questionText,
    required this.options,
    this.correctAnswer,
    this.explanation,
    required this.difficulty,
    this.tags,
  });

  factory AptitudeQuestion.fromJson(Map<String, dynamic> json) {
    return AptitudeQuestion(
      id: json['id'] as String,
      moduleId: json['module_id'] as String? ?? '',
      questionText: json['question_text'] as String,
      options: (json['options'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      correctAnswer: json['correct_answer'] as int?,
      explanation: json['explanation'] as String?,
      difficulty: json['difficulty'] as String,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'module_id': moduleId,
      'question_text': questionText,
      'options': options,
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'difficulty': difficulty,
      'tags': tags,
    };
  }
}
