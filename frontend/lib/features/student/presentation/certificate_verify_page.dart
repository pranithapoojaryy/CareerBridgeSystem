import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Public page — accessible at /verify?id=EH-XXXXXXXX
/// No authentication required. Works on web via QR scan.
class CertificateVerifyPage extends StatefulWidget {
  final String? certId;
  const CertificateVerifyPage({super.key, this.certId});

  @override
  State<CertificateVerifyPage> createState() => _CertificateVerifyPageState();
}

class _CertificateVerifyPageState extends State<CertificateVerifyPage> {
  String? _certId;
  _VerifyState _state = _VerifyState.loading;
  Map<String, dynamic>? _certData;

  @override
  void initState() {
    super.initState();
    _certId = widget.certId ?? _readCertIdFromUrl();
    if (_certId != null && _certId!.isNotEmpty) {
      _fetchCertificate(_certId!);
    } else {
      setState(() => _state = _VerifyState.invalid);
    }
  }

  String? _readCertIdFromUrl() {
    if (!kIsWeb) return null;
    try {
      return Uri.base.queryParameters['id'];
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchCertificate(String certId) async {
    try {
      final client = Supabase.instance.client;

      // Check student_course_enrollments (CareerBridge-issued certs)
      final enrollment = await client
          .from('student_course_enrollments')
          .select('is_completed, enrolled_at, completed_at, course_id, student_id')
          .eq('certificate_url', certId)
          .maybeSingle();

      if (enrollment != null) {
        final courseRes = await client
            .from('learning_courses')
            .select('title, provider_name')
            .eq('id', enrollment['course_id'])
            .maybeSingle();

        // Get student name from profiles table (works even when logged out)
        String studentName = 'Student';
        try {
          final profileRes = await client
              .from('profiles')
              .select('full_name')
              .eq('id', enrollment['student_id'])
              .maybeSingle();
          if (profileRes != null && profileRes['full_name'] != null) {
            studentName = profileRes['full_name'];
          }
        } catch (_) {}

        // Use completed_at (cert issue date) or fall back to enrolled_at
        final issueDate =
            enrollment['completed_at'] ?? enrollment['enrolled_at'];

        setState(() {
          _state = enrollment['is_completed'] == true
              ? _VerifyState.verified
              : _VerifyState.found;
          _certData = {
            'studentName': studentName,
            'courseName': courseRes?['title'] ?? 'CareerBridge Course',
            'issuer': courseRes?['provider_name'] ?? 'CareerBridge',
            'issueDate': issueDate,
            'certId': certId,
          };
        });
        return;
      }

      // Check student_certifications (external certs)
      final extCert = await client
          .from('student_certifications')
          .select(
            'certificate_name, issue_date, validation_status, issuer_name_snapshot',
          )
          .eq('certificate_id', certId)
          .maybeSingle();

      if (extCert != null) {
        final isVerified = extCert['validation_status'] == 'verified' ||
            extCert['validation_status'] == 'approved';
        setState(() {
          _state = isVerified ? _VerifyState.verified : _VerifyState.found;
          _certData = {
            'studentName': 'Student',
            'courseName': extCert['certificate_name'] ?? 'Certificate',
            'issuer': extCert['issuer_name_snapshot'] ?? 'CareerBridge',
            'issueDate': extCert['issue_date'],
            'certId': certId,
          };
        });
        return;
      }

      setState(() => _state = _VerifyState.notFound);
    } catch (e) {
      setState(() => _state = _VerifyState.notFound);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: _buildCard(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Soft off-white
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          // Outer "Soft" Shadow
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.3),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
          // Inner "Highlight" Shadow (Simulated)
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 20,
            offset: const Offset(-8, -8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo image
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/logo.png',
              height: 60,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.workspace_premium, size: 40, color: Color(0xFF1E3A8A)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'CERTIFICATE VERIFICATION',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF94A3B8),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),

          // State body
          if (_state == _VerifyState.loading) ...[
            const CircularProgressIndicator(color: Color(0xFF1D4ED8)),
            const SizedBox(height: 16),
            Text(
              'Verifying...',
              style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
            ),
          ] else if (_state == _VerifyState.invalid) ...[
            _buildBadge('⚠️', 'Invalid URL', const Color(0xFFF59E0B)),
            const SizedBox(height: 24),
            Text(
              'No certificate ID was found in the URL.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: const Color(0xFF64748B), height: 1.5),
            ),
          ] else if (_state == _VerifyState.notFound) ...[
          _buildBadge('❌', 'Not Found', const Color(0xFFEF4444)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _certId ?? 'Unknown',
                style: GoogleFonts.robotoMono(
                  fontSize: 14,
                  color: const Color(0xFF991B1B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This ID does not exist in our records.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
            ),
          ] else ...[
            _buildBadge(
              _state == _VerifyState.verified ? '✅' : '⚠️',
              _state == _VerifyState.verified
                  ? 'Verified'
                  : 'Found',
              _state == _VerifyState.verified
                  ? const Color(0xFF10B981)
                  : const Color(0xFFF59E0B),
            ),
            const SizedBox(height: 32),
            
            // Left-aligned data fields container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildField('AWARDED TO', _certData?['studentName'] ?? 'Student'),
                  const SizedBox(height: 16),
                  _buildField('COURSE', _certData?['courseName'] ?? '—'),
                  const SizedBox(height: 16),
                  _buildField('ISSUED BY', _certData?['issuer'] ?? 'CareerBridge'),
                  const SizedBox(height: 16),
                  _buildField('ISSUE DATE', _formatDate(_certData?['issueDate'])),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Text(
              'CERTIFICATE ID',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF94A3B8),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                _certData?['certId'] ?? _certId ?? '',
                style: GoogleFonts.robotoMono(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF475569),
                ),
              ),
            ),
          ],

          const SizedBox(height: 32),
          Text(
            'Verified by CareerBridge\ncareer-bridge-app.vercel.app',
            style: GoogleFonts.outfit(
              fontSize: 11, 
              color: const Color(0xFF94A3B8),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '—';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw.toString();
    }
  }
}

enum _VerifyState { loading, verified, found, notFound, invalid }
