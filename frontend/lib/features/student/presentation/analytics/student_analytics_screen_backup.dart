import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/student_analytics_repository.dart';
import 'widgets/radar_chart.dart';

// Provider to fetch all analytics data
final studentAnalyticsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      final repo = ref.watch(studentAnalyticsRepositoryProvider);
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId == null) throw Exception('User not logged in');

      final skills = await repo.getSkillScores(userId);
      final courses = await repo.getCourseProgress(userId);
      final aptitude = await repo.getAptitudeAttempts(userId);
      final interviews = await repo.getMockInterviewAttempts(userId);

      // Fetch Stats for Skill Score
      final stats = await Supabase.instance.client
          .from('student_stats')
          .select('skill_score')
          .eq('student_id', userId)
          .maybeSingle();

      return {
        'skills': skills,
        'courses': courses,
        'aptitude': aptitude,
        'interviews': interviews,
        'stats': stats,
      };
    });

class StudentAnalyticsScreen extends ConsumerStatefulWidget {
  const StudentAnalyticsScreen({super.key});

  @override
  ConsumerState<StudentAnalyticsScreen> createState() =>
      _StudentAnalyticsScreenState();
}

class _StudentAnalyticsScreenState extends ConsumerState<StudentAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- PDF Generation ---
  Future<void> _generatePdf(Map<String, dynamic> data) async {
    try {
      final pdf = pw.Document();
      final skills = data['skills'] as List<Map<String, dynamic>>;
      final courses = data['courses'] as List<Map<String, dynamic>>;
      final aptitude = data['aptitude'] as List<Map<String, dynamic>>;

      // Calculate averages
      double avgAptitude = 0;
      if (aptitude.isNotEmpty) {
        avgAptitude =
            aptitude
                .map((e) => (e['percentage'] as num?)?.toDouble() ?? 0.0)
                .reduce((a, b) => a + b) /
            aptitude.length;
      }

      // Load fonts
      final font = await PdfGoogleFonts.outfitRegular();
      final fontBold = await PdfGoogleFonts.outfitBold();

      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            theme: pw.ThemeData.withFont(base: font, bold: fontBold),
          ),
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Student Performance Report',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.Text(
                      DateFormat('MMM d, yyyy').format(DateTime.now()),
                      style: const pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Summary Section
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildPdfStat('Skills Assessed', '${skills.length}'),
                    _buildPdfStat('Courses Enrolled', '${courses.length}'),
                    _buildPdfStat(
                      'Avg Aptitude',
                      '${avgAptitude.toStringAsFixed(1)}%',
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Skills Section
              pw.Text(
                'Skill Breakdown',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                context: context,
                headers: ['Skill', 'Category', 'Score (0-10)'],
                data: skills
                    .map(
                      (s) => [
                        s['skill_name'] ?? 'Unknown',
                        s['skill_category'] ?? '-',
                        '${(s['current_score'] as num?)?.toStringAsFixed(1) ?? '0'}',
                      ],
                    )
                    .toList(),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue50,
                ),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
                border: null,
                cellAlignment: pw.Alignment.centerLeft,
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  ),
                ),
              ),
              pw.SizedBox(height: 30),

              // Courses Section
              pw.Text(
                'Course Progress',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                context: context,
                headers: ['Course', 'Progress', 'Status'],
                data: courses
                    .map(
                      (c) => [
                        c['course']?['title'] ?? 'Unknown Course',
                        '${(c['progress_percent'] as num?)?.toStringAsFixed(0) ?? '0'}%',
                        (c['is_completed'] == true ||
                                (c['progress_percent'] as num?)?.toDouble() ==
                                    100.0)
                            ? 'Completed'
                            : 'Ongoing',
                      ],
                    )
                    .toList(),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue50,
                ),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
                border: null,
                cellAlignment: pw.Alignment.centerLeft,
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  ),
                ),
              ),

              // Aptitude Section
              pw.SizedBox(height: 30),
              pw.Text(
                'Aptitude Test History',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                context: context,
                headers: ['Test Type', 'Date', 'Score'],
                data: aptitude.take(10).map((a) {
                  final dateStr = a['created_at'] != null
                      ? DateFormat(
                          'MMM d, yyyy',
                        ).format(DateTime.parse(a['created_at']))
                      : '-';
                  return [
                    a['test_type'] ?? 'General',
                    dateStr,
                    '${(a['percentage'] as num?)?.toStringAsFixed(1) ?? '0'}%',
                  ];
                }).toList(),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue50,
                ),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
                border: null,
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  ),
                ),
              ),
              pw.Footer(
                leading: pw.Text(
                  'Generated by CareerBridge',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey500,
                  ),
                ),
                trailing: pw.Text(
                  'Page 1',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey500,
                  ),
                ),
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name:
            'Analytics_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
    }
  }

  pw.Widget _buildPdfStat(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(studentAnalyticsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'My Analytics',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textColor),
        centerTitle: false,
        actions: [
          analyticsAsync.when(
            data: (data) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: FilledButton.icon(
                onPressed: () => _generatePdf(data),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Export PDF'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.primaryColor,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: "Overview"),
                Tab(text: "Courses"),
                Tab(text: "Aptitude"),
                Tab(text: "Interview"),
              ],
            ),
          ),
        ),
      ),
      body: analyticsAsync.when(
        data: (data) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(data),
              _buildCoursesTab(data['courses'] ?? []),
              _buildAptitudeTab(data['aptitude'] ?? []),
              _buildInterviewTab(data['interviews'] ?? []),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Could not load analytics',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$err',
                style: GoogleFonts.outfit(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => ref.refresh(studentAnalyticsProvider),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Tab 1: Overview ---
  Widget _buildOverviewTab(Map<String, dynamic> data) {
    final skills = data['skills'] as List<Map<String, dynamic>>;
    final courses = data['courses'] as List<Map<String, dynamic>>;
    final aptitude = data['aptitude'] as List<Map<String, dynamic>>;
    final interviews = data['interviews'] as List<Map<String, dynamic>>;
    final stats = data['stats'] as Map<String, dynamic>? ?? {};
    final overallSkillScore = stats['skill_score'] ?? 0;

    // Calculate course stats
    final coursesEnrolled = courses.length;
    final coursesCompleted = courses
        .where(
          (c) =>
              c['is_completed'] == true ||
              (c['progress_percent'] as num?)?.toDouble() == 100.0,
        )
        .length;

    // Calculate interview stats
    final interviewsTaken = interviews.length;
    final avgInterviewScore = interviews.isEmpty
        ? 0.0
        : interviews
                  .map((i) => (i['total_score'] as num?)?.toDouble() ?? 0.0)
                  .reduce((a, b) => a + b) /
              interviews.length;

    final Map<String, double> skillsMap = {};
    for (var s in skills) {
      if (s['skill_name'] != null && s['current_score'] != null) {
        double score = (s['current_score'] as num).toDouble();
        if (score > 10) score = score / 10;
        skillsMap[s['skill_name']] = score / 10.0;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primary Stat Cards Row
          Row(
            children: [
              Expanded(
                child: _buildGradientStatCard(
                  'Overall Score',
                  '$overallSkillScore%',
                  Icons.auto_graph_rounded,
                  [Colors.green, Colors.lightGreen],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGradientStatCard(
                  'Tests Taken',
                  '${aptitude.length}',
                  Icons.quiz_rounded,
                  [Colors.blue, Colors.lightBlueAccent],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Secondary Stats Row
          Row(
            children: [
              Expanded(
                child: _buildGradientStatCard(
                  'Courses',
                  '$coursesCompleted/$coursesEnrolled',
                  Icons.school_rounded,
                  [Colors.purple, Colors.purpleAccent],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGradientStatCard(
                  'Mock Interviews',
                  '$interviewsTaken',
                  Icons.video_call_rounded,
                  [Colors.orange, Colors.deepOrangeAccent],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Interview Performance (if available)
          if (interviews.isNotEmpty) ...[
            Text(
              'Interview Performance',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.orange.withValues(alpha: 0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.video_call_rounded,
                        color: Colors.orange,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Average Interview Score',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${avgInterviewScore.toStringAsFixed(1)}%',
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$interviewsTaken mock interviews completed',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          Text(
            'Skill Profile',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              height: 350,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Expanded(
                    child: skillsMap.isEmpty
                        ? Center(
                            child: Text(
                              "Complete assessments to see your skill profile",
                              style: GoogleFonts.outfit(color: Colors.grey),
                            ),
                          )
                        : StudentSkillsRadarChart(skillsData: skillsMap),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Tab 2: Courses ---
  Widget _buildCoursesTab(List<Map<String, dynamic>> courses) {
    if (courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "No courses enrolled yet",
              style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              "Start learning from the Learning Catalog!",
              style: GoogleFonts.outfit(color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: courses.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final course = courses[index];
        final title = course['course']?['title'] ?? 'Unknown Course';
        final progress =
            (course['progress_percent'] as num?)?.toDouble() ?? 0.0;
        final isCompleted =
            course['is_completed'] == true ||
            progress >= 100.0; // Graceful fallback
        final thumbnail = course['course']?['thumbnail_url'];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: thumbnail != null
                      ? Image.network(
                          thumbnail,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            width: 60,
                            height: 60,
                          ),
                        )
                      : Container(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          width: 60,
                          height: 60,
                          child: const Icon(
                            Icons.book,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                ),
                title: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress / 100,
                              backgroundColor: Colors.grey[100],
                              color: isCompleted
                                  ? Colors.green
                                  : AppTheme.primaryColor,
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${progress.toStringAsFixed(0)}%',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: isCompleted
                    ? Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.green,
                          size: 20,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Tab 3: Aptitude ---
  Widget _buildAptitudeTab(List<Map<String, dynamic>> attempts) {
    if (attempts.isEmpty)
      return const Center(child: Text("No aptitude tests taken."));

    final reversedAttempts = attempts.reversed
        .toList(); // For chart chronological order

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Chart Card
          Container(
            height: 280,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Performance Trend",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (v) =>
                            FlLine(color: Colors.grey[100], strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (v, m) => Text(
                              v.toInt().toString(),
                              style: GoogleFonts.outfit(
                                color: Colors.grey[400],
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minY: 0,
                      maxY: 100,
                      lineBarsData: [
                        LineChartBarData(
                          spots: reversedAttempts.asMap().entries.map((e) {
                            return FlSpot(
                              e.key.toDouble(),
                              (e.value['percentage'] as num?)?.toDouble() ??
                                  0.0,
                            );
                          }).toList(),
                          isCurved: true,
                          color: AppTheme.secondaryColor,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                                  radius: 4,
                                  color: Colors.white,
                                  strokeWidth: 2,
                                  strokeColor: AppTheme.secondaryColor,
                                ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: attempts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final attempt = attempts[index];
              final date = DateTime.parse(attempt['created_at']);
              final score = (attempt['percentage'] as num?)?.toDouble() ?? 0.0;
              Color scoreColor = score >= 80
                  ? Colors.green
                  : (score >= 50 ? Colors.orange : Colors.red);

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${score.toInt()}%',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: scoreColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            attempt['test_type'] ?? 'General Assessment',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            DateFormat('MMM d, yyyy • h:mm a').format(date),
                            style: GoogleFonts.outfit(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInterviewTab(List<Map<String, dynamic>> interviews) {
    if (interviews.isEmpty)
      return const Center(child: Text("No interview practice yet."));

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: interviews.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final interview = interviews[index];
        final score = (interview['total_score'] as num?)?.toDouble() ?? 0.0;
        final date =
            DateTime.tryParse(interview['created_at'] ?? '') ?? DateTime.now();

        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              'Mock Interview #${index + 1}',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              DateFormat('MMM d, yyyy').format(date),
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: score >= 70
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Score: $score',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: score >= 70 ? Colors.green : Colors.orange,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGradientStatCard(
    String title,
    String value,
    IconData icon,
    List<Color> colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
