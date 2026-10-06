import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import 'auth_controller.dart';

import 'widgets/platform_analytics_board.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  String _selectedRole = 'Student'; // Default role for UI toggle

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      await ref
          .read(authControllerProvider.notifier)
          .signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
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
        // Navigate to root on success to let AuthWrapper handle redirection
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    });

    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Desktop View (Split Layout)
            // Triggering Hot Reload for updates
            if (constraints.maxWidth > 1000) {
              return Row(
                children: [
                  // Left Side: Analytics Dashboard
                  Expanded(flex: 6, child: const PlatformAnalyticsBoard()),

                  // Right Side: Login Form
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: _buildLoginForm(authState),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            // Mobile/Tablet View (Centered Layout)
            // Mobile/Tablet View (Vertical Layout)
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: _buildLoginForm(authState),
                    ),
                  ),
                  const SizedBox(height: 64),

                  // Show Analytics Board below login on mobile
                  const PlatformAnalyticsBoard(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoginForm(AsyncValue<void> authState) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo
        SizedBox(
          width: 180, // Width-based sizing to prevent vertical gaps
          child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
        ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

        // Removed spacing as requested
        // Text and Tagline
        Column(
          children: [
            Text(
              'CareerBridge',
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

            Text(
              'Networking and Placement Training System',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
          ],
        ),
        const SizedBox(height: 24),

        // Login Card
        Container(
              padding: const EdgeInsets.all(32),
              decoration: AppTheme.clayDecoration,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      children: [
                        Text(
                          'Welcome Back',
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Icon(
                          Icons.login_rounded,
                          color: AppTheme.primaryColor,
                          size: 28,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Login to your account',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Role Toggle
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4F8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          _buildRoleButton('Student', Icons.school),
                          _buildRoleButton('Recruiter', Icons.business_center),
                          _buildRoleButton('College', Icons.account_balance),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Email Input
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        hintText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Input
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
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),


                    const SizedBox(height: 24),

                    // Login Button
                    FilledButton(
                          onPressed: authState.isLoading ? null : _login,
                          child: authState.isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Login'),
                        )
                        .animate(target: authState.isLoading ? 0 : 1)
                        .scale(duration: 200.ms),

                    const SizedBox(height: 16),

                    // Sign Up Link
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: GoogleFonts.outfit(color: Colors.grey[600]),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/role-selection'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Sign Up',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
            .animate()
            .slideY(
              begin: 0.2,
              end: 0,
              duration: 600.ms,
              curve: Curves.easeOutQuad,
            )
            .fadeIn(duration: 600.ms),

        const SizedBox(height: 32),

        // Motivational Quote
        Text(
          '"Your journey to a successful career starts here."',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: AppTheme.primaryColor.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 800.ms),
      ],
    );
  }

  Widget _buildRoleButton(String role, IconData icon) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedRole = role),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[500],
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
