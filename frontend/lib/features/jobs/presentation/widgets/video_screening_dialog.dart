import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../../../../core/theme/app_theme.dart';

class VideoScreeningDialog extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final String jobTitle;

  const VideoScreeningDialog({
    super.key,
    required this.questions,
    required this.jobTitle,
  });

  @override
  State<VideoScreeningDialog> createState() => _VideoScreeningDialogState();
}


class _VideoScreeningDialogState extends State<VideoScreeningDialog> {
  final List<TextEditingController> _controllers = [];
  final List<String?> _videoUrls = [];
  int _currentStep = 0;

  // Camera state
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isRecording = false;
  bool _isUploading = false;
  int _recordDuration = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.questions.length; i++) {
      _controllers.add(TextEditingController());
      _videoUrls.add(null);
    }
    _initializeCameraIfNeeded();
  }

  Future<void> _initializeCameraIfNeeded() async {
    final questionType = widget.questions[_currentStep]['type'] ?? 'text';
    if (questionType == 'video' && !_isCameraInitialized) {
      await _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      // Request permissions
      final cameraStatus = await Permission.camera.request();
      final micStatus = await Permission.microphone.request();

      if (cameraStatus.isDenied || micStatus.isDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera and microphone permissions are required.')),
          );
        }
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: true,
      );

      await _cameraController!.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cameraController?.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (_cameraController == null || !_isCameraInitialized) return;
    try {
      await _cameraController!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _recordDuration = 0;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) setState(() => _recordDuration++);
      });
    } catch (e) {
      debugPrint('Start recording error: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (_cameraController == null || !_isRecording) return;
    try {
      final file = await _cameraController!.stopVideoRecording();
      _timer?.cancel();
      setState(() {
        _isRecording = false;
      });
      await _uploadVideo(file);
    } catch (e) {
      debugPrint('Stop recording error: $e');
    }
  }

  Future<void> _uploadVideo(XFile file) async {
    setState(() => _isUploading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final fileName = 'screening/${user.id}/${DateTime.now().millisecondsSinceEpoch}.mp4';
      final bytes = await file.readAsBytes();

      await Supabase.instance.client.storage
          .from('video_interviews')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(contentType: 'video/mp4'),
          );

      final url = Supabase.instance.client.storage
          .from('video_interviews')
          .getPublicUrl(fileName);

      setState(() {
        _videoUrls[_currentStep] = url;
      });
    } catch (e) {
      debugPrint('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _submit() {
    final type = widget.questions[_currentStep]['type'] ?? 'text';
    
    if (type == 'text' && _controllers[_currentStep].text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer the current question.')),
      );
      return;
    }
    
    if (type == 'video' && _videoUrls[_currentStep] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please record your video response.')),
      );
      return;
    }

    if (_currentStep < widget.questions.length - 1) {
      setState(() {
        _currentStep++;
      });
      _initializeCameraIfNeeded();
    } else {
      // Final submission
      final responses = <Map<String, dynamic>>[];
      for (int i = 0; i < widget.questions.length; i++) {
        final qType = widget.questions[i]['type'] ?? 'text';
        responses.add({
          'question': widget.questions[i]['question'],
          'type': qType,
          if (qType == 'text') 'answer': _controllers[i].text.trim(),
          if (qType == 'video') 'video_url': _videoUrls[i],
        });
      }
      Navigator.pop(context, responses);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        width: 500,
        decoration: AppTheme.clayDecoration.copyWith(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(Icons.video_call, color: AppTheme.primaryColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Screening Interview',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          widget.jobTitle,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Progress Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: List.generate(widget.questions.length, (index) {
                  return Expanded(
                    child: Container(
                      height: 6,
                      margin: EdgeInsets.only(
                        right: index == widget.questions.length - 1 ? 0 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: index <= _currentStep
                            ? AppTheme.primaryColor
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question ${_currentStep + 1} of ${widget.questions.length}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.questions[_currentStep]['question'] ?? '',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if ((widget.questions[_currentStep]['type'] ?? 'text') == 'text')
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TextField(
                          controller: _controllers[_currentStep],
                          maxLines: 8,
                          decoration: InputDecoration(
                            hintText: 'Type your answer here...',
                            hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
                            contentPadding: const EdgeInsets.all(16),
                            border: InputBorder.none,
                          ),
                          style: GoogleFonts.outfit(fontSize: 16, height: 1.5),
                        ),
                      )
                    else
                      // Video Recorder UI
                      Column(
                        children: [
                          Container(
                            height: 300,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (_isCameraInitialized)
                                    CameraPreview(_cameraController!)
                                  else
                                    const CircularProgressIndicator(),
                                  if (_isUploading)
                                    Container(
                                      color: Colors.black54,
                                      child: const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          CircularProgressIndicator(color: Colors.white),
                                          SizedBox(height: 12),
                                          Text('Uploading...', style: TextStyle(color: Colors.white)),
                                        ],
                                      ),
                                    ),
                                  if (_videoUrls[_currentStep] != null && !_isRecording)
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.check, color: Colors.white, size: 14),
                                            SizedBox(width: 4),
                                            Text('Recorded', style: TextStyle(color: Colors.white, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!_isRecording && !_isUploading)
                                ElevatedButton.icon(
                                  onPressed: _startRecording,
                                  icon: const Icon(Icons.videocam),
                                  label: Text(_videoUrls[_currentStep] == null ? 'Record Response' : 'Re-record'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                )
                              else if (_isRecording)
                                ElevatedButton.icon(
                                  onPressed: _stopRecording,
                                  icon: const Icon(Icons.stop),
                                  label: Text('Stop ($_recordDuration s)'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.red,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _currentStep--;
                        });
                      },
                      child: Text(
                        'Previous',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentStep == widget.questions.length - 1
                              ? 'Submit Application'
                              : 'Next Question',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentStep == widget.questions.length - 1
                              ? Icons.send
                              : Icons.arrow_forward,
                          size: 18,
                        ),
                      ],
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
