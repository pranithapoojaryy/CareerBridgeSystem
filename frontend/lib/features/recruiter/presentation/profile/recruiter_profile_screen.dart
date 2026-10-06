import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/recruiter_profile_repository.dart';

class RecruiterProfileScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;
  const RecruiterProfileScreen({super.key, this.onBackPressed});

  @override
  State<RecruiterProfileScreen> createState() => _RecruiterProfileScreenState();
}

class _RecruiterProfileScreenState extends State<RecruiterProfileScreen> {
  final _repository = RecruiterProfileRepository();
  Map<String, dynamic>? _recruiterProfile;
  Map<String, dynamic>? _companyInfo;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isUploadingLogo = false;
  bool _isUploadingBanner = false;

  // Controllers for editable fields
  final _companyNameController = TextEditingController();
  final _taglineController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _industryController = TextEditingController();
  final _companySizeController = TextEditingController();
  final _headquartersController = TextEditingController();
  final _websiteController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _twitterController = TextEditingController();
  final _facebookController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _domainController = TextEditingController();
  final _foundedYearController = TextEditingController();

  final List<String> _specialties = [];
  final List<String> _domains = [];

  // Company size options
  final List<String> _companySizeOptions = [
    '1-10 employees',
    '11-50 employees',
    '51-200 employees',
    '201-500 employees',
    '501-1000 employees',
    '1001-5000 employees',
    '5000+ employees',
  ];

  // Industry options
  final List<String> _industryOptions = [
    'Technology',
    'Healthcare',
    'Finance',
    'Education',
    'Manufacturing',
    'Retail',
    'Consulting',
    'Real Estate',
    'Media & Entertainment',
    'Transportation',
    'Energy',
    'Telecommunications',
    'Hospitality',
    'Agriculture',
    'Construction',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadRecruiterProfile();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _taglineController.dispose();
    _descriptionController.dispose();
    _industryController.dispose();
    _companySizeController.dispose();
    _headquartersController.dispose();
    _websiteController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _linkedinController.dispose();
    _twitterController.dispose();
    _facebookController.dispose();
    _specialtyController.dispose();
    _domainController.dispose();
    _foundedYearController.dispose();
    super.dispose();
  }

  Future<void> _loadRecruiterProfile() async {
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

      final profile = await _repository.getRecruiterProfile(user.id);

      if (mounted) {
        setState(() {
          _recruiterProfile = profile;
          _companyInfo = profile['organization'];
          _isLoading = false;

          if (_companyInfo != null) {
            // Populate controllers
            _companyNameController.text = _companyInfo!['name'] ?? '';
            _taglineController.text = _companyInfo!['tagline'] ?? '';
            _descriptionController.text = _companyInfo!['description'] ?? '';
            _industryController.text = _companyInfo!['industry'] ?? '';
            _companySizeController.text = _companyInfo!['company_size'] ?? '';
            _headquartersController.text = _companyInfo!['headquarters'] ?? '';
            _websiteController.text = _companyInfo!['website'] ?? '';
            _phoneController.text = _companyInfo!['phone'] ?? '';
            _emailController.text = _companyInfo!['email'] ?? '';
            _foundedYearController.text =
                _companyInfo!['established_year']?.toString() ?? '';

            // Social links
            final socialLinks =
                _companyInfo!['social_links'] as Map<String, dynamic>?;
            if (socialLinks != null) {
              _linkedinController.text = socialLinks['linkedin'] ?? '';
              _twitterController.text = socialLinks['twitter'] ?? '';
              _facebookController.text = socialLinks['facebook'] ?? '';
            }

            // Populate specialties and domains
            if (_companyInfo!['specialties'] != null) {
              _specialties.clear();
              _specialties.addAll(
                List<String>.from(_companyInfo!['specialties']),
              );
            }
            if (_companyInfo!['domains'] != null) {
              _domains.clear();
              _domains.addAll(List<String>.from(_companyInfo!['domains']));
            }
          }
        });
      }
    } catch (e) {
      print('Error loading recruiter profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadRecruiterProfile,
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    try {
      if (_companyInfo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No company linked to this profile'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Prepare social links
      final socialLinks = {
        'linkedin': _linkedinController.text.trim(),
        'twitter': _twitterController.text.trim(),
        'facebook': _facebookController.text.trim(),
      };

      // Update organization
      await _repository.updateOrganization(_companyInfo!['id'], {
        'name': _companyNameController.text.trim(),
        'tagline': _taglineController.text.trim(),
        'description': _descriptionController.text.trim(),
        'industry': _industryController.text.trim(),
        'company_size': _companySizeController.text.trim(),
        'headquarters': _headquartersController.text.trim(),
        'website': _websiteController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'established_year': _foundedYearController.text.isNotEmpty
            ? int.tryParse(_foundedYearController.text)
            : null,
        'social_links': socialLinks,
        'specialties': _specialties,
        'domains': _domains,
      });

      setState(() => _isEditing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _loadRecruiterProfile(); // Refresh data
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

  void _addSpecialty() {
    final specialty = _specialtyController.text.trim();
    if (specialty.isNotEmpty && !_specialties.contains(specialty)) {
      setState(() {
        _specialties.add(specialty);
        _specialtyController.clear();
      });
    }
  }

  void _addDomain() {
    final domain = _domainController.text.trim();
    if (domain.isNotEmpty && !_domains.contains(domain)) {
      setState(() {
        _domains.add(domain);
        _domainController.clear();
      });
    }
  }

  Future<void> _selectCompanyLogo() async {
    if (_companyInfo == null) return;

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
              'Select Company Logo',
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

    setState(() => _isUploadingLogo = true);

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final logoUrl = await _repository.uploadCompanyLogo(
          _companyInfo!['id'],
          bytes,
          pickedFile.name,
        );

        if (logoUrl != null) {
          await _repository.updateOrganization(_companyInfo!['id'], {
            'logo_url': logoUrl,
          });

          if (mounted) {
            setState(() {
              _companyInfo!['logo_url'] =
                  '$logoUrl?t=${DateTime.now().millisecondsSinceEpoch}';
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Company logo updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating logo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingLogo = false);
      }
    }
  }

  Future<void> _selectCompanyBanner() async {
    if (_companyInfo == null) return;

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
              'Select Company Banner',
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

    setState(() => _isUploadingBanner = true);

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final bannerUrl = await _repository.uploadCompanyBanner(
          _companyInfo!['id'],
          bytes,
          pickedFile.name,
        );

        if (bannerUrl != null) {
          await _repository.updateOrganization(_companyInfo!['id'], {
            'banner_url': bannerUrl,
          });

          if (mounted) {
            setState(() {
              _companyInfo!['banner_url'] =
                  '$bannerUrl?t=${DateTime.now().millisecondsSinceEpoch}';
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Company banner updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating banner: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingBanner = false);
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_companyInfo == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Company Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.business_rounded, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No Company Linked',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please contact admin to link your profile to a company',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'Company Profile',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            if (widget.onBackPressed != null) {
              widget.onBackPressed!();
            } else {
              Navigator.maybePop(context);
            }
          },
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Edit Company Profile',
            )
          else ...[
            IconButton(
              onPressed: () {
                setState(() => _isEditing = false);
                _loadRecruiterProfile(); // Reset changes
              },
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Cancel',
            ),
            IconButton(
              onPressed: _saveProfile,
              icon: const Icon(Icons.check_rounded),
              tooltip: 'Save Changes',
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Banner
            _buildCompanyBanner(),

            // Main Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company Overview
                  _buildCompanyOverview(),
                  const SizedBox(height: 24),

                  // About Section
                  _buildAboutSection(),
                  const SizedBox(height: 24),

                  // Specialties
                  _buildSpecialtiesSection(),
                  const SizedBox(height: 24),

                  // Domains
                  _buildDomainsSection(),
                  const SizedBox(height: 24),

                  // Company Details
                  _buildCompanyDetailsSection(),
                  const SizedBox(height: 24),

                  // Contact Information
                  _buildContactSection(),
                  const SizedBox(height: 24),

                  // Social Links
                  _buildSocialLinksSection(),
                  const SizedBox(height: 24),

                  // Recruiter Information
                  _buildRecruiterInfoSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyBanner() {
    return Stack(
      children: [
        // Banner Image
        GestureDetector(
          onTap: _isEditing && !_isUploadingBanner
              ? _selectCompanyBanner
              : null,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              gradient: _companyInfo!['banner_url'] == null
                  ? LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              image: _companyInfo!['banner_url'] != null
                  ? DecorationImage(
                      image: NetworkImage(_companyInfo!['banner_url']),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _isUploadingBanner
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _isEditing && _companyInfo!['banner_url'] == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_photo_alternate_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add Company Banner',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
        ),

        // Edit Banner Button
        if (_isEditing &&
            _companyInfo!['banner_url'] != null &&
            !_isUploadingBanner)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: _selectCompanyBanner,
                icon: const Icon(Icons.edit_rounded, color: Colors.white),
                tooltip: 'Change Banner',
              ),
            ),
          ),

        // Company Logo (overlapping banner)
        Positioned(
          left: 24,
          bottom: -40,
          child: GestureDetector(
            onTap: _isEditing && !_isUploadingLogo ? _selectCompanyLogo : null,
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _isUploadingLogo
                      ? const Center(child: CircularProgressIndicator())
                      : _companyInfo!['logo_url'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _companyInfo!['logo_url'],
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.business_rounded,
                                size: 60,
                                color: Colors.grey[400],
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.business_rounded,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                ),

                // Edit Icon
                if (_isEditing && !_isUploadingLogo)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),

                // Verified Badge
                if (_companyInfo!['is_verified'] == true && !_isEditing)
                  Positioned(
                    top: 0,
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
              ],
            ),
          ),
        ),

        // Profile Completion Badge
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Profile ${_repository.calculateProfileCompletion(_recruiterProfile!)}% Complete',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyOverview() {
    return Container(
      margin: const EdgeInsets.only(top: 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company Name
          if (_isEditing)
            TextFormField(
              controller: _companyNameController,
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                labelText: 'Company Name',
                border: OutlineInputBorder(),
              ),
            )
          else
            Text(
              _companyInfo!['name'] ?? 'Company Name',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),

          const SizedBox(height: 8),

          // Tagline
          if (_isEditing)
            TextFormField(
              controller: _taglineController,
              decoration: const InputDecoration(
                labelText: 'Tagline',
                border: OutlineInputBorder(),
                hintText: 'Brief company tagline...',
              ),
            )
          else if (_companyInfo!['tagline'] != null)
            Text(
              _companyInfo!['tagline'],
              style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[700]),
            ),

          const SizedBox(height: 16),

          // Industry, Size, Location
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (_companyInfo!['industry'] != null || _isEditing)
                _buildInfoChip(
                  Icons.business_center_rounded,
                  _isEditing ? 'Industry' : _companyInfo!['industry'] ?? '',
                ),
              if (_companyInfo!['company_size'] != null || _isEditing)
                _buildInfoChip(
                  Icons.people_rounded,
                  _isEditing ? 'Size' : _companyInfo!['company_size'] ?? '',
                ),
              if (_companyInfo!['headquarters'] != null || _isEditing)
                _buildInfoChip(
                  Icons.location_on_rounded,
                  _isEditing ? 'HQ' : _companyInfo!['headquarters'] ?? '',
                ),
              if (_companyInfo!['established_year'] != null || _isEditing)
                _buildInfoChip(
                  Icons.calendar_today_rounded,
                  _isEditing
                      ? 'Founded'
                      : 'Founded ${_companyInfo!['established_year']}',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
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
            'About',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 16),

          if (_isEditing)
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Company Description',
                hintText: 'Tell us about your company, mission, and values...',
                border: OutlineInputBorder(),
              ),
            )
          else
            Text(
              _companyInfo!['description'] ?? 'No description provided',
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),

          if (_isEditing) ...[
            const SizedBox(height: 16),

            // Industry Dropdown
            DropdownButtonFormField<String>(
              value: _industryOptions.contains(_industryController.text)
                  ? _industryController.text
                  : null,
              decoration: const InputDecoration(
                labelText: 'Industry',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business_center_rounded),
              ),
              items: _industryOptions.map((industry) {
                return DropdownMenuItem(value: industry, child: Text(industry));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  _industryController.text = value;
                }
              },
            ),

            const SizedBox(height: 12),

            // Company Size Dropdown
            DropdownButtonFormField<String>(
              value: _companySizeOptions.contains(_companySizeController.text)
                  ? _companySizeController.text
                  : null,
              decoration: const InputDecoration(
                labelText: 'Company Size',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.people_rounded),
              ),
              items: _companySizeOptions.map((size) {
                return DropdownMenuItem(value: size, child: Text(size));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  _companySizeController.text = value;
                }
              },
            ),

            const SizedBox(height: 12),

            // Headquarters
            TextFormField(
              controller: _headquartersController,
              decoration: const InputDecoration(
                labelText: 'Headquarters',
                hintText: 'City, State, Country',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on_rounded),
              ),
            ),

            const SizedBox(height: 12),

            // Founded Year
            TextFormField(
              controller: _foundedYearController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Founded Year',
                hintText: 'e.g., 2020',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today_rounded),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecialtiesSection() {
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
            'Specialties',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 12),

          if (_isEditing) ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _specialtyController,
                    decoration: const InputDecoration(
                      labelText: 'Add Specialty',
                      hintText: 'e.g., AI/ML, Cloud Computing',
                      border: OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (_) => _addSpecialty(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addSpecialty,
                  icon: const Icon(Icons.add_circle),
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          if (_specialties.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _specialties.map((specialty) {
                return Chip(
                  label: Text(specialty),
                  deleteIcon: _isEditing
                      ? const Icon(Icons.close, size: 18)
                      : null,
                  onDeleted: _isEditing
                      ? () => setState(() => _specialties.remove(specialty))
                      : null,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  labelStyle: GoogleFonts.outfit(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList(),
            )
          else
            Text(
              'No specialties added yet',
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildDomainsSection() {
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
            'Business Domains',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 12),

          if (_isEditing) ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _domainController,
                    decoration: const InputDecoration(
                      labelText: 'Add Domain',
                      hintText: 'e.g., E-commerce, FinTech',
                      border: OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (_) => _addDomain(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addDomain,
                  icon: const Icon(Icons.add_circle),
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          if (_domains.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _domains.map((domain) {
                return Chip(
                  label: Text(domain),
                  deleteIcon: _isEditing
                      ? const Icon(Icons.close, size: 18)
                      : null,
                  onDeleted: _isEditing
                      ? () => setState(() => _domains.remove(domain))
                      : null,
                  backgroundColor: Colors.orange.withValues(alpha: 0.1),
                  labelStyle: GoogleFonts.outfit(
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList(),
            )
          else
            Text(
              'No domains added yet',
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildCompanyDetailsSection() {
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
            'Company Details',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 16),

          if (_isEditing)
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: 'Website',
                hintText: 'www.company.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.language_rounded),
              ),
            )
          else if (_companyInfo!['website'] != null)
            _buildDetailRow(
              'Website',
              _companyInfo!['website'],
              Icons.language_rounded,
              isLink: true,
            ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
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
            'Contact Information',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 16),

          if (_isEditing) ...[
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_rounded),
              ),
            ),
          ] else ...[
            if (_companyInfo!['phone'] != null)
              _buildDetailRow(
                'Phone',
                _companyInfo!['phone'],
                Icons.phone_rounded,
              ),
            if (_companyInfo!['email'] != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                'Email',
                _companyInfo!['email'],
                Icons.email_rounded,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSocialLinksSection() {
    final socialLinks = _companyInfo!['social_links'] as Map<String, dynamic>?;
    final hasAnyLinks =
        socialLinks != null &&
        (socialLinks['linkedin']?.isNotEmpty == true ||
            socialLinks['twitter']?.isNotEmpty == true ||
            socialLinks['facebook']?.isNotEmpty == true);

    if (!_isEditing && !hasAnyLinks) {
      return const SizedBox.shrink();
    }

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
            'Social Media',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 16),

          if (_isEditing) ...[
            TextFormField(
              controller: _linkedinController,
              decoration: const InputDecoration(
                labelText: 'LinkedIn',
                hintText: 'linkedin.com/company/...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _twitterController,
              decoration: const InputDecoration(
                labelText: 'Twitter',
                hintText: 'twitter.com/...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _facebookController,
              decoration: const InputDecoration(
                labelText: 'Facebook',
                hintText: 'facebook.com/...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
          ] else ...[
            if (socialLinks?['linkedin']?.isNotEmpty == true)
              _buildDetailRow(
                'LinkedIn',
                socialLinks!['linkedin'],
                Icons.link,
                isLink: true,
              ),
            if (socialLinks?['twitter']?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                'Twitter',
                socialLinks!['twitter'],
                Icons.link,
                isLink: true,
              ),
            ],
            if (socialLinks?['facebook']?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                'Facebook',
                socialLinks!['facebook'],
                Icons.link,
                isLink: true,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildRecruiterInfoSection() {
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
            'Your Information',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 16),

          _buildDetailRow(
            'Name',
            _recruiterProfile!['full_name'] ?? 'Not set',
            Icons.person_rounded,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Title',
            _recruiterProfile!['job_title'] ?? 'Not set',
            Icons.work_rounded,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Email',
            _recruiterProfile!['email'] ?? 'Not set',
            Icons.email_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    bool isLink = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              isLink
                  ? InkWell(
                      onTap: () => _launchUrl(value),
                      child: Text(
                        value,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          color: AppTheme.primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    )
                  : Text(
                      value,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        color: AppTheme.textColor,
                      ),
                    ),
            ],
          ),
        ),
        if (isLink) Icon(Icons.open_in_new, size: 16, color: Colors.grey[400]),
      ],
    );
  }
}
