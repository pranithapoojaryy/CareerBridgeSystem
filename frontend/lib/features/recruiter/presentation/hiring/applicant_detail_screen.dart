import 'package:flutter/material.dart';
import 'dart:convert'; // Added for jsonDecode
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../jobs/data/hiring_pipeline_repository.dart';
import '../../../jobs/domain/job_application.dart';
import '../../../jobs/domain/job_round.dart';
import '../../../jobs/domain/round_submission.dart';
import '../../../../features/networking/presentation/screens/network_profile_view.dart';

class ApplicantDetailScreen extends ConsumerStatefulWidget {
  final String applicationId;

  const ApplicantDetailScreen({super.key, required this.applicationId});

  @override
  ConsumerState<ApplicantDetailScreen> createState() =>
      _ApplicantDetailScreenState();
}

class _ApplicantDetailScreenState extends ConsumerState<ApplicantDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  JobApplication? _application;
  List<JobRound>? _rounds;
  List<RoundSubmission>? _submissions;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final repo = ref.read(hiringPipelineProvider);
      final app = await repo.getApplicationDetail(widget.applicationId);
      final rounds = await repo.getJobRounds(app.jobId);
      final submissions = await repo.getApplicationSubmissions(
        widget.applicationId,
      );

      setState(() {
        _application = app;
        _rounds = rounds;
        _submissions = submissions;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_application == null) {
      return const Scaffold(body: Center(child: Text('Application not found')));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return _buildDesktopLayout();
        }
        return _buildMobileLayout();
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Match overall theme background
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align to top
        children: [
          // LEFT SIDEBAR: Submissions & Actions (Fixed Width)
          Container(
            width: 400, // Slightly wider for better readability
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                // Clean Header for Sidebar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade100),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Back to Applications',
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Application Status',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content: Submissions List
                Expanded(
                  child: _buildSubmissionsTab(), // Reusing the list builder
                ),

                // Footer: Action Bar (Always visible at bottom of sidebar)
                if (_application!.isActive)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade100),
                      ),
                    ),
                    child: _buildSidebarActionBar(), // New compact action bar
                  ),
              ],
            ),
          ),

          // RIGHT CONTENT: Student Profile (Expanded)
          Expanded(
            child: _application?.student == null
                ? const Center(child: Text('Student profile not available'))
                : NetworkProfileView(
                    userId: _application!.student!['id'],
                    userName:
                        _application!.student!['full_name'] ?? 'Applicant',
                    userAvatar: _application!.student!['profile_photo_url'],
                    userRole: 'student',
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _application?.student?['full_name'] ?? 'Applicant',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          unselectedLabelColor: Colors.grey,
          labelColor: AppTheme.primaryColor,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Submissions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        // Swap order: Profile first on mobile standard
        children: [
          _application?.student == null
              ? const Center(child: Text('Student profile not available'))
              : NetworkProfileView(
                  userId: _application!.student!['id'],
                  userName: _application!.student!['full_name'] ?? 'Applicant',
                  userAvatar: _application!.student!['profile_photo_url'],
                  userRole: 'student',
                ),
          _buildSubmissionsTab(),
        ],
      ),
      bottomNavigationBar: _application != null && _application!.isActive
          ? _buildActionBar()
          : null,
    );
  }

  // Helper for Sidebar Actions to fit width
  Widget _buildSidebarActionBar() {
    // Reusing logic from _buildActionBar but optimized for vertical/sidebar width if needed
    // Actually standard _buildActionBar is row-based, might be too wide for 400px if labels are long.
    // Let's try reusing _buildActionBar but ensuring it wraps or fits.
    return _buildActionBar();
  }


  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error opening URL: $e');
    }
  }

  Widget _buildSubmissionsTab() {
    if (_rounds == null || _rounds!.isEmpty) {
      return const Center(child: Text('No rounds defined for this job'));
    }

    // Sort rounds by number
    final rounds = List<JobRound>.from(_rounds!)
      ..sort((a, b) => a.roundNumber.compareTo(b.roundNumber));

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // 1. Initial Screening Responses
        if (_application!.videoResponses != null &&
            _application!.videoResponses!.isNotEmpty) ...[
          _buildScreeningResponses(),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 32),
        ],

        // 2. Rounds Timeline
        ...rounds.map((round) {
          final index = rounds.indexOf(round);
        final submission = _submissions?.firstWhere(
          (s) => s.roundId == round.id,
          orElse: () => RoundSubmission(
            id: '',
            applicationId: '',
            roundId: '',
            submittedAt: DateTime(1970),
            status: 'unknown',
            submissionType: 'none',
          ),
        );

        final hasSubmission =
            submission != null && submission.status != 'unknown';
        final isCurrentRound =
            _application != null &&
            _application!.currentRound == round.roundNumber;
        final isPastRound =
            _application != null &&
            _application!.currentRound > round.roundNumber;
        final isUpcoming =
            _application != null &&
            _application!.currentRound < round.roundNumber;

        // Determine step status
        Color statusColor;
        String statusText;
        IconData statusIcon;

        if (hasSubmission) {
          statusColor = submission.status == 'passed'
              ? Colors.green
              : submission.status == 'failed'
              ? Colors.red
              : Colors.orange;
          statusText = submission.status.toUpperCase();
          statusIcon = submission.status == 'passed'
              ? Icons.check_circle
              : submission.status == 'failed'
              ? Icons.cancel
              : Icons.access_time_filled;
        } else if (isCurrentRound) {
          statusColor = Colors.blue;
          statusText = 'IN PROGRESS';
          statusIcon = Icons.play_circle_fill;
        } else if (isPastRound) {
          statusColor = Colors.grey;
          statusText = 'SKIPPED';
          statusIcon = Icons.skip_next;
        } else {
          statusColor = Colors.grey[300]!;
          statusText = 'UPCOMING';
          statusIcon = Icons.lock_outline;
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline Line & Dot
              Column(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: hasSubmission || isCurrentRound
                          ? statusColor.withValues(alpha: 0.1)
                          : Colors.grey[100],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: hasSubmission || isCurrentRound
                            ? statusColor
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      statusIcon,
                      size: 16,
                      color: hasSubmission || isCurrentRound
                          ? statusColor
                          : Colors.grey[400],
                    ),
                  ),
                  if (index != rounds.length - 1)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isPastRound || (isCurrentRound && hasSubmission)
                            ? AppTheme.primaryColor.withValues(alpha: 0.3)
                            : Colors.grey[200],
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrentRound
                                ? Colors.blue.withValues(alpha: 0.3)
                                : Colors.grey[200]!,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Round ${round.roundNumber}: ${round.title}',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: isUpcoming
                                              ? Colors.grey[500]
                                              : Colors.black87,
                                        ),
                                      ),
                                      if (hasSubmission)
                                        Text(
                                          'Submitted: ${_formatDate(submission.submittedAt.toIso8601String())}',
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  enabled: hasSubmission,
                                  onSelected: (value) {
                                    if (submission != null) {
                                      _evaluateSubmission(submission.id, value);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'pass',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Mark as Passed'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'fail',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.cancel,
                                            color: Colors.red,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Mark as Failed'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'reviewed',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.visibility,
                                            color: Colors.blue,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Mark as Reviewed'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          statusText,
                                          style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: statusColor,
                                          ),
                                        ),
                                        if (hasSubmission &&
                                            submission.status == 'pending') ...[
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.arrow_drop_down,
                                            size: 12,
                                            color: statusColor,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (isCurrentRound && !hasSubmission) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue[100]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.info_outline,
                                          size: 16,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Candidate Task',
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Colors.blue[900],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      round.instructions ??
                                          'No specific instructions provided.',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        color: Colors.blue[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (hasSubmission) ...[
                              const SizedBox(height: 16),
                              if (submission.textResponse != null)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    submission.textResponse!,
                                    style: GoogleFonts.outfit(fontSize: 14),
                                  ),
                                ),
                              if (submission.fileUrls != null &&
                                  submission.fileUrls!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                ...submission.fileUrls!.map(
                                  (url) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: OutlinedButton.icon(
                                      onPressed: () => _openUrl(url),
                                      icon: const Icon(
                                        Icons.description,
                                        size: 16,
                                      ),
                                      label: Text(
                                        'View Attachment',
                                        style: GoogleFonts.outfit(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              if (submission.videoUrl != null) ...[
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      _playVideo(submission.videoUrl!),
                                  icon: const Icon(
                                    Icons.play_circle_outline,
                                    size: 16,
                                  ),
                                  label: Text(
                                    'Watch Video',
                                    style: GoogleFonts.outfit(fontSize: 12),
                                  ),
                                ),
                              ],
                              if (submission.codingResponse != null) ...[
                                const SizedBox(height: 8),
                                Builder(
                                  builder: (context) {
                                    final response = submission.codingResponse!;
                                    final isQuiz =
                                        response['type'] == 'quiz_result';

                                    return OutlinedButton.icon(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text(
                                              isQuiz
                                                  ? 'Quiz Result'
                                                  : 'Submitted Code',
                                              style: GoogleFonts.outfit(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            content: SingleChildScrollView(
                                              child: Container(
                                                width: double.maxFinite,
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[100],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.grey[300]!,
                                                  ),
                                                ),
                                                child: isQuiz
                                                    ? Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            'Score: ${response['score']} / ${response['total_questions']}',
                                                            style:
                                                                GoogleFonts.outfit(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 18,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                          Text(
                                                            'Submitted at: ${_formatDate(response['submitted_at'] ?? '')}',
                                                            style:
                                                                GoogleFonts.outfit(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .grey[600],
                                                                ),
                                                          ),
                                                        ],
                                                      )
                                                    : SelectableText(
                                                        response['code'] ??
                                                            'No code found',
                                                        style:
                                                            GoogleFonts.firaCode(
                                                              fontSize: 13,
                                                            ),
                                                      ),
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Close'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      icon: Icon(
                                        isQuiz ? Icons.fact_check : Icons.code,
                                        size: 16,
                                      ),
                                      label: Text(
                                        isQuiz
                                            ? 'View Quiz Result'
                                            : 'View Code',
                                        style: GoogleFonts.outfit(fontSize: 12),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
      ],
    );
  }

  Widget _buildScreeningResponses() {
    final responses = _application!.videoResponses!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.assignment_turned_in,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Initial Screening',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...responses.map((res) {
          final type = res['type'] ?? 'text';
          final question = res['question'] ?? 'No Question';
          final answer = res['answer'] ?? '';
          final videoUrl = res['video_url'] as String?;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                if (type == 'text')
                  Text(
                    answer,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  )
                else if (type == 'video' && videoUrl != null)
                  ElevatedButton.icon(
                    onPressed: () => _playVideo(videoUrl),
                    icon: const Icon(Icons.play_circle_fill, size: 20),
                    label: const Text('Watch Video Response'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                      foregroundColor: Colors.red,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )
                else
                  Text(
                    'No response provided.',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _rejectApplication,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Reject'),
            ),
          ),
          const SizedBox(width: 12),
          if (_application!.status == 'applied')
            Expanded(
              child: FilledButton(
                onPressed: _shortlistApplication,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Shortlist'),
              ),
            ),
          if (_application!.status == 'shortlisted' ||
              _application!.status == 'in_progress') ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _progressToNextRound,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Next Round'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _selectCandidate,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Select'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<dynamic> _parseList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data;
    if (data is String) {
      if (data.isEmpty) return [];
      try {
        final decoded = jsonDecode(data);
        if (decoded is List) return decoded;
        return [decoded]; // treat as single item list
      } catch (_) {
        return [data]; // treat as single item list
      }
    }
    return [data]; // fallback
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (_) {
      return '';
    }
  }

  void _playVideo(String url) {
    showDialog(
      context: context,
      builder: (context) => _VideoPlayerDialog(videoUrl: url),
    );
  }

  Future<void> _shortlistApplication() async {
    try {
      await ref
          .read(hiringPipelineProvider)
          .shortlistApplication(widget.applicationId);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Applicant shortlisted!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _rejectApplication() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Application?'),
        content: const Text(
          'Are you sure you want to reject this application?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(hiringPipelineProvider)
            .rejectApplication(widget.applicationId);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Application rejected')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _progressToNextRound() async {
    try {
      await ref
          .read(hiringPipelineProvider)
          .progressToNextRound(widget.applicationId);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Moved to next round!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _selectCandidate() async {
    // Show offer dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _SelectCandidateDialog(),
    );

    if (result != null) {
      try {
        await ref
            .read(hiringPipelineProvider)
            .selectCandidate(
              applicationId: widget.applicationId,
              offerType: result['offer_type'],
              packageAmount: result['package_amount'],
              joiningDate: result['joining_date'],
              location: result['location'],
            );
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Candidate selected and offer extended!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _evaluateSubmission(String submissionId, String decision) async {
    try {
      await ref
          .read(hiringPipelineProvider)
          .evaluateSubmission(submissionId: submissionId, decision: decision);

      print('Evaluation submitted, reloading data...');
      await _loadData();
      print('Data reloaded.');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission marked as ${decision.toUpperCase()}'),
            backgroundColor: decision == 'pass' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

class _SelectCandidateDialog extends StatefulWidget {
  @override
  State<_SelectCandidateDialog> createState() => _SelectCandidateDialogState();
}

class _SelectCandidateDialogState extends State<_SelectCandidateDialog> {
  final _packageController = TextEditingController();
  final _locationController = TextEditingController();
  String _offerType = 'full_time';
  DateTime? _joiningDate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Extend Offer',
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _offerType,
              decoration: InputDecoration(
                labelText: 'Offer Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'full_time', child: Text('Full Time')),
                DropdownMenuItem(
                  value: 'internship',
                  child: Text('Internship'),
                ),
                DropdownMenuItem(value: 'ppo', child: Text('PPO')),
                DropdownMenuItem(value: 'contract', child: Text('Contract')),
              ],
              onChanged: (v) => setState(() => _offerType = v!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _packageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Package (LPA)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(
                _joiningDate == null
                    ? 'Select Joining Date'
                    : DateFormat.yMMMd().format(_joiningDate!),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _joiningDate = date);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, {
              'offer_type': _offerType,
              'package_amount': double.tryParse(_packageController.text),
              'location': _locationController.text.isNotEmpty
                  ? _locationController.text
                  : null,
              'joining_date': _joiningDate,
            });
          },
          child: const Text('Extend Offer'),
        ),
      ],
    );
  }
}

class _VideoPlayerDialog extends StatefulWidget {
  final String videoUrl;

  const _VideoPlayerDialog({super.key, required this.videoUrl});

  @override
  State<_VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<_VideoPlayerDialog> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

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
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error initializing video player: $e');
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: AspectRatio(
          aspectRatio: _videoPlayerController.value.isInitialized
              ? _videoPlayerController.value.aspectRatio
              : 16 / 9,
          child: Stack(
            children: [
              if (_chewieController != null &&
                  _chewieController!.videoPlayerController.value.isInitialized)
                Chewie(controller: _chewieController!)
              else
                const Center(child: CircularProgressIndicator()),

              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
