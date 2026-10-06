import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../data/learning_repository.dart';
import '../domain/learning_course.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  final LearningCourse course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> {
  bool _isEnrolling = false;

  Future<void> _enroll() async {
    setState(() => _isEnrolling = true);
    try {
      await ref
          .read(learningRepositoryProvider)
          .enrollInCourse(widget.course.id);
      // Refresh my learning logic
      ref.refresh(myLearningProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enrolled Successfully! Check "My Learning" tab.'),
          ),
        );
        Navigator.pop(context); // Or toggle state to "Start Learning"
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isEnrolling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 250,
            leading: const BackButton(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(
                        (course.title.hashCode * 0xFFFFFF).toInt(),
                      ).withValues(alpha: 0.9),
                      Color(
                        ((course.title.hashCode + 1) * 0xFFFFFF).toInt(),
                      ).withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.school,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(course.category, Colors.blue),
                      _buildChip(course.difficulty, Colors.green),
                      if (course.hasCertificate)
                        _buildChip('Certificate', Colors.orange),
                      ...course.tags
                          .map((t) => _buildChip(t, Colors.purple))
                          .take(3),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Title and Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          course.title,
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ).animate().fadeIn().slideX(begin: -0.1),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        course.price == 0 ? 'Free' : '₹${course.price}',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Provider
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.grey,
                        child: Icon(
                          Icons.business,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Offered by ${course.providerName}',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Description
                  Text(
                    "About this Course",
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    course.description,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.grey[600],
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Key Info Row
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoItem(
                          Icons.schedule,
                          '${course.durationHours} Hours',
                          'Duration',
                        ),
                        _buildInfoItem(
                          Icons.group,
                          '${course.studentsEnrolled}',
                          'Enrolled',
                        ),
                        _buildInfoItem(
                          Icons.star,
                          '${course.rating}',
                          'Rating',
                        ),
                        _buildInfoItem(
                          Icons.play_circle_outline,
                          '${course.totalLectures} Lectures',
                          'Content',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Curriculum
                  Text(
                    "Curriculum",
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (course.sections.isEmpty)
                    const Center(child: Text('Curriculum details coming soon')),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: course.sections.length,
                    itemBuilder: (context, index) {
                      final section = course.sections[index];
                      return ExpansionTile(
                        title: Text(
                          section.title,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${section.lectures.length} Lectures',
                          style: const TextStyle(fontSize: 12),
                        ),
                        initiallyExpanded: index == 0,
                        children: section.lectures
                            .map(
                              (lecture) => ListTile(
                                leading: Icon(
                                  lecture.type == 'video'
                                      ? Icons.play_circle_fill
                                      : Icons.article,
                                  color: AppTheme.primaryColor,
                                ),
                                title: Text(lecture.title),
                                subtitle: Text(
                                  '${lecture.durationMinutes} mins',
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 80), // Pad for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: FilledButton(
          onPressed: _isEnrolling ? null : _enroll,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppTheme.primaryColor,
          ),
          child: _isEnrolling
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : Text(
                  'Enroll Now',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
