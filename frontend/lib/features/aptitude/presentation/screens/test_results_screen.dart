import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';

class TestResultsScreen extends StatelessWidget {
  final Map<String, dynamic> resultData;
  final int totalQuestions;

  const TestResultsScreen({
    super.key,
    required this.resultData,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final score = num.tryParse(resultData['score'].toString()) ?? 0;
    final percentage = num.tryParse(resultData['percentage'].toString()) ?? 0;
    final correctCount =
        int.tryParse(resultData['correct_answers'].toString()) ?? 0;
    final wrongCount =
        int.tryParse(resultData['incorrect_answers'].toString()) ?? 0;
    final unansweredCount =
        int.tryParse(resultData['unanswered'].toString()) ?? 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Arena Results',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[50]!,
              AppTheme.primaryColor.withValues(alpha: 0.05),
              Colors.purple.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 100, 24, 40),
          child: Column(
            children: [
              // Score Circle Area
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: 1200.ms,
                      curve: Curves.elasticOut,
                      tween: Tween(begin: 0, end: percentage / 100),
                      builder: (context, value, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 220,
                              height: 220,
                              child: CircularProgressIndicator(
                                value: value,
                                strokeWidth: 15,
                                backgroundColor: Colors.grey[100],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getScoreColor(percentage.toDouble()),
                                ),
                              ).animate().scale(duration: 600.ms),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${(value * 100).toInt()}%',
                                  style: GoogleFonts.outfit(
                                    fontSize: 64,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textColor,
                                  ),
                                ),
                                Text(
                                  'PROFICIENCY',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: Colors.grey[400],
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    Text(
                      _getFeedbackMessage(percentage.toDouble()),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ).animate().fadeIn(delay: 400.ms).scale(),
                    const SizedBox(height: 8),
                    Text(
                      'You scored $score points in this arena battle.',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ).animate().fadeIn(delay: 600.ms),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Correct',
                      correctCount.toString(),
                      Icons.check_circle_rounded,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Wrong',
                      wrongCount.toString(),
                      Icons.cancel_rounded,
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Skipped',
                      unansweredCount.toString(),
                      Icons.pause_circle_filled_rounded,
                      Colors.orange,
                    ),
                  ),
                ],
              ).animate().slideY(begin: 0.2, end: 0, delay: 800.ms),

              const SizedBox(height: 48),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.textColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'RETURN TO ARENA HUB',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.hub_rounded),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 1000.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: Colors.grey[500],
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.blue;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }

  String _getFeedbackMessage(double percentage) {
    if (percentage >= 90) return 'Godlike! 👑';
    if (percentage >= 80) return 'Legendary! 🔥';
    if (percentage >= 60) return 'Elite Warrior! 💪';
    if (percentage >= 40) return 'Keep Fighting! ⚔️';
    return 'Trial by Fire! 🕯️';
  }
}
