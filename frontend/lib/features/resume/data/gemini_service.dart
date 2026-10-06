import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  late final GenerativeModel _model;

  // Singleton pattern
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;

  GeminiService._internal() {
    // Assuming API key is in environment or passed securely
    // For now we initialize with a placeholder or expect init() to be called
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
  }

  Future<String> generateSummary({
    required String role,
    required List<String> skills,
    required List<String> experience,
  }) async {
    final prompt =
        '''
      Generate a professional 3-4 sentence resume summary for a $role.
      Skills: ${skills.join(', ')}
      Experience Highlights: ${experience.join('; ')}
      
      Tone: Professional, Impactful.
      Output text only, no markdown formatting.
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? 'Could not generate summary.';
    } catch (e) {
      return 'Error connecting to AI service.';
    }
  }

  Future<String> enhanceBulletPoint(String original) async {
    final prompt =
        '''
      Enhance this resume bullet point to be more impactful, using action verbs and quantifying results if possible (guess reasonable metrics if needed but keep it realistic).
      Original: "$original"
      
      Output only the enhanced bullet point.
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? original;
    } catch (e) {
      return original;
    }
  }
}
