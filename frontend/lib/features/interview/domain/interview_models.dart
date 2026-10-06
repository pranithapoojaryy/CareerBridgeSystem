class InterviewCategory {
  final String id;
  final String name;
  final String type;
  final String? description;
  final String iconName;

  InterviewCategory({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    this.iconName = 'folder',
  });

  factory InterviewCategory.fromJson(Map<String, dynamic> json) {
    return InterviewCategory(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      description: json['description'],
      iconName: json['icon_name'] ?? 'folder',
    );
  }
}

class InterviewQuestion {
  final String id;
  final String categoryId;
  final String questionText;
  final String difficulty;
  final List<String> expectedKeywords;
  final String questionType; // 'video' or 'coding'

  InterviewQuestion({
    required this.id,
    required this.categoryId,
    required this.questionText,
    required this.difficulty,
    required this.expectedKeywords,
    this.questionType = 'video',
  });

  factory InterviewQuestion.fromJson(Map<String, dynamic> json) {
    return InterviewQuestion(
      id: json['id'] ?? '',
      categoryId: json['category_id'] ?? '',
      questionText: json['question_text'] ?? 'Unknown Question',
      difficulty: json['difficulty'] ?? 'Medium',
      expectedKeywords: List<String>.from(json['expected_keywords'] ?? []),
      questionType: json['question_type'] ?? 'video',
    );
  }
}

class LearningContent {
  final String id;
  final String categoryId;
  final String title;
  final String type; // 'video', 'article', 'pdf'
  final String url;
  final String? description;

  LearningContent({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.type,
    required this.url,
    this.description,
  });

  factory LearningContent.fromJson(Map<String, dynamic> json) {
    return LearningContent(
      id: json['id'],
      categoryId: json['category_id'],
      title: json['title'] ?? 'Untitled',
      type: json['type'] ?? 'Article',
      url: json['content_url'] ?? '',
      description: json['description'],
    );
  }
}

class InterviewAttempt {
  final String id;
  final String studentId;
  final String questionId;
  final String? videoUrl;
  final String? codeAnswer;
  final int? durationSeconds;
  final Map<String, dynamic> scoreJson;
  final String aiFeedback;
  final String status;
  final DateTime createdAt;
  final InterviewQuestion? question;
  // Faculty review
  final String? facultyFeedback;
  final int? facultyScore;
  final String? mockAttemptId;

  InterviewAttempt({
    required this.id,
    required this.studentId,
    required this.questionId,
    this.videoUrl,
    this.codeAnswer,
    this.durationSeconds,
    required this.scoreJson,
    required this.aiFeedback,
    required this.status,
    required this.createdAt,
    this.question,
    this.facultyFeedback,
    this.facultyScore,
    this.answerStartOffset,
    this.answerEndOffset,
    this.studentName,
    this.mockAttemptId,
    this.mockTitle,
    this.mockTotalScore,
  });

  final int? answerStartOffset;
  final int? answerEndOffset;
  final String? studentName;
  final String? mockTitle;
  final int? mockTotalScore;

  factory InterviewAttempt.fromJson(Map<String, dynamic> json) {
    return InterviewAttempt(
      id: json['id'] ?? '',
      studentId: json['student_id'] ?? '',
      questionId: json['question_id'] ?? '',
      videoUrl: json['video_url'],
      codeAnswer: json['code_answer'],
      durationSeconds: json['duration_seconds'],
      scoreJson: json['score_json'] ?? {},
      aiFeedback: json['ai_feedback'] ?? '',
      status: json['status'] ?? 'Pending',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      question: json['interview_questions'] != null
          ? InterviewQuestion.fromJson(json['interview_questions'])
          : null,
      facultyFeedback: json['faculty_feedback'],
      facultyScore: json['faculty_score'],
      answerStartOffset: json['answer_start_offset'],
      answerEndOffset: json['answer_end_offset'],
      studentName: json['profiles'] != null
          ? json['profiles']['full_name']
          : null,
      mockAttemptId: json['mock_attempt_id'],
      mockTitle:
          json['mock_attempts'] != null &&
              json['mock_attempts']['mock_definitions'] != null
          ? json['mock_attempts']['mock_definitions']['title']
          : null,
      mockTotalScore:
          json['mock_attempts'] != null &&
              json['mock_attempts']['total_score'] != null
          ? (json['mock_attempts']['total_score'] as num).toInt()
          : null,
    );
  }
}
