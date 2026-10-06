import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/logger_service.dart';
import '../domain/interview_models.dart';

class InterviewRepository {
  final SupabaseClient _supabase;
  InterviewRepository(this._supabase);

  Future<List<InterviewCategory>> getCategories() async {
    final data = await _supabase
        .from('interview_categories')
        .select()
        .order('name');
    final List<dynamic> list = data;
    return list.map((e) => InterviewCategory.fromJson(e)).toList();
  }

  Future<List<InterviewQuestion>> getQuestions(String categoryId) async {
    final data = await _supabase
        .from('interview_questions')
        .select()
        .eq('category_id', categoryId)
        .order('created_at');
    final List<dynamic> list = data;
    return list.map((e) => InterviewQuestion.fromJson(e)).toList();
  }

  Future<List<LearningContent>> getLearningContent(String categoryId) async {
    final data = await _supabase
        .from('interview_learning_content')
        .select()
        .eq('category_id', categoryId)
        .order('created_at');
    final List<dynamic> list = data;
    return list.map((e) => LearningContent.fromJson(e)).toList();
  }

  Future<void> addLearningContent({
    required String categoryId,
    required String title,
    required String type,
    required String url,
  }) async {
    await _supabase.from('interview_learning_content').insert({
      'category_id': categoryId,
      'title': title,
      'type': type,
      'content_url': url,
    });
  }

  Future<void> deleteLearningContent(String id) async {
    await _supabase.from('interview_learning_content').delete().eq('id', id);
  }

  Future<void> updateLearningContent({
    required String id,
    String? title,
    String? description,
    String? url,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (url != null) updates['content_url'] = url;

    if (updates.isNotEmpty) {
      await _supabase
          .from('interview_learning_content')
          .update(updates)
          .eq('id', id);
    }
  }

  Future<String> uploadVideo(XFile videoFile) async {
    final fileName = 'interview_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final path = '${_supabase.auth.currentUser!.id}/$fileName';
    final bytes = await videoFile.readAsBytes();

    await _supabase.storage
        .from('interview-videos')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    // Return signed URL or just the path? Backend needs path?
    // Storage upload returns the path usually or we know it.
    // Let's return the public URL if bucket is public, or signed URL.
    // Our bucket is private. Backend has Service Role so it can read by path.
    // Just return the path.
    return path;
  }

  Future<void> startMockAttempt({
    required String attemptId,
    required String mockId,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('mock_attempts').insert({
      'id': attemptId,
      'student_id': userId,
      'mock_id': mockId,
      'status': 'in_progress',
      'started_at': DateTime.now().toIso8601String(),
    });
  }

  // Direct Supabase Submission (No Backend Server needed)
  Future<InterviewAttempt> submitInterview({
    required String questionId,
    required String videoPath,
    required int duration,
    required String categoryName,
    String? transcript,
    String? mockAttemptId, // Optional Mock Link
  }) async {
    final userId = _supabase.auth.currentUser!.id;

    // 1. Fetch Question Details for Keywords
    final questionResponse = await _supabase
        .from('interview_questions')
        .select()
        .eq('id', questionId)
        .single();
    final question = InterviewQuestion.fromJson(questionResponse);

    // 2. Calculate Score Locally
    final scoreResult = _calculateScore(
      transcript: transcript,
      durationSeconds: duration,
      keywords: question.expectedKeywords,
    );

    final score = scoreResult['score'] as Map<String, dynamic>;
    final feedback = scoreResult['feedback'] as String;

    // 3. Insert into Supabase
    final response = await _supabase
        .from('student_interviews')
        .insert({
          'student_id': userId,
          'question_id': questionId,
          'video_url': videoPath,
          'duration_seconds': duration,
          'score_json': score,
          'ai_feedback': feedback,
          'status': 'Evaluated',
          'mock_attempt_id': mockAttemptId, // Link to Mock Attempt
        })
        .select()
        .single();

    return InterviewAttempt.fromJson(response);
  }

  Future<void> submitCodingInterview({
    required String questionId,
    required String codeAnswer,
    required String categoryName,
  }) async {
    final userId = _supabase.auth.currentUser!.id;

    // Simple auto-score for code (length/keywords check could be added here)
    // For now, defaulting to "Pending Review" status.

    await _supabase.from('student_interviews').insert({
      'student_id': userId,
      'question_id': questionId,
      'code_answer': codeAnswer,
      'duration_seconds': 0, // N/A for now or could track
      'score_json': {'total': 0, 'status': 'Pending'},
      'ai_feedback': 'Code submitted. Pending faculty review.',
      'status': 'Pending',
    });
  }

  Map<String, dynamic> _calculateScore({
    String? transcript,
    required int durationSeconds,
    List<String>? keywords,
  }) {
    Map<String, dynamic> score = {
      'structure': 0,
      'content': 0,
      'confidence': 0,
      'total': 0,
    };

    // 1. Confidence (Duration based)
    if (durationSeconds < 30) {
      score['confidence'] = 4;
    } else if (durationSeconds >= 30 && durationSeconds < 60) {
      score['confidence'] = 7;
    } else if (durationSeconds >= 60 && durationSeconds <= 180) {
      score['confidence'] = 9;
    } else {
      score['confidence'] = 8;
    }

    // 2. Content (Keyword Matching with Word Boundaries)
    if (keywords != null &&
        keywords.isNotEmpty &&
        transcript != null &&
        transcript.trim().isNotEmpty) {
      final normalizedTranscript = transcript.toLowerCase();
      int matchedCount = 0;

      for (var keyword in keywords) {
        final normalizedKeyword = keyword.trim().toLowerCase();
        if (normalizedKeyword.isEmpty) continue;

        // Use word boundaries \b to ensure we match the whole word, not substrings
        final regex = RegExp('\\b$normalizedKeyword\\b', caseSensitive: false);
        if (regex.hasMatch(normalizedTranscript)) {
          matchedCount++;
        }
      }

      final percentage = matchedCount / keywords.length;

      // Refined Content Score Thresholds
      if (percentage >= 0.8) {
        score['content'] = 10;
      } else if (percentage >= 0.6) {
        score['content'] = 8;
      } else if (percentage >= 0.4) {
        score['content'] = 6;
      } else if (percentage >= 0.2) {
        score['content'] = 4;
      } else {
        score['content'] = 2;
      }
    } else {
      // Default fallback if no transcript/keywords
      score['content'] = 5;
    }

    // 3. Structure (Sentence count proxy)
    if (transcript != null && transcript.split(RegExp(r'[.!?]')).length > 3) {
      score['structure'] = 8;
    } else {
      score['structure'] = 5;
    }

    // Total Calculation (Weighted)
    // Content: 40%, Confidence: 30%, Structure: 30%
    score['total'] =
        ((score['content'] * 4 +
                    score['confidence'] * 3 +
                    score['structure'] * 3) /
                10)
            .round();

    // Feedback Generation
    List<String> feedbacks = [];
    if (score['total'] >= 9) {
      feedbacks.add(
        "Outstanding response! You covered all key points with great structure.",
      );
    } else if (score['total'] >= 7) {
      feedbacks.add(
        "Solid answer. You demonstrated good knowledge of the topic.",
      );
    } else if (score['total'] >= 5) {
      feedbacks.add(
        "Good effort, but try to be more comprehensive and structured.",
      );
    } else {
      feedbacks.add(
        "Needs improvement. Focus on including more relevant technical terms and practicing your delivery.",
      );
    }

    if (durationSeconds < 30)
      feedbacks.add("Consider elongating your answer for more depth.");
    if (durationSeconds > 180)
      feedbacks.add("Try to keep your answer concise and within 3 minutes.");

    return {'score': score, 'feedback': feedbacks.join(' ')};
  }

  // ==========================================
  // COLLEGE / FACULTY METHODS
  // ==========================================

  /// Fetch all interviews for the college dashboard
  Future<List<InterviewAttempt>> getAllInterviews() async {
    final data = await _supabase
        .from('student_interviews')
        .select(
          '*, interview_questions(*), profiles(full_name), mock_attempts(total_score, mock_definitions(title))',
        )
        .order('created_at', ascending: false);

    final List<dynamic> list = data;
    if (list.isNotEmpty) {
      LoggerService.debug("First Interview Raw Data: ${list.first}");
      if (list.first['mock_attempts'] != null) {
        LoggerService.debug("Attached Mock Data: ${list.first['mock_attempts']}");
      }
    }
    return list.map((e) => InterviewAttempt.fromJson(e)).toList();
  }

  /// Update faculty feedback and score, and auto-update Mock Total Score
  Future<void> updateFacultyReview({
    required String attemptId,
    required int score,
    required String feedback,
    String? mockAttemptId,
  }) async {
    // 1. Update the individual question attempt
    await _supabase
        .from('student_interviews')
        .update({
          'faculty_score': score,
          'faculty_feedback': feedback,
          'status': 'Reviewed',
        })
        .eq('id', attemptId);

    // 2. If this is part of a Mock, recalculate Total Score
    if (mockAttemptId != null) {
      // Fetch all attempts for this mock
      final attemptsData = await _supabase
          .from('student_interviews')
          .select('faculty_score')
          .eq('mock_attempt_id', mockAttemptId);

      final attempts = attemptsData as List<dynamic>;
      int totalScore = 0;
      int gradedCount = 0;

      for (var a in attempts) {
        if (a['faculty_score'] != null) {
          totalScore += (a['faculty_score'] as int);
          gradedCount++;
        }
      }

      // Update the parent Mock Attempt with the new Total
      await _supabase
          .from('mock_attempts')
          .update({
            'total_score': totalScore,
            'status':
                'graded', // Or keep 'submitted' until all are done? usage preference.
            // Let's set to 'graded' if at least one is graded, or maybe just update score.
            'graded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', mockAttemptId);
    }
  }

  // ==========================================
  // STUDENT METHODS
  // ==========================================

  Future<List<InterviewAttempt>> getHistory() async {
    final userId = _supabase.auth.currentUser!.id;
    final data = await _supabase
        .from('student_interviews')
        .select(
          '*, interview_questions(*), mock_attempts(total_score, mock_definitions(title))',
        )
        .eq('student_id', userId)
        .order('created_at', ascending: false);

    final List<dynamic> list = data;
    return list.map((e) => InterviewAttempt.fromJson(e)).toList();
  }
}
