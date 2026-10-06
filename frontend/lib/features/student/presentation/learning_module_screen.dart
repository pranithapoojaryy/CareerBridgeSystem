import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../data/learning_repository.dart';
import '../domain/learning_course.dart';
import '../domain/assessment.dart';

import 'assessment_taking_screen.dart';
import 'widgets/learning_content_widgets.dart';

// Provider for course details
final courseDetailProvider = FutureProvider.family<LearningCourse, String>((
  ref,
  courseId,
) async {
  return ref
      .read(learningRepositoryProvider)
      .getCourseWithFullMetadata(courseId);
});

class LearningModuleScreen extends ConsumerStatefulWidget {
  final String courseId;
  final String sectionId;
  final CourseSection section;
  final String? initialLectureId;

  const LearningModuleScreen({
    super.key,
    required this.courseId,
    required this.sectionId,
    required this.section,
    this.initialLectureId,
  });

  @override
  ConsumerState<LearningModuleScreen> createState() =>
      _LearningModuleScreenState();
}

class _LearningModuleScreenState extends ConsumerState<LearningModuleScreen> {
  int _currentLectureIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialLectureId != null) {
      final index = widget.section.lectures.indexWhere(
        (l) => l.id == widget.initialLectureId,
      );
      if (index != -1) {
        _currentLectureIndex = index;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lecturesProgress = ref.watch(
      lectureProgressProvider(widget.courseId),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.section.title,
          style: GoogleFonts.outfit(
            color: AppTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.bookmark_border), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          lecturesProgress.when(
            data: (progress) => _buildProgressBar(progress),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          Expanded(
            child: lecturesProgress.when(
              data: (progress) => _buildContent(progress),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),

          // Bottom navigation
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildProgressBar(List<LectureProgress> progressList) {
    if (widget.section.lectures.isEmpty) return const SizedBox.shrink();

    final completedCount = progressList.where((p) => p.completed).length;
    final progress = completedCount / widget.section.lectures.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                '${completedCount} of ${widget.section.lectures.length} Completed',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.primaryColor,
            ),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<LectureProgress> progressList) {
    if (widget.section.lectures.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No content available',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final currentLecture = widget.section.lectures[_currentLectureIndex];
    final isCompleted = progressList.any(
      (p) => p.lectureId == currentLecture.id && p.completed,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lecture title
          Text(
            currentLecture.title,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              _buildLectureTypeBadge(currentLecture.type),
              const SizedBox(width: 8),
              Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                '${currentLecture.durationMinutes} min',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Completed',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          if (currentLecture.description != null &&
              currentLecture.description!.isNotEmpty) ...[
            Text(
              currentLecture.description!,
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Content based on type
          _buildLectureContent(currentLecture),

          const SizedBox(height: 32),

          // Mark as complete button - always shown for non-completed lectures
          if (!isCompleted)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _markAsComplete(currentLecture.id),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Mark as Complete'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Lecture list
          Text(
            'Module Content',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...widget.section.lectures.asMap().entries.map((entry) {
            final index = entry.key;
            final lecture = entry.value;
            final lectureCompleted = progressList.any(
              (p) => p.lectureId == lecture.id && p.completed,
            );

            // Determine if locked
            bool isLocked = false;
            if (index > 0) {
              final prevLectureId = widget.section.lectures[index - 1].id;
              final prevCompleted = progressList.any(
                (p) => p.lectureId == prevLectureId && p.completed,
              );
              if (!prevCompleted) {
                isLocked = true;
              }
            }

            return _buildLectureListItem(
              lecture,
              index,
              lectureCompleted,
              index == _currentLectureIndex,
              isLocked,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLectureTypeBadge(String type) {
    Color color;
    IconData icon;
    String label;

    switch (type.toLowerCase()) {
      case 'video':
        color = const Color(0xFFEF4444);
        icon = Icons.play_circle_outline;
        label = 'Video';
        break;
      case 'pdf':
      case 'article':
        color = const Color(0xFF8B5CF6);
        icon = Icons.description_outlined;
        label = 'Reading';
        break;
      case 'assignment':
      case 'quiz':
        color = const Color(0xFF10B981);
        icon = Icons.assignment_outlined;
        label = 'Assessment';
        break;
      default:
        color = Colors.grey;
        icon = Icons.circle;
        label = type;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLectureContent(CourseLecture lecture) {
    // Assessment Handling
    if (lecture.type.toLowerCase() == 'quiz' ||
        lecture.type.toLowerCase() == 'assignment') {
      return _buildAssessmentCard(lecture);
    }

    // If no URL, show empty message (friendly)
    if (lecture.contentUrl.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_empty, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Content not uploaded yet',
              style: GoogleFonts.outfit(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    switch (lecture.type.toLowerCase()) {
      case 'video':
        if (lecture.contentUrl.contains('youtube') ||
            lecture.contentUrl.contains('youtu.be')) {
          return CustomYouTubePlayer(
            videoUrl: lecture.contentUrl,
            onVideoCompleted: () => _markAsComplete(lecture.id),
          );
        } else {
          return CustomVideoPlayer(
            videoUrl: lecture.contentUrl,
            onVideoCompleted: () => _markAsComplete(lecture.id),
          );
        }
      case 'pdf':
      case 'article':
        return CustomPDFViewer(
          pdfUrl: lecture.contentUrl,
          onDocumentRead: () => _markAsComplete(lecture.id),
        );
      default:
        if (lecture.contentUrl.isNotEmpty) {
          return _buildExternalLinkCard(lecture.contentUrl);
        }
        return const SizedBox.shrink();
    }
  }

  Widget _buildAssessmentCard(CourseLecture lecture) {
    // For assessments, the actual assessment ID is linked via contentUrl
    // Fallback to lecture.id for backward compatibility
    final assessmentId = lecture.contentUrl.isNotEmpty
        ? lecture.contentUrl
        : lecture.id;

    // Check if this is the Final Assessment
    final isFinalAssessment = lecture.title.toLowerCase().contains(
      'final assessment',
    );

    // Get completion status
    final lecturesProgress = ref.watch(
      lectureProgressProvider(widget.courseId),
    );
    final isCompleted =
        lecturesProgress.value?.any(
          (p) => p.lectureId == lecture.id && p.completed,
        ) ??
        false;

    return FutureBuilder<bool>(
      future: isFinalAssessment
          ? ref
                .read(learningRepositoryProvider)
                .checkAllModulesCompleted(widget.courseId)
          : Future.value(true),
      builder: (context, snapshot) {
        final allModulesCompleted = snapshot.data ?? false;
        final isLocked = isFinalAssessment && !allModulesCompleted;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(Icons.quiz_outlined, size: 48, color: AppTheme.primaryColor),
              const SizedBox(height: 16),
              Text(
                lecture.title,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                lecture.description ??
                    'Complete this assessment to test your knowledge.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),

              if (isCompleted)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: null, // Disabled
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade50,
                      disabledBackgroundColor: Colors.green.shade50,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: Icon(
                      Icons.check_circle,
                      color: Colors.green.shade700,
                    ),
                    label: Text(
                      'Completed',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else if (isLocked)
                SizedBox(
                  width: double.infinity,
                  child: Tooltip(
                    message:
                        'Complete all other lessons and assessments first.',
                    child: FilledButton.icon(
                      onPressed: null, // Disabled
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        disabledBackgroundColor: Colors.grey.shade200,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: const Icon(Icons.lock, color: Colors.grey),
                      label: const Text(
                        'Locked: Finish all modules',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AssessmentTakingScreen(
                            assessmentId: assessmentId,
                            courseId: widget.courseId,
                          ),
                        ),
                      );

                      if (result == true) {
                        _markAsComplete(lecture.id);
                        // Refresh progress to update UI
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start Assessment'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExternalLinkCard(String url) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            AppTheme.secondaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.link,
              color: AppTheme.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'External Resource',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  url,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {
              // Open link
            },
            icon: const Icon(Icons.open_in_new),
            color: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildLectureListItem(
    CourseLecture lecture,
    int index,
    bool isCompleted,
    bool isCurrent,
    bool isLocked,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCurrent && !isLocked
            ? AppTheme.primaryColor.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent && !isLocked
              ? AppTheme.primaryColor
              : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        enabled: !isLocked,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isLocked
                ? Colors.grey.shade200
                : isCompleted
                ? Colors.green.shade50
                : AppTheme.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isLocked
                ? Icon(Icons.lock, color: Colors.grey.shade500, size: 16)
                : isCompleted
                ? Icon(Icons.check, color: Colors.green.shade700, size: 18)
                : Text(
                    '${index + 1}',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
          ),
        ),
        title: Text(
          lecture.title,
          style: GoogleFonts.outfit(
            fontWeight: isCurrent && !isLocked
                ? FontWeight.bold
                : FontWeight.w500,
            fontSize: 14,
            color: isLocked ? Colors.grey.shade500 : Colors.black87,
          ),
        ),
        subtitle: Text(
          '${lecture.durationMinutes} min',
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: isCurrent && !isLocked
            ? const Icon(Icons.play_arrow, color: AppTheme.primaryColor)
            : null,
        onTap: isLocked
            ? null
            : () {
                setState(() => _currentLectureIndex = index);
              },
      ),
    );
  }

  Widget _buildBottomNav() {
    final isFirstLecture = _currentLectureIndex == 0;
    final isLastLecture =
        _currentLectureIndex == widget.section.lectures.length - 1;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!isFirstLecture)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _currentLectureIndex--),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          if (!isFirstLecture && !isLastLecture) const SizedBox(width: 16),
          if (!isLastLecture)
            Expanded(
              child: FilledButton.icon(
                onPressed: () => setState(() => _currentLectureIndex++),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          if (isLastLecture)
            Expanded(
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Finish Module'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _markAsComplete(String lectureId) async {
    await ref.read(learningRepositoryProvider).markLectureComplete(lectureId);
    ref.invalidate(lectureProgressProvider(widget.courseId));
    ref.invalidate(courseProgressProvider(widget.courseId));
  }
}

// Provider for lecture progress
final lectureProgressProvider =
    FutureProvider.family<List<LectureProgress>, String>((ref, courseId) async {
      return ref.read(learningRepositoryProvider).getLectureProgress(courseId);
    });
