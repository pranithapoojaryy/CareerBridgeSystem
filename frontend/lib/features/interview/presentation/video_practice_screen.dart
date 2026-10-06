import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/core/utils/logger_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'interview_providers.dart';
import '../domain/interview_models.dart';
import 'interview_result_screen.dart';
import 'widgets/ai_scoring_explainer.dart';

class VideoPracticeScreen extends ConsumerStatefulWidget {
  final InterviewQuestion question;
  final String categoryName;

  // Mock Mode Props
  final bool isEmbedded;
  final String? mockAttemptId;
  final Function(InterviewAttempt)? onNext;

  const VideoPracticeScreen({
    super.key,
    required this.question,
    required this.categoryName,
    this.isEmbedded = false,
    this.mockAttemptId,
    this.onNext,
  });

  @override
  ConsumerState<VideoPracticeScreen> createState() =>
      _VideoPracticeScreenState();
}

class _VideoPracticeScreenState extends ConsumerState<VideoPracticeScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  VideoPlayerController? _videoController;

  // State Variables
  bool _isRecording = false;
  bool _isProcessing = false;
  int _secondsRecorded = 0;
  Timer? _timer;
  XFile? _videoFile;
  bool _isCameraInitialized = false;

  // Speech To Text
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  String _statusMessage = 'Initializing...';

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initSpeech();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _videoController?.dispose();
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      _speechEnabled = false; // Force disabled for now
      if (mounted) {
        setState(() {
          if (_isCameraInitialized) _statusMessage = 'Ready to record';
        });
      }
    } catch (e) {
      LoggerService.error("STT Init Error", e);
    }
  }

  Future<void> _initializeCamera() async {
    try {
      if (!kIsWeb) {
        await [Permission.camera, Permission.microphone].request();
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _statusMessage = "No camera found");
        return;
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: true,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          if (_speechEnabled) _statusMessage = 'Ready to record';
        });

        if (widget.isEmbedded) {
          _startRecording();
        }
      }
    } catch (e) {
      LoggerService.error("Camera Init Error", e);
      if (mounted) setState(() => _statusMessage = "Camera Error: $e");
    }
  }

  void _startRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      if (kIsWeb) {
        try {
          await _cameraController!.prepareForVideoRecording();
        } catch (e) {
          LoggerService.error("Prepare error", e);
        }
      }

      await _cameraController!.startVideoRecording();
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _isRecording = true;
          _secondsRecorded = 0;
          _statusMessage = 'Recording in progress...';
        });
      }

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() => _secondsRecorded++);
        } else {
          timer.cancel();
        }
      });
    } catch (e) {
      LoggerService.error("Start Recording Error", e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Recording Error: $e")));
      }
    }
  }

  void _stopRecording() async {
    if (_cameraController == null) return;

    try {
      _timer?.cancel();

      if (_speechEnabled) {
        await _speechToText.stop();
      }

      final file = await _cameraController!.stopVideoRecording();

      if (mounted) {
        setState(() {
          _isRecording = false;
          _videoFile = file;
          _statusMessage = 'Review your answer';
        });
        _initializeVideoPlayer(file);
      }
    } catch (e) {
      LoggerService.error("Stop Recording Error", e);
    }
  }

  Future<void> _initializeVideoPlayer(XFile file) async {
    try {
      if (kIsWeb) {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(file.path),
        );
      } else {
        _videoController = VideoPlayerController.file(File(file.path));
      }
      await _videoController!.initialize();
      if (!mounted) return;

      await _videoController!.setVolume(1.0);
      if (!mounted) return;

      await _videoController!.setLooping(true);
      if (!mounted) return;

      await _videoController!.play();
      if (mounted) setState(() {});
    } catch (e) {
      LoggerService.error("Video Review Init Error", e);
    }
  }

  Future<void> _submitInterview() async {
    if (_videoFile == null) return;

    setState(() => _isProcessing = true);

    try {
      final repo = ref.read(interviewRepositoryProvider);

      final videoPath = await repo.uploadVideo(_videoFile!);

      final finalTranscript = _lastWords.isEmpty
          ? "No audio transcript captured."
          : _lastWords;

      final attempt = await repo.submitInterview(
        questionId: widget.question.id,
        videoPath: videoPath,
        duration: _secondsRecorded,
        categoryName: widget.categoryName,
        transcript: finalTranscript,
        mockAttemptId: widget.mockAttemptId,
      );

      if (mounted) {
        if (widget.isEmbedded && widget.onNext != null) {
          widget.onNext!(attempt);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => InterviewResultScreen(attempt: attempt),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _reset() {
    _videoController?.dispose();
    if (mounted) {
      setState(() {
        _videoController = null;
        _videoFile = null;
        _secondsRecorded = 0;
        _lastWords = '';
        _statusMessage = 'Ready to record';
      });
    }
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1024;
    final isTablet = size.width >= 600 && size.width < 1024;

    if (!_isCameraInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
              ),
              const SizedBox(height: 16),
              Text(
                _statusMessage,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (isDesktop) {
      return _buildDesktopLayout();
    } else if (isTablet) {
      return _buildTabletLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Row(
        children: [
          // Left Panel - Camera/Video
          Expanded(flex: 6, child: _buildCameraSection()),
          // Right Panel - Info & AI Scoring
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(-5, 0),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuestionCard(isCompact: false),
                    const SizedBox(height: 24),
                    if (_isRecording || _videoFile != null) ...[
                      _buildRecordingStats(),
                      const SizedBox(height: 24),
                    ],
                    const AIScoringExplainer(),
                    const SizedBox(height: 24),
                    if (_videoFile == null && !_isRecording) _buildNotesInput(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Column(
        children: [
          // Top - Question
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: SafeArea(
              bottom: false,
              child: _buildQuestionCard(isCompact: true),
            ),
          ),
          // Middle - Camera
          Expanded(child: _buildCameraSection()),
          // Bottom - Controls & Info
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isRecording || _videoFile != null)
                    _buildRecordingStats(),
                  const SizedBox(height: 16),
                  _buildControls(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          if (_videoFile == null)
            CameraPreview(_cameraController!)
          else if (_videoController != null &&
              _videoController!.value.isInitialized)
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),

          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.8),
                ],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildMobileHeader(),
                const Spacer(),
                // Bottom Controls
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isRecording)
                        _buildRecordingIndicator()
                      else
                        _buildFloatingQuestionCard(),
                      const SizedBox(height: 24),
                      _buildControls(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraSection() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Camera/Video Player
            if (_videoFile == null && _cameraController != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: _cameraController!.value.aspectRatio,
                  child: CameraPreview(_cameraController!),
                ),
              )
            else if (_videoController != null &&
                _videoController!.value.isInitialized)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
              ),

            // Recording Pulse Effect
            if (_isRecording)
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.5),
                      width: 3,
                    ),
                  ),
                ),
              ),

            // Controls Overlay
            Positioned(bottom: 40, child: _buildControls()),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard({required bool isCompact}) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B5CF6).withValues(alpha: 0.1),
            const Color(0xFF6D28D9).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.question_answer,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Interview Question',
                  style: GoogleFonts.poppins(
                    fontSize: isCompact ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.question.questionText,
            style: GoogleFonts.poppins(
              fontSize: isCompact ? 14 : 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1F2937),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            Icons.timer_outlined,
            'Duration',
            _formatDuration(_secondsRecorded),
            const Color(0xFF3B82F6),
          ),
          Container(width: 1, height: 40, color: const Color(0xFFD1D5DB)),
          _buildStatItem(
            Icons.mic,
            'Audio',
            _isRecording ? 'Active' : 'Captured',
            const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: const Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Answer Key Points (Used for AI Evaluation)',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: (val) => _lastWords = val,
          maxLines: 3,
          decoration: InputDecoration(
            hintText:
                'Enter keywords or summary that the AI should look for in your answer...',
            hintStyle: GoogleFonts.poppins(fontSize: 11),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: const Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: const Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          style: GoogleFonts.poppins(fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildControls() {
    if (widget.isEmbedded) {
      return _buildMockModeControls();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Retry Button
        if (_videoFile != null && !_isProcessing)
          _buildControlButton(
            icon: Icons.refresh,
            label: 'Retry',
            onTap: _reset,
            color: const Color(0xFF6B7280),
          ),
        if (_videoFile != null && !_isProcessing) const SizedBox(width: 16),

        // Main Action Button
        if (_isProcessing)
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
          )
        else if (_videoFile == null)
          _buildRecordButton()
        else
          _buildControlButton(
            icon: Icons.check_circle,
            label: 'Submit',
            onTap: _submitInterview,
            color: const Color(0xFF10B981),
            isPrimary: true,
          ),
      ],
    );
  }

  Widget _buildRecordButton() {
    return GestureDetector(
      onTap: _isRecording ? _stopRecording : _startRecording,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: _isRecording
              ? const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                )
              : const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                ),
          boxShadow: [
            BoxShadow(
              color:
                  (_isRecording
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF8B5CF6))
                      .withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          _isRecording ? Icons.stop : Icons.videocam,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isPrimary ? 32 : 24,
          vertical: isPrimary ? 16 : 12,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: isPrimary ? 24 : 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: isPrimary ? 16 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockModeControls() {
    if (_isProcessing) {
      return const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
      );
    }

    return _buildControlButton(
      icon: Icons.arrow_forward,
      label: 'Next Question',
      onTap: () async {
        setState(() => _isProcessing = true);
        try {
          var file = await _cameraController?.stopVideoRecording();
          _videoFile = file;
          await _submitInterview();
        } catch (e) {
          LoggerService.error("Mock Next Error", e);
        } finally {
          if (mounted) setState(() => _isProcessing = false);
        }
      },
      color: const Color(0xFF3B82F6),
      isPrimary: true,
    );
  }

  Widget _buildMobileHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (!widget.isEmbedded)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.categoryName,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingQuestionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Text(
        widget.question.questionText,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1F2937),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.5),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.fiber_manual_record, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            'REC ${_formatDuration(_secondsRecorded)}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
