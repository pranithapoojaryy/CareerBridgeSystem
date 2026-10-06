import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/providers/email_service_provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../data/college_providers.dart';

class InviteStudentsDialog extends ConsumerStatefulWidget {
  const InviteStudentsDialog({super.key});

  @override
  ConsumerState<InviteStudentsDialog> createState() => _InviteStudentsDialogState();
}

class _InviteStudentsDialogState extends ConsumerState<InviteStudentsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailsController = TextEditingController();
  final _csvController = TextEditingController();
  final _customMessageController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailsController.dispose();
    _csvController.dispose();
    _customMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Invite Students',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: AppTheme.primaryColor,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Email Invites'),
                Tab(text: 'CSV Upload'),
                Tab(text: 'Bulk Import'),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEmailInviteTab(),
                  _buildCSVUploadTab(),
                  _buildBulkImportTab(),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: _isLoading ? null : _sendInvites,
                  child: _isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send Invites'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailInviteTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter student email addresses (one per line)',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          flex: 2,
          child: TextField(
            controller: _emailsController,
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              hintText: 'student1@college.edu\nstudent2@college.edu\nstudent3@college.edu',
              alignLabelWithHint: true,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Custom Message (Optional)',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _customMessageController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Add a personal message to the invitation...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Students will receive an email invitation to join the platform',
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
    );
  }

  Widget _buildCSVUploadTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload a CSV file with student details',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: _pickCSVFile,
            borderRadius: BorderRadius.circular(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_upload_rounded, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'Click to upload CSV file',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'or drag and drop here',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _downloadTemplate,
          icon: const Icon(Icons.download_rounded, size: 16),
          label: const Text('Download CSV Template'),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CSV Format Requirements:',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '• Columns: Name, Email, USN, Department, Batch\n• First row should contain headers\n• Maximum 500 students per upload',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: Colors.orange[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBulkImportTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Import students from existing systems',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),
        _buildImportOption(
          'University Management System',
          'Import directly from your university database',
          Icons.school_rounded,
          () => _importFromUMS(),
        ),
        const SizedBox(height: 16),
        _buildImportOption(
          'Google Classroom',
          'Import students from Google Classroom',
          Icons.class_rounded,
          () => _importFromClassroom(),
        ),
        const SizedBox(height: 16),
        _buildImportOption(
          'Microsoft Teams',
          'Import students from Microsoft Teams',
          Icons.groups_rounded,
          () => _importFromTeams(),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.security_rounded, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'All imports are secure and require proper authentication',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImportOption(String title, String description, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor,
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _pickCSVFile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV file picker coming soon!')),
    );
  }

  void _downloadTemplate() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading CSV template...')),
    );
  }

  void _importFromUMS() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('UMS integration coming soon!')),
    );
  }

  void _importFromClassroom() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google Classroom integration coming soon!')),
    );
  }

  void _importFromTeams() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Microsoft Teams integration coming soon!')),
    );
  }

  Future<void> _sendInvites() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final currentTab = _tabController.index;
      
      if (currentTab == 0) {
        // Email invites tab
        final emailText = _emailsController.text.trim();
        if (emailText.isEmpty) {
          throw Exception('Please enter at least one email address');
        }

        final emails = emailText
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty && e.contains('@'))
            .toList();

        if (emails.isEmpty) {
          throw Exception('Please enter valid email addresses');
        }

        // Get real college data
        final college = await ref.read(currentCollegeProvider.future);
        final collegeName = college?['name'] ?? 'Your College';
        
        // Use the email service to send invitations
        final emailService = ref.read(emailServiceProvider);
        
        // Generate a simple invite link (you can make this more sophisticated later)
        const inviteLink = 'https://CareerBridge.app/register';
        
        try {
          // Send invitations using the existing email service
          await emailService.sendStudentInvitations(
            emails: emails,
            collegeName: collegeName,
            inviteLink: inviteLink,
            customMessage: _customMessageController.text.trim().isNotEmpty 
                ? _customMessageController.text.trim() 
                : null,
          );
        } catch (e) {
          // Re-throw the error to be handled by the outer catch block
          throw Exception('Failed to send invitations: $e');
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Invitations sent to ${emails.length} students'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Other tabs - show coming soon message
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This feature is coming soon!'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}