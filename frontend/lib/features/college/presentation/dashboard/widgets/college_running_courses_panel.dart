import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../data/college_providers.dart';
import '../../../../student/data/learning_repository.dart'; // Implements allCoursesProvider
import '../../../../student/domain/learning_course.dart';

class CollegeRunningCoursesPanel extends ConsumerWidget {
  const CollegeRunningCoursesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reusing the existing courses provider which typically fetches ALL courses for the org
    final coursesAsync = ref.watch(allCoursesProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppTheme.secondaryColor.withValues(alpha: 0.02), // Very subtle tint
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryColor.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: AppTheme.secondaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Running Courses',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to full course management
                    ref
                        .read(collegeDashboardIndexProvider.notifier)
                        .setIndex(22); // Index for ManageLearningCoursesScreen
                  },
                  child: Text(
                    'View All',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // List
          coursesAsync.when(
            data: (courses) {
              if (courses.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No active courses',
                          style: GoogleFonts.outfit(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Show top 5
              final displayCourses = courses.take(5).toList();

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(0),
                itemCount: displayCourses.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, indent: 24, endIndent: 24),
                itemBuilder: (context, index) {
                  final course = displayCourses[index];
                  return _buildCourseItem(course);
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, stack) => Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('Error loading courses'),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCourseItem(LearningCourse course) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            course.title.isNotEmpty ? course.title[0].toUpperCase() : 'C',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
              fontSize: 20,
            ),
          ),
        ),
      ),
      title: Text(
        course.title,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: Colors.black87,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${course.studentsEnrolled} Students Enrolled • ${course.sections.length} Modules',
        style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Active',
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ),
    );
  }
}
