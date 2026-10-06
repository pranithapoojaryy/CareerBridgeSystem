import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'interview_providers.dart';
import '../domain/interview_models.dart';

class StudentDashboardAnalytics extends ConsumerStatefulWidget {
  const StudentDashboardAnalytics({super.key});

  @override
  ConsumerState<StudentDashboardAnalytics> createState() =>
      _StudentDashboardAnalyticsState();
}

class _StudentDashboardAnalyticsState
    extends ConsumerState<StudentDashboardAnalytics>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(interviewRepositoryProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1024;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: FutureBuilder<List<InterviewAttempt>>(
        future: repo.getHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF3B82F6)),
              ),
            );
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

          return Column(
            children: [
              _buildHeader(isMobile),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAnalyticsView(
                      mocks,
                      isMock: true,
                      isDesktop: isDesktop,
                    ),
                    _buildAnalyticsView(
                      practice,
                      isMock: false,
                      isDesktop: isDesktop,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Interview Analytics',
                          style: GoogleFonts.poppins(
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Track your progress and performance',
                          style: GoogleFonts.poppins(
                            fontSize: isMobile ? 12 : 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF6B7280),
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelStyle: GoogleFonts.poppins(
                    fontSize: isMobile ? 13 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: GoogleFonts.poppins(
                    fontSize: isMobile ? 13 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: [
                    Tab(
                      height: isMobile ? 48 : 52,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.assignment_turned_in, size: 18),
                          const SizedBox(width: 8),
                          Text(isMobile ? "Mocks" : "Mock Exams"),
                        ],
                      ),
                    ),
                    Tab(
                      height: isMobile ? 48 : 52,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_circle_outline, size: 18),
                          const SizedBox(width: 8),
                          Text(isMobile ? "Practice" : "Practice Sessions"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsView(
    List<InterviewAttempt> attempts, {
    required bool isMock,
    required bool isDesktop,
  }) {
    if (attempts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isMock ? Icons.assignment_outlined : Icons.code_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              "No ${isMock ? 'Mock Exams' : 'Practice Sessions'} Yet",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    // Calculate analytics
    final analytics = _calculateAnalytics(attempts, isMock);

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side - Stats and History
          Expanded(
            flex: 6,
            child: _buildLeftPanel(attempts, analytics, isMock),
          ),
          // Right side - Charts
          Container(
            width: 380,
            margin: const EdgeInsets.all(20),
            child: _buildChartsPanel(analytics, isMock),
          ),
        ],
      );
    } else {
      return SingleChildScrollView(
        child: Column(
          children: [
            _buildLeftPanel(attempts, analytics, isMock),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildChartsPanel(analytics, isMock),
            ),
          ],
        ),
      );
    }
  }

  Map<String, dynamic> _calculateAnalytics(
    List<InterviewAttempt> attempts,
    bool isMock,
  ) {
    if (isMock) {
      final Map<String, List<InterviewAttempt>> grouped = {};
      for (var a in attempts) {
        final key = a.mockAttemptId ?? 'unknown';
        grouped.putIfAbsent(key, () => []).add(a);
      }

      double totalScore = 0;
      int gradedCount = 0;
      int pendingCount = 0;
      int completedCount = 0;

      grouped.forEach((mockId, groupAttempts) {
        int groupGraded = 0;
        double groupScore = 0;

        for (var a in groupAttempts) {
          if (a.facultyScore != null) {
            groupScore += a.facultyScore!;
            groupGraded++;
          }
        }

        if (groupGraded > 0) {
          totalScore += (groupScore / groupGraded);
          gradedCount++;
          completedCount++;
        } else {
          pendingCount++;
        }
      });

      return {
        'avg': gradedCount > 0 ? (totalScore / gradedCount) : 0.0,
        'total': grouped.length,
        'completed': completedCount,
        'pending': pendingCount,
        'grouped': grouped,
      };
    } else {
      double totalScore = 0;
      int gradedCount = 0;
      Map<String, int> categoryBreakdown = {};

      for (var a in attempts) {
        final score = (a.scoreJson['total'] is int ? a.scoreJson['total'] : 0);
        if (score > 0) {
          totalScore += score;
          gradedCount++;
        }

        // Get category from question if available, otherwise default
        final category =
            'General'; // Simplified - could be enhanced with category lookup
        categoryBreakdown[category] = (categoryBreakdown[category] ?? 0) + 1;
      }

      return {
        'avg': gradedCount > 0 ? (totalScore / gradedCount) : 0.0,
        'total': attempts.length,
        'categories': categoryBreakdown,
      };
    }
  }

  Widget _buildLeftPanel(
    List<InterviewAttempt> attempts,
    Map<String, dynamic> analytics,
    bool isMock,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards
          _buildStatsCards(analytics, isMock),
          const SizedBox(height: 32),
          // History
          Text(
            "${isMock ? 'Mock' : 'Practice'} History",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          if (isMock)
            _buildMockHistory(analytics['grouped'])
          else
            _buildPracticeHistory(attempts),
        ],
      ),
    );
  }

  Widget _buildStatsCards(Map<String, dynamic> analytics, bool isMock) {
    if (isMock) {
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _StatCard(
            title: "Average Score",
            value: analytics['avg'].toStringAsFixed(1),
            subtitle: "Out of 100",
            color: const Color(0xFF3B82F6),
            icon: Icons.trending_up,
            width: 200,
          ),
          _StatCard(
            title: "Total Mocks",
            value: "${analytics['total']}",
            subtitle: "Attempted",
            color: const Color(0xFFF97316),
            icon: Icons.assignment,
            width: 200,
          ),
          _StatCard(
            title: "Completed",
            value: "${analytics['completed']}",
            subtitle: "Evaluated",
            color: const Color(0xFF10B981),
            icon: Icons.check_circle,
            width: 200,
          ),
          _StatCard(
            title: "Pending",
            value: "${analytics['pending']}",
            subtitle: "Under Review",
            color: const Color(0xFFFB923C),
            icon: Icons.pending,
            width: 200,
          ),
        ],
      );
    } else {
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _StatCard(
            title: "AI Average",
            value: analytics['avg'].toStringAsFixed(1),
            subtitle: "Out of 100",
            color: const Color(0xFF3B82F6),
            icon: Icons.auto_awesome,
            width: 240,
          ),
          _StatCard(
            title: "Sessions",
            value: "${analytics['total']}",
            subtitle: "Practiced",
            color: const Color(0xFFF97316),
            icon: Icons.play_circle,
            width: 240,
          ),
        ],
      );
    }
  }

  Widget _buildMockHistory(Map<String, List<InterviewAttempt>> grouped) {
    final cards = <Widget>[];

    grouped.forEach((mockId, groupAttempts) {
      double groupScore = 0;
      int groupGraded = 0;

      for (var a in groupAttempts) {
        if (a.facultyScore != null) {
          groupScore += a.facultyScore!;
          groupGraded++;
        }
      }

      final avg = groupGraded > 0 ? (groupScore / groupGraded) : 0.0;
      final date = groupAttempts.isNotEmpty
          ? groupAttempts.first.createdAt
          : DateTime.now();
      final mockTitle = groupAttempts.first.mockTitle ?? "Mock Exam";

      cards.add(
        _buildMockCard(
          title: mockTitle,
          date: date,
          questionsCount: groupAttempts.length,
          score: groupGraded > 0 ? avg : null,
        ),
      );
    });

    return Column(children: cards);
  }

  Widget _buildPracticeHistory(List<InterviewAttempt> attempts) {
    return Column(
      children: attempts
          .map(
            (a) => _buildPracticeCard(
              question: a.question?.questionText ?? "Question",
              date: a.createdAt,
              score: a.scoreJson['total'] ?? 0,
              category: "General", // Simplified category
            ),
          )
          .toList(),
    );
  }

  Widget _buildMockCard({
    required String title,
    required DateTime date,
    required int questionsCount,
    required double? score,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.assignment, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${DateFormat('MMM d, yyyy').format(date)} • $questionsCount Questions",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: score != null
                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                  : const Color(0xFFF97316).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              score != null ? "${score.toStringAsFixed(1)}" : "Pending",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: score != null
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF97316),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeCard({
    required String question,
    required DateTime date,
    required int score,
    required String category,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF97316).withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF97316).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.code, color: Color(0xFFF97316), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        category,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: const Color(0xFF3B82F6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMM d').format(date),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            "$score",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsPanel(Map<String, dynamic> analytics, bool isMock) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Performance Overview",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 24),
          if (isMock)
            _buildMockCharts(analytics)
          else
            _buildPracticeCharts(analytics),
        ],
      ),
    );
  }

  Widget _buildMockCharts(Map<String, dynamic> analytics) {
    final completed = analytics['completed'] as int;
    final pending = analytics['pending'] as int;

    return Column(
      children: [
        // Status Pie Chart
        _PieChart(
          data: [
            PieChartData(
              'Completed',
              completed.toDouble(),
              const Color(0xFF10B981),
            ),
            PieChartData(
              'Pending',
              pending.toDouble(),
              const Color(0xFFF97316),
            ),
          ],
          title: 'Status Distribution',
        ),
        const SizedBox(height: 32),
        // Score Gauge
        _ScoreGauge(score: analytics['avg'], title: 'Average Score'),
      ],
    );
  }

  Widget _buildPracticeCharts(Map<String, dynamic> analytics) {
    final categories = analytics['categories'] as Map<String, int>;
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFFF97316),
      const Color(0xFF10B981),
      const Color(0xFFFB923C),
    ];

    final pieData = categories.entries.toList().asMap().entries.map((entry) {
      return PieChartData(
        entry.value.key,
        entry.value.value.toDouble(),
        colors[entry.key % colors.length],
      );
    }).toList();

    return Column(
      children: [
        _PieChart(data: pieData, title: 'Category Distribution'),
        const SizedBox(height: 32),
        _ScoreGauge(score: analytics['avg'], title: 'AI Average'),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;
  final double width;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
    this.width = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.1), Colors.white],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4B5563),
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

class PieChartData {
  final String label;
  final double value;
  final Color color;

  PieChartData(this.label, this.value, this.color);
}

class _PieChart extends StatelessWidget {
  final List<PieChartData> data;
  final String title;

  const _PieChart({required this.data, required this.title});

  @override
  Widget build(BuildContext context) {
    final total = data.fold<double>(0, (sum, item) => sum + item.value);

    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 200,
          height: 200,
          child: CustomPaint(painter: _PieChartPainter(data, total)),
        ),
        const SizedBox(height: 16),
        ...data.map(
          (item) => _buildLegendItem(
            item.label,
            item.value.toInt(),
            item.color,
            total,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, int value, Color color, double total) {
    final percentage = total > 0
        ? ((value / total) * 100).toStringAsFixed(0)
        : "0";
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF4B5563),
              ),
            ),
          ),
          Text(
            "$value ($percentage%)",
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<PieChartData> data;
  final double total;

  _PieChartPainter(this.data, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    double startAngle = -math.pi / 2;

    for (var item in data) {
      final sweepAngle = (item.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }

    // Draw white center circle
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.5, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScoreGauge extends StatelessWidget {
  final double score;
  final String title;

  const _ScoreGauge({required this.score, required this.title});

  @override
  Widget build(BuildContext context) {
    final percentage = score / 100;
    final color = score >= 80
        ? const Color(0xFF10B981)
        : score >= 60
        ? const Color(0xFFF97316)
        : const Color(0xFFEF4444);

    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: percentage,
                  strokeWidth: 12,
                  backgroundColor: color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    score.toStringAsFixed(1),
                    style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    'out of 100',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
