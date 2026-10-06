import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/core/utils/logger_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/interview_models.dart';
import '../college/mock_interview_providers.dart';
import '../../data/interview_repository.dart';
import '../interview_providers.dart';

class ActiveMockSessionScreen extends ConsumerStatefulWidget {
  final String attemptId;
  final String mockId;

  const ActiveMockSessionScreen({
    super.key,
    required this.attemptId,
    required this.mockId,
  });

  @override
  ConsumerState<ActiveMockSessionScreen> createState() =>
      _ActiveMockSessionScreenState();
}

class _ActiveMockSessionScreenState
    extends ConsumerState<ActiveMockSessionScreen> {
  // State
  int _currentIndex = 0;
  bool _isSubmitting = false;
  bool _hasStarted = false;

  // Timer State
  int _timeLeftSeconds = 0;
  bool _timerInitialized = false;

  // Camera State (Continuous)
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isRecording = false;
  int _sessionDurationSeconds = 0;
  Timer? _sessionTimer;
  int _currentAnswerStartOffset = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _sessionTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      if (!kIsWeb) {
        await [Permission.camera, Permission.microphone].request();
      }
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: true,
      );

      await _cameraController!.initialize();
      // On Web, audio recording requires this extra step or sometimes specific codec handling
      if (kIsWeb) {
        try {
          await _cameraController!
              .prepareForVideoRecording(); // This method might verify audio permissions
        } catch (e) {
          LoggerService.error("Web Prepare Error", e);
          if (mounted)
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Web Prepare Error: $e")));
        }
      }

      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      LoggerService.error("Camera Init Error", e);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Camera Init Failed: $e")));
    }
  }

  void _startContinuousRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Camera Not Ready!")));
      return;
    }
    try {
      await _cameraController!.startVideoRecording();

      // Immediate check
      if (!_cameraController!.value.isRecordingVideo) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "WARNING: Camera reporting NOT recording after Start!",
              ),
            ),
          );
      } else {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Recording Started Successfully...")),
          );
      }

      _sessionTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (mounted) setState(() => _sessionDurationSeconds++);
      });
      if (mounted) setState(() => _isRecording = true);

      // Also start the Exam Countdown
      // _ensureTimerRunning(); // Moved to Start Button
    } catch (e) {
      LoggerService.error("Start Recording Error", e);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Start Recording Failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(mockQuestionsProvider(widget.mockId));
    final mockAsync = ref.watch(mockDetailProvider(widget.mockId));

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. BACKGROUND CAMERA (Always Visible)
          if (_isCameraInitialized && _cameraController != null)
            Center(child: CameraPreview(_cameraController!))
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // 2. MAIN CONTENT
          mockAsync.when(
            data: (mock) {
              if (!_timerInitialized) {
                _timeLeftSeconds = mock.timeLimitMinutes * 60;
                _timerInitialized = true;
              }

              return questionsAsync.when(
                data: (questions) {
                  if (questions.isEmpty) {
                    return Center(
                      child: Text(
                        "No questions.",
                        style: GoogleFonts.outfit(color: Colors.white),
                      ),
                    );
                  }

                  // INTRO LAYOUT
                  if (!_hasStarted) {
                    return _buildIntroOverlay(
                      questions.length,
                      mock.timeLimitMinutes,
                    );
                  }

                  // ACTIVE EXAM LAYOUT
                  final currentQ = questions[_currentIndex];
                  return SafeArea(
                    child: Stack(
                      children: [
                        // Top Bar
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: _buildTopBar(
                            questions.length,
                            _formatTime(_timeLeftSeconds),
                          ),
                        ),

                        // Bottom Controls Card
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min, // Wrap content
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  "Question ${_currentIndex + 1}",
                                  style: GoogleFonts.outfit(
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  currentQ.questionText,
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // CONTENT AREA (Video Note or Code Editor)
                                if (currentQ.questionType == 'coding')
                                  SizedBox(
                                    height:
                                        150, // Fixed height for code editor in HUD
                                    child: _CodingEditor(
                                      key: ValueKey(currentQ.id),
                                      onCodeChanged: (code) {
                                        /* ... */
                                      },
                                    ),
                                  ),

                                const SizedBox(height: 20),

                                // SUBMIT BUTTON
                                if (_isSubmitting)
                                  const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  )
                                else
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: () => _submitAnswer(
                                        currentQ,
                                        questions.length,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade600,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        _currentIndex == questions.length - 1
                                            ? "FINISH EXAM"
                                            : "NEXT QUESTION",
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox(),
                error: (e, s) => Center(
                  child: Text(
                    "Error: $e",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
            loading: () => const SizedBox(),
            error: (e, s) => Center(
              child: Text(
                "Error: $e",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(int totalQ, String timeString) {
    return Container(
      color: Colors.black45,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.fiber_manual_record,
                  color: Colors.white,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  "REC",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Icon(Icons.timer, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Text(
            timeString,
            style: GoogleFonts.firaCode(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            "Q ${_currentIndex + 1} / $totalQ",
            style: GoogleFonts.outfit(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroOverlay(int totalQuestions, int minutes) {
    return Center(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            Text(
              "Ready to Start?",
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "• This session is recorded continuously.\n"
              "• No pauses. Ensure you are ready.\n"
              "• $totalQuestions Questions in $minutes Minutes.",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 16,
                height: 1.5,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCameraInitialized
                    ? () async {
                        try {
                          await ref
                              .read(interviewRepositoryProvider)
                              .startMockAttempt(
                                attemptId: widget.attemptId,
                                mockId: widget.mockId,
                              );

                          if (mounted) {
                            setState(() {
                              _hasStarted = true;
                            });
                            // Start Timers immediately
                            _ensureTimerRunning();
                            _startContinuousRecording();
                            _currentAnswerStartOffset = 0;
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Failed to start mock: $e"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    : null, // Disable if not ready
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  disabledBackgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _isCameraInitialized
                      ? "START INTERVIEW"
                      : "Initializing Camera...",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitAnswer(InterviewQuestion q, int totalQ) async {
    setState(() => _isSubmitting = true);

    try {
      final endOffset = _sessionDurationSeconds;
      final startOffset = _currentAnswerStartOffset;
      final userId = Supabase.instance.client.auth.currentUser!.id;

      await Supabase.instance.client.from('student_interviews').insert({
        'student_id': userId,
        'question_id': q.id,
        'mock_attempt_id': widget.attemptId,
        'answer_start_offset': startOffset,
        'answer_end_offset': endOffset,
        'status': 'Pending',
        'ai_feedback': 'Mock Session Answer',
      });

      if (_currentIndex < totalQ - 1) {
        setState(() {
          _currentIndex++;
          _isSubmitting = false;
          _currentAnswerStartOffset = endOffset;
        });
      } else {
        await _finishExam();
      }
    } catch (e) {
      LoggerService.error("Submit Error", e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Submit Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _finishExam({bool auto = false}) async {
    _sessionTimer?.cancel();

    XFile? videoFile;

    // FORCE STOP ATTEMPT (Ignore isRecordingVideo flag if false)
    try {
      if (_cameraController != null) {
        LoggerService.debug("Attempting to stop recording...");
        try {
          // We stop blindly. If it wasn't recording, this might throw, which we catch.
          videoFile = await _cameraController!.stopVideoRecording();
        } catch (stopError) {
          LoggerService.error("Force Stop Exception", stopError);
          // Only complain if we really expected it to be recording
          if (mounted && _cameraController!.value.isRecordingVideo) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Stop Error: $stopError")));
          }
        }
      }
    } catch (e) {
      LoggerService.error("Outer Finish Error", e);
    }

    if (videoFile != null) {
      LoggerService.debug("Captured video: ${videoFile.path}");
    } else {
      // It's possible stopVideoRecording returns null or we moved to catch.
      // Warn user if we missed it.
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Warning: No video file returned from camera."),
          ),
        );
    }

    setState(() => _isSubmitting = true);

    try {
      String? videoPath;
      if (videoFile != null) {
        final repo = ref.read(interviewRepositoryProvider);
        try {
          videoPath = await repo.uploadVideo(videoFile);
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Video Uploaded: $videoPath")),
            );
        } catch (e) {
          throw "Upload Failed: $e";
        }
      }

      await Supabase.instance.client
          .from('mock_attempts')
          .update({
            'status': 'submitted',
            'submitted_at': DateTime.now().toIso8601String(),
            'video_path': videoPath,
          })
          .eq('id', widget.attemptId);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Interview Submitted Successfully!")),
        );
      }
    } catch (e) {
      LoggerService.error("Finish Error", e);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Submission Error: $e")));
      setState(() => _isSubmitting = false);
    }
  }

  void _ensureTimerRunning() {
    Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || !_hasStarted) {
        t.cancel();
        return;
      }
      if (_timeLeftSeconds > 0) {
        setState(() => _timeLeftSeconds--);
      } else {
        t.cancel();
        _finishExam(auto: true);
      }
    });
  }

  String _formatTime(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return "$m:$sec";
  }
}

class _CodingEditor extends StatefulWidget {
  final ValueChanged<String>? onCodeChanged;
  const _CodingEditor({super.key, this.onCodeChanged});
  @override
  State<_CodingEditor> createState() => _CodingEditorState();
}

class _CodingEditorState extends State<_CodingEditor> {
  final _ctrl = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _ctrl,
        maxLines: null,
        style: GoogleFonts.firaCode(fontSize: 14),
        onChanged: widget.onCodeChanged,
        decoration: const InputDecoration(
          hintText: "// Type your code...",
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
      ),
    );
  }
}
