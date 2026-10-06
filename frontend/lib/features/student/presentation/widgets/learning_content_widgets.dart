import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../../core/utils/logger_service.dart';

/// A wrapper around Chewie/VideoPlayer to handle direct file/network videos
/// Triggers [onVideoCompleted] when the video ends.
class CustomVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final VoidCallback? onVideoCompleted;

  const CustomVideoPlayer({
    super.key,
    required this.videoUrl,
    this.onVideoCompleted,
  });

  @override
  State<CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Error playing video: $errorMessage',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );

      // Listen for completion
      _videoPlayerController.addListener(_checkCompletion);

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _isError = true);
      LoggerService.error('Video initialization error', e);
    }
  }

  void _checkCompletion() {
    if (_videoPlayerController.value.isInitialized &&
        !_videoPlayerController.value.isPlaying &&
        _videoPlayerController.value.position >=
            _videoPlayerController.value.duration) {
      widget.onVideoCompleted?.call();
    }
  }

  @override
  void dispose() {
    _videoPlayerController.removeListener(_checkCompletion);
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return Container(
        height: 220,
        color: Colors.black,
        child: const Center(
          child: Text(
            'Could not load video',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    if (_chewieController != null &&
        _chewieController!.videoPlayerController.value.isInitialized) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black,
        ),
        clipBehavior: Clip.hardEdge,
        child: Chewie(controller: _chewieController!),
      );
    }

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

/// A wrapper around youtube_player_iframe
class CustomYouTubePlayer extends StatefulWidget {
  final String videoUrl;
  final VoidCallback? onVideoCompleted;

  const CustomYouTubePlayer({
    super.key,
    required this.videoUrl,
    this.onVideoCompleted,
  });

  @override
  State<CustomYouTubePlayer> createState() => _CustomYouTubePlayerState();
}

class _CustomYouTubePlayerState extends State<CustomYouTubePlayer> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();

    // Extract ID from various YT formats
    final videoId = _extractVideoId(widget.videoUrl);

    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId ?? '',
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        strictRelatedVideos: true,
      ),
    );

    // Listen to state changes for completion
    _controller.setFullScreenListener((isFullScreen) {
      // Handle fullscreen logic if needed
    });

    // Currently, the youtube_player_iframe package event stream for 'ended' state
    // can be tricky. We might need to listen to the stream manually if supported.
    // For now, we rely on user interaction or advanced stream listening.
    // NOTE: reliable 'onEnded' in iframe is limited. We will add a manual listener check.
  }

  String? _extractVideoId(String url) {
    // Basic regex for standard Youtube URLs
    final RegExp regExp = RegExp(
      r'.*(?:youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=)([^#\&\?]*).*',
      caseSensitive: false,
      multiLine: false,
    );
    final match = regExp.firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
    return null;
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_extractVideoId(widget.videoUrl) == null) {
      return Container(
        height: 220,
        color: Colors.black,
        child: const Center(
          child: Text(
            'Invalid YouTube URL',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black,
      ),
      clipBehavior: Clip.hardEdge,
      child: YoutubePlayer(controller: _controller, aspectRatio: 16 / 9),
    );
  }
}

/// A wrapper around Syncfusion PDF Viewer
class CustomPDFViewer extends StatelessWidget {
  final String pdfUrl;
  final VoidCallback? onDocumentRead;

  const CustomPDFViewer({super.key, required this.pdfUrl, this.onDocumentRead});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500, // Fixed height for PDF view in module flow
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: SfPdfViewer.network(
        pdfUrl,
        onDocumentLoaded: (details) {
          // If it's a short doc, we might consider it "read" immediately
          // But usually we wait for scroll.
          // For simplicity, we trigger read callback on load for now
          // or leave it to the user to click "Mark Complete".
          // Better: just load it. The parent widget handles "Mark Complete" button.
        },
        onPageChanged: (PdfPageChangedDetails details) {
          if (details.isLastPage) {
            onDocumentRead?.call();
          }
        },
      ),
    );
  }
}
