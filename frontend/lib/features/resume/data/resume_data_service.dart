import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../jobs/domain/services/resume_matching_service.dart';

class ResumeDataService {
  final SupabaseClient _supabase;
  final ResumeMatchingService _matchingService = ResumeMatchingService();

  ResumeDataService([SupabaseClient? client])
    : _supabase = client ?? Supabase.instance.client;

  /// Fetches structured profile data to pre-populate a resume
  Future<Map<String, dynamic>> fetchProfileData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return {};

    try {
      // 1. Basic Profile
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      // 2. Student Profile (Bio, Location, etc.)
      final studentProfile = await _supabase
          .from('student_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      // 3. Skills
      final skills = await _supabase
          .from('student_skills')
          .select('skills(name)')
          .eq('student_id', user.id);

      // 4. Projects
      final projects = await _supabase
          .from('student_projects')
          .select()
          .eq('student_id', user.id);

      return {
        'full_name': profile['full_name'],
        'email': user.email,
        'phone': profile['phone_number'],
        'avatar_url': profile['avatar_url'],
        'location': studentProfile?['location'],
        'bio': studentProfile?['bio'],
        'skills': (skills as List)
            .map((s) => s['skills']['name'].toString())
            .toList(),
        'projects': projects,
      };
    } catch (e) {
      debugPrint('Error fetching profile data for resume: $e');
      return {};
    }
  }

  /// Extracts text from a PDF resume and uses AI to structure it
  Future<Map<String, dynamic>?> parseResumeFromPdf(String url) async {
    try {
      final text = await _matchingService.extractTextFromPdf(url);
      if (text == null || text.isEmpty) return null;

      return await _structureResumeWithAI(text);
    } catch (e) {
      debugPrint('Error parsing resume from PDF: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _structureResumeWithAI(String text) async {
    final apiKey = dotenv.env['OPENROUTER_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint("OPENROUTER_API_KEY not found");
      return null;
    }

    final prompt =
        """
Analyze the following resume text and extract information into a structured JSON format.
STRICTLY follow this JSON schema for the response:

{
  "header": {
    "fullName": "Name",
    "email": "Email",
    "phone": "Phone",
    "location": "City, Country",
    "linkedin": "url",
    "portfolio": "url"
  },
  "summary": "Professional summary paragraph",
  "experience": [
    {
      "company": "Company Name",
      "role": "Title",
      "location": "Location",
      "startDate": "Date",
      "endDate": "Date or Present",
      "isCurrent": boolean,
      "description": "Bullet points or paragraph"
    }
  ],
  "education": [
    {
      "school": "Institution",
      "degree": "Major",
      "location": "Location",
      "startDate": "Year",
      "endDate": "Year",
      "grade": "GPA/Grade"
    }
  ],
  "skills": ["Skill 1", "Skill 2"],
  "projects": [
    {
      "name": "Project Name",
      "role": "Role",
      "startDate": "Date",
      "endDate": "Date",
      "link": "URL",
      "description": "Details"
    }
  ]
}

RESUME TEXT:
$text
""";

    try {
      final modelsToTry = [
        'openrouter/free',
        'google/gemma-4-31b-it:free',
        'qwen/qwen3.8-27b:free',
        'z-ai/glm-5.2:free',
        'google/gemini-2.0-flash-exp:free',
      ];

      http.Response? response;

      for (final modelName in modelsToTry) {
        try {
          final res = await http.post(
            Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
              'HTTP-Referer': 'https://CareerBridge.app',
              'X-Title': 'CareerBridge Resume Parser',
            },
            body: jsonEncode({
              'model': modelName,
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'You are a professional resume parser. Return ONLY valid JSON.',
                },
                {'role': 'user', 'content': prompt},
              ],
              'temperature': 0.1,
            }),
          );

          if (res.statusCode == 200) {
            response = res;
            break;
          }
        } catch (_) {}
      }

      String content = '';

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        content = data['choices'][0]['message']['content'] as String;
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
                          'You are a professional resume parser. Return ONLY valid JSON.\n\n$prompt'
                    }
                  ]
                }
              ]
            }),
          );

          if (geminiRes.statusCode == 200) {
            final geminiData = jsonDecode(geminiRes.body);
            content = geminiData['candidates'][0]['content']['parts'][0]['text']
                as String;
          } else {
            return null;
          }
        } else {
          return null;
        }
      }

      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch == null) return null;

      return jsonDecode(jsonMatch.group(0)!);
    } catch (e) {
      debugPrint('AI Parse Error: $e');
      return null;
    }
  }

  /// Persists extracted resume data back to the user's platform profile
  Future<void> persistExtractedData(Map<String, dynamic> data) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Update Profile (Name, Phone)
      final header = data['header'];
      if (header != null) {
        await _supabase
            .from('profiles')
            .update({
              if (header['fullName'] != null) 'full_name': header['fullName'],
              if (header['phone'] != null) 'phone_number': header['phone'],
            })
            .eq('id', user.id);

        if (header['location'] != null) {
          await _supabase.from('student_profiles').upsert({
            'id': user.id,
            'location': header['location'],
          });
        }
      }

      // 2. Update Bio from Summary
      if (data['summary'] != null) {
        await _supabase.from('student_profiles').upsert({
          'id': user.id,
          'bio': data['summary'],
        });
      }

      // 3. Update Skills
      if (data['skills'] != null && data['skills'] is List) {
        final List<String> skills = List<String>.from(data['skills']);
        for (final skillName in skills) {
          try {
            // Get or create skill in skills_database
            var skillResult = await _supabase
                .from('skills')
                .select('id')
                .ilike('name', skillName)
                .maybeSingle();

            String skillId;
            if (skillResult == null) {
              final newSkill = await _supabase
                  .from('skills')
                  .insert({'name': skillName})
                  .select('id')
                  .single();
              skillId = newSkill['id'];
            } else {
              skillId = skillResult['id'];
            }

            // Link to student
            await _supabase.from('student_skills').upsert({
              'student_id': user.id,
              'skill_id': skillId,
            });
          } catch (e) {
            debugPrint('Error syncing skill $skillName: $e');
          }
        }
      }

      // 4. Update Projects
      if (data['projects'] != null && data['projects'] is List) {
        for (final p in data['projects']) {
          await _supabase.from('student_projects').insert({
            'student_id': user.id,
            'title': p['name'] ?? 'Untitled Project',
            'description': p['description'] ?? '',
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (e) {
      debugPrint('Error persisting extracted data: $e');
      rethrow;
    }
  }
}
