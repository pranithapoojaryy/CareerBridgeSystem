import 'package:flutter/material.dart' hide Text;
import 'package:flutter/material.dart' as material show Text;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'manage_mocks_screen.dart';
import 'student_analytics_screen.dart';
import 'manage_categories_screen.dart';
import 'manage_questions_screen.dart';
import 'manage_content_screen.dart';
import 'mock_video_gallery_screen.dart';

import '../../domain/interview_models.dart';
import '../interview_providers.dart';

class CollegeInterviewDashboard extends ConsumerWidget {
  const CollegeInterviewDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interviewRepo = ref.watch(interviewRepositoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      material.Text(
                        "CareerBridge",
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF5A6ACF),
                          letterSpacing: 1.2,
                        ),
                      ),
                      material.Text(
                        "College Portal",
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1F36),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Color(0xFF5A6ACF),
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              FutureBuilder<List<InterviewAttempt>>(
                future: interviewRepo.getAllInterviews(),
                builder: (context, snapshot) {
                  String studentsPracticing = "0";
                  String pendingReviews = "0";

                  if (snapshot.hasData) {
                    final interviews = snapshot.data!;
                    final uniqueStudents = interviews
                        .map((e) => e.studentId)
                        .toSet()
                        .length;
                    final pending = interviews
                        .where(
                          (e) =>
                              e.status == 'Pending' ||
                              e.status == 'Pending Review',
                        )
                        .length;

                    studentsPracticing = uniqueStudents.toString();
                    pendingReviews = pending.toString();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: "Active Students",
                              value: studentsPracticing,
                              icon: Icons.people_alt_rounded,
                              colors: [
                                const Color(0xFF5A6ACF),
                                const Color(0xFF818EE1),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              title: "Pending Reviews",
                              value: pendingReviews,
                              icon: Icons.rate_review_rounded,
                              colors: [
                                const Color(0xFFF37335),
                                const Color(0xFFFDC830),
                              ],
                              onTap: () => _showManagementSheet(
                                context,
                                'Student Performance Analytics',
                                const StudentAnalyticsScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      material.Text(
                        "Management Console",
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1F36),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Refined Action Buttons
                      _buildActionTile(
                        context,
                        title: 'Student Analytics',
                        subtitle: 'Monitor progress and performance metrics',
                        icon: Icons.analytics_rounded,
                        colors: [
                          const Color(0xFF43E97B),
                          const Color(0xFF38F9D7),
                        ],
                        onTap: () => _showManagementSheet(
                          context,
                          'Student Performance Analytics',
                          const StudentAnalyticsScreen(),
                        ),
                      ),
                      _buildActionTile(
                        context,
                        title: 'Practice Mocks',
                        subtitle: 'Schedule and manage live interview sessions',
                        icon: Icons.video_camera_front_rounded,
                        colors: [
                          const Color(0xFFFA709A),
                          const Color(0xFFFEE140),
                        ],
                        onTap: () => _showManagementSheet(
                          context,
                          'Manage Practice Mocks',
                          const ManageMocksScreen(),
                        ),
                      ),
                      _buildActionTile(
                        context,
                        title: 'Mock Video Gallery',
                        subtitle: 'Browse all student interview recordings',
                        icon: Icons.video_library_rounded,
                        colors: [
                          const Color(0xFF667EEA),
                          const Color(0xFF764BA2),
                        ],
                        onTap: () => _showManagementSheet(
                          context,
                          'Mock Interview Gallery',
                          const MockVideoGalleryScreen(),
                        ),
                      ),
                      _buildActionTile(
                        context,
                        title: 'PRACTICE INTERVIEW TOPICS',
                        subtitle: 'Organize question sets and categories',
                        icon: Icons.auto_awesome_mosaic_rounded,
                        colors: [
                          const Color(0xFF667EEA),
                          const Color(0xFF764BA2),
                        ],
                        onTap: () => _showManagementSheet(
                          context,
                          'PRACTICE INTERVIEW TOPICS',
                          const ManageCategoriesScreen(),
                        ),
                      ),
                      _buildActionTile(
                        context,
                        title: 'Question Bank',
                        subtitle: 'Curate and edit interview questions',
                        icon: Icons.quiz_rounded,
                        colors: [
                          const Color(0xFF2AF598),
                          const Color(0xFF009EFD),
                        ],
                        onTap: () => _showManagementSheet(
                          context,
                          'Interview Question Bank',
                          const ManageQuestionsScreen(),
                        ),
                      ),
                      _buildActionTile(
                        context,
                        title: 'Learning Resources',
                        subtitle: 'Upload and manage study materials',
                        icon: Icons.menu_book_rounded,
                        colors: [
                          const Color(0xFFF83600),
                          const Color(0xFFFE8C00),
                        ],
                        onTap: () => _showManagementSheet(
                          context,
                          'Learning Resources',
                          const ManageContentScreen(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showManagementSheet(BuildContext context, String title, Widget screen) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.95,
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FD),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1F36),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Row(
                children: [
                  material.Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: screen),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> colors,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colors[0].withValues(alpha: 0.12),
              blurRadius: 24,
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
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 20),
            material.Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1F36),
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            material.Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF697386),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colors[0].withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    material.Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: const Color(0xFF1A1F36),
                      ),
                    ),
                    const SizedBox(height: 4),
                    material.Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF697386),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFD1D5DB),
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
