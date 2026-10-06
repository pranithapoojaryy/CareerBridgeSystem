import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../data/hiring_pipeline_repository.dart';
import '../domain/job_application.dart';
import '../domain/job_round.dart';
import '../domain/offer.dart';
import '../domain/round_submission.dart';
import 'round_submission_screen.dart';

class ApplicationTimelineScreen extends ConsumerStatefulWidget {
  final String applicationId;

  const ApplicationTimelineScreen({super.key, required this.applicationId});

  @override
  ConsumerState<ApplicationTimelineScreen> createState() =>
      _ApplicationTimelineScreenState();
}

class _ApplicationTimelineScreenState
    extends ConsumerState<ApplicationTimelineScreen> {
  JobApplication? _application;
  List<JobRound>? _rounds;
  List<RoundSubmission>? _submissions;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    debugPrint(
      '🔵 ApplicationTimelineScreen.initState() called for app ID: ${widget.applicationId}',
    );
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final repo = ref.read(hiringPipelineProvider);
      final app = await repo.getApplicationDetail(widget.applicationId);

      // Debug: Log application details
      debugPrint('=== Application Timeline Debug ===');
      debugPrint('Application ID: ${app.id}');
      debugPrint('Job ID: ${app.jobId}');
      debugPrint('Status: ${app.status}');
      debugPrint('Current Round: ${app.currentRound}');

      final rounds = await repo.getJobRounds(app.jobId);
      debugPrint('Rounds loaded: ${rounds.length}');
      for (var round in rounds) {
        debugPrint(
          '  Round ${round.roundNumber}: ${round.title} (${round.submissionType})',
        );
      }

      final submissions = await repo.getApplicationSubmissions(
        widget.applicationId,
      );
      debugPrint('Submissions loaded: ${submissions.length}');

      setState(() {
        _application = app;
        _rounds = rounds;
        _submissions = submissions;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Error loading application data: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading application: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Application Status',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _application == null
          ? const Center(child: Text('Application not found'))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildStatusBadge(),
                    const SizedBox(height: 32),
                    _buildTimelineSection(),
                    if (_application!.offer != null) ...[
                      const SizedBox(height: 32),
                      _buildOfferSection(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  // ... _buildHeader and _buildStatusBadge skipped (unchanged) ...

  Widget _buildHeader() {
    final job = _application!.job;
    return Column(
      children: [
        _buildActionableStatusBanner(),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.1),
                Colors.purple.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job?.title ?? 'Unknown Position',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (job?.organization != null)
                Text(
                  job!.organization!['name'] ?? '',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Applied on ${DateFormat.yMMMd().format(_application!.createdAt)}',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionableStatusBanner() {
    final status = _application!.status;
    Color bgColor;
    Color textColor;
    IconData icon;
    String message;
    String subMessage = '';

    switch (status) {
      case 'in_progress':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade900;
        icon = Icons.hourglass_top;
        message = 'Application in Progress';
        subMessage =
            'You have moved to the next round. Check the timeline below for actions.';
        break;
      case 'selected':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade900;
        icon = Icons.celebration;
        message = 'Congratulations!';
        subMessage =
            'You have been selected for this role. View your offer below.';
        break;
      case 'rejected':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade900;
        icon = Icons.cancel;
        message = 'Application Update';
        subMessage =
            'Thank you for your interest. Unfortunately, we will not be proceeding further.';
        break;
      case 'shortlisted':
        bgColor = Colors.amber.shade50;
        textColor = Colors.amber.shade900;
        icon = Icons.star;
        message = 'Shortlisted';
        subMessage =
            'Your profile has been shortlisted. Waiting for next steps from the recruiter.';
        break;
      default:
        return const SizedBox.shrink(); // No banner for 'applied', 'on_hold' etc if not needed
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                if (subMessage.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subMessage,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: textColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final status = _application!.status;
    final statusColors = {
      'applied': Colors.blue,
      'shortlisted': Colors.green,
      'in_progress': Colors.orange,
      'selected': Colors.green,
      'rejected': Colors.red,
      'on_hold': Colors.grey,
    };

    final color = statusColors[status] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(status), color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            _application!.displayStatus.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'applied':
        return Icons.send;
      case 'shortlisted':
        return Icons.star;
      case 'in_progress':
        return Icons.hourglass_empty;
      case 'selected':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'on_hold':
        return Icons.pause_circle;
      default:
        return Icons.info;
    }
  }

  Widget _buildTimelineSection() {
    if (_rounds == null || _rounds!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Column(
          children: [
            Icon(Icons.info_outline, color: Colors.orange[700], size: 48),
            const SizedBox(height: 16),
            Text(
              'No Hiring Rounds Configured',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The recruiter hasn\'t set up interview rounds for this position yet. You\'ll be notified when rounds are configured.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.orange[800],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INTERVIEW ROUNDS',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[500],
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(_rounds!.length, (index) {
          final round = _rounds![index];
          final isCompleted = round.roundNumber < _application!.currentRound;
          final isCurrent = round.roundNumber == _application!.currentRound;
          final isLast = index == _rounds!.length - 1;

          return _buildTimelineItem(
            round: round,
            isCompleted: isCompleted,
            isCurrent: isCurrent,
            isLast: isLast,
          );
        }),
      ],
    );
  }

  Widget _buildTimelineItem({
    required JobRound round,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
  }) {
    final hasSubmission =
        _submissions?.any((s) => s.roundId == round.id) ?? false;

    // If we have a submission, even if it's "current" round in DB,
    // it's effectively "waiting for review" from student perspective
    final isPendingReview = isCurrent && hasSubmission;

    final color = isCompleted
        ? Colors.green
        : isCurrent
        ? AppTheme.primaryColor
        : Colors.grey[400]!;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator (unchanged)
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : isCurrent
                    ? Container(
                        margin: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? Colors.green : Colors.grey[300],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppTheme.primaryColor.withValues(alpha: 0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCurrent
                      ? AppTheme.primaryColor.withValues(alpha: 0.3)
                      : Colors.grey[200]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              round.title,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isCurrent
                                    ? AppTheme.primaryColor
                                    : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              round.displayType,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isCurrent && round.submissionType != 'none')
                        if (hasSubmission)
                          Chip(
                            label: Text(
                              'Submitted',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor: Colors.green,
                            visualDensity: VisualDensity.compact,
                          )
                        else
                          FilledButton.icon(
                            onPressed: () => _openSubmission(round),
                            icon: const Icon(Icons.play_arrow, size: 18),
                            label: const Text('Start'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                            ),
                          ),
                    ],
                  ),
                  if (round.instructions != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INSTRUCTIONS:',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            round.instructions!,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferSection() {
    final offer = _application!.offer!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.withValues(alpha: 0.1),
            Colors.teal.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Offer Extended!',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildOfferDetail('Type', offer.offerType?.toUpperCase() ?? 'N/A'),
          if (offer.packageAmount != null)
            _buildOfferDetail(
              'Package',
              '${offer.currency} ${offer.packageAmount!.toStringAsFixed(0)} LPA',
            ),
          if (offer.location != null)
            _buildOfferDetail('Location', offer.location!),
          if (offer.joiningDate != null)
            _buildOfferDetail(
              'Joining Date',
              DateFormat.yMMMd().format(offer.joiningDate!),
            ),
          const SizedBox(height: 20),
          if (offer.canRespond)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _respondToOffer(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _respondToOffer(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Accept Offer'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildOfferDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openSubmission(JobRound round) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoundSubmissionScreen(
          applicationId: widget.applicationId,
          round: round,
        ),
      ),
    ).then((_) => _loadData());
  }

  Future<void> _respondToOffer(bool accept) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(accept ? 'Accept Offer?' : 'Decline Offer?'),
        content: Text(
          accept
              ? 'Are you sure you want to accept this offer?'
              : 'Are you sure you want to decline this offer? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: accept ? Colors.green : Colors.red,
            ),
            child: Text(accept ? 'Accept' : 'Decline'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(hiringPipelineProvider)
            .respondToOffer(_application!.offer!.id, accept);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(accept ? 'Offer accepted!' : 'Offer declined'),
              backgroundColor: accept ? Colors.green : Colors.orange,
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
}
