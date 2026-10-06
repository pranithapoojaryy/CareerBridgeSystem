import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'mock_interview_providers.dart';
import '../../domain/mock_interview_models.dart';
import 'grade_mock_screen.dart';

class MockVideoGalleryScreen extends ConsumerWidget {
  const MockVideoGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionsAsync = ref.watch(allMockSubmissionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A), // Dark Navy
      appBar: AppBar(
        title: Text(
          "Mock Interview Gallery",
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: submissionsAsync.when(
        data: (submissions) {
          if (submissions.isEmpty) {
            return _buildEmptyState(context);
          }

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 0.75, // Increased height for details
            ),
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              final submission = submissions[index];
              return _VideoCard(submission: submission);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF5A6ACF)),
        ),
        error: (err, stack) => Center(
          child: Text(
            "Error loading recordings: $err",
            style: GoogleFonts.outfit(color: Colors.white70),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_collection_outlined,
            size: 80,
            color: Colors.white24,
          ),
          const SizedBox(height: 16),
          Text(
            "No recordings found",
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Student recordings across all mocks will appear here.",
            style: GoogleFonts.outfit(
              color: Colors.white38,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final MockAttempt submission;

  const _VideoCard({required this.submission});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: const BoxDecoration(
              color: Color(0xFF161A26),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: GradeMockScreen(attempt: submission),
          ),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161A26),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Video Thumbnail
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: Colors.black45,
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        size: 40,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(submission.status).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _getStatusColor(submission.status).withOpacity(0.4)),
                      ),
                      child: Text(
                        submission.status.toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: _getStatusColor(submission.status),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    submission.studentName ?? "Unknown Student",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    submission.mockTitle ?? "Mock Interview",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 12, color: Colors.white30),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          submission.submittedAt != null
                              ? timeago.format(submission.submittedAt!)
                              : "No date",
                          style: GoogleFonts.outfit(
                            color: Colors.white30,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'graded':
        return const Color(0xFF65D4B0); // Teal
      case 'submitted':
        return const Color(0xFF5A6ACF); // Blue
      default:
        return Colors.amber;
    }
  }
}
