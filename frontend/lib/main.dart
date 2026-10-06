import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/college/presentation/dashboard/college_dashboard_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/role_selection_screen.dart';
import 'features/auth/presentation/student_registration_screen.dart';
import 'features/auth/presentation/college_registration_screen.dart';
import 'features/auth/presentation/recruiter_registration_screen.dart';
import 'features/auth/presentation/email_verification_screen.dart';
import 'features/student/presentation/student_profile_setup_screen.dart';
import 'features/student/presentation/student_dashboard_screen.dart';
import 'features/networking/presentation/screens/network_profile_view.dart';
import 'features/student/presentation/student_profile_screen.dart';
import 'features/interview/presentation/interview_landing_screen.dart';
import 'features/interview/presentation/learning_hub_screen.dart';
import 'features/student/presentation/course_detail_screen.dart';
import 'features/student/domain/learning_course.dart';
import 'features/interview/presentation/question_bank_screen.dart';
import 'features/interview/presentation/interview_result_screen.dart';
import 'features/interview/domain/interview_models.dart';
import 'features/recruiter/presentation/dashboard/recruiter_dashboard_screen.dart';
import 'features/shared/presentation/widgets/ai_assistant_widget.dart';
import 'core/navigation/navigation_service.dart';
import 'features/college/presentation/profile/college_public_profile_screen.dart';
import 'features/recruiter/presentation/events/recruiter_events_screen.dart';
import 'features/student/presentation/certificate_verify_page.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/navigation/route_tracking_observer.dart';
import 'core/utils/logger_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    LoggerService.warning("Warning: .env file not found, using defaults. Error: $e");
  }

  try {
    // Initialize Supabase with your project credentials
    await Supabase.initialize(
      url: 'https://cpjyqgsuqsihryxcwazv.supabase.co', // Your Supabase URL
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNwanlxZ3N1cXNpaHJ5eGN3YXp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ2NTIyMTUsImV4cCI6MjA4MDIyODIxNX0.mGiKMA33vOSQU2O7NQRpO5UIXQSuOTWJ-7sQ22BKMw4', // Your anon key
    );
  } catch (e) {
    // Supabase initialization error - app will handle gracefully
  }

  runApp(const ProviderScope(child: CareerBridgeApp()));
}

class CareerBridgeApp extends ConsumerWidget {
  const CareerBridgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'CareerBridge',
      navigatorKey: NavigationService.navigatorKey,
      navigatorObservers: [RouteTrackingObserver.instance],
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      initialRoute: '/',
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            Overlay(
              initialEntries: [
                OverlayEntry(builder: (context) => const AIAssistantWidget()),
              ],
            ),
          ],
        );
      },
      routes: {
        '/': (context) => const AuthWrapper(),
        // Public route — no auth required. QR codes point here.
        '/verify': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final certId = args is String ? args : null;
          return CertificateVerifyPage(certId: certId);
        },
        '/login': (context) => const LoginScreen(),
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/student-register': (context) => const StudentRegistrationScreen(),
        '/college-register': (context) => const CollegeRegistrationScreen(),
        '/recruiter-register': (context) => const RecruiterRegistrationScreen(),
        '/email-verification': (context) => const EmailVerificationScreen(),
        '/dashboard': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is int) {
            return AppWrapper(initialIndex: args);
          }
          return const AppWrapper();
        },
        '/student-profile-setup': (context) =>
            const StudentProfileSetupScreen(),
        '/student-dashboard': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is int) {
            return StudentDashboardScreen(initialIndex: args);
          }
          return const StudentDashboardScreen();
        },
        '/student-profile': (context) => const StudentProfileScreen(),
        '/interview-prep': (context) => const InterviewLandingScreen(),
        '/interview-learning': (context) => const LearningHubScreen(),
        '/interview-question': (context) => const QuestionBankScreen(),
        '/network-profile': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>?;
          if (args != null) {
            return NetworkProfileView(
              userId: args['userId'],
              userName: args['userName'] ?? 'User',
              userAvatar: args['userAvatar'],
              userRole: args['userRole'] ?? 'student',
            );
          }
          return const Scaffold(
            body: Center(child: Text("Profile ID missing")),
          );
        },
        '/interview-result': (context) {
          final attempt =
              ModalRoute.of(context)!.settings.arguments as InterviewAttempt;
          return InterviewResultScreen(attempt: attempt);
        },
        '/course-details': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>?;
          if (args != null) {
            try {
              final course = LearningCourse.fromJson(args);
              return CourseDetailScreen(course: course);
            } catch (e) {
              return Scaffold(
                body: Center(child: Text("Error loading course: $e")),
              );
            }
          }
          return const Scaffold(
            body: Center(child: Text("Course data missing")),
          );
        },
        '/college-public-profile': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>?;
          if (args != null) {
            return CollegePublicProfileScreen(
              organizationId: args['organizationId'],
              userId: args['userId'] ?? '',
              userName: args['userName'],
              userAvatar: args['userAvatar'],
            );
          }
          return const Scaffold(
            body: Center(child: Text("Organization ID missing")),
          );
        },
        '/recruiter-events': (context) => const RecruiterEventsScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // On Flutter Web: if the URL has ?id=..., show the public verify page immediately
    if (kIsWeb) {
      try {
        final certId = Uri.base.queryParameters['id'];
        if (certId != null && certId.isNotEmpty) {
          return CertificateVerifyPage(certId: certId);
        }
        // Also handle /verify path directly
        if (Uri.base.path.contains('verify')) {
          return CertificateVerifyPage(certId: certId);
        }
      } catch (_) {}
    }

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = Supabase.instance.client.auth.currentSession;
        final user = Supabase.instance.client.auth.currentUser;

        if (session != null && user != null) {
          // Check if email is verified
          if (user.emailConfirmedAt == null) {
            return const EmailVerificationScreen();
          }
          return const AppWrapper();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

class AppWrapper extends StatelessWidget {
  final int? initialIndex;

  const AppWrapper({super.key, this.initialIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: FutureBuilder<Map<String, dynamic>?>(
              future: _getUserProfile(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError || snapshot.data == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading profile',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error: ${snapshot.error}',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                // Restart the app
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) => const AppWrapper(),
                                  ),
                                );
                              },
                              child: const Text('Retry'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () async {
                                // Force logout and go to login
                                await Supabase.instance.client.auth.signOut();
                                if (context.mounted) {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/login',
                                    (route) => false,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }

                final profile = snapshot.data!;
                final role = profile['role'];
                final profileCompletion = profile['profile_completion'] ?? 0;
                final isProfileComplete =
                    profile['is_profile_complete'] ?? false;

                // Check if profile needs to be completed
                if (role == 'student' &&
                    (!isProfileComplete || profileCompletion < 100)) {
                  return const StudentProfileSetupScreen();
                }

                // Route based on user role
                switch (role) {
                  case 'student':
                    return StudentDashboardScreen(initialIndex: initialIndex);
                  case 'college':
                  case 'college_admin':
                  case 'admin':
                    return CollegeDashboardScreen(initialIndex: initialIndex);
                  case 'recruiter':
                  case 'HR':
                    return RecruiterDashboardScreen(initialIndex: initialIndex);
                  default:
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.warning_rounded,
                            size: 64,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Unknown user role: $role',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () async {
                              await Supabase.instance.client.auth.signOut();
                              if (context.mounted) {
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/login',
                                  (route) => false,
                                );
                              }
                            },
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _getUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .single();

      return response;
    } catch (e) {
      // PGRST116 = no rows returned (profile doesn't exist yet)
      final errorStr = e.toString();
      final isNoRowsError = errorStr.contains('PGRST116') ||
          errorStr.contains('No rows found') ||
          errorStr.contains('JSON object requested, multiple (or no) rows returned');

      if (isNoRowsError) {
        try {
          final role = user.userMetadata?['role'] as String? ?? 'student';
          final profileData = <String, dynamic>{
            'id': user.id,
            'email': user.email,
            'role': role,
            'full_name': user.userMetadata?['full_name'] ?? 'User',
            'phone': user.userMetadata?['phone'],
            'profile_completion': role == 'recruiter' ? 30 : 10,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          };

          // For recruiters, also add job_title if available
          if (role == 'recruiter') {
            profileData['job_title'] = user.userMetadata?['designation'];
          }

          // Insert the profile
          await Supabase.instance.client.from('profiles').insert(profileData);

          // Try to fetch the profile again
          final response = await Supabase.instance.client
              .from('profiles')
              .select('*')
              .eq('id', user.id)
              .single();

          return response;
        } catch (createError) {
          throw Exception('Failed to create user profile: $createError');
        }
      }
      throw Exception('Failed to load user profile: $e');
    }
  }
}
