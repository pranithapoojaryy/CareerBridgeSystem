import 'package:flutter/material.dart';
import 'package:frontend/core/utils/logger_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/interview_models.dart';
import '../interview_providers.dart';

class FacultyReviewScreen extends ConsumerStatefulWidget {
  final InterviewAttempt attempt;

  const FacultyReviewScreen({super.key, required this.attempt});

  @override
  ConsumerState<FacultyReviewScreen> createState() =>
      _FacultyReviewScreenState();
}

class _FacultyReviewScreenState extends ConsumerState<FacultyReviewScreen> {
  late VideoPlayerController _videoController;
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _scoreController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _feedbackController.text = widget.attempt.facultyFeedback ?? '';
    if (widget.attempt.facultyScore != null) {
      _scoreController.text = widget.attempt.facultyScore.toString();
    }

    if (widget.attempt.videoUrl != null) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    try {
      final path = widget.attempt.videoUrl!;
      final signedUrl = await Supabase.instance.client.storage
          .from('interview-videos')
          .createSignedUrl(path, 3600);

      _videoController = VideoPlayerController.networkUrl(Uri.parse(signedUrl));
      await _videoController.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      LoggerService.error("Error loading video review", e);
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _feedbackController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final score = int.tryParse(_scoreController.text);
    if (score == null || score < 0 || score > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid score (0-10)')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(interviewRepositoryProvider)
          .updateFacultyReview(
            attemptId: widget.attempt.id,
            score: score,
            feedback: _feedbackController.text,
            mockAttemptId: widget.attempt.mockAttemptId,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review Submitted Successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Faculty Review')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Video Player
            if (widget.attempt.videoUrl != null)
              AspectRatio(
                aspectRatio: _videoController.value.isInitialized
                    ? _videoController.value.aspectRatio
                    : 16 / 9,
                child: _videoController.value.isInitialized
                    ? Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          VideoPlayer(_videoController),
                          VideoProgressIndicator(
                            _videoController,
                            allowScrubbing: true,
                          ),
                          FloatingActionButton(
                            mini: true,
                            onPressed: () {
                              setState(() {
                                _videoController.value.isPlaying
                                    ? _videoController.pause()
                                    : _videoController.play();
                              });
                            },
                            child: Icon(
                              _videoController.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                            ),
                          ),
                        ],
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Question:",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  Text(widget.attempt.question?.questionText ?? "Unknown"),
                  const SizedBox(height: 16),

                  // AI Score Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "AI Score",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                            CircleAvatar(
                              backgroundColor: Colors.blue,
                              radius: 14,
                              child: Text(
                                widget.attempt.scoreJson['total']?.toString() ??
                                    "?",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "AI Feedback: ${widget.attempt.aiFeedback}",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Faculty Review Form
                  Text(
                    "Your Assessment",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _scoreController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Faculty Score (0-10)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _feedbackController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Detailed Feedback",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Submit Review"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
