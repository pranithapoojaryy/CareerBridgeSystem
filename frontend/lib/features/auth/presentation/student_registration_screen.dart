import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import 'auth_controller.dart';

class StudentRegistrationScreen extends ConsumerStatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  ConsumerState<StudentRegistrationScreen> createState() =>
      _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState
    extends ConsumerState<StudentRegistrationScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Step 1: Basic Info
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Step 2: College Selection
  String? _selectedCollegeId;
  String? _detectedCollege;
  List<Map<String, dynamic>> _availableColleges = [];
  bool _isLoadingColleges = true;

  // Step 3: Academic Details
  final _usnController = TextEditingController();
  String? _selectedDepartment;
  String? _selectedProgram;
  String? _selectedBatch;
  final _currentSemesterController = TextEditingController();
  final _cgpaController = TextEditingController();

  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _programs = [];
  List<Map<String, dynamic>> _batches = [];

  bool _isLoading = false;
  bool _isLoadingDepartments = false;
  bool _isLoadingPrograms = false;
  bool _isLoadingBatches = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadColleges();
    _emailController.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usnController.dispose();
    _currentSemesterController.dispose();
    _cgpaController.dispose();
    super.dispose();
  }

  Future<void> _loadColleges() async {
    setState(() => _isLoadingColleges = true);

    try {
      // Get all organizations and filter for colleges
      final response = await Supabase.instance.client
          .from('organizations')
          .select('id, name, allowed_emails_domain, type')
          .order('name');

      // Filter for colleges (include all educational institution types)
      final colleges = response
          .where(
            (org) =>
                org['type'] == 'college' ||
                org['type'] == 'university' ||
                org['type'] == 'institute' ||
                org['type'] ==
                    'Affiliated' || // Include the actual type from database
                org['type'] == null, // Include null types (default to college)
          )
          .toList();

      // If no colleges found, create a sample one for testing
      if (colleges.isEmpty) {
        await _createSampleCollege();
        // Reload after creating sample
        return _loadColleges();
      }

      setState(() {
        _availableColleges = List<Map<String, dynamic>>.from(colleges);
        _isLoadingColleges = false;
      });

      // Re-trigger email check in case they already typed it before load finished
      _onEmailChanged();
    } catch (e) {
      setState(() => _isLoadingColleges = false);

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading colleges: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createSampleCollege() async {
    try {
      await Supabase.instance.client.from('organizations').insert({
        'name': 'PES Institute of Management (Sample)',
        'type': 'college',
        'allowed_emails_domain': 'pim.ac.in',
        'website': 'https://pim.ac.in',
        'description': 'Sample college for testing student registration',
      });
      print('Sample college created successfully');
    } catch (e) {
      print('Error creating sample college: $e');
    }
  }

  void _onEmailChanged() {
    final email = _emailController.text.trim();
    if (email.contains('@')) {
      final domain = email.split('@').last.toLowerCase();

      // Find matching college by domain (support comma-separated lists)
      final matchingCollege = _availableColleges.firstWhere((college) {
        final collegeDomainStr = (college['allowed_emails_domain'] ?? '')
            .toString()
            .toLowerCase();
        final domains = collegeDomainStr.split(',').map((d) => d.trim());
        return domains.contains(domain);
      }, orElse: () => {});

      if (matchingCollege.isNotEmpty) {
        if (_selectedCollegeId != matchingCollege['id']) {
          setState(() {
            _detectedCollege = matchingCollege['name'];
            _selectedCollegeId = matchingCollege['id'];
          });
          _loadDepartments(matchingCollege['id']);
        }
      } else {
        if (_selectedCollegeId != null) {
          setState(() {
            _detectedCollege = null;
            _selectedCollegeId = null;
          });
        }
      }
    }
  }

  Future<void> _loadDepartments(String collegeId) async {
    setState(() => _isLoadingDepartments = true);

    try {
      final response = await Supabase.instance.client
          .from('college_departments')
          .select('id, name')
          .eq('org_id', collegeId)
          .order('name');

      setState(() {
        _departments = List<Map<String, dynamic>>.from(response);
        _selectedDepartment = null;
        _programs = [];
        _batches = [];
        _isLoadingDepartments = false;
      });
    } catch (e) {
      setState(() => _isLoadingDepartments = false);

      // Don't show error for empty departments - it's expected due to RLS
      setState(() {
        _departments = [];
        _selectedDepartment = null;
        _programs = [];
        _batches = [];
      });
    }
  }

  Future<void> _loadPrograms(String departmentId) async {
    setState(() => _isLoadingPrograms = true);

    try {
      final response = await Supabase.instance.client
          .from('college_programs')
          .select('id, name, duration_years')
          .eq('dept_id', departmentId)
          .order('name');

      setState(() {
        _programs = List<Map<String, dynamic>>.from(response);
        _selectedProgram = null;
        _batches = [];
        _isLoadingPrograms = false;
      });
    } catch (e) {
      setState(() => _isLoadingPrograms = false);

      // Don't show error for empty programs - it's expected due to RLS
      setState(() {
        _programs = [];
        _selectedProgram = null;
        _batches = [];
      });
    }
  }

  Future<void> _loadBatches(String programId) async {
    setState(() => _isLoadingBatches = true);

    try {
      final response = await Supabase.instance.client
          .from('college_batches')
          .select('id, name, start_year, end_year')
          .eq('program_id', programId)
          .order('start_year', ascending: false);

      setState(() {
        _batches = List<Map<String, dynamic>>.from(response);
        _selectedBatch = null;
        _isLoadingBatches = false;
      });
    } catch (e) {
      setState(() => _isLoadingBatches = false);

      // Don't show error for empty batches - it's expected due to RLS
      setState(() {
        _batches = [];
        _selectedBatch = null;
      });
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      if (_validateCurrentStep()) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentStep++);
      }
    } else {
      _register();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _formKey.currentState?.validate() ?? false;
      case 1:
        return _selectedCollegeId != null;
      case 2:
        // Only require USN - other fields are optional due to database constraints
        return _usnController.text.isNotEmpty;
      default:
        return true;
    }
  }

  Future<void> _register() async {
    if (!_validateCurrentStep()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authControllerProvider.notifier)
          .signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            role: 'student',
            additionalData: {
              'full_name': _nameController.text.trim(),
              'phone': _phoneController.text.trim(),
              'college_id': _selectedCollegeId,
              'department_id': _selectedDepartment, // Can be null
              'program_id': _selectedProgram, // Can be null
              'batch_id': _selectedBatch, // Can be null
              'usn': _usnController.text.trim(),
              'current_semester':
                  int.tryParse(_currentSemesterController.text) ?? 1,
              'cgpa': double.tryParse(_cgpaController.text) ?? 0.0,
            },
          );

      // Check if the authController ended up in an error state
      final authState = ref.read(authControllerProvider);
      if (authState.hasError) {
        throw authState.error!;
      }

      if (mounted) {
        // Show success message
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(
              'Registration Successful!',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'A verification email has been sent to ${_emailController.text.trim()}.\n\nPlease check your email and click the verification link to continue.',
              style: GoogleFonts.outfit(),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  ); // Redirect to root (AuthWrapper)
                },
                child: Text(
                  'OK',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString().toLowerCase();
        String userMessage;

        if (errorStr.contains('already registered') ||
            errorStr.contains('user already exists') ||
            errorStr.contains('duplicate') ||
            errorStr.contains('already been registered')) {
          userMessage =
              'This email is already registered. Please login or use a different email.';
        } else if (errorStr.contains('weak password') ||
            errorStr.contains('password')) {
          userMessage =
              'Password is too weak. Please use at least 6 characters.';
        } else if (errorStr.contains('invalid email') ||
            errorStr.contains('email')) {
          userMessage = 'Please enter a valid email address.';
        } else if (errorStr.contains('network') ||
            errorStr.contains('connection') ||
            errorStr.contains('socket')) {
          userMessage =
              'Network error. Please check your internet connection and try again.';
        } else {
          userMessage = 'Registration failed. Please try again.\n$e';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Left Side (Illustration) - Only on Wide Screens
          if (isWide)
            Expanded(
              flex: 4,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE0F2FE), Color(0xFFF3E8FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(48.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo Placeholder (Clay Style)
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(10, 10),
                            ),
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.5),
                              blurRadius: 20,
                              offset: const Offset(-5, -5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'CareerBridge',
                        style: GoogleFonts.outfit(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      Text(
                        'Student Onboarding Portal',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 64),
                      _buildBulletPoint('Verify your academic identity'),
                      const SizedBox(height: 24),
                      _buildBulletPoint('Connect with your college & peers'),
                      const SizedBox(height: 24),
                      _buildBulletPoint('Get personalized placement training'),
                    ],
                  ),
                ),
              ),
            ),

          // Right Side (Form)
          Expanded(
            flex: 6,
            child: Column(
              children: [
                if (!isWide)
                  AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      onPressed: _prevStep,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    title: Text(
                      'Student Registration',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor,
                      ),
                    ),
                  ),

                // Progress Indicator
                Container(
                  padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
                  child: Row(
                    children: List.generate(3, (index) {
                      final isActive = index <= _currentStep;
                      final isCompleted = index < _currentStep;

                      return Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? Colors.green
                                    : isActive
                                    ? AppTheme.primaryColor
                                    : Colors.grey[300],
                                shape: BoxShape.circle,
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.primaryColor
                                              .withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                isCompleted
                                    ? Icons.check_rounded
                                    : Icons.circle,
                                color: Colors.white,
                                size: isCompleted ? 16 : 8,
                              ),
                            ),
                            if (index < 2)
                              Expanded(
                                child: Container(
                                  height: 3,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: index < _currentStep
                                        ? AppTheme.primaryColor
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),

                // Step Labels
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Basic Details',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: _currentStep == 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _currentStep >= 0
                              ? AppTheme.primaryColor
                              : Colors.grey,
                        ),
                      ),
                      Text(
                        'Verification',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: _currentStep == 1
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _currentStep >= 1
                              ? AppTheme.primaryColor
                              : Colors.grey,
                        ),
                      ),
                      Text(
                        'Academics',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: _currentStep == 2
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _currentStep >= 2
                              ? AppTheme.primaryColor
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Content
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildBasicInfoStep(),
                        _buildCollegeSelectionStep(),
                        _buildAcademicDetailsStep(),
                      ],
                    ),
                  ),
                ),

                // Navigation Buttons (Sticky at bottom on mobile, side by side)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _prevStep,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Previous',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (_currentStep > 0) const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isLoading ? null : _nextStep,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  _currentStep == 2
                                      ? 'Complete Registration'
                                      : 'Continue',
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Basic Information'),

            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'e.g. Rahul Sharma',
              icon: Icons.person_outline_rounded,
              validator: (value) => (value?.isEmpty ?? true)
                  ? 'Please enter your full name'
                  : null,
            ),
            const SizedBox(height: 24),

            _buildTextField(
              controller: _emailController,
              label: 'Email Address',
              hint: 'e.g. rahul@college.edu',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Please enter your email';
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value!)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
              suffixIcon: _detectedCollege != null
                  ? Icon(
                      Icons.verified_rounded,
                      color: Colors.green[600],
                      size: 18,
                    )
                  : null,
            ),

            if (_detectedCollege != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: Colors.green[600],
                        size: 16,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Linked: $_detectedCollege',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              hint: 'e.g. +91 9876543210',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) => (value?.isEmpty ?? true)
                  ? 'Please enter your phone number'
                  : null,
            ),
            const SizedBox(height: 24),

            _buildTextField(
              controller: _passwordController,
              label: 'Password',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscureText: !_isPasswordVisible,
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                  color: Colors.grey[400],
                ),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Please enter a password';
                if (value!.length < 6)
                  return 'Password must be at least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 24),

            _buildTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscureText: !_isPasswordVisible,
              validator: (value) {
                if (value?.isEmpty ?? true)
                  return 'Please confirm your password';
                if (value != _passwordController.text)
                  return 'Passwords do not match';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollegeSelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Verify Identity'),
          Text(
            _detectedCollege != null
                ? 'We identified your institution from your email domain. Please confirm if this is correct.'
                : 'Please select your institution from the list below to link your account.',
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 32),

          if (_detectedCollege != null && _selectedCollegeId != null) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.school_rounded,
                        color: AppTheme.primaryColor,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _detectedCollege!,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Verified Workspace',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.green[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green[600],
                    size: 32,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Something wrong?',
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (_isLoadingColleges)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_availableColleges.isEmpty)
            _buildEmptyCollegesView()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _availableColleges.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final college = _availableColleges[index];
                final isSelected = _selectedCollegeId == college['id'];

                return InkWell(
                  onTap: () {
                    setState(() => _selectedCollegeId = college['id']);
                    _loadDepartments(college['id']);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.account_balance_rounded,
                            color: isSelected ? Colors.white : Colors.grey[500],
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                college['name'],
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                              if (college['allowed_emails_domain'] != null)
                                Text(
                                  '@${college['allowed_emails_domain']}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.radio_button_checked_rounded,
                            color: AppTheme.primaryColor,
                          )
                        else
                          Icon(
                            Icons.radio_button_off_rounded,
                            color: Colors.grey[300],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyCollegesView() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(Icons.school_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No Colleges Found',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We couldn\'t find any institutions in your region.',
            style: GoogleFonts.outfit(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _loadColleges,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Academic Details'),
          Text(
            'Secure your spot by providing your current academic standing.',
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 32),

          _buildTextField(
            controller: _usnController,
            label: 'USN / University Roll Number',
            hint: 'e.g. 4XX20CS001',
            icon: Icons.badge_outlined,
            validator: (value) =>
                (value?.isEmpty ?? true) ? 'Please enter your USN' : null,
          ),
          const SizedBox(height: 24),

          _buildDropdownField(
            label: 'Department',
            value: _selectedDepartment,
            hint: 'Select Department',
            icon: Icons.business_outlined,
            isLoading: _isLoadingDepartments,
            items: _departments
                .map(
                  (dept) => DropdownMenuItem(
                    value: dept['id'].toString(),
                    child: Text(dept['name'].toString()),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedDepartment = value;
                _selectedProgram = null;
                _selectedBatch = null;
              });
              if (value != null) _loadPrograms(value);
            },
            validator: (value) => _departments.isNotEmpty && value == null
                ? 'Please select department'
                : null,
          ),
          const SizedBox(height: 24),

          _buildDropdownField(
            label: 'Program',
            value: _selectedProgram,
            hint: 'Select Program',
            icon: Icons.school_outlined,
            isLoading: _isLoadingPrograms,
            items: _programs
                .map(
                  (prog) => DropdownMenuItem(
                    value: prog['id'].toString(),
                    child: Text(
                      '${prog['name']} (${prog['duration_years']} yrs)',
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedProgram = value;
                _selectedBatch = null;
              });
              if (value != null) _loadBatches(value);
            },
            validator: (value) => _programs.isNotEmpty && value == null
                ? 'Please select program'
                : null,
          ),
          const SizedBox(height: 24),

          _buildDropdownField(
            label: 'Graduation Batch',
            value: _selectedBatch,
            hint: 'Select Batch',
            icon: Icons.group_outlined,
            isLoading: _isLoadingBatches,
            items: _batches
                .map(
                  (batch) => DropdownMenuItem(
                    value: batch['id'].toString(),
                    child: Text(
                      '${batch['name']} (${batch['start_year']}-${batch['end_year']})',
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedBatch = value),
            validator: (value) => _batches.isNotEmpty && value == null
                ? 'Please select batch'
                : null,
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _currentSemesterController,
                  label: 'Semester',
                  hint: 'e.g. 6',
                  icon: Icons.calendar_today_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Required';
                    final s = int.tryParse(value!);
                    if (s == null || s < 1 || s > 10) return '1-10';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _cgpaController,
                  label: 'Current CGPA',
                  hint: 'e.g. 8.5',
                  icon: Icons.grade_outlined,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Required';
                    final c = double.tryParse(value!);
                    if (c == null || c < 0 || c > 10) return '0-10';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
    bool isLoading = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          style: GoogleFonts.outfit(fontSize: 16, color: AppTheme.textColor),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
            suffixIcon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 2, width: 40, color: AppTheme.primaryColor),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.outfit(fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF64748B),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 18,
              color: const Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }
}
