import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/image_service.dart';
import '../../../core/utils/logger_service.dart';

class StudentProfileScreenSimple extends ConsumerStatefulWidget {
  const StudentProfileScreenSimple({super.key});

  @override
  ConsumerState<StudentProfileScreenSimple> createState() =>
      _StudentProfileScreenSimpleState();
}

class _StudentProfileScreenSimpleState
    extends ConsumerState<StudentProfileScreenSimple> {
  Map<String, dynamic>? _studentProfile;
  bool _isLoading = true;
  bool _isUpdatingAvatar = false;
  bool _isEditMode = false;
  bool _isSaving = false;
  String? _errorMessage;

  // Dropdown lists
  List<Map<String, dynamic>> _departments = [];

  // Selected IDs
  String? _selectedDepartmentId;

  // Text Controllers for editing
  final _phoneController = TextEditingController();
  final _usnController = TextEditingController();
  final _cgpaController = TextEditingController();
  final _semesterController = TextEditingController();
  final _currentYearController = TextEditingController();
  final _backlogsController = TextEditingController();
  final _portfolioController = TextEditingController();
  final _githubController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _leetcodeController = TextEditingController();
  final _hackerrankController = TextEditingController();

  // Skills & Interests
  List<String> _skills = [];
  List<String> _interests = [];
  final _skillController = TextEditingController();
  final _interestController = TextEditingController();

  // Academic History
  List<dynamic> _academicHistory = [];

  @override
  void dispose() {
    _phoneController.dispose();
    _usnController.dispose();
    _cgpaController.dispose();
    _semesterController.dispose();
    _currentYearController.dispose();
    _backlogsController.dispose();
    _portfolioController.dispose();
    _githubController.dispose();
    _linkedinController.dispose();
    _leetcodeController.dispose();
    _hackerrankController.dispose();
    _skillController.dispose();
    _interestController.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadStudentProfile();
  }

  Future<void> _loadStudentProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'No authenticated user found';
          _isLoading = false;
        });
        return;
      }

      LoggerService.debug('Loading profile for user: ${user.id}');

      // Get the basic profile with student_profiles data
      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select('''
            *,
            student_profiles (
              *,
              college_departments (id, name),
              college_programs (id, name),
              college_batches (id, name)
            )
          ''')
          .eq('id', user.id)
          .single();

      // Create enriched profile
      Map<String, dynamic> enrichedProfile = Map<String, dynamic>.from(
        profileResponse,
      );

      // Flatten student_profiles data with non-destructive merge
      if (profileResponse['student_profiles'] != null) {
        final sp = profileResponse['student_profiles'];

        // Helper to get non-null value preferring sp, then enrichedProfile
        dynamic getValue(String key) {
          return sp[key] ?? enrichedProfile[key];
        }

        // Consolidated resume_url logic
        String? consolidatedResumeUrl =
            enrichedProfile['resume_url'] ?? sp['resume_url'];

        // If still null, check job applications (we'd need a separate query for this in simple client side,
        // but let's stick to the two main profile sources for now or fetch it if needed)
        // For now, these two cover most cases.

        enrichedProfile.addAll({
          'phone': sp['phone'],
          'usn': sp['usn'],
          'cgpa': sp['cgpa'],
          'semester': sp['semester'],
          'current_year': sp['current_year'],
          'sgpa': sp['sgpa'],
          'backlogs': sp['backlogs'],
          'backlog_subjects': sp['backlog_subjects'],
          // Shared fields - prefer student_profile if not null, otherwise keep base profile
          'skills': getValue('skills'),
          'interests': getValue('interests'),
          'portfolio_url': getValue('portfolio_url'),
          'github_url': getValue('github_url'),
          'linkedin_url': getValue('linkedin_url'),
          'bio': getValue('bio'),
          'address': getValue('address'),

          'verified_skills': sp['verified_skills'],
          'leetcode_username': sp['leetcode_username'],
          'hackerrank_username': sp['hackerrank_username'],

          'resume_url': consolidatedResumeUrl,
          'is_verified': sp['is_verified'],
          'department': sp['college_departments'],
          'program': sp['college_programs'],
          'batch': sp['college_batches'],
        });
      }

      // Get organization info if organization_id exists
      if (profileResponse['organization_id'] != null) {
        try {
          final orgResponse = await Supabase.instance.client
              .from('organizations')
              .select(
                'id, name, type, logo_url, website, tagline, city, state, country',
              )
              .eq('id', profileResponse['organization_id'])
              .single();

          enrichedProfile['organization'] = orgResponse;
        } catch (e) {
          // Organization not found, continue without it
        }
      }

      if (mounted) {
        setState(() {
          _studentProfile = enrichedProfile;
          _academicHistory = profileResponse['academic_history'] ?? [];

          if (enrichedProfile['skills'] != null) {
            _skills = List<String>.from(enrichedProfile['skills']);
          } else {
            _skills = [];
          }

          if (enrichedProfile['interests'] != null) {
            _interests = List<String>.from(enrichedProfile['interests']);
          } else {
            _interests = [];
          }

          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      LoggerService.error('Error loading profile', e);
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _populateControllers() {
    if (_studentProfile == null) return;

    try {
      _phoneController.text = _studentProfile!['phone']?.toString() ?? '';
      _usnController.text = _studentProfile!['usn']?.toString() ?? '';
      _cgpaController.text = _studentProfile!['cgpa']?.toString() ?? '';
      _semesterController.text = _studentProfile!['semester']?.toString() ?? '';
      _currentYearController.text =
          _studentProfile!['current_year']?.toString() ?? '';
      _backlogsController.text =
          _studentProfile!['backlogs']?.toString() ?? '0';
      _portfolioController.text =
          _studentProfile!['portfolio_url']?.toString() ?? '';
      _githubController.text = _studentProfile!['github_url']?.toString() ?? '';
      _linkedinController.text =
          _studentProfile!['linkedin_url']?.toString() ?? '';
      _leetcodeController.text =
          _studentProfile!['leetcode_username']?.toString() ?? '';
      _hackerrankController.text =
          _studentProfile!['hackerrank_username']?.toString() ?? '';
    } catch (e) {
      LoggerService.error('Error populating controllers', e);
    }
  }

  Future<void> _loadDropdowns() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Load departments
      final deptResponse = await Supabase.instance.client
          .from('college_departments')
          .select('id, name')
          .order('name');

      setState(() {
        _departments = List<Map<String, dynamic>>.from(deptResponse);

        // Set selected IDs from current profile
        _selectedDepartmentId = _studentProfile?['department']?['id'];
      });
    } catch (e) {
      LoggerService.error('Error loading dropdowns', e);
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (_isEditMode) {
        _populateControllers();
        _loadDropdowns();
      }
    });
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Update student_profiles table
      await Supabase.instance.client
          .from('student_profiles')
          .update({
            'phone': _phoneController.text.trim(),
            'usn': _usnController.text.trim(),
            'cgpa': double.tryParse(_cgpaController.text.trim()),
            'semester': int.tryParse(_semesterController.text.trim()),
            'current_year': int.tryParse(_currentYearController.text.trim()),
            'backlogs': int.tryParse(_backlogsController.text.trim()) ?? 0,
            'department_id': _selectedDepartmentId,
            'portfolio_url': _portfolioController.text.trim().isEmpty
                ? null
                : _portfolioController.text.trim(),
            'github_url': _githubController.text.trim().isEmpty
                ? null
                : _githubController.text.trim(),
            'linkedin_url': _linkedinController.text.trim().isEmpty
                ? null
                : _linkedinController.text.trim(),
            'leetcode_username': _leetcodeController.text.trim().isEmpty
                ? null
                : _leetcodeController.text.trim(),
            'hackerrank_username': _hackerrankController.text.trim().isEmpty
                ? null
                : _hackerrankController.text.trim(),
            'skills': _skills,
            'interests': _interests,
          })
          .eq('id', user.id);

      // Update basic profile with academic_history
      await Supabase.instance.client
          .from('profiles')
          .update({
            'academic_history': _academicHistory,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      await _loadStudentProfile();

      setState(() {
        _isEditMode = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
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

  void _removeInterest(String interest) {
    setState(() {
      _interests.remove(interest);
    });
  }

  Future<void> _updateProfilePicture() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Show image source selection
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Image Source',
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

    setState(() {
      _isUpdatingAvatar = true;
    });

    try {
      final String? newAvatarUrl = await ImageService().updateProfilePicture(
        user.id,
        source: source,
      );

      if (newAvatarUrl != null) {
        // Update local profile data
        setState(() {
          _studentProfile!['profile_photo_url'] = newAvatarUrl;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
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
            content: Text('Error updating profile photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingAvatar = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading profile...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error Loading Profile',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _loadStudentProfile();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_studentProfile == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('No profile data available')),
      );
    }

    final profile = _studentProfile!;

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
          if (!_isEditMode)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: _toggleEditMode,
              tooltip: 'Edit Profile',
            )
          else ...[
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            else ...[
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  setState(() => _isEditMode = false);
                },
                tooltip: 'Cancel',
              ),
              IconButton(
                icon: const Icon(Icons.check_rounded),
                onPressed: _saveProfile,
                tooltip: 'Save',
              ),
            ],
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Container(
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
                  // Profile Image with College Verification Badge and Edit Button
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        backgroundImage:
                            profile['profile_photo_url'] != null &&
                                profile['profile_photo_url'].isNotEmpty
                            ? NetworkImage(profile['profile_photo_url'])
                            : null,
                        child:
                            profile['profile_photo_url'] == null ||
                                profile['profile_photo_url'].isEmpty
                            ? Icon(
                                Icons.person_rounded,
                                size: 50,
                                color: Colors.white.withValues(alpha: 0.8),
                              )
                            : null,
                      ),
                      // Edit Profile Picture Button
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isUpdatingAvatar
                              ? null
                              : _updateProfilePicture,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: _isUpdatingAvatar
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.blue,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.camera_alt_rounded,
                                    color: AppTheme.primaryColor,
                                    size: 16,
                                  ),
                          ),
                        ),
                      ),
                      // College Verification Badge
                      if (profile['organization'] != null)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child:
                                profile['organization']['logo_url'] != null &&
                                    profile['organization']['logo_url']
                                        .isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      profile['organization']['logo_url'],
                                      width: 16,
                                      height: 16,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.verified_rounded,
                                              color: Colors.white,
                                              size: 16,
                                            );
                                          },
                                    ),
                                  )
                                : const Icon(
                                    Icons.verified_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Name with College Verification
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          profile['full_name'] ?? 'Student',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (profile['organization'] != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (profile['organization']['logo_url'] != null &&
                                  profile['organization']['logo_url']
                                      .isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    profile['organization']['logo_url'],
                                    width: 12,
                                    height: 12,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.verified_rounded,
                                        color: Colors.white,
                                        size: 12,
                                      );
                                    },
                                  ),
                                ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Email
                  Text(
                    profile['email'] ?? 'No email',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),

                  // College Name
                  if (profile['organization'] != null)
                    Text(
                      profile['organization']['name'] ?? 'College',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  if (profile['department']?['name'] != null)
                    Text(
                      profile['department']['name'],
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),

                  // Profile Completion
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Profile ${profile['profile_completion'] ?? 30}% Complete',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // College Information Card (if available)
            if (profile['organization'] != null) ...[
              Container(
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
                          child:
                              profile['organization']['logo_url'] != null &&
                                  profile['organization']['logo_url'].isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    profile['organization']['logo_url'],
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
                                      profile['organization']['name'] ??
                                          'College',
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
                                      color: Colors.green.withValues(
                                        alpha: 0.1,
                                      ),
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
                              if (profile['organization']['tagline'] != null)
                                Text(
                                  profile['organization']['tagline'],
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              if (profile['organization']['city'] != null)
                                Text(
                                  '${profile['organization']['city']}, ${profile['organization']['state'] ?? ''}',
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

                    if (profile['organization']['website'] != null) ...[
                      const SizedBox(height: 16),
                      Container(
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
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Academic Information
            _buildSection('Academic Information', [
              _buildEditableInfoRow(
                'USN',
                profile['usn'] ?? 'Not provided',
                _usnController,
              ),
              // Department Dropdown
              _buildDropdownRow(
                'Department',
                profile['department']?['name'] ?? 'Not provided',
                _departments,
                _selectedDepartmentId,
                (value) {
                  setState(() => _selectedDepartmentId = value);
                },
              ),
              _buildEditableInfoRow(
                'Current Semester',
                profile['semester']?.toString() ?? 'Not provided',
                _semesterController,
                keyboardType: TextInputType.number,
              ),
              _buildEditableInfoRow(
                'Current Year',
                profile['current_year']?.toString() ?? 'Not provided',
                _currentYearController,
                keyboardType: TextInputType.number,
              ),
              _buildEditableInfoRow(
                'CGPA',
                profile['cgpa']?.toString() ?? 'Not provided',
                _cgpaController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              _buildEditableInfoRow(
                'Backlogs',
                profile['backlogs']?.toString() ?? '0',
                _backlogsController,
                keyboardType: TextInputType.number,
                isLast: true,
              ),
            ]),

            const SizedBox(height: 24),

            // Basic Information
            Container(
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
                    'Basic Information',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildInfoRow(
                    'Full Name',
                    profile['full_name'] ?? 'Not provided',
                  ),
                  _buildInfoRow('Email', profile['email'] ?? 'Not provided'),
                  _buildEditableInfoRow(
                    'Phone',
                    profile['phone'] ?? 'Not provided',
                    _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  _buildInfoRow('Role', profile['role'] ?? 'Not provided'),
                  _buildInfoRow('USN', profile['usn'] ?? 'Not provided'),
                  _buildInfoRow(
                    'Current Semester',
                    '${profile['current_semester'] ?? 'N/A'}',
                  ),
                  _buildInfoRow(
                    'CGPA',
                    '${profile['cgpa'] ?? 'N/A'}',
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Skills & Interests
            // Skills & Interests
            _buildSection('Skills & Interests', [
              // Skills
              Text(
                'Skills',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              if (_isEditMode)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _skillController,
                        decoration: InputDecoration(
                          hintText: 'Add a skill',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        onSubmitted: (_) => _addSkill(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      color: AppTheme.primaryColor,
                      onPressed: _addSkill,
                    ),
                  ],
                ),
              if (_isEditMode || _skills.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _skills.map((skill) {
                    return Chip(
                      label: Text(skill),
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                      labelStyle: GoogleFonts.outfit(
                        color: AppTheme.primaryColor,
                      ),
                      deleteIcon: _isEditMode
                          ? const Icon(Icons.close, size: 18)
                          : null,
                      onDeleted: _isEditMode ? () => _removeSkill(skill) : null,
                    );
                  }).toList(),
                ),
              ] else
                const Text('No skills added yet'),

              const SizedBox(height: 16),
              Divider(color: Colors.grey[200]),
              const SizedBox(height: 16),

              // Interests
              Text(
                'Interests',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              if (_isEditMode)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _interestController,
                        decoration: InputDecoration(
                          hintText: 'Add an interest',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        onSubmitted: (_) => _addInterest(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      color: Colors.orange,
                      onPressed: _addInterest,
                    ),
                  ],
                ),
              if (_isEditMode || _interests.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _interests.map((interest) {
                    return Chip(
                      label: Text(interest),
                      backgroundColor: Colors.orange.withValues(alpha: 0.1),
                      labelStyle: GoogleFonts.outfit(color: Colors.orange),
                      deleteIcon: _isEditMode
                          ? const Icon(Icons.close, size: 18)
                          : null,
                      onDeleted: _isEditMode
                          ? () => _removeInterest(interest)
                          : null,
                    );
                  }).toList(),
                ),
              ] else
                const Text('No interests added yet'),
            ]),

            if (profile['skills'] != null || profile['interests'] != null)
              const SizedBox(height: 24),

            // Professional Links
            _buildSection('Professional Links', [
              _buildEditableInfoRow(
                'Portfolio',
                profile['portfolio_url'] ?? 'Not provided',
                _portfolioController,
              ),
              _buildEditableInfoRow(
                'GitHub',
                profile['github_url'] ?? 'Not provided',
                _githubController,
              ),
              _buildEditableInfoRow(
                'LinkedIn',
                profile['linkedin_url'] ?? 'Not provided',
                _linkedinController,
              ),
              _buildEditableInfoRow(
                'LeetCode',
                profile['leetcode_username'] ?? 'Not provided',
                _leetcodeController,
              ),
              _buildEditableInfoRow(
                'HackerRank',
                profile['hackerrank_username'] ?? 'Not provided',
                _hackerrankController,
                isLast: true,
              ),
            ]),

            const SizedBox(height: 24),

            // Academic History (from setup)
            _buildSection(
              'Academic History',
              [
                if (_academicHistory.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No academic records added yet.',
                        style: GoogleFonts.outfit(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ..._academicHistory.asMap().entries.map((entry) {
                    final index = entry.key;
                    final record = entry.value;
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
                          if (_isEditMode) ...[
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                size: 20,
                                color: Colors.blue,
                              ),
                              onPressed: () => _showAcademicRecordDialog(
                                record: record,
                                index: index,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                size: 20,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                setState(
                                  () => _academicHistory.removeAt(index),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
              ],
              action: _isEditMode
                  ? IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: AppTheme.primaryColor,
                      ),
                      onPressed: () => _showAcademicRecordDialog(),
                    )
                  : null,
            ),

            const SizedBox(height: 24),
          ],
        ),
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
              width: 120,
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

  Widget _buildEditableInfoRow(
    String label,
    String value,
    TextEditingController controller, {
    bool isLast = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
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
              child: _isEditMode
                  ? TextField(
                      controller: controller,
                      keyboardType: keyboardType,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppTheme.textColor,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.primaryColor),
                        ),
                      ),
                    )
                  : Text(
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

  Widget _buildDropdownRow(
    String label,
    String currentValue,
    List<Map<String, dynamic>> items,
    String? selectedId,
    Function(String?) onChanged, {
    bool isLast = false,
  }) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
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
              child: _isEditMode
                  ? DropdownButtonFormField<String>(
                      value: selectedId,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.primaryColor),
                        ),
                      ),
                      items: items.map((item) {
                        return DropdownMenuItem<String>(
                          value: item['id'],
                          child: Text(
                            item['name'],
                            style: GoogleFonts.outfit(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: onChanged,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppTheme.textColor,
                      ),
                    )
                  : Text(
                      currentValue,
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

  Widget _buildSection(String title, List<Widget> children, {Widget? action}) {
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
                title,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLinkRow(
    String label,
    String url,
    IconData icon, {
    bool isLast = false,
  }) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
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
              child: InkWell(
                onTap: () {
                  // TODO: Launch URL
                },
                child: Row(
                  children: [
                    Icon(icon, size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        url,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: AppTheme.primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
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
