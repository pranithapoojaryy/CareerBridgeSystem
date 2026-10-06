import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/image_service.dart';

class StudentProfileSetupScreen extends ConsumerStatefulWidget {
  const StudentProfileSetupScreen({super.key});

  @override
  ConsumerState<StudentProfileSetupScreen> createState() =>
      _StudentProfileSetupScreenState();
}

class _StudentProfileSetupScreenState
    extends ConsumerState<StudentProfileSetupScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Profile Photo
  Uint8List? _profileImageBytes;
  String? _profileImageName;
  String? _profilePhotoUrl;
  bool _isUploadingPhoto = false;

  // Personal Details
  final _bioController = TextEditingController();
  final _addressController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _githubController = TextEditingController();
  final _portfolioController = TextEditingController();

  // Skills
  final _skillController = TextEditingController();
  final List<String> _skills = [];
  final List<String> _interests = [];
  final _interestController = TextEditingController();

  // Academic History
  final List<Map<String, dynamic>> _academicHistory = [];
  final _institutionController = TextEditingController();
  final _degreeController = TextEditingController();
  final _fieldController = TextEditingController();
  final _gradeController = TextEditingController();
  final _startYearController = TextEditingController();
  final _endYearController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    _linkedinController.dispose();
    _githubController.dispose();
    _portfolioController.dispose();
    _skillController.dispose();
    _interestController.dispose();
    _institutionController.dispose();
    _degreeController.dispose();
    _fieldController.dispose();
    _gradeController.dispose();
    _startYearController.dispose();
    _endYearController.dispose();
    super.dispose();
  }

  Future<void> _selectProfilePhoto() async {
    // Show image source selection
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
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

    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final String? photoUrl = await ImageService().updateProfilePicture(
        user.id,
        source: source,
      );

      if (photoUrl != null) {
        setState(() {
          _profilePhotoUrl = photoUrl;
          _profileImageBytes = null; // Clear old file picker data
          _profileImageName = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo selected successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to select profile photo'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting profile photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
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

  void _addAcademicRecord() {
    if (_institutionController.text.isNotEmpty &&
        _degreeController.text.isNotEmpty &&
        _fieldController.text.isNotEmpty) {
      setState(() {
        _academicHistory.add({
          'institution': _institutionController.text.trim(),
          'degree': _degreeController.text.trim(),
          'field': _fieldController.text.trim(),
          'grade': _gradeController.text.trim(),
          'start_year': _startYearController.text.trim(),
          'end_year': _endYearController.text.trim(),
        });
        _institutionController.clear();
        _degreeController.clear();
        _fieldController.clear();
        _gradeController.clear();
        _startYearController.clear();
        _endYearController.clear();
      });
    }
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _saveProfile();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Update base profile
      await Supabase.instance.client
          .from('profiles')
          .update({
            'bio': _bioController.text.trim(),
            'address': _addressController.text.trim(),
            'linkedin_url': _linkedinController.text.trim(),
            'github_url': _githubController.text.trim(),
            'portfolio_url': _portfolioController.text.trim(),
            'profile_photo_url': _profilePhotoUrl,
            'skills': _skills,
            'interests': _interests,
            'academic_history': _academicHistory,
            'profile_completion': 100,
            'is_profile_complete': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      // Also update student_profiles for consistency and better fetching
      await Supabase.instance.client.from('student_profiles').upsert({
        'id': user.id,
        'linkedin_url': _linkedinController.text.trim(),
        'github_url': _githubController.text.trim(),
        'portfolio_url': _portfolioController.text.trim(),
        'skills': _skills,
        'interests': _interests,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to dashboard through AppWrapper for proper routing
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/dashboard',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildPhotoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.camera_alt_rounded,
              color: AppTheme.primaryColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Profile Photo',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a photo to help others recognize you',
            style: GoogleFonts.outfit(fontSize: 15, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // Profile Photo Picker
          GestureDetector(
            onTap: _isUploadingPhoto ? null : _selectProfilePhoto,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: (_profilePhotoUrl != null || _profileImageBytes != null)
                    ? Colors.transparent
                    : Colors.grey[100],
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      (_profilePhotoUrl != null || _profileImageBytes != null)
                      ? AppTheme.primaryColor
                      : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: _isUploadingPhoto
                  ? const Center(child: CircularProgressIndicator())
                  : _profilePhotoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        _profilePhotoUrl!,
                        fit: BoxFit.cover,
                        width: 150,
                        height: 150,
                        errorBuilder: (context, error, stackTrace) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Error loading photo',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    )
                  : _profileImageBytes != null
                  ? ClipOval(
                      child: Image.memory(
                        _profileImageBytes!,
                        fit: BoxFit.cover,
                        width: 150,
                        height: 150,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          size: 48,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add Photo',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),

          if (_profilePhotoUrl != null || _profileImageBytes != null)
            Column(
              children: [
                Text(
                  _profilePhotoUrl != null
                      ? 'Profile photo uploaded'
                      : (_profileImageName ?? 'Selected Image'),
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => setState(() {
                    _profilePhotoUrl = null;
                    _profileImageBytes = null;
                    _profileImageName = null;
                  }),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove Photo'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),

          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your photo will be visible to recruiters and college administrators',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Details',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us more about yourself',
            style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          // Bio
          TextFormField(
            controller: _bioController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Bio',
              hintText: 'Tell us about yourself...',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 16),

          // Address
          TextFormField(
            controller: _addressController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Address',
              hintText: 'Enter your current address',
              prefixIcon: Icon(Icons.location_on_outlined),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),

          // Social Links
          _buildSocialInput(
            controller: _linkedinController,
            label: 'LinkedIn',
            hint: 'linkedin.com/in/username',
            icon: Icons.link_rounded,
          ),
          const SizedBox(height: 12),
          _buildSocialInput(
            controller: _githubController,
            label: 'GitHub',
            hint: 'github.com/username',
            icon: Icons.code_rounded,
          ),
          const SizedBox(height: 12),
          _buildSocialInput(
            controller: _portfolioController,
            label: 'Portfolio',
            hint: 'yourportfolio.com',
            icon: Icons.language_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildSkillsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Skills & Interests',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your technical skills and interests',
            style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          // Skills Section
          Text(
            'Technical Skills',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _skillController,
                  decoration: InputDecoration(
                    labelText: 'Add Skill',
                    hintText: 'e.g., Flutter, Python, React',
                    prefixIcon: const Icon(Icons.code_rounded, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onFieldSubmitted: (_) => _addSkill(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: _addSkill,
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Skills Chips
          if (_skills.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skills.map((skill) {
                return Chip(
                  label: Text(skill),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () {
                    setState(() => _skills.remove(skill));
                  },
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                );
              }).toList(),
            ),

          const SizedBox(height: 32),

          // Interests Section
          Text(
            'Interests',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _interestController,
                  decoration: InputDecoration(
                    labelText: 'Add Interest',
                    hintText: 'e.g., ML, Web Dev',
                    prefixIcon: const Icon(
                      Icons.favorite_outline_rounded,
                      size: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onFieldSubmitted: (_) => _addInterest(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: _addInterest,
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Interests Chips
          if (_interests.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _interests.map((interest) {
                return Chip(
                  label: Text(interest),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () {
                    setState(() => _interests.remove(interest));
                  },
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAcademicStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Academic History',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your previous educational qualifications',
            style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          // Add Academic Record Form
          _buildAcademicForm(),

          const SizedBox(height: 24),

          // Academic Records List
          if (_academicHistory.isNotEmpty) ...[
            Text(
              'Academic Records',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 12),

            ..._academicHistory.asMap().entries.map((entry) {
              final index = entry.key;
              final record = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[100]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.01),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record['degree'],
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${record['institution']} • ${record['field']}',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${record['start_year']} - ${record['end_year']} • ${record['grade']}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() => _academicHistory.removeAt(index));
                      },
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildAcademicForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
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
          Text(
            'Add Academic Record',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildMinimalInput(
            controller: _institutionController,
            label: 'Institution',
            hint: 'e.g., ABC High School',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMinimalInput(
                  controller: _degreeController,
                  label: 'Degree',
                  hint: 'e.g., 10th/12th',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMinimalInput(
                  controller: _fieldController,
                  label: 'Field',
                  hint: 'e.g., Science',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMinimalInput(
                  controller: _gradeController,
                  label: 'Grade',
                  hint: 'e.g., 85%',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMinimalInput(
                  controller: _startYearController,
                  label: 'Start',
                  hint: '2018',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMinimalInput(
                  controller: _endYearController,
                  label: 'End',
                  hint: '2020',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addAcademicRecord,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Record'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalInput({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.outfit(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        labelStyle: GoogleFonts.outfit(fontSize: 13),
        hintStyle: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[400]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.gradientBackground,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              decoration: AppTheme.clayDecoration.copyWith(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Custom Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentStep > 0)
                          IconButton(
                            onPressed: _prevStep,
                            icon: const Icon(Icons.arrow_back_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                            ),
                          )
                        else
                          const SizedBox(width: 48),

                        Expanded(
                          child: Text(
                            'Setup Profile',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColor,
                            ),
                          ),
                        ),

                        TextButton(
                          onPressed: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/dashboard',
                              (route) => false,
                            );
                          },
                          child: Text(
                            'Skip',
                            style: GoogleFonts.outfit(
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Modern Progress Indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 8,
                    ),
                    child: Row(
                      children: List.generate(4, (index) {
                        final isActive = index <= _currentStep;
                        final isCompleted = index < _currentStep;

                        return Expanded(
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? Colors.green
                                      : isActive
                                      ? AppTheme.primaryColor
                                      : Colors.grey[200],
                                  shape: BoxShape.circle,
                                  boxShadow: isActive || isCompleted
                                      ? [
                                          BoxShadow(
                                            color:
                                                (isCompleted
                                                        ? Colors.green
                                                        : AppTheme.primaryColor)
                                                    .withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                              if (index < 3)
                                Expanded(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    height: 2,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    color: index < _currentStep
                                        ? AppTheme.primaryColor
                                        : Colors.grey[200],
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Content (PageView)
                  SizedBox(
                    height:
                        500, // Fixed height for consistency in "pop-up" style
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildPhotoStep(),
                        _buildPersonalDetailsStep(),
                        _buildSkillsStep(),
                        _buildAcademicStep(),
                      ],
                    ),
                  ),

                  // Navigation Buttons
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: _isLoading ? null : _nextStep,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                              shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _currentStep == 3
                                        ? 'Complete Profile'
                                        : 'Next Step',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
