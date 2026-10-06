import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/interview_models.dart';
import 'interview_providers.dart';
import 'college/college_interview_dashboard.dart';
import 'student_dashboard_analytics.dart';
import 'student/student_mocks_screen.dart';

import 'question_bank_screen.dart';
import 'learning_hub_screen.dart';
import 'widgets/shared_widgets.dart';

class InterviewLandingScreen extends ConsumerWidget {
  const InterviewLandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: GradientAppBar(title: 'Interview Prep', showBackButton: true),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(context, isSmallScreen),
            SizedBox(height: isSmallScreen ? 20 : 28),
            _buildStatsOverview(ref, isSmallScreen),
            SizedBox(height: isSmallScreen ? 20 : 28),
            Text(
              'Quick Start',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 18 : 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            _buildQuickAccessGrid(context, isSmallScreen),
            SizedBox(height: isSmallScreen ? 20 : 28),
            Text(
              'Recent Activity',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 18 : 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            _buildRecentActivity(ref, isSmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6EC9F5), Color(0xFF4A90E2)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6EC9F5).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isSmallScreen
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroText(isSmallScreen),
                const SizedBox(height: 20),
                _buildHeroIcon(),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildHeroText(isSmallScreen)),
                const SizedBox(width: 24),
                _buildHeroIcon(),
              ],
            ),
    );
  }

  Widget _buildHeroText(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Practice makes Perfect',
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 20 : 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Master your interview skills with video practice and instant feedback.',
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 13 : 15,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroIcon() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.video_camera_front,
        size: 48,
        color: Colors.white,
      ),
    );
  }

  Widget _buildStatsOverview(WidgetRef ref, bool isSmallScreen) {
    final historyAsync = ref.watch(interviewHistoryProvider);

    return historyAsync.when(
      data: (attempts) {
        final mockAttempts = attempts
            .where((a) => a.mockAttemptId != null)
            .length;
        final practiceAttempts = attempts
            .where((a) => a.mockAttemptId == null)
            .length;

        final gradedMocks = attempts
            .where((a) => a.mockAttemptId != null && a.mockTotalScore != null)
            .toList();

        final avgScore = gradedMocks.isNotEmpty
            ? gradedMocks
                      .map((a) => a.mockTotalScore!)
                      .reduce((a, b) => a + b) /
                  gradedMocks.length
            : 0.0;

        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth < 600 ? 2 : 4;

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: isSmallScreen ? 12 : 16,
              crossAxisSpacing: isSmallScreen ? 12 : 16,
              childAspectRatio: isSmallScreen ? 1.1 : 1.3,
              children: [
                StatCard(
                  title: 'Mock Exams',
                  value: mockAttempts.toString(),
                  icon: Icons.assignment,
                  color: const Color(0xFF8B5CF6),
                ),
                StatCard(
                  title: 'Practice Sessions',
                  value: practiceAttempts.toString(),
                  icon: Icons.psychology,
                  color: const Color(0xFFF97316),
                ),
                StatCard(
                  title: 'Avg Score',
                  value: avgScore > 0
                      ? '${avgScore.toStringAsFixed(1)}%'
                      : 'N/A',
                  icon: Icons.trending_up,
                  color: const Color(0xFF10B981),
                ),
                StatCard(
                  title: 'Total Attempts',
                  value: attempts.length.toString(),
                  icon: Icons.bar_chart,
                  color: const Color(0xFF4A90E2),
                ),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const EmptyState(
        title: 'Unable to load stats',
        message: 'Please try again later',
        icon: Icons.error_outline,
      ),
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context, bool isSmallScreen) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 600 ? 1 : 2;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: isSmallScreen ? 12 : 16,
          crossAxisSpacing: isSmallScreen ? 12 : 16,
          childAspectRatio: isSmallScreen ? 3 : 3.5,
          children: [
            ActionCard(
              title: 'Mock Interviews',
              subtitle: 'Take full mock tests',
              icon: Icons.video_camera_front,
              color: const Color(0xFF8B5CF6),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentMocksScreen()),
                );
              },
            ),
            ActionCard(
              title: 'Practice Arena',
              subtitle: 'AI-powered practice sessions',
              icon: Icons.psychology_rounded,
              color: const Color(0xFFF97316),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuestionBankScreen()),
                );
              },
            ),
            ActionCard(
              title: 'Learning Hub',
              subtitle: 'Master interview concepts',
              icon: Icons.menu_book_rounded,
              color: const Color(0xFF3B82F6),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LearningHubScreen()),
                );
              },
            ),
            ActionCard(
              title: 'My Analytics',
              subtitle: 'View your progress',
              icon: Icons.analytics,
              color: const Color(0xFF10B981),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StudentDashboardAnalytics(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentActivity(WidgetRef ref, bool isSmallScreen) {
    final historyAsync = ref.watch(interviewHistoryProvider);

    return historyAsync.when(
      data: (attempts) {
        if (attempts.isEmpty) {
          return const EmptyState(
            title: 'No Activity Yet',
            message: 'Start practicing to see your recent activity here',
            icon: Icons.access_time,
          );
        }

        final recent = attempts.take(5).toList();

        return Column(
          children: recent.map((attempt) {
            final isMock = attempt.mockAttemptId != null;
            final color = isMock
                ? const Color(0xFF8B5CF6)
                : const Color(0xFFF97316);
            final title = isMock
                ? attempt.mockTitle ?? 'Mock Exam'
                : attempt.question?.questionText ?? 'Practice Question';
            final score = isMock
                ? (attempt.mockTotalScore != null
                      ? '${attempt.mockTotalScore}/100'
                      : 'Pending')
                : '${attempt.scoreJson['total'] ?? 0}/10';

            return Card(
              margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 8 : 12,
                ),
                leading: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isMock ? Icons.assignment : Icons.psychology,
                    color: color,
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),
                title: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${attempt.createdAt.toString().split(' ')[0]} • ${isMock ? 'Mock Exam' : 'Practice'}',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: Colors.black54,
                  ),
                ),
                trailing: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 12,
                    vertical: isSmallScreen ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    score,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 12 : 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const EmptyState(
        title: 'Unable to load activity',
        message: 'Please try again later',
        icon: Icons.error_outline,
      ),
    );
  }
}
