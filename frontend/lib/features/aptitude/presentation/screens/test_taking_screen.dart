import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/test_attempt.dart';
import '../../domain/aptitude_question.dart';
import '../controllers/aptitude_controller.dart';
import 'test_results_screen.dart';

class TestTakingScreen extends ConsumerStatefulWidget {
  final TestAttempt attempt;
  final Map<String, dynamic> settings;

  const TestTakingScreen({
    super.key,
    required this.attempt,
    required this.settings,
  });

  @override
  ConsumerState<TestTakingScreen> createState() => _TestTakingScreenState();
}

class _TestTakingScreenState extends ConsumerState<TestTakingScreen>
    with WidgetsBindingObserver {
  late PageController _pageController;
  late Timer _timer;
  int _timeRemainingSeconds = 0;
  int _currentQuestionIndex = 0;

  // Tracking
  final Map<String, int> _answers = {};
  final Set<String> _markedForReview = {};
  final Map<String, int> _timeSpentPerQuestion = {};
  DateTime _questionStartTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController();

    // Initialize timer
    if (widget.attempt.durationSeconds != null) {
      _timeRemainingSeconds = widget.attempt.durationSeconds!;
      _startTimer();
    }

    // Initialize existing answers if resuming
    for (var entry in widget.attempt.answers.entries) {
      _answers[entry.key] = entry.value;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemainingSeconds <= 0) {
        _timer.cancel();
        _submitTest(timedOut: true);
      } else {
        setState(() {
          _timeRemainingSeconds--;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle backgrounding/security if needed
  }

  void _recordTimeSpent() {
    final questionId = widget.attempt.questions[_currentQuestionIndex].id;
    final elapsed = DateTime.now().difference(_questionStartTime).inSeconds;
    _timeSpentPerQuestion[questionId] =
        (_timeSpentPerQuestion[questionId] ?? 0) + elapsed;
    _questionStartTime = DateTime.now();
  }

  void _onPageChanged(int index) {
    _recordTimeSpent();
    setState(() {
      _currentQuestionIndex = index;
    });
  }

  void _selectAnswer(String questionId, int optionIndex) {
    setState(() {
      _answers[questionId] = optionIndex;
    });
    // Auto-save to backend
    ref
        .read(aptitudeRepositoryProvider)
        .saveAnswer(
          attemptId: widget.attempt.id,
          questionId: questionId,
          selectedOption: optionIndex,
        );
  }

  void _toggleReview() {
    final questionId = widget.attempt.questions[_currentQuestionIndex].id;
    setState(() {
      if (_markedForReview.contains(questionId)) {
        _markedForReview.remove(questionId);
      } else {
        _markedForReview.add(questionId);
      }
    });
  }

  Future<void> _submitTest({bool timedOut = false}) async {
    _recordTimeSpent();
    _timer.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await ref
          .read(aptitudeRepositoryProvider)
          .submitTest(
            attemptId: widget.attempt.id,
            answers: _answers,
            timePerQuestion: _timeSpentPerQuestion,
          );

      if (mounted) {
        Navigator.pop(context); // Pop loader
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TestResultsScreen(
              resultData: result,
              totalQuestions: widget.attempt.questions.length,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Pop loader
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit test: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.attempt.questions;
    final currentQuestion = questions[_currentQuestionIndex];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Quit Arena?'),
            content: const Text(
              'Your progress will be saved, but you will lose the current momentum.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Stay & Fight'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Quit Arena'),
              ),
            ],
          ),
        );
        if (shouldExit == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey[50]!,
                AppTheme.primaryColor.withValues(alpha: 0.05),
                Colors.purple.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Top Bar: Timer & Progress (Glassmorphism inspired)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Timer
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _timeRemainingSeconds < 60
                              ? Colors.red.withValues(alpha: 0.1)
                              : Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 20,
                              color: _timeRemainingSeconds < 60
                                  ? Colors.red
                                  : AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTime(_timeRemainingSeconds),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _timeRemainingSeconds < 60
                                    ? Colors.red
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Progress
                      Column(
                        children: [
                          Text(
                            'Question',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            '${_currentQuestionIndex + 1}/${questions.length}',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColor,
                            ),
                          ),
                        ],
                      ),

                      // Submit
                      TextButton(
                        onPressed: _submitTest,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.green.withValues(alpha: 0.1),
                          foregroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'FINISH',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.check_circle_outline, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (_currentQuestionIndex + 1) / questions.length,
                      backgroundColor: Colors.white,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ),

                // Question Area
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: _onPageChanged,
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      return _buildQuestionPage(questions[index]);
                    },
                  ),
                ),

                // Bottom Navigation
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 30,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Previous
                      if (_currentQuestionIndex > 0)
                        IconButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: 400.ms,
                              curve: Curves.easeOutCubic,
                            );
                          },
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            padding: const EdgeInsets.all(16),
                          ),
                        )
                      else
                        const SizedBox(width: 48),

                      const SizedBox(width: 16),

                      // Mark for Review
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _toggleReview,
                          icon: Icon(
                            _markedForReview.contains(currentQuestion.id)
                                ? Icons.flag_rounded
                                : Icons.flag_outlined,
                            size: 20,
                          ),
                          label: Text(
                            _markedForReview.contains(currentQuestion.id)
                                ? 'Flagged'
                                : 'Review Later',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                _markedForReview.contains(currentQuestion.id)
                                ? Colors.orange
                                : Colors.grey[600],
                            side: BorderSide(
                              color:
                                  _markedForReview.contains(currentQuestion.id)
                                  ? Colors.orange
                                  : Colors.grey[300]!,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Next
                      if (_currentQuestionIndex < questions.length - 1)
                        ElevatedButton.icon(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: 400.ms,
                              curve: Curves.easeOutCubic,
                            );
                          },
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text('NEXT'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: _submitTest,
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('SUBMIT'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionPage(AptitudeQuestion question) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Text(
              question.questionText,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
                height: 1.5,
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

          const SizedBox(height: 40),

          Text(
            'SELECT THE CORRECT OPTION',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
              letterSpacing: 1.2,
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 16),

          ...List.generate(question.options.length, (index) {
            final option = question.options[index];
            final isSelected = _answers[question.id] == index;

            return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () => _selectAnswer(question.id, index),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: 250.ms,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor.withValues(alpha: 0.12)
                            : Colors.white,
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.grey[200]!,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: 250.ms,
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.grey[50],
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + index),
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              option,
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.textColor,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.primaryColor,
                              size: 24,
                            ).animate().scale(),
                        ],
                      ),
                    ),
                  ),
                )
                .animate()
                .fadeIn(delay: (300 + (index * 100)).ms)
                .slideX(begin: 0.1);
          }),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
