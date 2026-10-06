import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/recruiter_repository.dart';

class RunningCoursesSidebarWidget extends ConsumerWidget {
  const RunningCoursesSidebarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(runningCoursesProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Running Courses',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1D1E),
                ),
              ),
              const Icon(Icons.school_outlined, color: Colors.orange, size: 20),
            ],
          ),
          const SizedBox(height: 20),
          coursesAsync.when(
            data: (courses) {
              if (courses.isEmpty) {
                return Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Icon(
                        Icons.book_outlined,
                        size: 40,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No courses offered yet',
                        style: GoogleFonts.outfit(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: courses.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final course = courses[index];
                  final String title = course['title'] ?? 'Untitled Course';
                  final String category = course['category'] ?? 'General';
                  final String? thumbnail = course['thumbnail_url'];

                  final categoryColor = _getCategoryColor(category);

                  return Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              categoryColor,
                              categoryColor.withValues(alpha: 0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          image: thumbnail != null
                              ? DecorationImage(
                                  image: NetworkImage(thumbnail),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: thumbnail == null
                            ? Icon(
                                _getCategoryIcon(category),
                                color: Colors.white,
                                size: 24,
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: categoryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                category.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: categoryColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (err, stack) => Center(
              child: Text(
                'Error loading courses',
                style: GoogleFonts.outfit(color: Colors.red[300], fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('tech')) return const Color(0xFF2196F3); // Blue
    if (cat.contains('soft') || cat.contains('skill'))
      return const Color(0xFF4CAF50); // Green
    if (cat.contains('market')) return const Color(0xFF9C27B0); // Purple
    if (cat.contains('business')) return const Color(0xFFFF9800); // Orange
    if (cat.contains('design')) return const Color(0xFFE91E63); // Pink
    return const Color(0xFF607D8B); // Blue Grey for others
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('tech')) return Icons.code;
    if (cat.contains('soft') || cat.contains('skill')) return Icons.psychology;
    if (cat.contains('market')) return Icons.trending_up;
    if (cat.contains('business')) return Icons.business_center;
    if (cat.contains('design')) return Icons.brush;
    return Icons.play_circle_outline;
  }
}
