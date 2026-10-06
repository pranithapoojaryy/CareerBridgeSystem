import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to login after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Logo
                SizedBox(
                      width: 200,
                      height: 200,
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    )
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .scale(
                      duration: 2.seconds,
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.05, 1.05),
                      curve: Curves.easeInOut,
                    ) // Soft breathing effect
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .slideY(
                      begin: 0.5,
                      end: 0,
                      duration: 800.ms,
                      curve: Curves.easeOutBack,
                    ), // Initial bounce in

                const SizedBox(height: 24),

                // Title
                Text(
                      'CareerBridge',
                      style: GoogleFonts.outfit(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                        letterSpacing: 1.2,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms)
                    .moveY(begin: 20, end: 0),

                const SizedBox(height: 12),

                // Tagline
                Text(
                  'Unlock Opportunities. Build Futures.',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(delay: 800.ms, duration: 600.ms),

                const SizedBox(height: 40),

                // Loading Indicator (Clay style)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                    strokeWidth: 4,
                    backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.3),
                  ),
                ).animate().fadeIn(delay: 1200.ms),

                const SizedBox(height: 40),

                // Footer
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Column(
                    children: [
                      Text(
                        'Powered by Supabase + Flutter',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '© 2024 CareerBridge',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 1500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
