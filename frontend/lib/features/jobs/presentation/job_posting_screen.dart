import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';

class JobPostingScreen extends ConsumerStatefulWidget {
  const JobPostingScreen({super.key});

  @override
  ConsumerState<JobPostingScreen> createState() => _JobPostingScreenState();
}

class _JobPostingScreenState extends ConsumerState<JobPostingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();
  String _jobType = 'Full-time';
  bool _isLoading = false;

  final List<String> _jobTypes = [
    'Full-time',
    'Part-time',
    'Internship',
    'Contract',
    'Freelance',
  ];

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Get recruiter's organization_id
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('organization_id')
          .eq('id', user.id)
          .single();

      final jobData = {
        'recruiter_id': user.id,
        'posted_by':
            user.id, // Ensure compatibility with RecruiterRepository queries
        'organization_id': profile['organization_id'],
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'requirements': _requirementsController.text.trim(),
        'location': _locationController.text.trim(),
        'salary_range': _salaryController.text.trim(),
        'job_type': _jobType,
        'status': 'open',
      };

      await Supabase.instance.client.from('jobs').insert(jobData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error posting job: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Post a New Job',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Job Title'),
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration('e.g. Senior Flutter Developer'),
                validator: (v) => v?.isNotEmpty == true ? null : 'Required',
              ),
              const SizedBox(height: 20),

              _buildLabel('Job Type'),
              DropdownButtonFormField<String>(
                value: _jobType,
                items: _jobTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type, style: GoogleFonts.outfit()),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _jobType = val!),
                decoration: _inputDecoration(''),
              ),
              const SizedBox(height: 20),

              _buildLabel('Location'),
              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration('e.g. Bangalore, Remote'),
                validator: (v) => v?.isNotEmpty == true ? null : 'Required',
              ),
              const SizedBox(height: 20),

              _buildLabel('Salary Range (Optional)'),
              TextFormField(
                controller: _salaryController,
                decoration: _inputDecoration('e.g. ₹10L - ₹15L LPA'),
              ),
              const SizedBox(height: 20),

              _buildLabel('Job Description'),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: _inputDecoration(
                  'Describe the role and responsibilities...',
                ),
                validator: (v) => v?.isNotEmpty == true ? null : 'Required',
              ),
              const SizedBox(height: 20),

              _buildLabel('Requirements'),
              TextFormField(
                controller: _requirementsController,
                maxLines: 3,
                decoration: _inputDecoration(
                  'Key skills and qualifications...',
                ),
                validator: (v) => v?.isNotEmpty == true ? null : 'Required',
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submitJob,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Post Job',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }
}
