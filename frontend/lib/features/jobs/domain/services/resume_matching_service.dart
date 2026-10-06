import 'dart:math';
import 'package:flutter/foundation.dart';
import 'text_utils.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:http/http.dart' as http;

class ResumeMatchingService {
  // Singleton
  static final ResumeMatchingService _instance =
      ResumeMatchingService._internal();
  factory ResumeMatchingService() => _instance;
  ResumeMatchingService._internal();

  // Cache for extracted resume text to avoid re-downloading
  String? _cachedResumeText;
  String? _cachedResumeUrl;

  Future<String?> extractTextFromPdf(String url) async {
    if (_cachedResumeUrl == url && _cachedResumeText != null) {
      return _cachedResumeText;
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        debugPrint('Failed to download PDF: ${response.statusCode}');
        return null; // Or throw error
      }

      final PdfDocument document = PdfDocument(inputBytes: response.bodyBytes);
      String text = PdfTextExtractor(document).extractText();
      document.dispose();

      _cachedResumeText = text;
      _cachedResumeUrl = url;
      return text;
    } catch (e) {
      debugPrint('Error extracting PDF text: $e');
      return null;
    }
  }

  /// Calculates the match score (0-100) and details using OpenRouter AI
  Future<Map<String, dynamic>> calculateMatchWithAI({
    required String resumeText,
    required String jobTitle,
    required String jobDescription,
    String? jobRequirements,
  }) async {
    try {
      final apiKey = dotenv.env['OPENROUTER_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception("OPENROUTER_API_KEY not found in .env");
      }

      final prompt =
          """
Analyze the fit between a student's resume and a job opening.
JOB TITLE: $jobTitle
JOB REQUIREMENTS: ${jobRequirements ?? 'See description'}
JOB DESCRIPTION: $jobDescription

STUDENT RESUME TEXT:
$resumeText

TASK:
1. Calculate a semantic match score (0-100) based on how well the student's skills and experience align with the recruiter's requirements.
2. Identify specific "matched" keywords or skills found in the resume.
3. Identify "missing" critical requirements or skills mentioned in the job post but not found in the resume.

RESPONSE FORMAT (STRICT JSON ONLY):
{
  "score": integer,
  "matched": ["skill1", "skill2", ...],
  "missing": ["skill1", "skill2", ...]
}
""";

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
              'X-Title': 'CareerBridge AI Matcher',
            },
            body: jsonEncode({
              'model': modelName,
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'You are a professional HR Tech recruiter specializing in technical skill gap analysis. Return only valid JSON.',
                },
                {'role': 'user', 'content': prompt},
              ],
              'temperature': 0.3,
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

      Map<String, dynamic> data = {};

      if (response != null && response.statusCode == 200) {
        data = jsonDecode(response.body);
      } else {
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
                    {
                      'text':
                          'You are a professional HR Tech recruiter specializing in technical skill gap analysis. Return only valid JSON.\n\n$prompt'
                    }
                  ]
                }
              ]
            }),
          );

          if (geminiRes.statusCode == 200) {
            final geminiData = jsonDecode(geminiRes.body);
            final textResp = geminiData['candidates'][0]['content']['parts'][0]
                ['text'] as String;
            data = {
              'choices': [
                {
                  'message': {'content': textResp}
                }
              ]
            };
          } else {
            throw Exception("OpenRouter AI Error: $lastErrorBody");
          }
        } else {
          throw Exception("OpenRouter AI Error: $lastErrorBody");
        }
      }

      final content = data['choices'][0]['message']['content'] as String;

      // Extract JSON if model includes markdown markers
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch == null) {
        throw Exception("AI did not return valid JSON results.");
      }

      return jsonDecode(jsonMatch.group(0)!);
    } catch (e) {
      debugPrint("AI Match Error: $e");
      // Fallback to local logic if AI fails
      return calculateMatch(
        resumeText,
        jobDescription,
        jobRequirements: jobRequirements,
      );
    }
  }

  /// Calculates the match score (0-100) and details (Local Heuristic)
  Map<String, dynamic> calculateMatch(
    String resumeText,
    String jobDescription, {
    String? jobRequirements, // New parameter for high-priority tokens
    List<String>? jobSkills,
  }) {
    final Set<String> resumeTokens = TextUtils.tokenize(resumeText);
    // ... rest of the original logic

    // 1. Build the "Target Set" of tokens (What we are looking for)
    Set<String> targetTokens = {};

    // A. Priority 1: Recruiter-entered Requirements (The "Golden Source")
    if (jobRequirements != null && jobRequirements.isNotEmpty) {
      targetTokens.addAll(TextUtils.tokenize(jobRequirements));
    }

    // B. Priority 2: Explicit Skills (if any)
    if (jobSkills != null) {
      for (var skill in jobSkills) {
        targetTokens.addAll(TextUtils.tokenize(skill));
      }
    }

    // C. Fallback: If we have very few tokens from requirements (< 5),
    // we assume the recruiter might have put details in the description instead.
    if (targetTokens.length < 5) {
      targetTokens.addAll(TextUtils.tokenize(jobDescription));
    }

    if (targetTokens.isEmpty) {
      return {'score': 0, 'matched': <String>[], 'missing': <String>[]};
    }

    // 2. Calculate Intersection (Matched Keywords)
    final Set<String> intersection = resumeTokens.intersection(targetTokens);

    // 3. Calculate Score using Coverage Ratio
    // Score = (Matches / Total Requirements) * 100
    double score = (intersection.length / targetTokens.length) * 100;

    // Boost score slightly for semantic matches or near-matches (heuristic)
    // and cap at 100.
    score = min(score * 1.2, 100);

    return {
      'score': score.round(),
      'matched': intersection.toList(),
      'missing': targetTokens.difference(intersection).toList(),
    };
  }
}
