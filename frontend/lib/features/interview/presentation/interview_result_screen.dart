import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/core/utils/logger_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/interview_models.dart';
import 'widgets/ai_scoring_explainer.dart';

class InterviewResultScreen extends StatefulWidget {
  final InterviewAttempt attempt;

  const InterviewResultScreen({super.key, required this.attempt});

  @override
  State<InterviewResultScreen> createState() => _InterviewResultScreenState();
}

class _InterviewResultScreenState extends State<InterviewResultScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _hasError = false;
  bool _isLoadingVideo = true;

  late AnimationController _scoreAnimationController;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _initVideo();
    _scoreAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scoreAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _scoreAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _scoreAnimationController.forward();
  }

  Future<void> _initVideo() async {
    if (widget.attempt.videoUrl == null || widget.attempt.videoUrl!.isEmpty) {
      if (mounted) setState(() => _isLoadingVideo = false);
      return;
    }

    try {
      String videoUrl = widget.attempt.videoUrl!;

      if (!videoUrl.startsWith('http')) {
        try {
          videoUrl = await Supabase.instance.client.storage
              .from('interview-videos')
              .createSignedUrl(widget.attempt.videoUrl!, 3600);
        } catch (e) {
          LoggerService.error("Error signing URL", e);
          throw Exception("Could not sign video URL");
        }
      }

      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

      await _videoController!.initialize();
      if (!mounted) return;

      await _videoController!.setVolume(1.0);
      if (!mounted) return;

      await _videoController!.setLooping(true);
      if (!mounted) return;

      setState(() {
        _isVideoInitialized = true;
        _isLoadingVideo = false;
      });
    } catch (e) {
      LoggerService.error("Video Init Error", e);
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoadingVideo = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _scoreAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1024;

    final scoreData = widget.attempt.scoreJson;
    final totalScore = scoreData['total'] != null
        ? (scoreData['total'] as num).toInt()
        : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Interview Results',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1F2937)),
          onPressed: () {
            int count = 0;
            Navigator.popUntil(context, (route) {
              return count++ >= 2 || route.isFirst;
            });
          },
        ),
      ),
      body: isDesktop
          ? _buildDesktopLayout(totalScore, scoreData)
          : _buildMobileLayout(totalScore, scoreData),
    );
  }

  Widget _buildDesktopLayout(int totalScore, Map<String, dynamic> scoreData) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left - Video Player
        Expanded(
          flex: 5,
          child: Container(
            margin: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVideoPlayer(),
                const SizedBox(height: 24),
                _buildFeedbackCard(
                  "AI Feedback",
                  Icons.auto_awesome,
                  const Color(0xFF8B5CF6),
                  widget.attempt.aiFeedback,
                ),
                if (widget.attempt.facultyFeedback != null &&
                    widget.attempt.facultyFeedback!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildFeedbackCard(
                    "Faculty Feedback",
                    Icons.rate_review,
                    const Color(0xFF3B82F6),
                    widget.attempt.facultyFeedback!,
                  ),
                ],
              ],
            ),
          ),
        ),
        // Right - Scores & Breakdown
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(32),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildScoreHeader(totalScore),
                  const SizedBox(height: 32),
                  _buildScoreBreakdown(scoreData),
                  const SizedBox(height: 32),
                  const AIScoringExplainer(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(int totalScore, Map<String, dynamic> scoreData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildScoreHeader(totalScore),
          const SizedBox(height: 24),
          _buildVideoPlayer(),
          const SizedBox(height: 24),
          _buildScoreBreakdown(scoreData),
          const SizedBox(height: 24),
          const AIScoringExplainer(),
          const SizedBox(height: 24),
          _buildFeedbackCard(
            "AI Feedback",
            Icons.auto_awesome,
            const Color(0xFF8B5CF6),
            widget.attempt.aiFeedback,
          ),
          if (widget.attempt.facultyFeedback != null &&
              widget.attempt.facultyFeedback!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildFeedbackCard(
              "Faculty Feedback",
              Icons.rate_review,
              const Color(0xFF3B82F6),
              widget.attempt.facultyFeedback!,
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildScoreHeader(int totalScore) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getScoreColor(totalScore).withValues(alpha: 0.1),
            _getScoreColor(totalScore).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getScoreColor(totalScore).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildAnimatedScoreCircle(
            totalScore,
            "AI Score",
            _getScoreColor(totalScore),
          ),
          if (widget.attempt.facultyScore != null)
            _buildAnimatedScoreCircle(
              widget.attempt.facultyScore!,
              "Faculty Score",
              const Color(0xFF3B82F6),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedScoreCircle(int score, String label, Color color) {
    return AnimatedBuilder(
      animation: _scoreAnimation,
      builder: (context, child) {
        final animatedScore = (score * _scoreAnimation.value).toInt();
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: _scoreAnimation.value * (score / 100),
                strokeWidth: 10,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$animatedScore',
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildVideoPlayer() {
    if (_isVideoInitialized && _videoController != null) {
      return Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.black,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_videoController!),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _videoController!.value.isPlaying
                            ? _videoController!.pause()
                            : _videoController!.play();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _videoController!.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: const Color(0xFF1F2937),
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (_hasError) {
      return _buildVideoError();
    } else if (_isLoadingVideo) {
      return _buildVideoLoading();
    }
    return const SizedBox.shrink();
  }

  Widget _buildVideoError() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_off, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            "Video Unavailable",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade800,
            ),
          ),
          Text(
            kIsWeb ? "Check browser format support" : "File not found",
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.red.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoLoading() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
        ),
      ),
    );
  }

  Widget _buildScoreBreakdown(Map<String, dynamic> scoreData) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Performance Breakdown",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          _buildScoreBar(
            'Content Relevance',
            _extractScore(scoreData, 'content'),
            10,
            const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 16),
          _buildScoreBar(
            'Confidence',
            _extractScore(scoreData, 'confidence'),
            10,
            const Color(0xFF10B981),
          ),
          const SizedBox(height: 16),
          _buildScoreBar(
            'Structure',
            _extractScore(scoreData, 'structure'),
            10,
            const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBar(String label, int value, int total, Color color) {
    return AnimatedBuilder(
      animation: _scoreAnimation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                Text(
                  '${(value * _scoreAnimation.value).toInt()}/$total',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _scoreAnimation.value * (value / total),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeedbackCard(
    String title,
    IconData icon,
    Color color,
    String content,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.6,
              color: const Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }

  int _extractScore(Map<String, dynamic> json, String key) {
    if (json[key] == null) return 0;
    return (json[key] as num).toInt();
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF10B981); // Green
    if (score >= 60) return const Color(0xFFF59E0B); // Orange
    return const Color(0xFFEF4444); // Red
  }
}
