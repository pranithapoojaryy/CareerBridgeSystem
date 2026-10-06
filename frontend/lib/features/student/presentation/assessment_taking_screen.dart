import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/learning_repository.dart';
import '../domain/assessment.dart';

class AssessmentTakingScreen extends ConsumerStatefulWidget {
  final String assessmentId;
  final String courseId;

  const AssessmentTakingScreen({
    super.key,
    required this.assessmentId,
    required this.courseId,
  });

  @override
  ConsumerState<AssessmentTakingScreen> createState() =>
      _AssessmentTakingScreenState();
}

class _AssessmentTakingScreenState
    extends ConsumerState<AssessmentTakingScreen> {
  bool _isLoading = true;
  Assessment? _assessment;
  AssessmentSubmission? _existingSubmission;
  final Map<String, dynamic> _answers = {};
  int _currentQuestionIndex = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final repo = ref.read(learningRepositoryProvider);

      // Load assessment
      final assessment = await repo.getAssessmentById(widget.assessmentId);

      // Check for existing attempts
      final user = Supabase.instance.client.auth.currentUser;
      AssessmentSubmission? submission;

      if (user != null) {
        submission = await repo.getLatestSubmission(
          user.id,
          widget.assessmentId,
        );
      }

      if (mounted) {
        setState(() {
          _assessment = assessment;
          _existingSubmission = submission;
          _isLoading = false;
        });

        if (submission != null && (submission.isPassed ?? false)) {
          // Already passed
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: Text(
                  'Assessment Completed',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
                content: const Text(
                  'You have already successfully completed this assessment.',
                ),
                actions: [
                  FilledButton(
                    onPressed: () =>
                        Navigator.pop(context, true), // Return true as passed
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading assessment: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _submitAssessment() async {
    if (_assessment == null) return;

    setState(() => _isSubmitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Create submission
      final submission = AssessmentSubmission(
        id: const Uuid().v4(), // Temporary ID, DB handles actual if uuid
        studentId: user.id,
        assessmentId: widget.assessmentId,
        submittedAt: DateTime.now(),
        attemptNumber: (_existingSubmission?.attemptNumber ?? 0) + 1,
        answers: _answers,
      );

      // Submit to DB
      final submissionId = await ref
          .read(learningRepositoryProvider)
          .submitAssessment(submission);

      bool isPassed = false;

      // Calculate score if auto-evaluated
      if (_assessment!.isAutoEvaluated) {
        final result = AssessmentResult.calculate(_assessment!, submission);
        isPassed = result.passed;

        // Update submission with score
        await ref
            .read(learningRepositoryProvider)
            .evaluateSubmission(
              submissionId, // Use the ID returned from the database
              result.scorePercentage,
              result.passed,
              'Auto-evaluated',
            );

        // Trigger certificate generation if passed and is likely final assessment
        // Heuristic: Check if title contains "Final" (case insensitive)
        if (isPassed && _assessment!.title.toLowerCase().contains('final')) {
          await ref
              .read(learningRepositoryProvider)
              .generateCertificate(widget.courseId);
        }
      }

      // Mark module as complete if passed
      // We don't have direct access to lectureId here, but we can update module progress if needed.
      // For now, let's just go back.

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(
              'Assessment Submitted',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            content: Text(
              isPassed
                  ? 'Congratulations! You passed the assessment.'
                  : 'Assessment submitted successfully.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context, isPassed); // Return passed status
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_assessment == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Assessment not found')),
      );
    }

    // Check attempts
    if (_existingSubmission != null &&
        _existingSubmission!.attemptNumber >= _assessment!.attemptsAllowed) {
      return _buildResultScreen(_existingSubmission!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _assessment!.title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _assessment!.questions.length,
            backgroundColor: Colors.grey[100],
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.primaryColor,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1} of ${_assessment!.questions.length}',
                    style: GoogleFonts.outfit(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildQuestion(_assessment!.questions[_currentQuestionIndex]),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentQuestionIndex > 0)
                  OutlinedButton(
                    onPressed: () {
                      setState(() => _currentQuestionIndex--);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('Previous'),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          if (_currentQuestionIndex <
                              _assessment!.questions.length - 1) {
                            setState(() => _currentQuestionIndex++);
                          } else {
                            _submitAssessment();
                          }
                        },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _currentQuestionIndex <
                                  _assessment!.questions.length - 1
                              ? 'Next'
                              : 'Submit',
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen(AssessmentSubmission submission) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assessment Result')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                submission.isPassed == true ? Icons.check_circle : Icons.cancel,
                color: submission.isPassed == true ? Colors.green : Colors.red,
                size: 80,
              ),
              const SizedBox(height: 16),
              Text(
                submission.isPassed == true ? 'Passed!' : 'Failed',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (submission.score != null)
                Text(
                  'Score: ${submission.score?.toStringAsFixed(1)}%',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    color: Colors.grey.shade700,
                  ),
                ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Course'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion(AssessmentQuestion question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.questionText,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        if (question.type == QuestionType.multipleChoice)
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = _answers[question.id] == index;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _answers[question.id] = index;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                        ? AppTheme.primaryColor.withValues(alpha: 0.05)
                        : Colors.white,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected ? AppTheme.primaryColor : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList()
        else if (question.type == QuestionType.trueFalse)
          // Similar to MCQ but with True/False hardcoded
          ...['True', 'False'].map((val) {
            final isSelected =
                _answers[question.id].toString().toLowerCase() ==
                val.toLowerCase();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _answers[question.id] = val;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                        ? AppTheme.primaryColor.withValues(alpha: 0.05)
                        : Colors.white,
                  ),
                  child: Text(val),
                ),
              ),
            );
          }).toList()
        else
          TextField(
            onChanged: (val) {
              _answers[question.id] = val;
            },
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Enter your answer...',
              border: OutlineInputBorder(),
            ),
          ),
      ],
    );
  }
}
