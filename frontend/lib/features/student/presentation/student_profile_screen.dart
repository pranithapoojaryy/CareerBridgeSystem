import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart'; // Added
import '../../../core/theme/app_theme.dart';
import '../../../core/services/image_service.dart'; // Added
import '../../../core/utils/logger_service.dart';

class StudentProfileScreen extends ConsumerStatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  ConsumerState<StudentProfileScreen> createState() =>
      _StudentProfileScreenState();
}

class _StudentProfileScreenState extends ConsumerState<StudentProfileScreen> {
  Map<String, dynamic>? _studentProfile;
  Map<String, dynamic>? _collegeInfo;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isUploadingPhoto = false; // Added state
  final _supabase = Supabase.instance.client;

  // Controllers for editable fields
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _githubController = TextEditingController();
  final _portfolioController = TextEditingController();
  final _skillController = TextEditingController();
  final List<String> _skills = [];
  final List<String> _interests = [];
  final _interestController = TextEditingController();
  final List<dynamic> _academicHistory = [];
  final _hackerrankController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStudentProfile();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _linkedinController.dispose();
    _githubController.dispose();
    _portfolioController.dispose();
    _skillController.dispose();
    _interestController.dispose();
    _hackerrankController.dispose();

    super.dispose();
  }

  Future<void> _loadStudentProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No authenticated user found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // First get the basic profile
      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .single();

      // Then get related data separately if IDs exist
      Map<String, dynamic> enrichedProfile = Map<String, dynamic>.from(
        profileResponse,
      );

      // Fetch student-specific academic profile
      Map<String, dynamic>? studentProfileData;
      try {
        studentProfileData = await Supabase.instance.client
            .from('student_profiles')
            .select('*')
            .eq('id', user.id)
            .single();

        enrichedProfile.addAll(studentProfileData);
      } catch (e) {
        LoggerService.error('Student academic profile not found', e);
      }

      // Get organization info if organization_id exists
      final orgId =
          profileResponse['organization_id'] ??
          studentProfileData?['college_id'];
      if (orgId != null) {
        try {
          final orgResponse = await Supabase.instance.client
              .from('organizations')
              .select('''
                id, name, type, logo_url, website, 
                allowed_emails_domain, primary_color, tagline,
                address_city, address_state, address_country
              ''')
              .eq('id', orgId)
              .single();
          enrichedProfile['organizations'] = orgResponse;
        } catch (e) {
          LoggerService.error('Organization not found', e);
        }
      }

      // Get department info
      final deptId =
          studentProfileData?['department_id'] ??
          profileResponse['department_id'];
      if (deptId != null) {
        try {
          final deptResponse = await Supabase.instance.client
              .from('college_departments')
              .select('id, name')
              .eq('id', deptId)
              .single();
          enrichedProfile['college_departments'] = deptResponse;
        } catch (e) {
          LoggerService.error('Department not found', e);
        }
      }

      // Get program info
      final programId =
          studentProfileData?['program_id'] ?? profileResponse['program_id'];
      if (programId != null) {
        try {
          final programResponse = await Supabase.instance.client
              .from('college_programs')
              .select('id, name, duration_years')
              .eq('id', programId)
              .single();
          enrichedProfile['college_programs'] = programResponse;
        } catch (e) {
          LoggerService.error('Program not found', e);
        }
      }

      // Get batch info
      final batchId =
          studentProfileData?['batch_id'] ?? profileResponse['batch_id'];
      if (batchId != null) {
        try {
          final batchResponse = await Supabase.instance.client
              .from('college_batches')
              .select('id, name, start_year, end_year')
              .eq('id', batchId)
              .single();
          enrichedProfile['college_batches'] = batchResponse;
        } catch (e) {
          LoggerService.error('Batch not found', e);
        }
      }

      if (mounted) {
        setState(() {
          _studentProfile = enrichedProfile;
          _collegeInfo = enrichedProfile['organizations'];
          _isLoading = false;

          // Populate controllers
          _bioController.text = enrichedProfile['bio'] ?? '';
          _phoneController.text = enrichedProfile['phone'] ?? '';
          _addressController.text = enrichedProfile['address'] ?? '';
          _linkedinController.text = enrichedProfile['linkedin_url'] ?? '';
          _githubController.text = enrichedProfile['github_url'] ?? '';
          _portfolioController.text = enrichedProfile['portfolio_url'] ?? '';

          // Populate skills and interests
          if (enrichedProfile['skills'] != null) {
            _skills.clear();
            _skills.addAll(List<String>.from(enrichedProfile['skills']));
          }
          if (enrichedProfile['interests'] != null) {
            _interests.clear();
            _interests.addAll(List<String>.from(enrichedProfile['interests']));
          }

          // Populate academic history
          if (enrichedProfile['academic_history'] != null) {
            _academicHistory.clear();
            _academicHistory.addAll(
              List<dynamic>.from(enrichedProfile['academic_history']),
            );
          }

          _hackerrankController.text =
              enrichedProfile['hackerrank_username'] ?? '';
        });
      }
    } catch (e) {
      LoggerService.error('Error loading student profile', e);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadStudentProfile,
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('profiles')
          .update({
            'bio': _bioController.text.trim(),
            'phone': _phoneController.text.trim(),
            'address': _addressController.text.trim(),
            'linkedin_url': _linkedinController.text.trim(),
            'github_url': _githubController.text.trim(),
            'portfolio_url': _portfolioController.text.trim(),
            'skills': _skills,
            'interests': _interests,
            'academic_history': _academicHistory, // Persist academic history
            'updated_at': DateTime.now().toIso8601String(),
            'hackerrank_username': _hackerrankController.text.trim().isEmpty
                ? null
                : _hackerrankController.text.trim(),
          })
          .eq('id', user.id);

      setState(() => _isEditing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _loadStudentProfile(); // Refresh data
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillController.clear();
      });
    }
  }

  void _addInterest() {
    final interest = _interestController.text.trim();
    if (interest.isNotEmpty && !_interests.contains(interest)) {
      setState(() {
        _interests.add(interest);
        _interestController.clear();
      });
    }
  }

  Future<void> _selectProfilePhoto() async {
    // Show image source selection
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Profile Photo',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );

    if (source == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final String? photoUrl = await ImageService().updateProfilePicture(
        user.id,
        source: source,
      );

      if (photoUrl != null) {
        if (mounted) {
          setState(() {
            // Update local state with new URL
            // HACK: Append timestamp to force refresh if URL is same (though ImageService uses unique, safety first)
            final cleanUrl = photoUrl.split('?').first;
            _studentProfile!['profile_photo_url'] =
                '$cleanUrl?t=${DateTime.now().millisecondsSinceEpoch}';
            _studentProfile!['profile_image_url'] =
                '$cleanUrl?t=${DateTime.now().millisecondsSinceEpoch}'; // Handle both keys
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // No need to reload whole profile if we update state here,
          // but reloading ensures consistency
          // await _loadStudentProfile();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update profile photo'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_studentProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Error loading profile')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'My Profile',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_rounded),
            )
          else ...[
            IconButton(
              onPressed: () => setState(() => _isEditing = false),
              icon: const Icon(Icons.close_rounded),
            ),
            IconButton(
              onPressed: _saveProfile,
              icon: const Icon(Icons.check_rounded),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header with College Verification
            _buildProfileHeader(),
            const SizedBox(height: 24),

            // College Information Card
            _buildCollegeCard(),
            const SizedBox(height: 24),

            // Personal Information
            _buildPersonalInfoCard(),
            const SizedBox(height: 24),

            // Academic Information
            _buildAcademicInfoCard(),
            const SizedBox(height: 24),

            // Academic History (from setup)
            if (_studentProfile!['academic_history'] != null &&
                (_studentProfile!['academic_history'] as List).isNotEmpty)
              _buildAcademicHistoryCard(),
            if (_studentProfile!['academic_history'] != null &&
                (_studentProfile!['academic_history'] as List).isNotEmpty)
              const SizedBox(height: 24),

            // Skills & Interests
            _buildSkillsCard(),
            const SizedBox(height: 24),

            // Social Links
            _buildSocialLinksCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Profile Image
          GestureDetector(
            onTap: _isEditing && !_isUploadingPhoto
                ? _selectProfilePhoto
                : null,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  backgroundImage: _studentProfile!['profile_photo_url'] != null
                      ? NetworkImage(_studentProfile!['profile_photo_url'])
                      : _studentProfile!['profile_image_url'] != null
                      ? NetworkImage(_studentProfile!['profile_image_url'])
                      : null,
                  child: _isUploadingPhoto
                      ? const CircularProgressIndicator(color: Colors.white)
                      : (_studentProfile!['profile_photo_url'] == null &&
                            _studentProfile!['profile_image_url'] == null)
                      ? Icon(
                          Icons.person_rounded,
                          size: 50,
                          color: Colors.white.withValues(alpha: 0.8),
                        )
                      : null,
                ),
                // College Verification Badge
                if (_collegeInfo != null && !_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),

                // Edit Icon Overlay
                if (_isEditing && !_isUploadingPhoto)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            _studentProfile!['full_name'] ?? 'Student',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          // USN
          if (_studentProfile!['usn'] != null)
            Text(
              _studentProfile!['usn'],
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),

          // Profile Completion
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Profile ${_studentProfile!['profile_completion'] ?? 30}% Complete',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollegeCard() {
    if (_collegeInfo == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              // College Logo
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _collegeInfo!['logo_url'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _collegeInfo!['logo_url'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.school_rounded,
                              color: Colors.grey[600],
                              size: 30,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.school_rounded,
                        color: Colors.grey[600],
                        size: 30,
                      ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _collegeInfo!['name'] ?? 'College',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColor,
                            ),
                          ),
                        ),
                        // Verified Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                color: Colors.green,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Verified',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_collegeInfo!['tagline'] != null)
                      Text(
                        _collegeInfo!['tagline'],
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    if (_collegeInfo!['address_city'] != null)
                      Text(
                        '${_collegeInfo!['address_city']}, ${_collegeInfo!['address_state'] ?? ''}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          if (_collegeInfo!['website'] != null) ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _launchUrl(_collegeInfo!['website']),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.language_rounded,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Visit Website',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            'Personal Information',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 16),

          // Bio
          if (_isEditing)
            TextFormField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Tell us about yourself...',
                border: OutlineInputBorder(),
              ),
            )
          else if (_studentProfile!['bio'] != null &&
              _studentProfile!['bio'].isNotEmpty)
            _buildInfoRow('Bio', _studentProfile!['bio']),

          const SizedBox(height: 12),

          // Phone
          if (_isEditing)
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            )
          else
            _buildInfoRow('Phone', _studentProfile!['phone'] ?? 'Not provided'),

          const SizedBox(height: 12),

          // Email (read-only)
          _buildInfoRow('Email', _studentProfile!['email'] ?? 'Not available'),

          const SizedBox(height: 12),

          // Address
          if (_isEditing)
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            )
          else if (_studentProfile!['address'] != null &&
              _studentProfile!['address'].isNotEmpty)
            _buildInfoRow('Address', _studentProfile!['address']),
        ],
      ),
    );
  }

  Widget _buildAcademicInfoCard() {
    final department = _studentProfile!['college_departments'];
    final program = _studentProfile!['college_programs'];
    final batch = _studentProfile!['college_batches'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            'Academic Information',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 16),

          _buildInfoRow('USN', _studentProfile!['usn'] ?? 'Not provided'),
          _buildInfoRow('Department', department?['name'] ?? 'Not specified'),
          _buildInfoRow(
            'Program',
            program != null
                ? '${program['name']} (${program['duration_years']} years)'
                : 'Not specified',
          ),
          _buildInfoRow(
            'Batch',
            batch != null
                ? '${batch['name']} (${batch['start_year']}-${batch['end_year']})'
                : 'Not specified',
          ),
          _buildInfoRow(
            'Current Semester',
            '${_studentProfile!['semester'] ?? _studentProfile!['current_semester'] ?? 'N/A'}',
          ),
          _buildInfoRow(
            'CGPA',
            '${_studentProfile!['cgpa'] ?? 'N/A'}',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            'Skills & Interests',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 16),

          // Skills Section
          Text(
            'Technical Skills',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),

          if (_isEditing) ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _skillController,
                    decoration: const InputDecoration(
                      hintText: 'Add a skill',
                      border: OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (_) => _addSkill(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addSkill,
                  icon: const Icon(Icons.add_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          if (_skills.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skills.map((skill) {
                return Chip(
                  label: Text(skill),
                  deleteIcon: _isEditing
                      ? const Icon(Icons.close, size: 18)
                      : null,
                  onDeleted: _isEditing
                      ? () {
                          setState(() => _skills.remove(skill));
                        }
                      : null,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                );
              }).toList(),
            )
          else
            Text(
              'No skills added yet',
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600]),
            ),

          const SizedBox(height: 24),

          // Interests Section
          Text(
            'Interests',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),

          if (_isEditing) ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _interestController,
                    decoration: const InputDecoration(
                      hintText: 'Add an interest',
                      border: OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (_) => _addInterest(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addInterest,
                  icon: const Icon(Icons.add_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          if (_interests.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _interests.map((interest) {
                return Chip(
                  label: Text(interest),
                  deleteIcon: _isEditing
                      ? const Icon(Icons.close, size: 18)
                      : null,
                  onDeleted: _isEditing
                      ? () {
                          setState(() => _interests.remove(interest));
                        }
                      : null,
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                );
              }).toList(),
            )
          else
            Text(
              'No interests added yet',
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }

  Widget _buildSocialLinksCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            'Social Links',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 16),

          // LinkedIn
          if (_isEditing)
            TextFormField(
              controller: _linkedinController,
              decoration: const InputDecoration(
                labelText: 'LinkedIn Profile',
                hintText: 'https://linkedin.com/in/yourprofile',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.work_outline_rounded),
              ),
            )
          else if (_studentProfile!['linkedin_url'] != null &&
              _studentProfile!['linkedin_url'].isNotEmpty)
            _buildSocialLinkRow(
              'LinkedIn',
              _studentProfile!['linkedin_url'],
              Icons.work_outline_rounded,
            ),

          const SizedBox(height: 12),

          // GitHub
          if (_isEditing)
            TextFormField(
              controller: _githubController,
              decoration: const InputDecoration(
                labelText: 'GitHub Profile',
                hintText: 'https://github.com/yourusername',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.code_rounded),
              ),
            )
          else if (_studentProfile!['github_url'] != null &&
              _studentProfile!['github_url'].isNotEmpty)
            _buildSocialLinkRow(
              'GitHub',
              _studentProfile!['github_url'],
              Icons.code_rounded,
            ),

          const SizedBox(height: 12),

          // Portfolio
          if (_isEditing)
            TextFormField(
              controller: _portfolioController,
              decoration: const InputDecoration(
                labelText: 'Portfolio Website',
                hintText: 'https://yourportfolio.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.web_rounded),
              ),
            )
          else if (_studentProfile!['portfolio_url'] != null &&
              _studentProfile!['portfolio_url'].isNotEmpty)
            _buildSocialLinkRow(
              'Portfolio',
              _studentProfile!['portfolio_url'],
              Icons.web_rounded,
            ),
          const SizedBox(height: 12),

          // HackerRank
          if (_isEditing)
            TextFormField(
              controller: _hackerrankController,
              decoration: const InputDecoration(
                labelText: 'HackerRank Username',
                hintText: 'your_hackerrank_username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.code),
              ),
            )
          else if (_studentProfile!['hackerrank_username'] != null &&
              _studentProfile!['hackerrank_username'].isNotEmpty)
            _buildSocialLinkRow(
              'HackerRank',
              'https://www.hackerrank.com/profile/${_studentProfile!['hackerrank_username']}',
              Icons.code,
            ),
        ],
      ),
    );
  }

  Widget _buildAcademicHistoryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Academic History',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              if (_isEditing)
                TextButton.icon(
                  onPressed: () => _showAcademicRecordDialog(),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Add Education'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ..._academicHistory.map((record) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.history_edu_rounded,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record['institution'] ?? 'Institution',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textColor,
                          ),
                        ),
                        Text(
                          '${record['degree'] ?? ''} in ${record['field'] ?? ''}',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${record['start_year'] ?? ''} - ${record['end_year'] ?? ''} • Grade: ${record['grade'] ?? ''}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isEditing) ...[
                    IconButton(
                      onPressed: () => _showAcademicRecordDialog(
                        record: record,
                        index: _academicHistory.indexOf(record),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      color: Colors.blue,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _academicHistory.remove(record);
                        });
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      color: Colors.red,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppTheme.textColor,
                ),
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 12),
          Divider(color: Colors.grey[200]),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildSocialLinkRow(String label, String url, IconData icon) {
    return InkWell(
      onTap: () => _launchUrl(url),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    url,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new_rounded, size: 16, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  void _showAcademicRecordDialog({Map<String, dynamic>? record, int? index}) {
    final institutionController = TextEditingController(
      text: record?['institution'] ?? '',
    );
    final degreeController = TextEditingController(
      text: record?['degree'] ?? '',
    );
    final fieldController = TextEditingController(text: record?['field'] ?? '');
    final startYearController = TextEditingController(
      text: record?['start_year']?.toString() ?? '',
    );
    final endYearController = TextEditingController(
      text: record?['end_year']?.toString() ?? '',
    );
    final gradeController = TextEditingController(text: record?['grade'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          record == null ? 'Add Academic Record' : 'Edit Academic Record',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: institutionController,
                decoration: const InputDecoration(labelText: 'Institution'),
              ),
              TextField(
                controller: degreeController,
                decoration: const InputDecoration(
                  labelText: 'Degree (e.g. BCA, MCA)',
                ),
              ),
              TextField(
                controller: fieldController,
                decoration: const InputDecoration(labelText: 'Field of Study'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startYearController,
                      decoration: const InputDecoration(
                        labelText: 'Start Year',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: endYearController,
                      decoration: const InputDecoration(labelText: 'End Year'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              TextField(
                controller: gradeController,
                decoration: const InputDecoration(labelText: 'Grade/CGPA'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newRecord = {
                'institution': institutionController.text.trim(),
                'degree': degreeController.text.trim(),
                'field': fieldController.text.trim(),
                'start_year': int.tryParse(startYearController.text.trim()),
                'end_year': int.tryParse(endYearController.text.trim()),
                'grade': gradeController.text.trim(),
              };

              setState(() {
                if (index != null) {
                  _academicHistory[index] = newRecord;
                } else {
                  _academicHistory.add(newRecord);
                }
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
