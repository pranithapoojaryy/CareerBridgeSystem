import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/navigation/navigation_service.dart';
import '../../../../features/auth/presentation/auth_controller.dart';
import '../../../../features/networking/presentation/screens/network_profile_view.dart';
import '../../../../features/networking/presentation/screens/recruiter_profile_view.dart';
import '../../../../features/college/presentation/profile/college_public_profile_screen.dart';
import '../../../../features/notifications/presentation/providers/popover_provider.dart';
import '../../../../features/notifications/presentation/providers/notification_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// --- State Management ---

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Map<String, dynamic>? question;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.question,
  }) : this.timestamp = timestamp ?? DateTime.now();
}

class AIAssistantState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isOpen;
  final String? lastAction;
  final String? pendingAction;
  final String? userRole;
  final bool isThinkMode;

  AIAssistantState({
    this.messages = const [],
    this.isLoading = false,
    this.isOpen = false,
    this.lastAction,
    this.pendingAction,
    this.userRole,
    this.isThinkMode = false,
  });

  AIAssistantState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isOpen,
    String? lastAction,
    bool clearLastAction = false,
    String? pendingAction,
    bool clearPendingAction = false,
    String? userRole,
    bool? isThinkMode,
  }) {
    return AIAssistantState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isOpen: isOpen ?? this.isOpen,
      lastAction: clearLastAction ? null : (lastAction ?? this.lastAction),
      pendingAction: clearPendingAction
          ? null
          : (pendingAction ?? this.pendingAction),
      userRole: userRole ?? this.userRole,
      isThinkMode: isThinkMode ?? this.isThinkMode,
    );
  }
}

class AIAssistantNotifier extends Notifier<AIAssistantState> {
  @override
  AIAssistantState build() {
    // Watch Auth State to trigger re-build/reset on login/logout
    ref.watch(authStateProvider);

    final user = Supabase.instance.client.auth.currentUser;
    return AIAssistantState(
      messages: [
        ChatMessage(
          text: user == null
              ? "Hi! I'm CareerBridge AI. 🚀\n\nPlease login or signup to access my full features! I can help you find your way around once you're in."
              : "Hi! I'm CareerBridge AI, your career sidekick. 🚀\n\nI can help you find sections in the app or show you sample questions. What can I do for you today?\n\n(Tip: Say 'help' to see what I can do!)",
          isUser: false,
        ),
      ],
    );
  }

  void toggleOpen() {
    state = state.copyWith(isOpen: !state.isOpen);
  }

  void toggleThinkMode() {
    state = state.copyWith(isThinkMode: !state.isThinkMode);

    // Add a system message explaining the change
    final explainer = state.isThinkMode
        ? "Think Mode ACTIVATED. 🧠\n\nI'll now use advanced reasoning (Gemini-2.0-Flash) to help you with complex career strategy, roadmaps, and in-depth advice."
        : "Think Mode DEACTIVATED. ⚡\n\nReturning to fast navigation and quick app assistance mode.";

    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(text: explainer, isUser: false),
      ],
    );
  }

  void clearAction() {
    state = state.copyWith(clearLastAction: true);
  }

  Future<void> sendMessage(String text, {String? currentPath}) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(text: text, isUser: true);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    );

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      await Future.delayed(const Duration(milliseconds: 600));
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            text:
                "Please login or signup to interact with me! 🚀\n\nI can guide you through the platform once you've joined.",
            isUser: false,
          ),
        ],
        isLoading: false,
      );
      return;
    }

    // Use Edge Function if Think Mode is ON
    if (state.isThinkMode) {
      await _handleLLMRequest(text, currentPath);
    } else {
      // 100% Local Logic
      await _handleLocalRules(text);
    }
  }

  Future<void> _handleLLMRequest(String text, String? currentPath) async {
    try {
      final envKey = dotenv.env['OPENROUTER_API_KEY'];
      const defineKey = String.fromEnvironment('OPENROUTER_API_KEY');
      final apiKey = (envKey != null && envKey.isNotEmpty && !envKey.startsWith('YOUR_'))
          ? envKey
          : defineKey;

      if (apiKey.isEmpty || apiKey.startsWith('YOUR_')) {
        throw Exception("OPENROUTER_API_KEY not found in .env or --dart-define");
      }

      // Fetch User context
      await _fetchUserRole();
      final userName =
          Supabase
              .instance
              .client
              .auth
              .currentUser
              ?.userMetadata?['full_name'] ??
          'User';
      final role = state.userRole ?? 'student';

      final rolePrompts = {
        'student':
            'You are CareerBridge AI Career Coach. Student: $userName. Help them find app sections: /interview-prep, /interview-learning, /student-profile, /dashboard.',
        'college_admin':
            'You are CareerBridge AI Admin Assistant. Admin: $userName. Sections: /college-admin/registrations, /college-admin/drives.',
        'recruiter':
            'You are CareerBridge AI Recruiter Assistant. Recruiter: $userName. Sections: /recruiter/search, /recruiter/jobs, /recruiter/applications.',
      };

      const String navigationAtlas = """
NAVIGATION ATLAS (ONLY USE THESE INDICES):
- Student Portal:
  - Profile: /student-dashboard?index=2
  - Projects: /student-dashboard?index=3
  - Resume Builder: /student-dashboard?index=4
  - Jobs: /student-dashboard?index=5
  - Interview Prep: /student-dashboard?index=6
  - Learning Paths: /student-dashboard?index=7
  - Practice Arena: /student-dashboard?index=9
  - Aptitude Arena: /student-dashboard?index=10
  - Events: /student-dashboard?index=11
  - Network: /student-dashboard?index=12

- Recruiter Portal:
  - Jobs Manager: /dashboard?index=1
  - Applications: /dashboard?index=2
  - Learning Manager: /dashboard?index=5
  - Professional Network: /dashboard?index=6
  - Global Search: /recruiter/search

- College Admin Portal:
  - Learning Manager: /dashboard?index=22
  - Placement Drives: /college-admin/drives
  - Registrations: /college-admin/registrations
""";

      String systemInstructions =
          "${rolePrompts[role] ?? rolePrompts['student']!}\n\n"
          "$navigationAtlas\n\n"
          "CURRENT CONTEXT:\n- Path: ${currentPath ?? 'Unknown'}\n\n"
          "GUIDELINES:\n- NEVER hallucinate indices. ONLY use the Navigation Atlas above.\n"
          "- MANDATORY: Whenever the user asks to open, go to, or navigate to any section, ALWAYS include [NAVIGATE: /path] (e.g., [NAVIGATE: /student-dashboard?index=6]) in your response.\n"
          "- Use [PREVIEW_QUESTION: any] to show a sample question.";

      if (state.isThinkMode) {
        systemInstructions +=
            "\n\nTHINK MODE ACTIVE: Provide detailed, analytical career strategy. Be verbose and strategic.";
      }

      // Map history to OpenRouter (OpenAI-compatible) format
      final history = state.messages
          .where((m) => m.text.length < 500)
          .toList()
          .reversed
          .take(10)
          .toList()
          .reversed
          .map((m) {
            return {'role': m.isUser ? 'user' : 'assistant', 'content': m.text};
          })
          .toList();

      final messages = [
        {'role': 'system', 'content': systemInstructions},
        ...history,
        {'role': 'user', 'content': text},
      ];

      final modelsToTry = [
        'openrouter/free',
        'google/gemma-4-31b-it:free',
        'qwen/qwen3.8-27b:free',
        'z-ai/glm-5.2:free',
        'google/gemini-2.0-flash-exp:free',
      ];

      http.Response? response;
      String? lastErrorBody;

      for (final modelName in modelsToTry) {
        try {
          final res = await http.post(
            Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
              'HTTP-Referer': 'https://CareerBridge.app',
              'X-Title': 'CareerBridge AI',
            },
            body: jsonEncode({
              'model': modelName,
              'messages': messages,
              'temperature': 0.7,
            }),
          );

          if (res.statusCode == 200) {
            response = res;
            break;
          } else {
            lastErrorBody = "Model $modelName (${res.statusCode}): ${res.body}";
          }
        } catch (e) {
          lastErrorBody = "Model $modelName exception: $e";
        }
      }

      String reply = '';

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        reply = data['choices'][0]['message']['content'] as String;
      } else {
        // Fallback to Google Gemini direct API if available
        final geminiKey = dotenv.env['GEMINI_API_KEY'];
        if (geminiKey != null &&
            geminiKey.isNotEmpty &&
            !geminiKey.startsWith('YOUR_')) {
          final geminiRes = await http.post(
            Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$geminiKey',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': '$systemInstructions\n\nUser: $text'}
                  ]
                }
              ]
            }),
          );

          if (geminiRes.statusCode == 200) {
            final geminiData = jsonDecode(geminiRes.body);
            reply = geminiData['candidates'][0]['content']['parts'][0]['text']
                as String;
          } else {
            throw Exception(
              "AI Service Error (OpenRouter: $lastErrorBody | Gemini: ${geminiRes.statusCode})",
            );
          }
        } else {
          throw Exception("OpenRouter Error: $lastErrorBody");
        }
      }

      // Handle custom commands
      String? action;
      if (reply.contains('[NAVIGATE:')) {
        final match = RegExp(r'\[NAVIGATE:\s*(.*?)\]').firstMatch(reply);
        if (match != null) {
          action = match.group(1)?.trim();
        }
      }

      // Smart navigation fallback if LLM omitted the tag
      if (action == null) {
        final lower = text.toLowerCase();
        if (lower.contains('interview prep') || lower.contains('prep')) {
          action = '/student-dashboard?index=6';
        } else if (lower.contains('learning') || lower.contains('course')) {
          action = '/student-dashboard?index=7';
        } else if (lower.contains('job')) {
          action = '/student-dashboard?index=5';
        } else if (lower.contains('profile')) {
          action = '/student-dashboard?index=2';
        } else if (lower.contains('practice') || lower.contains('aptitude')) {
          action = '/student-dashboard?index=9';
        } else if (lower.contains('event')) {
          action = '/student-dashboard?index=11';
        } else if (lower.contains('network')) {
          action = '/student-dashboard?index=12';
        } else if (lower.contains('resume')) {
          action = '/student-dashboard?index=4';
        } else if (lower.contains('project')) {
          action = '/student-dashboard?index=3';
        } else if (lower.contains('dashboard') || lower.contains('home')) {
          action = '/student-dashboard?index=0';
        }
      }

      Map<String, dynamic>? questionData;
      if (reply.contains('[PREVIEW_QUESTION:')) {
        final qResponse = await Supabase.instance.client
            .from('aptitude_questions')
            .select('id, question_text, options, difficulty')
            .limit(1)
            .maybeSingle();

        if (qResponse != null) {
          questionData = qResponse;
        }
      }

      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            text: reply.replaceAll(RegExp(r'\[NAVIGATE: .*?\]'), '').trim(),
            isUser: false,
            question: questionData,
          ),
        ],
        isLoading: false,
        lastAction: action,
        clearLastAction: action == null,
      );
    } catch (e) {
      debugPrint("Client-Side AI Error: $e");
      String errorMsg = "I'm having trouble thinking: $e";

      if (e.toString().contains('GEMINI_API_KEY not found') ||
          e.toString().contains('apiKey == null')) {
        errorMsg =
            "Missing Gemini API Key! Please add GEMINI_API_KEY=your_key to your frontend's .env file and restart the app.";
      } else if (e.toString().contains('invalid API key')) {
        errorMsg =
            "Invalid Gemini API Key! Please check your key in Google AI Studio and update your .env file.";
      }

      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(text: errorMsg, isUser: false),
        ],
        isLoading: false,
      );
    }
  }

  Future<void> _fetchUserRole() async {
    if (state.userRole != null) return;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .maybeSingle();

        if (profile != null) {
          state = state.copyWith(userRole: profile['role']);
        }
      }
    } catch (e) {
      debugPrint("Error fetching user role: $e");
    }
  }

  Future<void> _handleLocalRules(String text) async {
    final query = text.toLowerCase().trim();

    // Fetch role if not already present
    await _fetchUserRole();

    // Realistic thinking delay
    await Future.delayed(const Duration(milliseconds: 600));

    String reply = "";
    String? action;
    String? newPendingAction;
    Map<String, dynamic>? questionData;

    try {
      // 0. Handle Confirmation for Pending Actions
      if (state.pendingAction != null) {
        if (query.contains("yes") ||
            query.contains("sure") ||
            query.contains("ok") ||
            query.contains("fine") ||
            query.contains("yeah")) {
          reply = "Perfect! Taking you there now.";
          action = state.pendingAction;
          newPendingAction = null;
        } else if (query.contains("no") ||
            query.contains("cancel") ||
            query.contains("stop")) {
          reply = "No problem! What else can I help you with?";
          action = null;
          newPendingAction = null;
        }
      }

      // 0.5 Small Talk & Gratitude
      if (reply.isEmpty) {
        if (query.contains("thank") || query.contains("thanks")) {
          reply = "You're welcome! Happy to help. 🚀";
        } else if (query.toLowerCase() == "hi" ||
            query.toLowerCase() == "hello" ||
            query.toLowerCase() == "hey" ||
            query.toLowerCase() == "hola") {
          reply =
              "Hello! I'm CareerBridge AI. Ready to help you navigate and succeed! What do you need?";
        } else if (query.contains("bye") || query.contains("goodbye")) {
          reply = "Goodbye! Have a productive day! 👋";
        }
      }

      // 1. Entity Search Logic (Search Profiles & Organizations)
      if (reply.isEmpty && query.length >= 3) {
        // Only ignore search for very common general commands to avoid DB noise
        final isGeneralCommand =
            query == "help" ||
            query == "hi" ||
            query == "hello" ||
            query == "bye";

        if (!isGeneralCommand) {
          final searchTerm = query
              .replaceAll(RegExp(r'who is|search|find|profile|open'), '')
              .trim();

          // If after removing prefixes we have a decent search term, or if original was just the name
          final effectiveSearchTerm = searchTerm.isEmpty ? query : searchTerm;

          if (effectiveSearchTerm.length >= 3) {
            // Search Profiles
            final profileRes = await Supabase.instance.client
                .from('profiles')
                .select('id, full_name, role, organization_id')
                .ilike('full_name', '%$effectiveSearchTerm%')
                .limit(1)
                .maybeSingle();

            if (profileRes != null) {
              reply =
                  "I found ${profileRes['full_name']} (${profileRes['role']}). Would you like me to open their profile?";
              final name = Uri.encodeComponent(profileRes['full_name']);
              final role = profileRes['role']?.toString().toLowerCase() ?? '';
              final id = profileRes['id'];

              final orgId = profileRes['organization_id'];

              if (role == 'recruiter' || role == 'hr' || role == 'company') {
                newPendingAction =
                    "/recruiter-profile?userId=$id&userName=$name&organizationId=${orgId ?? ''}";
              } else if (role == 'college' || role == 'college_admin') {
                newPendingAction =
                    "/college-public-profile?userId=$id&userName=$name";
              } else {
                newPendingAction =
                    "/network-profile?userId=$id&userName=$name&userRole=$role";
              }
            } else {
              // Search Organizations
              final orgRes = await Supabase.instance.client
                  .from('organizations')
                  .select('id, name, type')
                  .ilike('name', '%$effectiveSearchTerm%')
                  .limit(1)
                  .maybeSingle();

              if (orgRes != null) {
                reply =
                    "I found ${orgRes['name']} (${orgRes['type']}). Should I take you to their profile?";
                final name = Uri.encodeComponent(orgRes['name']);
                final type = orgRes['type']?.toString().toLowerCase() ?? '';
                final orgName = orgRes['name']?.toString().toLowerCase() ?? '';
                final isCollegeType =
                    type.contains('college') ||
                    type.contains('university') ||
                    type.contains('affiliated') ||
                    type.contains('institute') ||
                    orgName.contains('institute') ||
                    orgName.contains('college') ||
                    orgName.contains('university');

                if (isCollegeType) {
                  newPendingAction =
                      "/college-public-profile?organizationId=${orgRes['id']}&userName=$name";
                } else {
                  newPendingAction =
                      "/recruiter-profile?organizationId=${orgRes['id']}&userName=$name";
                }
              } else {
                // Search Courses
                final courseRes = await Supabase.instance.client
                    .from('learning_courses')
                    .select('id, title')
                    .ilike('title', '%$effectiveSearchTerm%')
                    .limit(1)
                    .maybeSingle();

                if (courseRes != null) {
                  reply =
                      "I found the course '**${courseRes['title']}**'. Would you like to view the details?";
                  newPendingAction =
                      "/course-details-fetch?id=${courseRes['id']}";
                }
              }
            }
          }
        }
      }

      // 1.5 How-To Guides (Contextual Help)
      if (reply.isEmpty &&
          (query.contains("how to") ||
              query.contains("guide") ||
              query.contains("steps"))) {
        if (query.contains("course") || query.contains("content")) {
          if (state.userRole == 'recruiter' ||
              state.userRole == 'college_admin') {
            reply =
                "**How to Create a Course:**\n\n"
                "1. Go to **Learning Content**.\n"
                "2. Click the **'+ Create Course'** button.\n"
                "3. Fill in details like Title, Description, and Modules.\n"
                "4. Publish it for students to see!\n\n"
                "Shall I take you to the Learning Manager?";
            action = state.userRole == 'recruiter'
                ? "/dashboard?index=5"
                : "/dashboard?index=22";
          } else {
            reply =
                "Students can't create courses, but you can browse them in the **Learning Hub**! Want to go there?";
            action = "/student-dashboard?index=6";
          }
        } else if (query.contains("job") || query.contains("post")) {
          if (state.userRole == 'recruiter') {
            reply =
                "**How to Post a Job:**\n\n"
                "1. Go to **Jobs**.\n"
                "2. Tap **'+ Post Job'**.\n"
                "3. Enter role details, requirements, and salary.\n"
                "4. Post it to start receiving applications!\n\n"
                "Ready to post a job?";
            action = "/dashboard?index=1";
          } else {
            reply =
                "To apply for jobs, head to the **Jobs** section. Want me to take you there?";
            action = "/student-dashboard?index=5";
          }
        } else if (query.contains("test") || query.contains("assessment")) {
          reply =
              "**How to Take a Test:**\n\n"
              "1. Go to **Practice Arena**.\n"
              "2. Select a topic (Aptitude, Tech, etc.).\n"
              "3. Start the quiz and track your score!\n\n"
              "Want to try a test now?";
          action = "/student-dashboard?index=9";
        }
      }

      // 2. Feature Mapping (Common Names & App-Specific Names)
      if (reply.isEmpty) {
        if (query.contains("question") ||
            query.contains("sample") ||
            query.contains("example") ||
            query.contains("aptitude")) {
          final response = await Supabase.instance.client
              .from('aptitude_questions')
              .select('id, question_text, options, difficulty')
              .limit(1)
              .single();

          questionData = response;
          reply =
              "I've pulled a sample aptitude question from the Practice Arena for you!";
        }
        // Practice Arena / Tests (Students)
        else if (query.contains("practice") ||
            query.contains("test") ||
            query.contains("mock") ||
            query.contains("arena") ||
            query.contains("exam")) {
          if (state.userRole == 'student') {
            reply =
                "Taking you to the **Practice Arena**. This is where you can take mock tests and improve your proficiency scores!";
            action = "/student-dashboard?index=9";
          } else {
            reply =
                "That section is mainly for students. Would you like to check out the **Question Bank** or **Placement Drives** instead?";
          }
        }
        // Learning Hub / Courses / Paths
        else if (query.contains("learn") ||
            query.contains("course") ||
            query.contains("hub") ||
            query.contains("study") ||
            query.contains("material") ||
            query.contains("path") ||
            query.contains("content")) {
          if (state.userRole == 'student') {
            reply =
                "Opening **Learning Paths**. You'll find all modules and resources here.";
            action = "/student-dashboard?index=7";
          } else if (state.userRole == 'recruiter') {
            reply = "Opening **Learning Content Manager**.";
            action = "/dashboard?index=5";
          } else {
            reply = "Opening **Learning Content Manager**.";
            action = "/dashboard?index=22";
          }
        }
        // Interview Prep / Question Bank
        else if (query.contains("interview") ||
            query.contains("mock") ||
            query.contains("bank") ||
            query.contains("viva")) {
          if (state.userRole == 'student') {
            reply =
                "Opening **Interview Prep**. You can practice with AI mock interviews and browse common questions here.";
            action = "/student-dashboard?index=6";
          } else {
            reply =
                "Heading to the **Question Bank**. You can browse through our collection of interview questions here.";
            action = "/interview-question";
          }
        } else if (query.contains("resume") || query.contains("cv")) {
          if (state.userRole == 'student') {
            reply =
                "Opening the **Resume Builder**. You can create and edit your professional resume here.";
            action = "/student-dashboard?index=4";
          } else {
            reply =
                "Opening your Dashboard where you can access your profile settings.";
            action = "/dashboard";
          }
        }
        // Profile
        else if (query.contains("profile") ||
            query.contains("my data") ||
            query.contains("about me")) {
          if (state.userRole == 'student') {
            reply =
                "Opening your **Profile**. You can manage your academic history and personal details here.";
            action = "/student-dashboard?index=2";
          } else {
            reply =
                "Opening your Dashboard where you can access your profile settings.";
            action = "/dashboard";
          }
        }
        // Projects
        else if (query.contains("project")) {
          if (state.userRole == 'student') {
            reply =
                "Opening your **Projects**. You can showcase your work and add new projects here.";
            action = "/student-dashboard?index=3";
          }
        }
        // Aptitude
        else if (query.contains("aptitude") ||
            query.contains("test") ||
            query.contains("quiz") ||
            query.contains("reasoning")) {
          if (state.userRole == 'student') {
            reply =
                "Opening the **Aptitude Arena**. Time to sharpen those reasoning and problem-solving skills!";
            action = "/student-dashboard?index=10";
          }
        }
        // Identity
        else if (query.contains("who are you") ||
            query.contains("who r u") ||
            (query.contains("your name") && query.contains("what"))) {
          reply =
              "I'm **CareerBridge AI**, your personal career assistant! 🤖\n\nI can help you find jobs, connect with people, discover courses, and navigate the platform. Just ask!";
          action = null;
        }
        // Recent Activities: New Jobs
        else if (query.contains("new job") ||
            query.contains("recent job") ||
            query.contains("latest job") ||
            query.contains("job posting")) {
          if (state.userRole == 'student') {
            try {
              final jobsRes = await Supabase.instance.client
                  .from('jobs')
                  .select(
                    'id, title, location, organization:organizations(name)',
                  )
                  .eq('status', 'open')
                  .order('created_at', ascending: false)
                  .limit(3);

              if (jobsRes != null && (jobsRes as List).isNotEmpty) {
                reply = "Here are the latest job postings for you:\n";
                for (var job in jobsRes) {
                  final orgName =
                      job['organization']?['name'] ?? 'Unknown Company';
                  reply += "\n• **${job['title']}** at $orgName";
                }
                reply += "\n\nWould you like to apply?";
                action = "/student-dashboard?index=5";
              } else {
                reply = "I couldn't find any recent job postings right now.";
              }
            } catch (e) {
              reply =
                  "I had trouble fetching the latest jobs. Please try viewing the Jobs tab directly.";
              action = "/student-dashboard?index=5";
            }
          } else if (state.userRole == 'recruiter') {
            reply =
                "You can manage your job postings in the **Jobs** section. Would you like to go there?";
            action = "/dashboard?index=1";
          } else {
            reply =
                "Job postings are primarily for students. You can view them in the Jobs section.";
            action = "/dashboard?index=2"; // Or appropriate index
          }
        }
        // Recent Activities: New Users
        else if (query.contains("new person") ||
            query.contains("new user") ||
            query.contains("who joined") ||
            query.contains("recent user") ||
            query.contains("new member")) {
          try {
            var dbQuery = Supabase.instance.client
                .from('profiles')
                .select('id, full_name, role')
                .neq(
                  'id',
                  Supabase.instance.client.auth.currentUser?.id ?? '',
                ); // Exclude self

            // Role-based filtering (apply BEFORE order/limit)
            if (state.userRole == 'recruiter' ||
                state.userRole == 'college_admin') {
              // Recruiters and Colleges mostly interested in Students
              dbQuery = dbQuery.eq('role', 'student');
            }
            // Students can see everyone (networking), so no extra filter needed

            // Apply ordering and limiting at the end
            final profilesRes = await dbQuery
                .order('created_at', ascending: false)
                .limit(3);

            if (profilesRes != null && (profilesRes as List).isNotEmpty) {
              reply = "Here are some new members you might like to meet! 🎉\n";
              for (var profile in profilesRes) {
                reply += "\n• **${profile['full_name']}** (${profile['role']})";
              }
              reply += "\n\nSay hello in the Network tab!";
              action = "/student-dashboard?index=12";
            } else {
              reply =
                  "I couldn't find any recent members matching your network.";
            }
          } catch (e) {
            reply = "I had trouble fetching recent members.";
          }
        }
        // General Knowledge: CareerBridge
        else if (query.contains("CareerBridge") ||
            query.contains("app") &&
                (query.contains("what") || query.contains("about"))) {
          reply =
              "**CareerBridge** is your comprehensive career platform bridging the gap between students, colleges, and recruiters. We offer:\n\n"
              "• **For Students:** AI-driven job matching, interview prep, and skill building.\n"
              "• **For Colleges:** Placement tracking and student performance analytics.\n"
              "• **For Recruiters:** Efficient hiring tools and candidate discovery.\n\n"
              "I'm here to help you navigate it all! 🚀";
          action = null; // Informational only
        }
        // Job Applications / Jobs
        else if (query.contains("job") ||
            query.contains("apply") ||
            query.contains("application") ||
            query.contains("hiring")) {
          if (state.userRole == 'student') {
            reply =
                "Taking you to the **Jobs** section. Good luck with your applications!";
            action = "/student-dashboard?index=5";
          } else {
            reply =
                "Opening your **Applications Manager**. You can track candidate applications here!";
            action = "/dashboard?index=2";
          }
        }
        // Network / Connections / Recruiters / Companies
        else if (query.contains("network") ||
            query.contains("connect") ||
            query.contains("mentor") ||
            query.contains("expert") ||
            query.contains("peer") ||
            query.contains("recruiter") ||
            query.contains("company") ||
            query.contains("companies")) {
          if (state.userRole == 'student') {
            reply =
                "Opening your **Network**. You can find and connect with recruiters and companies here!";
            action = "/student-dashboard?index=12";
          } else {
            reply =
                "Opening your **Professional Network**. Find potential candidates and partners here.";
            action = "/dashboard?index=6";
          }
        }
        // Events
        else if (query.contains("event") ||
            query.contains("webinar") ||
            query.contains("workshop") ||
            query.contains("hackathon")) {
          if (state.userRole == 'student') {
            reply = "Checking upcoming **Events** for you.";
            action = "/student-dashboard?index=11";
          } else if (state.userRole == 'recruiter') {
            reply =
                "Opening **My Events**. You can post new events and manage existing ones here.";
            action = "/recruiter-events";
          } else {
            reply = "Opening **Events Management**.";
            action = "/dashboard?index=10";
          }
        }
        // Dashboard
        else if (query.contains("dashboard") ||
            query.contains("home") ||
            query.contains("main") ||
            query.contains("feed")) {
          reply = "Returning to your **Dashboard**.";
          action = "/dashboard";
        }
        // Specific Portal features (Recruiter/Admin)
        else if (query.contains("drive") ||
            query.contains("placement") ||
            query.contains("hiring")) {
          reply = "Opening the **Drives Management** section.";
          action = "/college-admin/drives";
        }
        // Notifications / Updates
        else if (query.contains("notification") ||
            query.contains("update") ||
            query.contains("whats new") ||
            query.contains("what's new") ||
            query.contains("any news")) {
          reply = "Checking your **Notifications** for you.";
          action = "trigger_notifications";
        }
        // Clearing Notifications
        else if ((query.contains("clear") ||
                query.contains("delete") ||
                query.contains("empty") ||
                query.contains("remove")) &&
            query.contains("notification")) {
          reply = "Understood. **Clearing all your notifications** now.";
          action = "clear_notifications";
        }
        // Help / Capabilities
        else if (query.contains("help") ||
            query.contains("what can you do") ||
            query.contains("features") ||
            query.contains("how to use")) {
          if (state.userRole == 'student') {
            reply =
                "I'm CareerBridge AI! I can help you navigate:\n\n"
                "• Say **'Practice'** for mock tests.\n"
                "• Say **'Learning Paths'** for courses.\n"
                "• Say **'Open [Course Name]'** to view details.\n"
                "• Say **'Applications'** for your job status.\n"
                "• Say **'List Recruiters'** to find companies.\n"
                "• Say **'Profile'** for your resume.";
          } else if (state.userRole == 'recruiter') {
            reply =
                "I'm CareerBridge AI! I can help you with:\n\n"
                "• Say **'Applications'** to track candidates.\n"
                "• Say **'Learning Content'** to manage library.\n"
                "• Say **'Open [Student Name]'** to view profiles.\n"
                "• Say **'Drives'** for placement management.";
          } else {
            reply =
                "I'm CareerBridge AI! Say **'Applications'**, **'Drives'**, or **'Learning Content'** and I'll take you there!";
          }
        } else {
          // 3. Fallback Entity Search (For direct names like "Poornaprajna" or "John Doe")
          // No prefix restrictions, just checking if it looks like a name/entity
          if (query.length >= 3) {
            // Avoid searching for "ok", "no", etc.
            final searchTerm = query
                .replaceAll(RegExp(r'who is|search|find|profile|open'), '')
                .trim();

            // Search Profiles
            final profileRes = await Supabase.instance.client
                .from('profiles')
                .select('id, full_name, role')
                .ilike('full_name', '%$searchTerm%')
                .limit(1)
                .maybeSingle();

            if (profileRes != null) {
              reply =
                  "I found ${profileRes['full_name']} (${profileRes['role']}). Would you like me to open their profile?";
              final name = Uri.encodeComponent(profileRes['full_name']);
              final role = Uri.encodeComponent(profileRes['role']);
              final id = profileRes['id'];
              newPendingAction =
                  "/network-profile?userId=$id&userName=$name&userRole=$role";
            } else {
              // Search Organizations
              final orgRes = await Supabase.instance.client
                  .from('organizations')
                  .select('id, name, type')
                  .ilike('name', '%$searchTerm%')
                  .limit(1)
                  .maybeSingle();

              if (orgRes != null) {
                reply =
                    "I found ${orgRes['name']} (${orgRes['type']}). Should I take you to their profile?";
                final name = Uri.encodeComponent(orgRes['name']);
                newPendingAction =
                    "/college-public-profile?organizationId=${orgRes['id']}&userName=$name&orgType=${orgRes['type']}";
              } else {
                // Search Courses
                final courseRes = await Supabase.instance.client
                    .from('learning_courses')
                    .select('id, title')
                    .ilike('title', '%$searchTerm%')
                    .limit(1)
                    .maybeSingle();

                if (courseRes != null) {
                  reply =
                      "I found the course '**${courseRes['title']}**'. Would you like to view the details?";
                  newPendingAction =
                      "/course-details-fetch?id=${courseRes['id']}";
                }
              }
            }
          }

          if (reply.isEmpty) {
            reply =
                "I'm not exactly sure about that. Try asking for '**Practice Arena**', '**Learning Hub**', or a '**Sample Question**'. Say 'help' for all commands!";
          }
        }
      }

      final aiMessage = ChatMessage(
        text: reply,
        isUser: false,
        question: questionData,
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
        lastAction: action,
        clearLastAction: action == null,
        pendingAction: newPendingAction,
        clearPendingAction: newPendingAction == null,
        // Only close if we executed a finalized direct action, not a proposed one
        isOpen: action != null ? false : state.isOpen,
      );
    } catch (e) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            text:
                "Something went wrong while I was looking that up. Please try again!",
            isUser: false,
          ),
        ],
        isLoading: false,
      );
    }
  }
}

final aiAssistantProvider =
    NotifierProvider<AIAssistantNotifier, AIAssistantState>(() {
      return AIAssistantNotifier();
    });

// --- UI Widgets ---

class AIAssistantWidget extends ConsumerStatefulWidget {
  const AIAssistantWidget({super.key});

  @override
  ConsumerState<AIAssistantWidget> createState() => _AIAssistantWidgetState();
}

class _AIAssistantWidgetState extends ConsumerState<AIAssistantWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiAssistantProvider);
    final notifier = ref.read(aiAssistantProvider.notifier);

    // Auto-scroll when messages length changes
    ref.listen<int>(aiAssistantProvider.select((s) => s.messages.length), (
      prev,
      next,
    ) {
      if (next > (prev ?? 0)) {
        _scrollToBottom();
      }
    });

    // Auto-scroll when loading state changes (typing indicator)
    ref.listen<bool>(aiAssistantProvider.select((s) => s.isLoading), (
      prev,
      next,
    ) {
      if (next) {
        _scrollToBottom();
      }
    });

    // Listen for AI Actions (like Navigation)
    ref.listen<String?>(aiAssistantProvider.select((s) => s.lastAction), (
      prev,
      next,
    ) async {
      if (next != null) {
        if (next == "trigger_notifications") {
          ref.read(notificationPopoverProvider.notifier).open();
          notifier.clearAction();
          return;
        }

        if (next == "clear_notifications") {
          ref
              .read(notificationNotifierProvider.notifier)
              .deleteAllNotifications();
          notifier.clearAction();
          return;
        }

        if (next.startsWith('/')) {
          final uri = Uri.parse(next);
          final route = uri.path;

          if (route == '/network-profile') {
            final userId = uri.queryParameters['userId'];
            final userName = uri.queryParameters['userName'];
            final userRole = uri.queryParameters['userRole'];
            final userAvatar = uri
                .queryParameters['userAvatar']; // Might need to check if available

            if (userId != null && userName != null) {
              Future.microtask(() {
                if (context.mounted) {
                  // Check if it's a recruiter or company to show RecruiterProfileView
                  final role = userRole?.toLowerCase() ?? '';
                  if (role == 'recruiter' ||
                      role == 'company' ||
                      role == 'hr') {
                    showDialog(
                      context: NavigationService.navigatorKey.currentContext!,
                      builder: (context) => Dialog(
                        insetPadding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width > 900
                              ? 0
                              : 16,
                          vertical: MediaQuery.of(context).size.width > 900
                              ? 0
                              : 24,
                        ),
                        child: Container(
                          width: MediaQuery.of(context).size.width > 900
                              ? 1200
                              : double.infinity,
                          height: MediaQuery.of(context).size.height > 900
                              ? 850
                              : MediaQuery.of(context).size.height * 0.9,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: RecruiterProfileView(
                            userId: userId,
                            userName: userName,
                            userAvatar: userAvatar,
                          ),
                        ),
                      ),
                    );
                  } else if (role == 'college' || role == 'college_admin') {
                    showDialog(
                      context: NavigationService.navigatorKey.currentContext!,
                      builder: (context) => Dialog(
                        insetPadding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width > 900
                              ? 0
                              : 16,
                          vertical: MediaQuery.of(context).size.width > 900
                              ? 0
                              : 24,
                        ),
                        child: Container(
                          width: MediaQuery.of(context).size.width > 900
                              ? 1200
                              : double.infinity,
                          height: MediaQuery.of(context).size.height > 900
                              ? 850
                              : MediaQuery.of(context).size.height * 0.9,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CollegePublicProfileScreen(
                            userId: userId,
                            userName: userName,
                            userAvatar: userAvatar,
                          ),
                        ),
                      ),
                    );
                  } else {
                    showDialog(
                      context: NavigationService.navigatorKey.currentContext!,
                      builder: (context) => Dialog(
                        insetPadding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width > 900
                              ? 0
                              : 16,
                          vertical: MediaQuery.of(context).size.width > 900
                              ? 0
                              : 24,
                        ),
                        child: Container(
                          width: MediaQuery.of(context).size.width > 900
                              ? 1200
                              : double.infinity,
                          height: MediaQuery.of(context).size.height > 900
                              ? 850
                              : MediaQuery.of(context).size.height * 0.9,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: NetworkProfileView(
                            userId: userId,
                            userName: userName,
                            userAvatar: userAvatar, // Pass if available
                            userRole: userRole ?? 'student',
                          ),
                        ),
                      ),
                    );
                  }
                }
              });
            }
            notifier.clearAction();
            return;
          }

          if (route == '/college-public-profile') {
            final organizationId = uri.queryParameters['organizationId'];
            final userId = uri.queryParameters['userId'];
            final userName = uri.queryParameters['userName'];

            if (organizationId != null || userId != null) {
              Future.microtask(() {
                if (context.mounted) {
                  showDialog(
                    context: NavigationService.navigatorKey.currentContext!,
                    builder: (context) => Dialog(
                      insetPadding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width > 900
                            ? 0
                            : 16,
                        vertical: MediaQuery.of(context).size.width > 900
                            ? 0
                            : 24,
                      ),
                      child: Container(
                        width: MediaQuery.of(context).size.width > 900
                            ? 1200
                            : double.infinity,
                        height: MediaQuery.of(context).size.height > 900
                            ? 850
                            : MediaQuery.of(context).size.height * 0.9,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: CollegePublicProfileScreen(
                          userId: userId ?? '',
                          organizationId: organizationId,
                          userName: userName ?? 'College',
                        ),
                      ),
                    ),
                  );
                }
              });
            }
            notifier.clearAction();
            return;
          }

          if (route == '/recruiter-profile') {
            final organizationId = uri.queryParameters['organizationId'];
            final userId = uri.queryParameters['userId'];
            final userName = uri.queryParameters['userName'];

            if (organizationId != null || userId != null) {
              Future.microtask(() {
                if (context.mounted) {
                  showDialog(
                    context: NavigationService.navigatorKey.currentContext!,
                    builder: (context) => Dialog(
                      insetPadding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width > 900
                            ? 0
                            : 16,
                        vertical: MediaQuery.of(context).size.width > 900
                            ? 0
                            : 24,
                      ),
                      child: Container(
                        width: MediaQuery.of(context).size.width > 900
                            ? 1200
                            : double.infinity,
                        height: MediaQuery.of(context).size.height > 900
                            ? 850
                            : MediaQuery.of(context).size.height * 0.9,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: RecruiterProfileView(
                          organizationId: organizationId,
                          userId: userId ?? '',
                          userName: userName ?? 'Company',
                        ),
                      ),
                    ),
                  );
                }
              });
            }
            notifier.clearAction();
            return;
          }

          dynamic arguments;

          if (route == '/course-details-fetch') {
            // Special handling: Fetch course data then navigate
            final courseId = uri.queryParameters['id'];
            if (courseId != null) {
              try {
                final courseData = await Supabase.instance.client
                    .from('learning_courses')
                    .select(
                      '*, sections:learning_course_sections(*, lectures:learning_course_lectures(*))',
                    )
                    .eq('id', courseId)
                    .single();

                NavigationService.navigatorKey.currentState?.pushNamed(
                  '/course-details',
                  arguments: courseData,
                );
              } catch (e) {
                debugPrint("Error fetching course for AI nav: $e");
              }
            }
            notifier.clearAction();
            return;
          }

          if (uri.queryParameters.containsKey('index')) {
            arguments = int.tryParse(uri.queryParameters['index']!);
          } else if (uri.queryParameters.isNotEmpty) {
            arguments = uri.queryParameters;
          }

          NavigationService.navigatorKey.currentState?.pushNamed(
            route,
            arguments: arguments,
          );
        }
        notifier.clearAction();
      }
    });

    return Stack(
      children: [
        // Chat Window
        if (aiState.isOpen)
          Positioned(
            bottom: 90,
            right: 20,
            child: Material(
              elevation: 10,
              borderRadius: BorderRadius.circular(24),
              color: Colors.transparent,
              child: Container(
                width: 350,
                height: 500,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryColor, Colors.blue[700]!],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 18,
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'CareerBridge AI',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'BETA',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.greenAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      aiState.isThinkMode
                                          ? 'Deep Reasoning'
                                          : 'Online',
                                      style: GoogleFonts.outfit(
                                        color: aiState.isThinkMode
                                            ? Colors.orangeAccent
                                            : Colors.white70,
                                        fontSize: 11,
                                        fontWeight: aiState.isThinkMode
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Think Mode Toggle Switch
                          Column(
                            children: [
                              Transform.scale(
                                scale: 0.7,
                                child: Switch(
                                  value: aiState.isThinkMode,
                                  onChanged: (_) => notifier.toggleThinkMode(),
                                  activeColor: Colors.orangeAccent,
                                  activeTrackColor: Colors.orangeAccent
                                      .withValues(alpha: 0.5),
                                  inactiveThumbColor: Colors.white,
                                  inactiveTrackColor:
                                      Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              Text(
                                'THINK',
                                style: GoogleFonts.outfit(
                                  color: aiState.isThinkMode
                                      ? Colors.orangeAccent
                                      : Colors.white70,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: notifier.toggleOpen,
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    // Messages
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount:
                            aiState.messages.length +
                            (aiState.isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == aiState.messages.length) {
                            return const TypingIndicator();
                          }
                          final message = aiState.messages[index];
                          final isLast = index == aiState.messages.length - 1;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MessageBubble(message: message),
                              if (!message.isUser &&
                                  isLast &&
                                  aiState.pendingAction != null)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 4,
                                    bottom: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      _buildQuickAction(
                                        "Yes, please!",
                                        Icons.check_circle_outline,
                                        () => notifier.sendMessage("Yes"),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildQuickAction(
                                        "No, thanks",
                                        Icons.cancel_outlined,
                                        () => notifier.sendMessage("No"),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    // Input
                    ChatInput(
                      onSend: (text) => notifier.sendMessage(
                        text,
                        currentPath: ModalRoute.of(context)?.settings.name,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Floating Bubble
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: notifier.toggleOpen,
            backgroundColor: AppTheme.primaryColor,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              aiState.isOpen
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.auto_awesome_rounded,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(20),
          color: AppTheme.primaryColor.withValues(alpha: 0.05),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppTheme.primaryColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: message.isUser ? AppTheme.primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isUser ? 16 : 0),
            bottomRight: Radius.circular(message.isUser ? 0 : 16),
          ),
        ),
        child: Text(
          message.text,
          style: GoogleFonts.outfit(
            color: message.isUser ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class ChatInput extends StatefulWidget {
  final Function(String) onSend;
  const ChatInput({super.key, required this.onSend});

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();

  void _submit() {
    if (_controller.text.trim().isEmpty) return;
    widget.onSend(_controller.text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _submit,
            icon: const Icon(Icons.send_rounded, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }
}

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(0),
            const SizedBox(width: 4),
            _dot(1),
            const SizedBox(width: 4),
            _dot(2),
          ],
        ),
      ),
    );
  }

  Widget _dot(int index) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }
}
