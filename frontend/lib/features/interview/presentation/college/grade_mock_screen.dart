import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'mock_interview_providers.dart';
import '../../domain/mock_interview_models.dart';
import '../../domain/interview_models.dart';
import 'package:url_launcher/url_launcher.dart';

class GradeMockScreen extends ConsumerStatefulWidget {
  final MockAttempt attempt;

  const GradeMockScreen({super.key, required this.attempt});

  @override
  ConsumerState<GradeMockScreen> createState() => _GradeMockScreenState();
}

class _GradeMockScreenState extends ConsumerState<GradeMockScreen> {
  late TextEditingController _feedbackCtrl;
  late TextEditingController _scoreCtrl;
  VideoPlayerController? _videoCtrl;
  bool _isPlaying = false;
  bool _isSaving = false;
  String? _errorMsg;

  late Future<List<InterviewAttempt>> _answersFuture;

  @override
  void initState() {
    super.initState();
    _feedbackCtrl = TextEditingController(
      text: widget.attempt.facultyFeedback ?? "",
    );
    _scoreCtrl = TextEditingController(
      text: widget.attempt.totalScore?.toString() ?? "",
    );

    if (widget.attempt.videoPath != null) {
      _initVideo(widget.attempt.videoPath!);
    } else {
      _errorMsg = "No video recording found for this attempt.";
    }

    _answersFuture = ref
        .read(mockRepositoryProvider)
        .getMockAnswers(widget.attempt.id);
  }

  Future<void> _initVideo(String pathOrUrl) async {
    if (mounted) setState(() => _errorMsg = null);
    try {
      String playUrl = pathOrUrl;
      if (!pathOrUrl.startsWith('http')) {
        final supabase = Supabase.instance.client;
        playUrl = await supabase.storage
            .from('interview-videos')
            .createSignedUrl(pathOrUrl, 3600);
      }

      final controller = VideoPlayerController.networkUrl(Uri.parse(playUrl));
      _videoCtrl = controller;
      await _videoCtrl!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = "Video initialization failed: The browser or device may not support this video format natively.";
          _videoCtrl = null;
        });
      }
    }
  }

  Future<void> _downloadVideo() async {
    if (widget.attempt.videoPath == null) return;
    try {
      final supabase = Supabase.instance.client;
      final playUrl = await supabase.storage
          .from('interview-videos')
          .createSignedUrl(widget.attempt.videoPath!, 3600);
      
      final uri = Uri.parse(playUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not generate download link: $e")),
        );
      }
    }
  }

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    _scoreCtrl.dispose();
    _videoCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Video Player Section
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.width * 9 / 16,
                  decoration: const BoxDecoration(color: Colors.black),
                  child: _videoCtrl != null && _videoCtrl!.value.isInitialized
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(_videoCtrl!),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (_videoCtrl!.value.isPlaying) {
                                    _videoCtrl!.pause();
                                    _isPlaying = false;
                                  } else {
                                    _videoCtrl!.play();
                                    _isPlaying = true;
                                  }
                                });
                              },
                              child: Container(
                                color: Colors.transparent,
                                child: Center(
                                  child: AnimatedOpacity(
                                    opacity: _isPlaying ? 0.0 : 1.0,
                                    duration: const Duration(milliseconds: 300),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: const BoxDecoration(
                                        color: Colors.black45,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 48,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 40,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.black54,
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                                child: VideoProgressIndicator(
                                  _videoCtrl!,
                                  allowScrubbing: true,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  colors: const VideoProgressColors(
                                    playedColor: Color(0xFF5A6ACF),
                                    bufferedColor: Colors.white24,
                                    backgroundColor: Colors.white12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: _errorMsg != null
                              ? Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        color: Color(0xFFFF6584),
                                        size: 48,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _errorMsg!,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.outfit(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: () => _initVideo(widget.attempt.videoPath!),
                                            icon: const Icon(Icons.refresh_rounded, size: 18),
                                            label: const Text("Retry"),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.white,
                                              side: const BorderSide(color: Colors.white38),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          ElevatedButton.icon(
                                            onPressed: _downloadVideo,
                                            icon: const Icon(Icons.download_rounded, size: 18),
                                            label: const Text("Download"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF5A6ACF),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              : const CircularProgressIndicator(
                                  color: Color(0xFF5A6ACF),
                                ),
                        ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Grading Form Section
                      _buildSectionHeader("Performance Assessment"),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildInputCard(
                              title: "Final Score",
                              child: TextField(
                                controller: _scoreCtrl,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF5A6ACF),
                                ),
                                decoration: InputDecoration(
                                  hintText: "0",
                                  suffixText: "/100",
                                  suffixStyle: GoogleFonts.outfit(
                                    color: const Color(0xFF697386),
                                    fontSize: 16,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 3,
                            child: _buildInputCard(
                              title: "Submission ID",
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Text(
                                  "#${widget.attempt.id.substring(0, 8).toUpperCase()}",
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1A1F36),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInputCard(
                        title: "Detailed Faculty Feedback",
                        child: TextField(
                          controller: _feedbackCtrl,
                          maxLines: 4,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: const Color(0xFF1A1F36),
                          ),
                          decoration: InputDecoration(
                            hintText:
                                "What are the student's key strengths and areas for improvement?",
                            hintStyle: GoogleFonts.outfit(
                              color: const Color(0xFF697386),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                      _buildSectionHeader("Question Breakdown"),
                      const SizedBox(height: 12),
                      FutureBuilder<List<InterviewAttempt>>(
                        future: _answersFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          final answers = snapshot.data ?? [];
                          if (answers.isEmpty) return _buildEmptyAnswers();

                          return Column(
                            children: answers
                                .map((answer) => _buildAnswerCard(answer))
                                .toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveGrade,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1F36),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    "SUBMIT EVALUATION",
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1A1F36),
      ),
    );
  }

  Widget _buildInputCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3E8EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF5A6ACF),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }

  Widget _buildAnswerCard(InterviewAttempt answer) {
    final start = answer.answerStartOffset ?? 0;
    final isCoding = answer.question?.questionType == 'coding';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE3E8EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isCoding ? Icons.code_rounded : Icons.videocam_rounded,
                        color: const Color(0xFF5A6ACF),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        answer.question?.questionText ?? "Question Details",
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1F36),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (!isCoding)
                  InkWell(
                    onTap: () {
                      if (_videoCtrl != null &&
                          _videoCtrl!.value.isInitialized) {
                        _videoCtrl!.seekTo(Duration(seconds: start));
                        _videoCtrl!.play();
                        setState(() => _isPlaying = true);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.play_circle_filled_rounded,
                            color: Color(0xFF5A6ACF),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Jump to response (${start}s)",
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF5A6ACF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (isCoding && answer.codeAnswer != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F36),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      answer.codeAnswer!,
                      style: GoogleFonts.firaCode(
                        color: const Color(0xFF2AF598),
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAnswers() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3E8EE)),
      ),
      child: Center(
        child: Text(
          "No question data was recorded for this attempt.",
          style: GoogleFonts.outfit(color: const Color(0xFF697386)),
        ),
      ),
    );
  }

  Future<void> _saveGrade() async {
    final score = int.tryParse(_scoreCtrl.text);
    if (score == null || score < 0 || score > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid score (0-100)")),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref
          .read(mockRepositoryProvider)
          .updateMockGrade(widget.attempt.id, score, _feedbackCtrl.text);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Evaluation submitted successfully!"),
            backgroundColor: Color(0xFF1A1F36),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
        setState(() => _isSaving = false);
      }
    }
  }
}
