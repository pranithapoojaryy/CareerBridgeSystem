import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import 'auth_controller.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Form Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(); // Added Phone
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  // Role specific controllers
  final _companyNameController = TextEditingController();
  final _collegeNameController = TextEditingController();
  final _designationController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  String _selectedRole = 'student';
  PlatformFile? _pickedResume;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyNameController.dispose();
    _collegeNameController.dispose();
    _designationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 1) {
      // Validate Form in Step 1
      if (_formKey.currentState!.validate()) {
        if (_selectedRole == 'student') {
          // Student goes to Resume step
          _pageController.nextPage(duration: 300.ms, curve: Curves.easeInOut);
          setState(() => _currentStep++);
        } else {
          // Others finish here
          _signup();
        }
      }
    } else if (_currentStep == 0) {
      // Role selection step
      if (_selectedRole == 'college') {
        Navigator.pushNamed(context, '/college-register');
      } else {
        _pageController.nextPage(duration: 300.ms, curve: Curves.easeInOut);
        setState(() => _currentStep++);
      }
    } else {
      // Last step for student
      _signup();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: 300.ms, curve: Curves.easeInOut);
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  Future<void> _pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result != null) {
      setState(() {
        _pickedResume = result.files.first;
      });
    }
  }

  Future<void> _signup() async {
    if (_currentStep == 1 && !_formKey.currentState!.validate()) {
      return;
    }

    // Build metadata map
    final Map<String, dynamic> metadata = {
      'full_name': _nameController.text.trim(),
    };

    if (_selectedRole == 'recruiter') {
      // Recruiter now only sends basic info. Setup is later.
      metadata['phone'] = _phoneController.text.trim();
    } else if (_selectedRole == 'faculty') {
      metadata['college_name'] = _companyNameController.text.trim();
      metadata['designation'] = _designationController.text.trim();
    }

    if (_selectedRole == 'faculty') {
      metadata['college_name'] = _collegeNameController.text.trim();
      metadata['designation'] = _designationController.text.trim();
    }

    try {
      await ref
          .read(authControllerProvider.notifier)
          .signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            role: _selectedRole,
            additionalData: metadata,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      // Only react when transitioning FROM a loading state (i.e. a real action completed)
      if (previous == null || !previous.isLoading) return;

      if (next.hasError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error.toString())));
      } else if (next.hasValue && !next.isLoading) {
        // Show confirmation dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(
              'Account Created',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'A confirmation email has been sent to ${_emailController.text.trim()}.\n\nPlease check your email and click the verification link to continue.',
              style: GoogleFonts.outfit(),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  context.pop(); // Close dialog
                  // Don't navigate - let auth state handle it
                  // User will be automatically routed to email verification screen
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
    });

    final totalSteps = _selectedRole == 'student' ? 3 : 2;

    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: _prevStep,
                      color: AppTheme.primaryColor,
                    ),
                    Expanded(
                      child: Text(
                        'Create Account',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Stepper
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStepIndicator(0, 'Role'),
                    _buildStepConnector(0, totalSteps),
                    _buildStepIndicator(1, 'Details'),
                    if (_selectedRole == 'student') ...[
                      _buildStepConnector(1, totalSteps),
                      _buildStepIndicator(2, 'Resume'),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Content
              Expanded(
                child: Form(
                  key: _formKey,
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // Step 0: Role Selection
                      _buildRoleStep(),
                      // Step 1: Dynamic Form
                      _buildDetailsStep(),
                      // Step 2: Resume (Conditional)
                      if (_selectedRole == 'student')
                        _buildResumeStep(authState.isLoading),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        AnimatedContainer(
          duration: 300.ms,
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryColor : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isActive ? AppTheme.primaryColor : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Center(
            child: isActive
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '${step + 1}',
                    style: GoogleFonts.outfit(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            color: isActive ? AppTheme.primaryColor : Colors.grey[400],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(int step, int totalSteps) {
    if (step >= totalSteps - 1) return const SizedBox.shrink();
    final isActive = _currentStep > step;
    return Expanded(
      child: Container(
        height: 4,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // STEP 0
  Widget _buildRoleStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Who are you?',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 32),

          _buildRoleCard(
            'student',
            'Student',
            Icons.school,
            'Looking for jobs & internships',
          ),
          const SizedBox(height: 16),
          _buildRoleCard(
            'recruiter',
            'Recruiter',
            Icons.business_center,
            'Hiring talent for company',
          ),
          const SizedBox(height: 16),
          _buildRoleCard(
            'college', // Changed from faculty
            'College', // Changed from College Faculty / TPO
            Icons.account_balance,
            'Register your institution',
          ),

          const SizedBox(height: 32),
          FilledButton(onPressed: _nextStep, child: const Text('Continue')),
        ],
      ).animate().fadeIn().slideX(begin: 0.1, end: 0),
    );
  }

  // STEP 1
  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _selectedRole == 'recruiter'
                ? 'Recruiter Sign Up'
                : _selectedRole == 'faculty'
                ? 'College Details'
                : 'Personal Details',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Common Fields
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) => v?.isEmpty == true ? 'Required' : null,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              hintText: 'Work Email Address', // Hint for recruiters
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) => v?.isEmpty == true ? 'Required' : null,
          ),
          const SizedBox(height: 16),

          // Recruiter Specific: Phone
          if (_selectedRole == 'recruiter') ...[
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            // No Company Name or Designation here anymore!
          ],

          if (_selectedRole == 'faculty') ...[
            TextFormField(
              controller: _collegeNameController,
              decoration: const InputDecoration(
                hintText: 'College/Institute Name',
                prefixIcon: Icon(Icons.account_balance),
              ),
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _designationController,
              decoration: const InputDecoration(
                hintText: 'Department / Designation',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
          ],

          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              hintText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
            ),
            validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 chars' : null,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_isPasswordVisible,
            decoration: const InputDecoration(
              hintText: 'Confirm Password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            validator: (v) => v != _passwordController.text ? 'Mismatch' : null,
          ),
          const SizedBox(height: 32),

          FilledButton(
            onPressed: () {
              // If next step exists (Resume), go there, else submit
              _selectedRole == 'student' ? _nextStep() : _signup();
            },
            child: Text(
              _selectedRole == 'student' ? 'Continue' : 'Create Account',
            ),
          ),
        ],
      ).animate().fadeIn().slideX(begin: 0.1, end: 0),
    );
  }

  // STEP 2 (Only Student)
  Widget _buildResumeStep(bool isLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Almost there!',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload your resume to get started (Optional)',
            style: GoogleFonts.outfit(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          GestureDetector(
            onTap: _pickResume,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _pickedResume != null
                            ? Icons.description
                            : Icons.cloud_upload_rounded,
                        size: 40,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _pickedResume != null
                          ? _pickedResume!.name
                          : 'Tap to upload Resume',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 48),

          FilledButton(
            onPressed: isLoading ? null : _signup,
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Create Account'),
          ),
        ],
      ).animate().fadeIn().slideX(begin: 0.1, end: 0),
    );
  }

  Widget _buildRoleCard(
    String value,
    String title,
    IconData icon,
    String subtitle,
  ) {
    final isSelected = _selectedRole == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = value),
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor.withValues(alpha: 0.1)
                    : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.primaryColor : Colors.grey[400],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey[700],
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }
}
