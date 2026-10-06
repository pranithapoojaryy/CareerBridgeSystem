import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:frontend/core/utils/logger_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'interview_providers.dart';
import '../domain/interview_models.dart';
import 'student/student_mocks_screen.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LearningHubScreen extends ConsumerStatefulWidget {
  const LearningHubScreen({super.key});

  @override
  ConsumerState<LearningHubScreen> createState() => _LearningHubScreenState();
}

class _LearningHubScreenState extends ConsumerState<LearningHubScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(interviewCategoriesProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Learning Hub',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentMocksScreen()),
                );
              },
              icon: const Icon(Icons.assignment_turned_in_rounded, size: 20),
              label: Text(
                "Mock Exams",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                foregroundColor: AppTheme.secondaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty)
            return const Center(child: Text('No categories found'));

          // Initialize tab controller if needed or key changed
          if (_tabController == null ||
              _tabController!.length != categories.length) {
            _tabController = TabController(
              length: categories.length,
              vsync: this,
            );
          }

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    ),
                  ),
                  tabs: categories
                      .map(
                        (c) => Tab(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              c.name,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: categories
                      .map((c) => _ContentList(categoryId: c.id))
                      .toList(),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ContentList extends ConsumerWidget {
  final String categoryId;
  const _ContentList({required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(learningContentProvider(categoryId));

    return contentAsync.when(
      data: (contents) {
        if (contents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.library_books_outlined,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No content available yet.',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: contents.length,
          itemBuilder: (context, index) {
            final item = contents[index];
            return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: AppTheme.clayDecoration,
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: _buildIcon(item.type),
                      title: Text(
                        item.title,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.textColor,
                        ),
                      ),
                      subtitle: Text(
                        item.type,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      iconColor: AppTheme.primaryColor,
                      collapsedIconColor: Colors.grey[400],
                      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.description != null &&
                            item.description!.isNotEmpty) ...[
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 16),
                          Text(
                            "About this resource",
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.grey[400],
                              letterSpacing: 1,
                            ),
                          ).animate().fadeIn(delay: 100.ms),
                          const SizedBox(height: 8),
                          Text(
                            item.description!,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: AppTheme.textColor.withValues(alpha: 0.8),
                              height: 1.5,
                            ),
                          ).animate().fadeIn(delay: 200.ms),
                          const SizedBox(height: 20),
                        ],
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () => _openContent(context, item),
                            icon: Icon(_getActionIcon(item.type), size: 20),
                            label: Text(
                              _getActionLabel(item.type),
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor
                                  .withValues(alpha: 0.1),
                              foregroundColor: AppTheme.secondaryColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ).animate().scale(
                          delay: 300.ms,
                          curve: Curves.easeOutBack,
                        ),
                      ],
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 400.ms, delay: (index * 100).ms)
                .slideX(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading content')),
    );
  }

  IconData _getActionIcon(String type) {
    if (type == 'YouTube' || type == 'Video') return Icons.play_arrow;
    if (type == 'PDF') return Icons.visibility;
    return Icons.open_in_new;
  }

  String _getActionLabel(String type) {
    if (type == 'YouTube' || type == 'Video') return "Watch Video";
    if (type == 'PDF') return "View PDF";
    return "Open Link";
  }

  Widget _buildIcon(String type) {
    IconData icon;
    Color color;
    switch (type) {
      case 'Video':
      case 'YouTube':
        icon = Icons.play_circle_filled_rounded;
        color = const Color(0xFFFF4D4D);
        break;
      case 'PDF':
        icon = Icons.picture_as_pdf_rounded;
        color = const Color(0xFFF44336);
        break;
      case 'Article':
      default:
        icon = Icons.article_rounded;
        color = AppTheme.secondaryColor;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Future<void> _openContent(BuildContext context, LearningContent item) async {
    String url = item.url;
    LoggerService.debug("Opening Content. Type: ${item.type}, Path: $url");

    // Convert Storage Path to Signed URL if needed
    if (!url.startsWith('http')) {
      try {
        LoggerService.debug("Generating signed URL for path: $url");
        url = await Supabase.instance.client.storage
            .from('learning-content')
            .createSignedUrl(item.url, 3600); // 1 hour expiry
        LoggerService.debug("Generated Signed URL: $url");
      } catch (e) {
        LoggerService.error("Signed URL Gen Error", e);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Could not resolve file: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    } else {
      LoggerService.debug("URL is already http: $url");
    }

    if (!context.mounted) return;

    if (item.type == 'YouTube') {
      String? videoId;
      try {
        if (url.contains("youtu.be/")) {
          videoId = url.split("youtu.be/")[1];
        } else if (url.contains("v=")) {
          videoId = url.split("v=")[1].split("&")[0];
        } else if (url.contains("youtube.com/embed/")) {
          videoId = url.split("youtube.com/embed/")[1];
        }
        // Clean up ID
        if (videoId != null && videoId.contains("?")) {
          videoId = videoId.split("?")[0];
        }
      } catch (e) {
        LoggerService.error("Error extracting YouTube ID", e);
      }

      if (videoId != null) {
        showDialog(
          context: context,
          builder: (_) => _YouTubePlayerDialog(videoId: videoId!),
        );
      } else {
        _launchUrl(url);
      }
    } else if (item.type == 'PDF') {
      // Use Robust In-App Viewer
      showDialog(
        context: context,
        builder: (_) => _PdfViewerDialog(path: url),
      );
    } else if (item.type == 'Video') {
      // Use in-app Video player
      showDialog(
        context: context,
        builder: (ctx) => _VideoPlayerDialog(videoUrl: url),
      );
    } else {
      _launchUrl(url);
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _YouTubePlayerDialog extends StatefulWidget {
  final String videoId;
  const _YouTubePlayerDialog({required this.videoId});

  @override
  State<_YouTubePlayerDialog> createState() => _YouTubePlayerDialogState();
}

class _YouTubePlayerDialogState extends State<_YouTubePlayerDialog> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(showFullscreenButton: true),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Center(
        child: _DraggableHeaderWrapper(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: YoutubePlayer(controller: _controller, aspectRatio: 16 / 9),
          ),
        ),
      ),
    );
  }
}

class _VideoPlayerDialog extends StatefulWidget {
  final String videoUrl;
  const _VideoPlayerDialog({required this.videoUrl});

  @override
  State<_VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<_VideoPlayerDialog> {
  VideoPlayerController? _videoPlayerController;
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
      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      LoggerService.error("Video Player Init Error", e);
      if (mounted) setState(() => _isError = true);
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Center(
        child: _DraggableHeaderWrapper(
          child: _isError
              ? const AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Center(
                    child: Text(
                      "Failed to load video",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                )
              : _chewieController != null &&
                    _chewieController!.videoPlayerController.value.isInitialized
              ? AspectRatio(
                  aspectRatio: _chewieController!
                      .videoPlayerController
                      .value
                      .aspectRatio,
                  child: Chewie(controller: _chewieController!),
                )
              : const AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Center(child: CircularProgressIndicator()),
                ),
        ),
      ),
    );
  }
}

// Reusable Draggable Header Wrapper
class _DraggableHeaderWrapper extends StatelessWidget {
  final Widget child;
  const _DraggableHeaderWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 20, spreadRadius: 5),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[900]!.withValues(alpha: 0.9),
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.drag_handle_rounded,
                  color: Colors.white24,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  "Resource Preview",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                  tooltip: "Close",
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Content
          child,
        ],
      ),
    );
  }
}

class _PdfViewerDialog extends StatefulWidget {
  final String path;
  const _PdfViewerDialog({required this.path});

  @override
  State<_PdfViewerDialog> createState() => _PdfViewerDialogState();
}

class _PdfViewerDialogState extends State<_PdfViewerDialog> {
  bool _isLoading = true;
  String? _errorMessage;
  String? _signedUrl; 

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      if (widget.path.startsWith('http')) {
        _signedUrl = widget.path;
      } else {
        _signedUrl = await Supabase.instance.client.storage
            .from('learning-content')
            .createSignedUrl(widget.path, 3600);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      LoggerService.error("PDF Load Error", e);
      if (mounted) {
        setState(() {
          _errorMessage = "Could not resolve document: $e";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 800,
        height: 600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Text(
                    "Document Viewer",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const Spacer(),
                  if (_signedUrl != null)
                    TextButton.icon(
                      icon: const Icon(Icons.open_in_new),
                      label: const Text("Open in Browser"),
                      onPressed: () => launchUrl(
                        Uri.parse(_signedUrl!),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text("Preparing secure viewer..."),
                        ],
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _errorMessage = null;
                                    _isLoading = true;
                                  });
                                  _loadPdf();
                                },
                                child: const Text("Retry"),
                              ),
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: () => launchUrl(
                                  Uri.parse("https://docs.google.com/viewer?url=${Uri.encodeComponent(_signedUrl!)}"),
                                  mode: LaunchMode.externalApplication,
                                ),
                                child: const Text("Try Google Docs Viewer"),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          color: Colors.white,
                          child: HtmlWidget(
                            '<iframe src="https://docs.google.com/viewer?url=${Uri.encodeComponent(_signedUrl!)}&embedded=true" width="100%" height="100%" style="border: none;"></iframe>',
                            key: ValueKey(_signedUrl),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
