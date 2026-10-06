// Assessment Domain Models for Learning Path System

class Assessment {
  final String id;
  final String sectionId;
  final String title;
  final String description;
  final AssessmentType type;
  final double passingCriteria; // Percentage required to pass (0-100)
  final double weightage; // Contribution to overall course score
  final int attemptsAllowed;
  final bool isAutoEvaluated;
  final List<AssessmentQuestion> questions;
  final String? feedbackTemplate;
  final DateTime createdAt;

  Assessment({
    required this.id,
    required this.sectionId,
    required this.title,
    required this.description,
    required this.type,
    required this.passingCriteria,
    required this.weightage,
    this.attemptsAllowed = 1,
    this.isAutoEvaluated = false,
    this.questions = const [],
    this.feedbackTemplate,
    required this.createdAt,
  });

  factory Assessment.fromJson(Map<String, dynamic> json) {
    return Assessment(
      id: json['id'] ?? '',
      sectionId: json['section_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: AssessmentType.fromString(json['assessment_type'] ?? 'Quiz'),
      passingCriteria: (json['passing_criteria'] as num?)?.toDouble() ?? 60.0,
      weightage: (json['weightage'] as num?)?.toDouble() ?? 10.0,
      attemptsAllowed: json['attempts_allowed'] ?? 1,
      isAutoEvaluated: json['is_auto_evaluated'] ?? false,
      questions: json['questions'] != null
          ? (json['questions'] as List)
                .map((q) => AssessmentQuestion.fromJson(q))
                .toList()
          : [],
      feedbackTemplate: json['feedback_template'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'section_id': sectionId,
      'title': title,
      'description': description,
      'assessment_type': type.toString(),
      'passing_criteria': passingCriteria,
      'weightage': weightage,
      'attempts_allowed': attemptsAllowed,
      'is_auto_evaluated': isAutoEvaluated,
      'questions': questions.map((q) => q.toJson()).toList(),
      'feedback_template': feedbackTemplate,
    };
  }

  Assessment copyWith({
    String? id,
    String? sectionId,
    String? title,
    String? description,
    AssessmentType? type,
    double? passingCriteria,
    double? weightage,
    int? attemptsAllowed,
    bool? isAutoEvaluated,
    List<AssessmentQuestion>? questions,
    String? feedbackTemplate,
    DateTime? createdAt,
  }) {
    return Assessment(
      id: id ?? this.id,
      sectionId: sectionId ?? this.sectionId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      passingCriteria: passingCriteria ?? this.passingCriteria,
      weightage: weightage ?? this.weightage,
      attemptsAllowed: attemptsAllowed ?? this.attemptsAllowed,
      isAutoEvaluated: isAutoEvaluated ?? this.isAutoEvaluated,
      questions: questions ?? this.questions,
      feedbackTemplate: feedbackTemplate ?? this.feedbackTemplate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum AssessmentType {
  quiz,
  assignment,
  videoResponse,
  codeTask;

  static AssessmentType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'quiz':
        return AssessmentType.quiz;
      case 'assignment':
        return AssessmentType.assignment;
      case 'video response':
        return AssessmentType.videoResponse;
      case 'code task':
        return AssessmentType.codeTask;
      default:
        return AssessmentType.quiz;
    }
  }

  @override
  String toString() {
    switch (this) {
      case AssessmentType.quiz:
        return 'Quiz';
      case AssessmentType.assignment:
        return 'Assignment';
      case AssessmentType.videoResponse:
        return 'Video Response';
      case AssessmentType.codeTask:
        return 'Code Task';
    }
  }
}

class AssessmentQuestion {
  final String id;
  final String questionText;
  final QuestionType type;
  final List<String> options; // For MCQ
  final List<int> correctAnswers; // Indices of correct options for MCQ
  final String? correctAnswer; // For text-based questions
  final int points;
  final String? explanation;

  AssessmentQuestion({
    required this.id,
    required this.questionText,
    required this.type,
    this.options = const [],
    this.correctAnswers = const [],
    this.correctAnswer,
    this.points = 1,
    this.explanation,
  });

  factory AssessmentQuestion.fromJson(Map<String, dynamic> json) {
    // Handle both 'question_text' and 'question' keys for backwards compatibility
    final questionText = json['question_text'] ?? json['question'] ?? '';

    // Handle both 'type' and 'questionType' keys
    final typeStr = json['type'] ?? json['questionType'] ?? 'mcq';

    // Handle options - could be stored as 'options' or need extraction
    List<String> options = [];
    if (json['options'] != null) {
      if (json['options'] is List) {
        options = List<String>.from(json['options']);
      }
    }

    // Handle correct_answers - could be 'correct_answers' or 'correctAnswers'
    List<int> correctAnswers = [];
    if (json['correct_answers'] != null) {
      correctAnswers = List<int>.from(json['correct_answers']);
    } else if (json['correctAnswers'] != null) {
      correctAnswers = List<int>.from(json['correctAnswers']);
    }

    return AssessmentQuestion(
      id: json['id'] ?? '',
      questionText: questionText,
      type: QuestionType.fromString(typeStr),
      options: options,
      correctAnswers: correctAnswers,
      correctAnswer: json['correct_answer'] ?? json['correctAnswer'],
      points: json['points'] ?? 1,
      explanation: json['explanation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_text': questionText,
      'type': type.toString(),
      'options': options,
      'correct_answers': correctAnswers,
      'correct_answer': correctAnswer,
      'points': points,
      'explanation': explanation,
    };
  }
}

enum QuestionType {
  multipleChoice,
  trueFalse,
  shortAnswer,
  essay,
  code;

  static QuestionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'mcq':
      case 'multiple_choice':
        return QuestionType.multipleChoice;
      case 'true_false':
        return QuestionType.trueFalse;
      case 'short_answer':
        return QuestionType.shortAnswer;
      case 'essay':
        return QuestionType.essay;
      case 'code':
        return QuestionType.code;
      default:
        return QuestionType.multipleChoice;
    }
  }

  @override
  String toString() {
    switch (this) {
      case QuestionType.multipleChoice:
        return 'mcq';
      case QuestionType.trueFalse:
        return 'true_false';
      case QuestionType.shortAnswer:
        return 'short_answer';
      case QuestionType.essay:
        return 'essay';
      case QuestionType.code:
        return 'code';
    }
  }
}

class AssessmentSubmission {
  final String id;
  final String studentId;
  final String assessmentId;
  final DateTime submittedAt;
  final int attemptNumber;
  final Map<String, dynamic> answers; // questionId -> answer
  final String? submissionUrl; // For file uploads
  final double? score;
  final bool? isPassed;
  final String? facultyFeedback;
  final DateTime? evaluatedAt;
  final String? evaluatedBy;

  AssessmentSubmission({
    required this.id,
    required this.studentId,
    required this.assessmentId,
    required this.submittedAt,
    required this.attemptNumber,
    required this.answers,
    this.submissionUrl,
    this.score,
    this.isPassed,
    this.facultyFeedback,
    this.evaluatedAt,
    this.evaluatedBy,
  });

  factory AssessmentSubmission.fromJson(Map<String, dynamic> json) {
    return AssessmentSubmission(
      id: json['id'] ?? '',
      studentId: json['student_id'] ?? '',
      assessmentId: json['assessment_id'] ?? '',
      submittedAt:
          DateTime.tryParse(json['submitted_at'] ?? '') ?? DateTime.now(),
      attemptNumber: json['attempt_number'] ?? 1,
      answers: Map<String, dynamic>.from(json['answers'] ?? {}),
      submissionUrl: json['submission_url'],
      score: (json['score'] as num?)?.toDouble(),
      isPassed: json['is_passed'],
      facultyFeedback: json['faculty_feedback'],
      evaluatedAt: json['evaluated_at'] != null
          ? DateTime.tryParse(json['evaluated_at'])
          : null,
      evaluatedBy: json['evaluated_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'assessment_id': assessmentId,
      'attempt_number': attemptNumber,
      'answers': answers,
      'submission_url': submissionUrl,
      'score': score,
      'is_passed': isPassed,
      'faculty_feedback': facultyFeedback,
      'evaluated_at': evaluatedAt?.toIso8601String(),
      'evaluated_by': evaluatedBy,
    };
  }
}

class AssessmentResult {
  final AssessmentSubmission submission;
  final Assessment assessment;
  final int totalQuestions;
  final int correctAnswers;
  final double scorePercentage;
  final bool passed;
  final Map<String, QuestionResult> questionResults;

  AssessmentResult({
    required this.submission,
    required this.assessment,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.scorePercentage,
    required this.passed,
    required this.questionResults,
  });

  static AssessmentResult calculate(
    Assessment assessment,
    AssessmentSubmission submission,
  ) {
    int totalPoints = 0;
    int earnedPoints = 0;
    Map<String, QuestionResult> results = {};

    for (var question in assessment.questions) {
      totalPoints += question.points;

      final studentAnswer = submission.answers[question.id];
      bool isCorrect = false;

      if (question.type == QuestionType.multipleChoice) {
        if (studentAnswer is int) {
          isCorrect = question.correctAnswers.contains(studentAnswer);
        }
      } else if (question.type == QuestionType.trueFalse) {
        isCorrect =
            studentAnswer.toString().toLowerCase() ==
            question.correctAnswer?.toLowerCase();
      } else if (question.type == QuestionType.shortAnswer) {
        isCorrect =
            studentAnswer.toString().toLowerCase().trim() ==
            question.correctAnswer?.toLowerCase().trim();
      }

      if (isCorrect) {
        earnedPoints += question.points;
      }

      results[question.id] = QuestionResult(
        questionId: question.id,
        studentAnswer: studentAnswer,
        isCorrect: isCorrect,
        pointsEarned: isCorrect ? question.points : 0,
        explanation: question.explanation,
      );
    }

    final scorePercentage = totalPoints > 0
        ? (earnedPoints / totalPoints) * 100
        : 0.0;
    final passed = scorePercentage >= assessment.passingCriteria;

    return AssessmentResult(
      submission: submission,
      assessment: assessment,
      totalQuestions: assessment.questions.length,
      correctAnswers: results.values.where((r) => r.isCorrect).length,
      scorePercentage: scorePercentage,
      passed: passed,
      questionResults: results,
    );
  }
}

class QuestionResult {
  final String questionId;
  final dynamic studentAnswer;
  final bool isCorrect;
  final int pointsEarned;
  final String? explanation;

  QuestionResult({
    required this.questionId,
    required this.studentAnswer,
    required this.isCorrect,
    required this.pointsEarned,
    this.explanation,
  });
}

// Progress Tracking Models

class ModuleProgress {
  final String id;
  final String studentId;
  final String sectionId;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final ModuleStatus status;

  ModuleProgress({
    required this.id,
    required this.studentId,
    required this.sectionId,
    this.startedAt,
    this.completedAt,
    required this.status,
  });

  factory ModuleProgress.fromJson(Map<String, dynamic> json) {
    return ModuleProgress(
      id: json['id'] ?? '',
      studentId: json['student_id'] ?? '',
      sectionId: json['section_id'] ?? '',
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'])
          : null,
      status: ModuleStatus.fromString(json['status'] ?? 'Not Started'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'section_id': sectionId,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'status': status.toString(),
    };
  }
}

enum ModuleStatus {
  notStarted,
  inProgress,
  completed;

  static ModuleStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'not started':
        return ModuleStatus.notStarted;
      case 'in progress':
        return ModuleStatus.inProgress;
      case 'completed':
        return ModuleStatus.completed;
      default:
        return ModuleStatus.notStarted;
    }
  }

  @override
  String toString() {
    switch (this) {
      case ModuleStatus.notStarted:
        return 'Not Started';
      case ModuleStatus.inProgress:
        return 'In Progress';
      case ModuleStatus.completed:
        return 'Completed';
    }
  }
}

class LectureProgress {
  final String id;
  final String studentId;
  final String lectureId;
  final bool completed;
  final DateTime? watchedAt;
  final int? watchDurationSeconds;

  LectureProgress({
    required this.id,
    required this.studentId,
    required this.lectureId,
    this.completed = false,
    this.watchedAt,
    this.watchDurationSeconds,
  });

  factory LectureProgress.fromJson(Map<String, dynamic> json) {
    return LectureProgress(
      id: json['id'] ?? '',
      studentId: json['student_id'] ?? '',
      lectureId: json['lecture_id'] ?? '',
      completed: json['is_completed'] ?? false,
      watchedAt: json['watched_at'] != null
          ? DateTime.tryParse(json['watched_at'])
          : null,
      watchDurationSeconds: json['watch_duration_seconds'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'lecture_id': lectureId,
      'is_completed': completed,
      'watched_at': watchedAt?.toIso8601String(),
      'watch_duration_seconds': watchDurationSeconds,
    };
  }
}
