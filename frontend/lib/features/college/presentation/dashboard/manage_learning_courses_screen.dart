import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../student/data/learning_repository.dart';
import '../../../student/domain/learning_course.dart';
import 'course_creation_wizard.dart';
import 'module_management_screen.dart';
import 'certificate_template_screen.dart';
import '../learning/course_enrollments_screen.dart';

class ManageLearningCoursesScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBackPressed;
  const ManageLearningCoursesScreen({super.key, this.onBackPressed});

  @override
  ConsumerState<ManageLearningCoursesScreen> createState() =>
      _ManageLearningCoursesScreenState();
}

class _ManageLearningCoursesScreenState
    extends ConsumerState<ManageLearningCoursesScreen> {
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(managedCoursesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PathCreationWizard()),
          ).then((_) => ref.refresh(managedCoursesProvider));
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create Course'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      onPressed: () {
                        if (widget.onBackPressed != null) {
                          widget.onBackPressed!();
                        } else {
                          Navigator.maybePop(context);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Learning Courses',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your learning content and modules',
                          style: GoogleFonts.outfit(
                            color: Colors.grey[600],
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Analytics button removed as per request
                    /*
                    FilledButton.icon(
                      onPressed: () {
                        ref
                            .read(collegeDashboardIndexProvider.notifier)
                            .setIndex(20);
                      },
                      icon: const Icon(Icons.bar_chart_rounded, size: 20),
                      label: const Text('Analytics'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    */
                    IconButton(
                      onPressed: () => setState(() => _isGridView = true),
                      icon: Icon(
                        Icons.grid_view_rounded,
                        color: _isGridView
                            ? AppTheme.primaryColor
                            : Colors.grey,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _isGridView = false),
                      icon: Icon(
                        Icons.view_list_rounded,
                        color: !_isGridView
                            ? AppTheme.primaryColor
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            Expanded(
              child: coursesAsync.when(
                data: (courses) {
                  if (courses.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.school_outlined,
                              size: 80,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No courses yet',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first course to get started',
                            style: GoogleFonts.outfit(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PathCreationWizard(),
                                ),
                              ).then(
                                (_) => ref.refresh(managedCoursesProvider),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Create First Course'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (_isGridView) {
                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 400,
                            childAspectRatio: 1.1,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                          ),
                      itemCount: courses.length,
                      itemBuilder: (context, index) {
                        final course = courses[index];
                        return _buildCourseCard(course, index);
                      },
                    );
                  } else {
                    return ListView.separated(
                      itemCount: courses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final course = courses[index];
                        return _buildCourseListTile(course, index);
                      },
                    );
                  }
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(LearningCourse course, int index) {
    final totalLectures = course.sections.fold(
      0,
      (sum, s) => sum + s.lectures.length,
    );
    final durationHours =
        course.sections.fold(
          0,
          (sum, s) =>
              sum + s.lectures.fold(0, (lsum, l) => lsum + l.durationMinutes),
        ) ~/
        60;

    return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Header
              Container(
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(
                        (course.title.hashCode * 0xFFFFFF).toInt(),
                      ).withValues(alpha: 0.7),
                      Color(
                        ((course.title.hashCode + 1) * 0xFFFFFF).toInt(),
                      ).withValues(alpha: 0.5),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Overlay icons
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(
                        Icons.school_outlined,
                        size: 100,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    // Top right menu
                    Positioned(
                      top: 8,
                      right: 8,
                      child: PopupMenuButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.more_vert, size: 20),
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 12),
                                Text('Edit Course'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'modules',
                            child: Row(
                              children: [
                                Icon(Icons.view_module_outlined, size: 18),
                                SizedBox(width: 12),
                                Text('Manage Modules'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'stats',
                            child: Row(
                              children: [
                                Icon(Icons.analytics_outlined, size: 18),
                                SizedBox(width: 12),
                                Text('View Stats'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) =>
                            _handleMenuAction(value.toString(), course),
                      ),
                    ),
                    // Domain badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          course.domainType ?? 'General',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        course.providerName,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),

                      // Stats Row
                      Row(
                        children: [
                          _buildStatChip(
                            Icons.people_outline,
                            '${course.studentsEnrolled}',
                          ),
                          const SizedBox(width: 8),
                          _buildStatChip(
                            Icons.menu_book,
                            '${course.sections.length}M',
                          ),
                          const SizedBox(width: 8),
                          _buildStatChip(
                            Icons.access_time,
                            '${durationHours}h',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: (index * 50).ms)
        .scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseListTile(LearningCourse course, int index) {
    final totalLectures = course.sections.fold(
      0,
      (sum, s) => sum + s.lectures.length,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(
                  (course.title.hashCode * 0xFFFFFF).toInt(),
                ).withValues(alpha: 0.7),
                Color(
                  ((course.title.hashCode + 1) * 0xFFFFFF).toInt(),
                ).withValues(alpha: 0.5),
              ],
            ),
          ),
          child: Center(
            child: Text(
              course.category.substring(0, 1).toUpperCase(),
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white,
              ),
            ),
          ),
        ),
        title: Text(
          course.title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Icon(Icons.people_outline, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                '${course.studentsEnrolled}',
                style: GoogleFonts.outfit(fontSize: 12),
              ),
              const SizedBox(width: 16),
              Icon(Icons.menu_book, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                '${course.sections.length} modules',
                style: GoogleFonts.outfit(fontSize: 12),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.play_circle_outline,
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                '$totalLectures lectures',
                style: GoogleFonts.outfit(fontSize: 12),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _handleMenuAction('edit', course),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.view_module_outlined),
              onPressed: () => _handleMenuAction('modules', course),
              tooltip: 'Modules',
            ),
            IconButton(
              icon: const Icon(Icons.people_alt_outlined),
              onPressed: () => _handleMenuAction('enrollments', course),
              tooltip: 'Enrolled Students',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _handleMenuAction('delete', course),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: -0.05);
  }

  void _handleMenuAction(String action, LearningCourse course) {
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PathCreationWizard(courseToEdit: course),
          ),
        ).then((_) => ref.refresh(managedCoursesProvider));
        break;

      case 'modules':
        // Navigate to module management (to be created)
        _showModuleManagement(course);
        break;

      case 'enrollments':
        // Navigate to enrollments view
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CourseEnrollmentsScreen(course: course),
          ),
        );
        break;

      case 'stats':
        _showCourseStats(course);
        break;

      case 'delete':
        _confirmDelete(course);
        break;
    }
  }

  void _showModuleManagement(LearningCourse course) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ModuleManagementScreen(course: course)),
    ).then((_) => ref.refresh(managedCoursesProvider));
  }

  void _showCourseStats(LearningCourse course) {
    final totalLectures = course.sections.fold(
      0,
      (sum, s) => sum + s.lectures.length,
    );
    final durationHours = showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Course Statistics',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatRow('Course Title', course.title),
                const Divider(),
                _buildStatRow('Provider', course.providerName),
                const Divider(),
                _buildStatRow('Domain', course.domainType ?? 'General'),
                const Divider(),
                _buildStatRow('Difficulty', course.difficulty),
                const Divider(),
                FutureBuilder<int>(
                  future: ref
                      .read(learningRepositoryProvider)
                      .getCourseEnrollmentCount(course.id),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _buildStatRow(
                        'Enrolled Students',
                        'Err: ${snapshot.error}',
                      );
                    }
                    return _buildStatRow(
                      'Enrolled Students',
                      snapshot.hasData ? '${snapshot.data}' : '...',
                    );
                  },
                ),
                const Divider(),
                _buildStatRow('Total Modules', '${course.sections.length}'),
                const Divider(),
                _buildStatRow(
                  'Total Lectures',
                  '${course.sections.fold(0, (sum, s) => sum + s.lectures.length)}',
                ),
                const Divider(),
                _buildStatRow('Duration', '${course.durationHours} hours'),
                const Divider(),
                _buildStatRow(
                  'Price',
                  course.price > 0 ? '₹${course.price}' : 'Free',
                ),
                const SizedBox(height: 16),
                if (course.skillsGained?.isNotEmpty ?? false) ...[
                  Text(
                    'Skills Covered:',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: course.skillsGained!
                        .map(
                          (skill) => Chip(
                            label: Text(
                              skill,
                              style: GoogleFonts.outfit(fontSize: 11),
                            ),
                            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CertificateTemplatePreviewScreen(
                    courseTitle: course.title,
                    providerName: course.providerName,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.workspace_premium, size: 18),
            label: const Text('View Certificate Template'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(LearningCourse course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Course?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${course.title}"?',
              style: GoogleFonts.outfit(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. All course data will be permanently deleted.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.red.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteCourse(course);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCourse(LearningCourse course) async {
    try {
      // Delete from Supabase
      await ref.read(learningRepositoryProvider).deleteCourse(course.id);

      // Refresh the list
      ref.refresh(allCoursesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Course "${course.title}" deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting course: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
