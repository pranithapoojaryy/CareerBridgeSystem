import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/college_providers.dart'; // Ensure this provides access to repository or create a new provider

// Provider to fetch certifications with optional status filter
final certificationsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String?>((ref, status) async {
      final repository = ref.watch(collegeRepositoryProvider);
      final college = await ref.watch(currentCollegeProvider.future);

      if (college == null) return [];

      return await repository.getAllCertifications(
        collegeId: college['id'],
        status: status,
      );
    });

class CertificateVerificationScreen extends ConsumerStatefulWidget {
  const CertificateVerificationScreen({super.key});

  @override
  ConsumerState<CertificateVerificationScreen> createState() =>
      _CertificateVerificationScreenState();
}

class _CertificateVerificationScreenState
    extends ConsumerState<CertificateVerificationScreen>
    with SingleTickerProviderStateMixin {
  // To track processing state for individual items (optional, or rely on refresh)
  final Set<String> _processingIds = {};
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String? _getStatusFilter() {
    switch (_currentTabIndex) {
      case 0:
        return null; // All
      case 1:
        return 'pending';
      case 2:
        return 'college_verified';
      case 3:
        return 'rejected';
      default:
        return null;
    }
  }

  Future<void> _handleAction(
    String certId,
    String action, {
    String? reason,
  }) async {
    setState(() => _processingIds.add(certId));
    try {
      final repository = ref.read(collegeRepositoryProvider);

      await repository.updateCertificationStatus(
        certificationId: certId,
        status: action == 'approve' ? 'college_verified' : 'rejected',
        rejectionReason: reason,
      );

      // Refresh list
      ref.invalidate(certificationsProvider);

      // Switch to appropriate tab
      if (mounted) {
        if (action == 'approve') {
          _tabController.animateTo(2); // Approved tab (index 2)
        } else {
          _tabController.animateTo(3); // Rejected tab (index 3)
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'approve'
                  ? 'Certificate Approved'
                  : 'Certificate Rejected',
            ),
            backgroundColor: action == 'approve' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(certId));
      }
    }
  }

  void _showRejectDialog(String certId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Certificate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'e.g., Image unclear, Invalid details',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(context);
              _handleAction(
                certId,
                'reject',
                reason: reasonController.text.trim(),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final certsAsync = ref.watch(certificationsProvider(_getStatusFilter()));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Certificate Verification',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: certsAsync.when(
        data: (certs) {
          if (certs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green[200],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'All clear! No pending requests.',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: certs.length,
            itemBuilder: (context, index) {
              final cert = certs[index];
              return _buildCertCard(cert);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildCertCard(Map<String, dynamic> cert) {
    final isProcessing = _processingIds.contains(cert['id']);
    // student and provider maps removed as we now use flat structure from view
    final certUrl = cert['certificate_file_url'] ?? cert['certificate_url'];
    final issuer =
        cert['issuer_name_snapshot'] ??
        cert['provider_name'] ??
        'Unknown Provider';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Student Info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  backgroundImage: cert['profile_photo_url'] != null
                      ? NetworkImage(cert['profile_photo_url'])
                      : null,
                  child: cert['profile_photo_url'] == null
                      ? Text((cert['student_name']?[0] ?? 'S').toUpperCase())
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cert['student_name'] ?? 'Unknown Student',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (cert['enroll_no'] != null)
                      Text(
                        'ID: ${cert['enroll_no']}',
                        style: GoogleFonts.outfit(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            // Cert Info
            Text(
              cert['certificate_name'] ?? 'Untitled Certificate',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            Text(
              'Issued by: $issuer',
              style: GoogleFonts.outfit(color: Colors.grey[700]),
            ),
            if (cert['certificate_id'] != null)
              Text(
                'Cert ID: ${cert['certificate_id']}',
                style: GoogleFonts.outfit(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),

            const SizedBox(height: 16),

            // Proof
            if (certUrl != null)
              OutlinedButton.icon(
                onPressed: () => launchUrl(Uri.parse(certUrl)),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('View Proof'),
              )
            else
              const Text(
                'No proof attachment',
                style: TextStyle(color: Colors.amber),
              ),

            const SizedBox(height: 16),

            // Actions - only show for pending certificates
            if (cert['validation_status'] == 'pending')
              if (isProcessing)
                const Center(child: LinearProgressIndicator())
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showRejectDialog(cert['id']),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _handleAction(cert['id'], 'approve'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Approve'),
                      ),
                    ),
                  ],
                )
            else
              // Show status badge for non-pending certificates
              _buildStatusBadge(cert['validation_status']),
            if (cert['validation_status'] == 'rejected' &&
                cert['rejection_reason'] != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[100]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REJECTION REASON:',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.red[800],
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cert['rejection_reason'],
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.red[900],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final bool isApproved = ['verified', 'approved', 'college_verified'].contains(status);
    final Color baseColor = isApproved ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final Color softBg = isApproved ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
    final Color textColor = isApproved ? const Color(0xFF065F46) : const Color(0xFF991B1B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: softBg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          // Outer Soft Shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          // Inner White "Clay" Highlight
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 10,
            offset: const Offset(-4, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isApproved ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 18,
            color: baseColor,
          ),
          const SizedBox(width: 8),
          Text(
            isApproved ? 'APPROVED' : 'REJECTED',
            style: GoogleFonts.outfit(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
