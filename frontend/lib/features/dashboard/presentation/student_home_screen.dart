import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../resume/data/resume_providers.dart';
import 'dashboard_controller.dart';

class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        final isExtraSmall = constraints.maxWidth < 600;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              _buildWelcomeHeader(),
              const SizedBox(height: 32),

              // Progress Trackers
              statsAsync.when(
                data: (stats) {
                  final cards = [
                    _buildProgressCard(
                      'Resume Strength',
                      stats.resumeStrength,
                      AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 24, height: 16),
                    _buildProgressCard(
                      'Profile Completion',
                      stats.profileCompletion,
                      AppTheme.secondaryColor,
                    ),
                    const SizedBox(width: 24, height: 16),
                    _buildProgressCard(
                      'Skill Score',
                      stats.skillScore,
                      Colors.orange,
                    ),
                  ];

                  if (isMobile) {
                    return Column(
                          children: [
                            cards[0],
                            cards[1], // SizedBox
                            cards[2],
                            cards[3], // SizedBox
                            cards[4],
                          ],
                        )
                        .animate()
                        .fadeIn(delay: 200.ms)
                        .slideY(begin: 0.2, end: 0);
                  }

                  return Row(
                    children: [
                      Expanded(child: cards[0]),
                      const SizedBox(width: 24),
                      Expanded(child: cards[2]),
                      const SizedBox(width: 24),
                      Expanded(child: cards[4]),
                    ],
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error loading stats: $err'),
              ),

              const SizedBox(height: 32),
              _buildResumeSection(context, ref),
              const SizedBox(height: 32),

              // Quick Access Grid
              Text(
                'Quick Access',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 16),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isExtraSmall
                    ? 2
                    : isMobile
                    ? 3
                    : 4, // 4 on desktop, 3 on tablet, 2 on mobile
                crossAxisSpacing: isMobile ? 16 : 24,
                mainAxisSpacing: isMobile ? 16 : 24,
                childAspectRatio: 1.5,
                children: [
                  _buildQuickActionCard(
                    'Resume Builder',
                    Icons.description_rounded,
                    AppTheme.primaryColor,
                  ),
                  _buildQuickActionCard(
                    'Job Listings',
                    Icons.work_rounded,
                    AppTheme.secondaryColor,
                  ),
                  _buildQuickActionCard(
                    'Aptitude Center',
                    Icons.psychology_rounded,
                    AppTheme.accentColor,
                  ),
                  _buildQuickActionCard(
                    'Skill Courses',
                    Icons.school_rounded,
                    Colors.teal[300]!,
                  ),
                  _buildQuickActionCard(
                    'Mock Interview',
                    Icons.mic_rounded,
                    Colors.orange[300]!,
                  ),
                  _buildQuickActionCard(
                    'Events',
                    Icons.event_rounded,
                    Colors.pink[300]!,
                  ),
                ],
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),

              // Bottom padding for scrolling
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, Neelu 👋',
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Let\'s make some progress today!',
              style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_none_rounded, color: Colors.grey),
              const SizedBox(width: 12),
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryColor,
                child: Icon(Icons.person, size: 20, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard(String title, double progress, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.clayDecoration.copyWith(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeSection(BuildContext context, WidgetRef ref) {
    final resumeUrlAsync = ref.watch(resumeUrlProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            blurRadius: 20,
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
              Text(
                'My Resume',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              resumeUrlAsync.when(
                data: (url) {
                  if (url != null) {
                    return Row(
                      children: [
                        IconButton(
                          onPressed: () => _viewResume(url),
                          icon: const Icon(Icons.visibility_rounded),
                          tooltip: 'View Resume',
                          color: AppTheme.primaryColor,
                        ),
                        IconButton(
                          onPressed: () => _deleteResume(context, ref),
                          icon: const Icon(Icons.delete_rounded),
                          tooltip: 'Delete Resume',
                          color: Colors.red[400],
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) =>
                    const Icon(Icons.error_outline, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 16),
          resumeUrlAsync.when(
            data: (url) {
              if (url != null) {
                return InkWell(
                  onTap: () => _viewResume(url),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf_rounded,
                            color: Colors.red,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Resume.pdf',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textColor,
                                ),
                              ),
                              Text(
                                'Click to view or update via upload',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: Colors.grey[600],
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
              return _buildUploadPlaceholder(context, ref);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _buildUploadPlaceholder(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadPlaceholder(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _uploadResume(context, ref),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            style: BorderStyle.solid, // Solid border for clarity
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_upload_rounded, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Upload your Resume (PDF)',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Max file size: 5MB',
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadResume(BuildContext context, WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true, // Required for web
      );

      if (result != null) {
        // Show uploading indicator
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Uploading resume...')));
        }

        if (kIsWeb) {
          final bytes = result.files.single.bytes;
          if (bytes != null) {
            await ref.read(resumeRepositoryProvider).uploadResume(bytes: bytes);
          } else {
            throw Exception("Failed to read file data");
          }
        } else if (result.files.single.path != null) {
          final file = File(result.files.single.path!);
          await ref.read(resumeRepositoryProvider).uploadResume(file: file);
        }

        // Refresh provider
        ref.invalidate(resumeUrlProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Resume uploaded successfully!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading resume: $e')));
      }
    }
  }

  Future<void> _deleteResume(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Resume?'),
        content: const Text(
          'Are you sure you want to delete your current resume?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(resumeRepositoryProvider).deleteResume();
        ref.invalidate(resumeUrlProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Resume deleted.')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _viewResume(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color) {
    return Container(
      decoration: AppTheme.clayDecoration.copyWith(color: Colors.white),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
