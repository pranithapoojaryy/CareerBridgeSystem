import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../data/hiring_pipeline_repository.dart';
import '../domain/job_round.dart';

class RoundSubmissionScreen extends ConsumerStatefulWidget {
  final String applicationId;
  final JobRound round;

  const RoundSubmissionScreen({
    super.key,
    required this.applicationId,
    required this.round,
  });

  @override
  ConsumerState<RoundSubmissionScreen> createState() =>
      _RoundSubmissionScreenState();
}

class _RoundSubmissionScreenState extends ConsumerState<RoundSubmissionScreen> {
  final _textController = TextEditingController();
  CameraController? _cameraController;
  bool _isRecording = false;
  bool _isSubmitting = false;
  XFile? _recordedVideo;
  bool _cameraInitialized = false;
  String? _cameraError;
  PlatformFile? _selectedFile;
  final Map<int, int> _quizAnswers = {};

  @override
  void initState() {
    super.initState();
    if (widget.round.submissionType == 'video') {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraError = 'No cameras available');
        return;
      }

      // Prefer front camera
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: true,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _cameraInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cameraError = 'Camera initialization failed: $e');
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          widget.round.title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInstructions(),
            const SizedBox(height: 24),
            _buildSubmissionArea(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Instructions',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.round.instructions ??
                'Please complete the submission below.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionArea() {
    switch (widget.round.submissionType) {
      case 'video':
        return _buildVideoSubmission();
      case 'text':
        return _buildTextSubmission();
      case 'file':
        return _buildFileSubmission();
      case 'coding':
        return _buildCodingSubmission();
      case 'quiz':
        return _buildQuizSubmission();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildQuizSubmission() {
    final criteria = widget.round.evaluationCriteria;
    final questions =
        (criteria?['quiz_questions'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];

    if (questions.isEmpty) {
      return const Center(child: Text('No questions available for this quiz.'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final q = questions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question ${index + 1}',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  q['question'] ?? '',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ...(q['options'] as List<dynamic>).asMap().entries.map((entry) {
                  final optIndex = entry.key;
                  final optText = entry.value as String;
                  return RadioListTile<int>(
                    value: optIndex,
                    groupValue: _quizAnswers[index],
                    onChanged: (val) {
                      setState(() {
                        _quizAnswers[index] = val!;
                      });
                    },
                    title: Text(optText, style: GoogleFonts.outfit()),
                    activeColor: AppTheme.primaryColor,
                    contentPadding: EdgeInsets.zero,
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCodingSubmission() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Coding Challenge',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Paste your solution code URL (GitHub Gist, Repo) or code directly below.',
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            onChanged: (_) =>
                setState(() {}), // Trigger rebuild to update button state
            maxLines: 15,
            decoration: InputDecoration(
              hintText: 'Paste your code here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.all(16),
            ),
            style: GoogleFonts.firaCode(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSubmission() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20),
        ],
      ),
      child: Column(
        children: [
          // Camera preview
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildCameraPreview(),
            ),
          ),
          // Controls
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (_recordedVideo != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Video recorded successfully',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _recordedVideo = null);
                          },
                          child: const Text('Re-record'),
                        ),
                      ],
                    ),
                  ),
                if (_recordedVideo == null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _isRecording ? _stopRecording : _startRecording,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isRecording
                                ? Colors.red
                                : AppTheme.primaryColor,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (_isRecording
                                            ? Colors.red
                                            : AppTheme.primaryColor)
                                        .withValues(alpha: 0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isRecording ? Icons.stop : Icons.videocam,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_cameraError != null) {
      return Container(
        color: Colors.black87,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off, color: Colors.white54, size: 48),
              const SizedBox(height: 16),
              Text(
                _cameraError!,
                style: GoogleFonts.outfit(color: Colors.white54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (!_cameraInitialized || _cameraController == null) {
      return Container(
        color: Colors.black87,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return CameraPreview(_cameraController!);
  }

  Widget _buildTextSubmission() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Response',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            maxLines: 10,
            decoration: InputDecoration(
              hintText: 'Type your response here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            style: GoogleFonts.outfit(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFileSubmission() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          if (_selectedFile != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedFile!.name,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _selectedFile = null),
                  ),
                ],
              ),
            )
          else ...[
            Text(
              'Drag and drop files here',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'or click to browse',
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file),
              label: const Text('Select Files'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'zip'],
        withData: true,
      );

      if (result != null) {
        setState(() => _selectedFile = result.files.first);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      }
    }
  }

  Widget _buildSubmitButton() {
    final canSubmit =
        _recordedVideo != null ||
        _textController.text.isNotEmpty ||
        _selectedFile != null ||
        (widget.round.submissionType == 'quiz' &&
            _quizAnswers.isNotEmpty &&
            _quizAnswers.length ==
                ((widget.round.evaluationCriteria?['quiz_questions']
                            as List<dynamic>?)
                        ?.length ??
                    0)) ||
        widget.round.submissionType == 'none';

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: canSubmit && !_isSubmitting ? _submitResponse : null,
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Submit Response',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _startRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      await _cameraController!.startVideoRecording();
      setState(() => _isRecording = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (_cameraController == null ||
        !_cameraController!.value.isRecordingVideo) {
      return;
    }

    try {
      final video = await _cameraController!.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _recordedVideo = video;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to stop recording: $e')));
      }
    }
  }

  Future<void> _submitResponse() async {
    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(hiringPipelineProvider);

      String? videoUrl;
      if (_recordedVideo != null) {
        // Upload video to Supabase Storage
        final bytes = await _recordedVideo!.readAsBytes();
        videoUrl = await repo.uploadRoundVideo(
          fileBytes: bytes,
          applicationId: widget.applicationId,
          roundId: widget.round.id,
        );
      }

      List<String>? fileUrls;
      if (_selectedFile != null && _selectedFile!.bytes != null) {
        final url = await repo.uploadRoundFile(
          fileBytes: _selectedFile!.bytes!,
          applicationId: widget.applicationId,
          roundId: widget.round.id,
          extension: _selectedFile!.extension ?? 'file',
        );
        fileUrls = [url];
      }

      // Prepare coding/quiz response
      Map<String, dynamic>? codingResponse;

      if (widget.round.submissionType == 'coding' &&
          _textController.text.isNotEmpty) {
        codingResponse = {
          'code': _textController.text,
          'language': 'text',
          'submitted_at': DateTime.now().toIso8601String(),
        };
      } else if (widget.round.submissionType == 'quiz') {
        int score = 0;
        final questions =
            (widget.round.evaluationCriteria?['quiz_questions']
                as List<dynamic>?) ??
            [];

        // Calculate score
        for (int i = 0; i < questions.length; i++) {
          final q = questions[i] as Map<String, dynamic>;
          if (_quizAnswers[i] == q['correct_option']) {
            score++;
          }
        }

        codingResponse = {
          'type': 'quiz_result',
          'answers': _quizAnswers.map((k, v) => MapEntry(k.toString(), v)),
          'score': score,
          'total_questions': questions.length,
          'submitted_at': DateTime.now().toIso8601String(),
        };
      }

      await repo.submitRoundResponse(
        applicationId: widget.applicationId,
        roundId: widget.round.id,
        submissionType: widget.round.submissionType ?? 'text',
        textResponse:
            widget.round.submissionType != 'coding' &&
                widget.round.submissionType != 'quiz' &&
                _textController.text.isNotEmpty
            ? _textController.text
            : null,
        videoUrl: videoUrl,
        fileUrls: fileUrls,
        codingResponse: codingResponse,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Response submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
