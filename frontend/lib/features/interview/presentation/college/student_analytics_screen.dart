import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/interview_models.dart';
import '../interview_providers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';

class StudentAnalyticsScreen extends ConsumerStatefulWidget {
  const StudentAnalyticsScreen({super.key});

  @override
  ConsumerState<StudentAnalyticsScreen> createState() =>
      _StudentAnalyticsScreenState();
}

class _StudentAnalyticsScreenState
    extends ConsumerState<StudentAnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: const Color(0xFF1A1F36),
            unselectedLabelColor: const Color(0xFF697386),
            indicatorColor: AppTheme.primaryColor,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            unselectedLabelStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: "Mock Submissions"),
              Tab(text: "Practice Logs"),
            ],
          ),
          const Divider(height: 1, color: Color(0xFFE3E8EE)),
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                final repo = ref.watch(interviewRepositoryProvider);

                return FutureBuilder<List<InterviewAttempt>>(
                  future: repo.getAllInterviews(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }

                    final allAttempts = snapshot.data ?? [];
                    final mocks = allAttempts
                        .where((a) => a.mockAttemptId != null)
                        .toList();
                    final practice = allAttempts
                        .where((a) => a.mockAttemptId == null)
                        .toList();

                    return TabBarView(
                      children: [
                        _buildMockDashboard(mocks, ref),
                        _buildPracticeList(practice),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockDashboard(List<InterviewAttempt> attempts, WidgetRef ref) {
    if (attempts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_turned_in_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              "No mock submissions yet.",
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // GROUP BY MOCK ID
    final Map<String, List<InterviewAttempt>> grouped = {};
    for (var a in attempts) {
      final key = a.mockAttemptId ?? 'unknown';
      grouped.putIfAbsent(key, () => []).add(a);
    }

    final List<Widget> cards = [];
    double totalMockAvg = 0;
    int gradedMocksCount = 0;

    grouped.forEach((mockId, groupAttempts) {
      if (groupAttempts.isEmpty) return;

      double groupTotalScore = 0;
      int groupGradedCount = 0;

      final studentName = groupAttempts.first.studentName ?? "Unknown Student";
      final date = groupAttempts.first.createdAt;

      for (var a in groupAttempts) {
        if (a.facultyScore != null) {
          groupTotalScore += a.facultyScore!;
          groupGradedCount++;
        }
      }

      final groupAvg = groupGradedCount > 0
          ? (groupTotalScore / groupGradedCount)
          : 0.0;

      if (groupAttempts.first.mockTotalScore != null) {
        totalMockAvg += groupAttempts.first.mockTotalScore!;
        gradedMocksCount++;
      } else if (groupGradedCount > 0) {
        totalMockAvg += groupAvg;
        gradedMocksCount++;
      }

      final isEvaluated = groupGradedCount > 0;

      cards.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                shape: BoxShape.circle,
              ),
              child: Text(
                studentName.isNotEmpty
                    ? studentName.substring(0, 1).toUpperCase()
                    : "S",
                style: GoogleFonts.outfit(
                  color: const Color(0xFF5A6ACF),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            title: Text(
              studentName,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: const Color(0xFF1A1F36),
              ),
            ),
            subtitle: Text(
              DateFormat('MMM d, yyyy • HH:mm').format(date),
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: const Color(0xFF697386),
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (groupAttempts.first.mockTotalScore != null ||
                            isEvaluated)
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    groupAttempts.first.mockTotalScore != null
                        ? "${groupAttempts.first.mockTotalScore}/100"
                        : (isEvaluated
                              ? "${(groupAvg * groupGradedCount).toStringAsFixed(0)}*"
                              : "Pending"),
                    style: GoogleFonts.outfit(
                      color:
                          (groupAttempts.first.mockTotalScore != null ||
                              isEvaluated)
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
            onTap: () {
              _showMockDetails(context, ref, studentName, groupAttempts);
            },
          ),
        ),
      );
    });

    final overallAvg = gradedMocksCount > 0
        ? (totalMockAvg / gradedMocksCount).toStringAsFixed(1)
        : "0.0";

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionHeader("Overview"),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: "Mock Sessions",
                value: "${grouped.length}",
                icon: Icons.assignment_rounded,
                colors: [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _MetricCard(
                title: "Average Grade",
                value: overallAvg,
                icon: Icons.auto_graph_rounded,
                colors: [const Color(0xFF5A6ACF), const Color(0xFF818EE1)],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSectionHeader("Submissions History"),
        const SizedBox(height: 12),
        ...cards,
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1A1F36),
      ),
    );
  }

  void _showMockDetails(
    BuildContext context,
    WidgetRef ref,
    String studentName,
    List<InterviewAttempt> attempts,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1F36),
                        ),
                      ),
                      Text(
                        "Detailed Mock Results",
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: const Color(0xFF697386),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE3E8EE)),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    itemCount: attempts.length,
                    itemBuilder: (ctx, index) {
                      final attempt = attempts[index];
                      final isGraded = attempt.facultyScore != null;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE3E8EE)),
                        ),
                        child: Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isGraded
                                    ? const Color(0xFFE8F5E9)
                                    : const Color(0xFFF5F7FA),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isGraded
                                    ? Icons.check_circle_rounded
                                    : Icons.pending_actions_rounded,
                                color: isGraded
                                    ? Colors.green
                                    : const Color(0xFF5A6ACF),
                                size: 24,
                              ),
                            ),
                            title: Text(
                              "Question ${index + 1}",
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: const Color(0xFF1A1F36),
                              ),
                            ),
                            subtitle: Text(
                              isGraded
                                  ? "Score: ${attempt.facultyScore}/10"
                                  : "Pending Evaluation",
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: isGraded
                                    ? Colors.green.shade700
                                    : const Color(0xFF697386),
                                fontWeight: isGraded
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  20,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Divider(height: 24),
                                    Text(
                                      "Question text",
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1A1F36),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      attempt.question?.questionText ??
                                          "No question data available",
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        color: const Color(0xFF697386),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "Student Feedback/Response",
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1A1F36),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "AI Analysis performed. Waiting for faculty review for final grade.",
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPracticeList(List<InterviewAttempt> attempts) {
    if (attempts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology_alt_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              "No practice attempts found.",
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: attempts.length,
      itemBuilder: (context, index) {
        final attempt = attempts[index];
        final score = attempt.scoreJson['total'] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0E6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology_rounded,
                color: Color(0xFF764BA2),
                size: 24,
              ),
            ),
            title: Text(
              attempt.studentName ?? "Student",
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              attempt.question?.questionText ?? "Practice Question",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: const Color(0xFF697386),
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0E6FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "$score/10",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF764BA2),
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    "AI Grade",
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF764BA2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> colors;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE3E8EE)),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1F36),
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: const Color(0xFF697386),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
