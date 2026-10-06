# Chapter 6: Coding

## 6.1 Introduction
The coding phase of **CareerBridge** focuses on transforming design specifications into high-quality, executable software components. This chapter details the programming paradigms, practices, and methodologies employed during development to ensure the platform is scalable, maintainable, and efficient.

## 6.2 Programming Practices
To manage the complexity of a multi-portal platform, the development team adopted industry-standard software engineering practices.

### 6.2.1 Top-down & Bottom-up Approaches
- **Bottom-up Approach**: Used for building core infrastructure and shared utilities. Low-level components like the `SupabaseClient`, custom UI widgets (buttons, inputs), and data models were developed first. This ensured a solid foundation of reusable building blocks.
- **Top-down Approach**: Used for feature implementation. High-level user requirements were broken down into functional modules (e.g., "Student Resume Builder"). This allowed for rapid prototyping of user interfaces before finalizing complex backend integrations.

### 6.2.2 Structured Programming
CareerBridge adheres to **Structured Programming** principles to maximize code readability and minimize logical errors:
- **Modularity**: Code is organized into independent, feature-based modules.
- **Single Responsibility Principle (SRP)**: Each class or function has a single, well-defined purpose (e.g., `ResumeMatchingService` only handles matching logic).
- **Control Structures**: Consistent use of standardized control flows (if/else, switch, try/catch) for predictable execution.

### 6.2.3 Verification
Verification was integrated into the coding cycle to ensure correctness:
- **Static Analysis**: Continuous use of the Dart analyzer to enforce type safety and linting rules.
- **Peer Review**: Modular code segments were cross-verified against design documents.
- **Component Testing**: Individual UI widgets and services (like the AI Matcher) were tested in isolation using the Flutter DevTools and logging.

## 6.3 Source Code Snippets

### 6.3.1 Authentication Repository (Data Layer)
The following snippet demonstrates the structured approach to identity management using Supabase.

```dart
class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }
}
```

### 6.3.2 Resume Matching Service (Domain Logic)
This snippet shows the custom algorithmic logic used for resume analysis.

```dart
class ResumeMatchingService {
  double calculateMatchScore(String resumeText, List<String> requirements) {
    if (requirements.isEmpty) return 0.0;
    
    final resumeTokens = resumeText.toLowerCase().split(RegExp(r'[\W_]+'));
    int matchCount = 0;

    for (var req in requirements) {
      if (resumeTokens.contains(req.toLowerCase())) {
        matchCount++;
      }
    }

    return (matchCount / requirements.length) * 100;
  }
}
```

### 6.3.3 Auth Provider (State Management)
Demonstrating reactive state updates using Riverpod and the Repository pattern.

```dart
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState.initial());

  Future<void> login(String email, String password) async {
    state = AuthState.loading();
    try {
      await _repository.signInWithEmail(email: email, password: password);
      state = AuthState.authenticated();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }
}
```

### 6.3.4 Application Entry Point (main.dart)
The `main.dart` file serves as the orchestration layer, initializing Supabase and setting up the global AI Assistant overlay.

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://your-project.supabase.co',
    anonKey: 'your-anon-key',
  );
  runApp(const ProviderScope(child: CareerBridgeApp()));
}

class CareerBridgeApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      builder: (context, child) {
        // Global overlay for the AI Assistant sidekick
        return Stack(children: [child!, const AIAssistantWidget()]);
      },
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/dashboard': (context) => const AppWrapper(),
      },
    );
  }
}
```

### 6.3.5 AI Chatbot Heuristic Engine (CareerBridge AI)
This snippet highlights the local heuristic parsing used by CareerBridge AI to navigate the app and fetch data without external LLM latency.

```dart
class AIAssistantNotifier extends Notifier<AIAssistantState> {
  Future<void> _handleLocalRules(String text) async {
    final query = text.toLowerCase().trim();
    String reply = "";
    String? action;

    // Entity Search Logic (Profiles & Organizations)
    if (query.contains("who is") || query.startsWith("search ")) {
      final searchTerm = query.replaceAll(RegExp(r'who is|search'), '').trim();
      final profile = await _supabase.from('profiles')
          .select('full_name, role').ilike('full_name', '%$searchTerm%')
          .maybeSingle();

      if (profile != null) {
        reply = "I found ${profile['full_name']}. Open their profile?";
        action = "/network-profile?id=${profile['id']}";
      }
    }

    // Feature Mapping
    if (query.contains("practice") || query.contains("test")) {
      reply = "Opening the Practice Arena for you!";
      action = "/interview-prep";
    }

    state = state.copyWith(messages: [...state.messages, ChatMessage(text: reply)], lastAction: action);
  }
}
```
