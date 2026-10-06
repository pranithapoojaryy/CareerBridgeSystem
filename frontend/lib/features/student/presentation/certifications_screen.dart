import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../data/certification_providers.dart';
import 'certificate_screen.dart';
import 'widgets/add_certification_dialog.dart';
import 'widgets/certification_card.dart';

class CertificationsScreen extends ConsumerStatefulWidget {
  const CertificationsScreen({super.key});

  @override
  ConsumerState<CertificationsScreen> createState() =>
      _CertificationsScreenState();
}

class _CertificationsScreenState extends ConsumerState<CertificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final certificationsAsync = ref.watch(certificationsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 900) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Certifications',
                              style: GoogleFonts.outfit(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Upload and validate your professional certifications',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _showSkillsBreakdown(),
                                  icon: const Icon(Icons.analytics_rounded),
                                  label: const Text('Analytics'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _showValidationInfo(context),
                                  icon: const Icon(Icons.info_outline_rounded),
                                  label: const Text('How it Works'),
                                ),
                                FilledButton.icon(
                                  onPressed: () =>
                                      _showAddCertificationDialog(),
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Add Certificate'),
                                ),
                              ],
                            ),
                          ],
                        );
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Certifications',
                                  style: GoogleFonts.outfit(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Upload and validate your professional certifications',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _showSkillsBreakdown(),
                                icon: const Icon(Icons.analytics_rounded),
                                label: const Text('Skills Analytics'),
                              ),
                              const SizedBox(width: 16),
                              OutlinedButton.icon(
                                onPressed: () => _showValidationInfo(context),
                                icon: const Icon(Icons.info_outline_rounded),
                                label: const Text('How it Works'),
                              ),
                              const SizedBox(width: 16),
                              FilledButton.icon(
                                onPressed: () => _showAddCertificationDialog(),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Add Certificate'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Stats Cards
                  certificationsAsync.when(
                    data: (certifications) => _buildStatsCards(certifications),
                    loading: () => _buildLoadingStats(),
                    error: (_, __) => _buildErrorStats(),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: AppTheme.primaryColor,
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'All Certificates'),
                  Tab(text: 'Validated'),
                  Tab(text: 'Pending'),
                ],
              ),
            ),

            // Content Area
            Expanded(
              child: certificationsAsync.when(
                data: (certifications) => TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCertificationsList(certifications, 'all'),
                    _buildCertificationsList(certifications, 'validated'),
                    _buildCertificationsList(certifications, 'pending'),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Database Setup Required',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'The certification system database tables are not set up yet.',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.red[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Error: $err',
                              style: GoogleFonts.robotoMono(
                                fontSize: 12,
                                color: Colors.red[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FilledButton.icon(
                                onPressed: () =>
                                    ref.invalidate(certificationsProvider),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Retry'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red[600],
                                ),
                              ),
                              const SizedBox(width: 16),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _showSetupInstructions(context),
                                icon: const Icon(Icons.help_outline),
                                label: const Text('Setup Guide'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red[600],
                                  side: BorderSide(color: Colors.red[600]!),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please run the certification system migration in Supabase SQL Editor',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.red[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(List<Map<String, dynamic>> certifications) {
    final totalCerts = certifications.length;
    final validatedCerts = certifications
        .where(
          (c) =>
              c['validation_status'] == 'verified' ||
              c['validation_status'] == 'college_verified',
        )
        .length;
    final pendingCerts = certifications
        .where((c) => c['validation_status'] == 'pending')
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          // Mobile/Tablet: 2x2 Grid
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Certificates',
                      totalCerts.toString(),
                      'Uploaded',
                      Icons.workspace_premium_rounded,
                      AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Validated',
                      validatedCerts.toString(),
                      '${totalCerts > 0 ? ((validatedCerts / totalCerts) * 100).round() : 0}% success rate',
                      Icons.verified_rounded,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Pending Review',
                      pendingCerts.toString(),
                      'Awaiting validation',
                      Icons.pending_rounded,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        // Desktop: 1 Row
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Certificates',
                totalCerts.toString(),
                'Uploaded',
                Icons.workspace_premium_rounded,
                AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Validated',
                validatedCerts.toString(),
                '${totalCerts > 0 ? ((validatedCerts / totalCerts) * 100).round() : 0}% success rate',
                Icons.verified_rounded,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Pending Review',
                pendingCerts.toString(),
                'Awaiting validation',
                Icons.pending_rounded,
                Colors.orange,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingStats() {
    return Row(
      children: List.generate(
        4,
        (index) => Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < 3 ? 16 : 0),
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600]),
          const SizedBox(width: 12),
          Text(
            'Unable to load certification statistics',
            style: GoogleFonts.outfit(color: Colors.red[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
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
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationsList(
    List<Map<String, dynamic>> allCertifications,
    String filter,
  ) {
    List<Map<String, dynamic>> filteredCertifications;

    switch (filter) {
      case 'verified':
        filteredCertifications = allCertifications
            .where(
              (c) =>
                  c['validation_status'] == 'verified' ||
                  c['validation_status'] == 'college_verified',
            )
            .toList();
        break;
      case 'pending':
        filteredCertifications = allCertifications
            .where((c) => c['validation_status'] == 'pending')
            .toList();
        break;
      default:
        filteredCertifications = allCertifications;
    }

    if (filteredCertifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.workspace_premium_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              filter == 'all'
                  ? 'No certificates uploaded yet'
                  : 'No ${filter} certificates',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload your first certificate to get started',
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showAddCertificationDialog(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Certificate'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Determine number of columns based on available width
          int crossAxisCount = 2;
          if (constraints.maxWidth > 1200) {
            crossAxisCount = 3;
          } else if (constraints.maxWidth < 800) {
            crossAxisCount = 1;
          }

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 1.2,
            ),
            itemCount: filteredCertifications.length,
            itemBuilder: (context, index) {
              final certification = filteredCertifications[index];
              return CertificationCard(
                certification: certification,
                onTap: () => _viewCertificationDetails(certification),
                onValidate: () => _validateCertification(certification),
                onDelete: () => _deleteCertification(certification),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddCertificationDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddCertificationDialog(),
    );
  }

  void _showSkillsBreakdown() {
    // Show detailed skills analytics
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Skills analytics coming soon!')),
    );
  }

  void _viewCertificationDetails(Map<String, dynamic> certification) async {
    final certUrl =
        certification['certificate_file_url'] ??
        certification['certificate_url'];

    // CareerBridge-issued course certificates store "EH-XXXXXXXX" in certificate_url
    // Navigate to the in-app viewer instead of trying to open as a URL
    final isCareerBridgeCert =
        certUrl != null &&
        (certUrl as String).startsWith('EH-');

    if (isCareerBridgeCert) {
      if (!mounted) return;
      final user = Supabase.instance.client.auth.currentUser;
      final userName = user?.userMetadata?['full_name'] ?? 'Student';
      final courseName =
          certification['certificate_name'] ??
          certification['issuer_name_snapshot'] ??
          'CareerBridge Course';
      final issuedAt =
          certification['issue_date'] != null
              ? DateTime.tryParse(certification['issue_date']) ?? DateTime.now()
              : DateTime.now();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CertificateScreen(
            studentName: userName,
            courseName: courseName,
            completionDate: issuedAt,
            certificateId: certUrl,
          ),
        ),
      );
      return;
    }

    // External certificates — open URL in browser
    if (certUrl != null && certUrl.isNotEmpty) {
      try {
        final url = Uri.parse(certUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unable to open certificate')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error opening certificate: $e')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No certificate file attached')),
        );
      }
    }
  }

  void _validateCertification(Map<String, dynamic> certification) async {
    try {
      await ref
          .read(certificationRepositoryProvider)
          .validateCertification(certification['id']);
      ref.invalidate(certificationsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Certificate validation initiated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Validation failed: $e')));
      }
    }
  }

  void _deleteCertification(Map<String, dynamic> certification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Certificate'),
        content: Text(
          'Are you sure you want to delete "${certification['certificate_name']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(certificationRepositoryProvider)
            .deleteCertification(certification['id']);
        ref.invalidate(certificationsProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Certificate deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
        }
      }
    }
  }

  void _showSetupInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.settings_rounded, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            const Text('Database Setup Required'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The certification system requires database tables to be created first.',
                style: GoogleFonts.outfit(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Text(
                'Steps to set up:',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '1. Open Supabase Dashboard → SQL Editor\n'
                '2. Copy content from: backend/migration_008_certification_system.sql\n'
                '3. Paste and run the migration\n'
                '4. Refresh this screen',
                style: GoogleFonts.outfit(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will create 16 certification providers and 25+ skills in the database.',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.invalidate(certificationsProvider);
            },
            child: const Text('Retry After Setup'),
          ),
        ],
      ),
    );
  }

  void _showValidationInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.verified_user_rounded, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            const Text('Certificate Validation Process'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Our Trust Engine automatically classifies and validates your certificates:',
                style: GoogleFonts.outfit(fontSize: 14),
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.check_circle,
                Colors.green,
                'Category A: Auto-Verified',
                'Top providers like Coursera, NPTEL, AWS. Verified instantly via URL/ID.',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.school,
                Colors.blue,
                'Category B: College Verified',
                'Certificates from your University. Sent to Faculty for manual approval.',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.verified_user_outlined,
                Colors.orange,
                'Category C: Partially Verified',
                'Internships & Companies. We verify domain and email authenticity.',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.help_outline,
                Colors.grey,
                'Category D: Unverified',
                'Other certificates. Low trust score until manually reviewed.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, Color color, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: color,
                ),
              ),
              Text(
                desc,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
