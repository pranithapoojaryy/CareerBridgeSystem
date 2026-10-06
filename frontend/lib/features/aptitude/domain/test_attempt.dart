import 'aptitude_question.dart';

class TestAttempt {
  final String id;
  final String testId;
  final String? assignmentId;
  final String studentId;
  final String testType;
  final String? moduleName;
  final String difficulty;
  final int attemptNumber;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationSeconds;
  final List<AptitudeQuestion> questions;
  final Map<String, int> answers; // question_id -> selected_option_index
  final List<String> markedForReview;
  final Map<String, int> timePerQuestion; // question_id -> seconds
  final int totalQuestions;
  final int attemptedQuestions;
  final int correctAnswers;
  final int incorrectAnswers;
  final int unanswered;
  final double? score;
  final double? percentage;
  final String status; // 'in_progress', 'completed', 'abandoned', 'timed_out'

  TestAttempt({
    required this.id,
    required this.testId,
    this.assignmentId,
    required this.studentId,
    required this.testType,
    this.moduleName,
    required this.difficulty,
    required this.attemptNumber,
    required this.startTime,
    this.endTime,
    this.durationSeconds,
    required this.questions,
    Map<String, int>? answers,
    List<String>? markedForReview,
    Map<String, int>? timePerQuestion,
    required this.totalQuestions,
    this.attemptedQuestions = 0,
    this.correctAnswers = 0,
    this.incorrectAnswers = 0,
    this.unanswered = 0,
    this.score,
    this.percentage,
    this.status = 'in_progress',
  }) : answers = answers ?? {},
       markedForReview = markedForReview ?? [],
       timePerQuestion = timePerQuestion ?? {};

  factory TestAttempt.fromJson(
    Map<String, dynamic> json,
    List<AptitudeQuestion> questions,
  ) {
    return TestAttempt(
      id: json['id'] as String,
      testId: json['test_id'] as String,
      assignmentId: json['assignment_id'] as String?,
      studentId: json['student_id'] as String,
      testType: json['test_type'] as String,
      moduleName: json['module_name'] as String?,
      difficulty: json['difficulty'] as String,
      attemptNumber: json['attempt_number'] as int,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      durationSeconds: json['duration_seconds'] as int?,
      questions: questions,
      answers:
          (json['answers'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as int),
          ) ??
          {},
      markedForReview:
          (json['marked_for_review'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      timePerQuestion:
          (json['time_per_question'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as int),
          ) ??
          {},
      totalQuestions: json['total_questions'] as int,
      attemptedQuestions: json['attempted_questions'] as int? ?? 0,
      correctAnswers: json['correct_answers'] as int? ?? 0,
      incorrectAnswers: json['incorrect_answers'] as int? ?? 0,
      unanswered: json['unanswered'] as int? ?? 0,
      score: double.tryParse(json['score']?.toString() ?? '0'),
      percentage: double.tryParse(json['percentage']?.toString() ?? '0'),
      status: json['status'] as String? ?? 'in_progress',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'test_id': testId,
      'assignment_id': assignmentId,
      'student_id': studentId,
      'test_type': testType,
      'module_name': moduleName,
      'difficulty': difficulty,
      'attempt_number': attemptNumber,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_seconds': durationSeconds,
      'answers': answers,
      'marked_for_review': markedForReview,
      'time_per_question': timePerQuestion,
      'total_questions': totalQuestions,
      'attempted_questions': attemptedQuestions,
      'correct_answers': correctAnswers,
      'incorrect_answers': incorrectAnswers,
      'unanswered': unanswered,
      'score': score,
      'percentage': percentage,
      'status': status,
    };
  }

  // Helper methods
  bool get isCompleted => status == 'completed' || status == 'submitted';
  bool get isInProgress => status == 'in_progress';

  int get timeRemaining {
    if (durationSeconds == null) return 0;
    final elapsed = DateTime.now().difference(startTime).inSeconds;
    return durationSeconds! - elapsed;
  }

  double get progress => attemptedQuestions / totalQuestions;

  TestAttempt copyWith({
    String? id,
    String? testId,
    String? assignmentId,
    String? studentId,
    String? testType,
    String? moduleName,
    String? difficulty,
    int? attemptNumber,
    DateTime? startTime,
    DateTime? endTime,
    int? durationSeconds,
    List<AptitudeQuestion>? questions,
    Map<String, int>? answers,
    List<String>? markedForReview,
    Map<String, int>? timePerQuestion,
    int? totalQuestions,
    int? attemptedQuestions,
    int? correctAnswers,
    int? incorrectAnswers,
    int? unanswered,
    double? score,
    double? percentage,
    String? status,
  }) {
    return TestAttempt(
      id: id ?? this.id,
      testId: testId ?? this.testId,
      assignmentId: assignmentId ?? this.assignmentId,
      studentId: studentId ?? this.studentId,
      testType: testType ?? this.testType,
      moduleName: moduleName ?? this.moduleName,
      difficulty: difficulty ?? this.difficulty,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      markedForReview: markedForReview ?? this.markedForReview,
      timePerQuestion: timePerQuestion ?? this.timePerQuestion,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      attemptedQuestions: attemptedQuestions ?? this.attemptedQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      incorrectAnswers: incorrectAnswers ?? this.incorrectAnswers,
      unanswered: unanswered ?? this.unanswered,
      score: score ?? this.score,
      percentage: percentage ?? this.percentage,
      status: status ?? this.status,
    );
  }
}
