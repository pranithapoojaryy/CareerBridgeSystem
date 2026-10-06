import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/aptitude_module.dart';
import '../../domain/test_attempt.dart';
import 'test_taking_screen.dart';
import '../controllers/aptitude_controller.dart';
import 'module_detail_screen.dart';
import 'assignments_list_screen.dart';
import 'aptitude_sections.dart';
import '../../../student/presentation/assessment_taking_screen.dart';
import '../../domain/test_assignment.dart'; // Ensure this is imported for clean type usage

class AptitudeHomeScreen extends ConsumerWidget {
  const AptitudeHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modulesAsync = ref.watch(aptitudeModulesProvider);
    final statsAsync = ref.watch(aptitudeStatsProvider);
    final assignmentsAsync = ref.watch(myAssignmentsProvider);
    final pendingCourseAssessmentsAsync = ref.watch(
      pendingCourseAssessmentsProvider,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[50]!,
              Colors.blue.withValues(alpha: 0.05),
              Colors.purple.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section (Practice Arena Style)
              _buildHeader(context).animate().fadeIn().slideX(begin: -0.1),

              const SizedBox(height: 32),

              // Stats Row
              statsAsync.when(
                data: (stats) => Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Tests Taken',
                        stats['total_tests']?.toString() ?? '0',
                        Icons.assignment_turned_in_rounded,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Avg Score',
                        '${(stats['average_score'] as num? ?? 0).toStringAsFixed(1)}%',
                        Icons.analytics_rounded,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Highest Score',
                        '${(stats['highest_score'] as num? ?? 0).toStringAsFixed(1)}%',
                        Icons.emoji_events_rounded,
                        Colors.purple,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                loading: () => const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox(),
              ),

              const SizedBox(height: 40),

              // Async Assignments Content
              assignmentsAsync.when(
                data: (assignments) {
                  // Filter Assignments
                  final activeAssignments = assignments
                      .where((a) => !a.isExpired && a.completionRate < 1)
                      .toList();

                  final recruiterTests = activeAssignments
                      .where(
                        (a) => a.assignedByRole.toLowerCase().contains(
                          'recruiter',
                        ),
                      )
                      .toList();

                  final collegeTests = activeAssignments
                      .where(
                        (a) =>
                            a.assignedByRole.toLowerCase().contains('college'),
                      )
                      .toList();

                  // Merge System 2 Assessments
                  pendingCourseAssessmentsAsync.whenData((assessments) {
                    for (final assessment in assessments) {
                      // Create a synthetic TestAssignment for System 2 assessment
                      final syntheticAssignment = TestAssignment(
                        id: assessment['id'], // assessmentId
                        testId:
                            assessment['lecture_id'], // Use lectureId as testId marker
                        assignedToUser: 'me',
                        assignedToBatch:
                            assessment['course_id'], // Store courseId here for navigation
                        assignedToDepartment: null,
                        assignedBy: 'College Faculty',
                        assignedByRole: 'college_faculty',
                        organizationId: 'college', // Placeholder
                        assignmentType: 'course_assessment',
                        startDate: DateTime.now(),
                        deadline: null,
                        testTitle: assessment['title'],
                        testDescription:
                            'Course Assessment from ${assessment['course_title']}',
                        durationMinutes:
                            assessment['duration_minutes'] ??
                            30, // Default if null
                        totalQuestions: 0, // Unknown
                        isAttempted: false,
                        myScore: null,
                        myStatus: 'pending',
                      );
                      collegeTests.add(syntheticAssignment);
                    }
                  });

                  if (activeAssignments.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      alignment: Alignment.center,
                      child: Text(
                        'No active assignments found.\nCheck console logs for details.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(color: Colors.grey),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      // 1. Recruiter Section (Gold/Premium)
                      if (recruiterTests.isNotEmpty) ...[
                        SectionHeaderWidget(
                          title: 'Recruiter Challenges',
                          onViewAll: () => _navigateToViewAll(context),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 220, // Increased height for premium cards
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: recruiterTests.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 16),
                            itemBuilder: (context, index) {
                              return PremiumTestCard(
                                assignment: recruiterTests[index],
                                isRecruiter: true,
                                onStart: () => _startAssignmentTest(
                                  context,
                                  ref,
                                  recruiterTests[index].id,
                                  recruiterTests[index].testId,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],

                      // 2. College Section (Clean/Standard)
                      if (collegeTests.isNotEmpty) ...[
                        SectionHeaderWidget(
                          title: 'College Assessments',
                          onViewAll: () => _navigateToViewAll(context),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 220,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: collegeTests.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 16),
                            itemBuilder: (context, index) {
                              return PremiumTestCard(
                                assignment: collegeTests[index],
                                isRecruiter: false,
                                onStart: () {
                                  if (collegeTests[index].assignmentType ==
                                      'course_assessment') {
                                    // System 2 Navigation
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AssessmentTakingScreen(
                                          assessmentId: collegeTests[index].id,
                                          courseId:
                                              collegeTests[index]
                                                  .assignedToBatch ??
                                              '', // Retrieve courseId
                                        ),
                                      ),
                                    );
                                  } else {
                                    // System 1 Navigation
                                    _startAssignmentTest(
                                      context,
                                      ref,
                                      collegeTests[index].id,
                                      collegeTests[index].testId,
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ],
                  ).animate().fadeIn(delay: 300.ms);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.red.withValues(alpha: 0.1),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(height: 8),
                      Text(
                        'Error loading assignments: $err',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 3. Practice Modules (Existing)
              SectionHeaderWidget(title: 'Practice Modules'),
              const SizedBox(height: 16),

              modulesAsync.when(
                data: (modules) => LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = constraints.maxWidth > 900
                        ? 4
                        : (constraints.maxWidth > 600 ? 3 : 2);
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 1.1,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: modules.length,
                      itemBuilder: (context, index) {
                        final module = modules[index];
                        return _buildModuleCard(context, module, index);
                      },
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Text(
                    'Error loading modules',
                    style: TextStyle(color: Colors.red[300]),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (Navigator.canPop(context))
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                'CAREERBRIDGE YOUR SKILLS',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Aptitude Arena',
          style: GoogleFonts.outfit(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Master quantitative and logical reasoning tests.',
          style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startAssignmentTest(
    BuildContext context,
    WidgetRef ref,
    String assignmentId,
    String testId,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final result = await ref
          .read(aptitudeRepositoryProvider)
          .startTest(
            testId: testId,
            testType: 'assignment',
            assignmentId: assignmentId,
          );

      if (context.mounted) {
        Navigator.pop(context);

        final attempt = result['attempt'] as TestAttempt;
        final settings = result['settings'] as Map<String, dynamic>;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                TestTakingScreen(attempt: attempt, settings: settings),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to start test: $e')));
      }
    }
  }

  Widget _buildModuleCard(
    BuildContext context,
    AptitudeModule module,
    int index,
  ) {
    Color cardColor;
    try {
      cardColor = module.colorCode != null
          ? Color(int.parse(module.colorCode!.replaceAll('#', '0xFF')))
          : Colors.blueAccent;
    } catch (e) {
      cardColor = Colors.blueAccent;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ModuleDetailScreen(module: module),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: cardColor.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [cardColor, cardColor.withValues(alpha: 0.8)],
            ),
          ),
          child: Stack(
            children: [
              // Decorative Circles
              Positioned(
                right: -15,
                top: -15,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              Positioned(
                left: -20,
                bottom: -20,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        module.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          module.name,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Practice Now',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (400 + (index * 50)).ms).slideY(begin: 0.2);
  }

  void _navigateToViewAll(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AssignmentsListScreen()),
    );
  }
}
