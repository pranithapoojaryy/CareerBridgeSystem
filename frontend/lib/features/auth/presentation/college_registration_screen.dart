import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../organization/data/organization_repository.dart';
import 'auth_controller.dart';

class CollegeRegistrationScreen extends ConsumerStatefulWidget {
  const CollegeRegistrationScreen({super.key});

  @override
  ConsumerState<CollegeRegistrationScreen> createState() =>
      _CollegeRegistrationScreenState();
}

class _CollegeRegistrationScreenState
    extends ConsumerState<CollegeRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers - Organization
  final _collegeNameController = TextEditingController();
  final _shortCodeController = TextEditingController();
  final _websiteController = TextEditingController();
  String _selectedType = 'Autonomous';
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  // Controllers - Primary Contact (Admin)
  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPhoneController = TextEditingController();
  final _designationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Controllers - Preferences
  final _defaultProgramsController = TextEditingController(
    text: 'MBA, MCA, B.Tech',
  );
  final _defaultBatchesController = TextEditingController(text: '2024-2026');

  bool _isLoading = false;
  bool _isShortCodeAvailable = true;

  @override
  void dispose() {
    _collegeNameController.dispose();
    _shortCodeController.dispose();
    _websiteController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _adminNameController.dispose();
    _adminEmailController.dispose();
    _adminPhoneController.dispose();
    _designationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _defaultProgramsController.dispose();
    _defaultBatchesController.dispose();
    super.dispose();
  }

  Future<void> _checkShortCode(String value) async {
    if (value.length < 3) return;
    final repo = OrganizationRepository(Supabase.instance.client);
    final available = await repo.checkShortCodeAvailability(value);
    setState(() {
      _isShortCodeAvailable = available;
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isShortCodeAvailable) return;

    setState(() => _isLoading = true);

    try {
      // 1. Create Admin User
      final authRepo = ref.read(authRepositoryProvider);
      final response = await authRepo.signUp(
        email: _adminEmailController.text.trim(),
        password: _passwordController.text.trim(),
        role: 'college',
        additionalData: {
          'full_name': _adminNameController.text.trim(),
          'designation': _designationController.text.trim(),
          'phone': _adminPhoneController.text.trim(),
          'type': 'primary_admin',
        },
      );

      final user = response.user;
      if (user == null) throw Exception('User creation failed');

      // 2. Create Organization
      final orgRepo = OrganizationRepository(Supabase.instance.client);
      await orgRepo.createOrganization(
        userId: user.id,
        name: _collegeNameController.text.trim(),
        shortCode: _shortCodeController.text.trim(),
        type: _selectedType,
        website: _websiteController.text.trim(),
        addressCity: _cityController.text.trim(),
        addressState: _stateController.text.trim(),
        programs: _defaultProgramsController.text
            .split(',')
            .map((e) => e.trim())
            .toList(),
        batches: _defaultBatchesController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration Successful! Pending Approval.'),
          ),
        );
        // Navigate to root so AuthWrapper handles the unverified session correctly
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we are on wide screen (web/desktop) or mobile
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Very light cool grey/white
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
                          Icons.school,
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
                        'Networking and Placement Training System',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 64),
                      _buildBulletPoint(
                        'Onboard your entire college in one place',
                      ),
                      const SizedBox(height: 24),
                      _buildBulletPoint(
                        'Manage students, drives, and analytics',
                      ),
                      const SizedBox(height: 24),
                      _buildBulletPoint(
                        'Secure, structured, multi-department support',
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Right Side (Form)
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isWide) ...[
                          Center(
                            child: Text(
                              'CareerBridge',
                              style: GoogleFonts.outfit(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],

                        Text(
                          'Register Your Institution',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create a digital campus for your placement cell.',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Section 1: Institution Details
                        _buildSectionHeader('Institution Details'),
                        _buildTextField(
                          controller: _collegeNameController,
                          label: 'College Name',
                          hint: 'Poornaprajna Institute of Management',
                          icon: Icons.account_balance,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _shortCodeController,
                                label: 'Short Code / Handle',
                                hint: 'pim-udupi',
                                icon: Icons.link,
                                onChanged: (val) => _checkShortCode(val),
                                errorText: !_isShortCodeAvailable
                                    ? 'Handle already taken'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedType,
                                decoration: InputDecoration(
                                  labelText: 'College Type',
                                  prefixIcon: const Icon(Icons.category),
                                  fillColor: const Color(0XFFF1F5F9),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                items:
                                    [
                                          'Autonomous',
                                          'Affiliated',
                                          'University',
                                          'Trust',
                                        ]
                                        .map(
                                          (t) => DropdownMenuItem(
                                            value: t,
                                            child: Text(t),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedType = v!),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 12, top: 8),
                          child: Text(
                            'Your space: ${_shortCodeController.text.isEmpty ? '...' : _shortCodeController.text}.CareerBridge.in',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _websiteController,
                          label: 'Official Website',
                          hint: 'https://www.pim.ac.in',
                          icon: Icons.language,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _cityController,
                                label: 'City',
                                icon: Icons.location_city,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _stateController,
                                label: 'State',
                                icon: Icons.map,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),
                        // Section 2: Primary Contact
                        _buildSectionHeader('Primary Contact (Admin)'),
                        _buildTextField(
                          controller: _adminNameController,
                          label: 'Full Name',
                          hint: 'Dr. John Doe',
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _designationController,
                          label: 'Designation',
                          hint: 'Placement Officer',
                          icon: Icons.badge,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _adminEmailController,
                          label: 'Official Email',
                          hint: 'placement@pim.ac.in',
                          icon: Icons.email,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _adminPhoneController,
                          label: 'Phone Number',
                          icon: Icons.phone,
                        ),

                        const SizedBox(height: 40),
                        // Section 3: Credentials
                        _buildSectionHeader('Account Setup'),
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.lock,
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          icon: Icons.lock_clock,
                          obscureText: true,
                          validator: (val) {
                            if (val != _passwordController.text)
                              return 'Passwords do not match';
                            return null;
                          },
                        ),

                        const SizedBox(height: 40),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _register,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    'Complete Registration',
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
    Function(String)? onChanged,
    String? errorText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      validator: validator ?? (val) => val?.isEmpty == true ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey[400]),
        filled: true,
        fillColor: const Color(0xFFF1F5F9), // Clay-like background
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
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        errorText: errorText,
      ),
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
