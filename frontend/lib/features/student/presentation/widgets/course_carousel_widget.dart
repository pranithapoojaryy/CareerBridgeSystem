import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/learning_repository.dart';
import '../../domain/learning_course.dart';

class CourseCarouselWidget extends ConsumerWidget {
  const CourseCarouselWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(allCoursesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Courses',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to Learning Catalog
                },
                child: Text(
                  'View All',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        coursesAsync.when(
          data: (courses) {
            if (courses.isEmpty) {
              return _buildEmptyState();
            }
            return SizedBox(
              height: 280, // Taller appropriately
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: courses.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) =>
                    _buildCourseCard(context, courses[index]),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.school_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text(
              'No courses available yet',
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, LearningCourse course) {
    // Generate a consistent random color based on course ID or title
    final int hash = course.title.hashCode;
    final List<List<Color>> gradients = [
      [const Color(0xFF6A11CB), const Color(0xFF2575FC)],
      [const Color(0xFFFF512F), const Color(0xFFDD2476)],
      [const Color(0xFF11998e), const Color(0xFF38ef7d)],
      [const Color(0xFF00b09b), const Color(0xFF96c93d)],
      [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
      [const Color(0xFFFF416C), const Color(0xFFFF4B2B)],
    ];
    final gradient = gradients[hash.abs() % gradients.length];

    return Container(
      width: 240, // Slightly smaller width for sidebar
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFFFF0F5), // Very light pink/purple tint
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.08), // Colored shadow
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.purple.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppTheme.primaryColor, // Solid color for course card
              image: course.thumbnailAsset.isNotEmpty
                  ? DecorationImage(
                      image: course.thumbnailAsset.startsWith('http')
                          ? NetworkImage(course.thumbnailAsset)
                          : AssetImage(course.thumbnailAsset) as ImageProvider,
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: course.thumbnailAsset.isEmpty
                ? Stack(
                    children: [
                      // Texture/Pattern overlay for "premium" feel (optional, using simple circle for now)
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Center(
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: 40,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  )
                : null,
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    course.description,
                    style: GoogleFonts.outfit(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        size: 16,
                        color: gradient[0], // Use primary gradient color
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${course.sections.length} Modules',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: gradient[0],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
