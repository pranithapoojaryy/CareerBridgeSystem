import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/dashboard_stats.dart';

class DashboardRepository {
  final SupabaseClient _supabase;

  DashboardRepository(this._supabase);

  Future<DashboardStats> getStudentStats(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return _calculateStats(response);
    } catch (e) {
      // If profile not found or error, return empty stats
      return DashboardStats.empty();
    }
  }

  DashboardStats _calculateStats(Map<String, dynamic> profile) {
    // 1. Profile Completion Calculation
    // Fields to check: full_name, phone, college_id, department, cgpa, skills, resume_url
    int totalFields = 7;
    int filledFields = 0;

    if (profile['full_name'] != null &&
        profile['full_name'].toString().isNotEmpty)
      filledFields++;
    if (profile['phone'] != null && profile['phone'].toString().isNotEmpty)
      filledFields++;
    if (profile['college_id'] != null &&
        profile['college_id'].toString().isNotEmpty)
      filledFields++;
    if (profile['department'] != null &&
        profile['department'].toString().isNotEmpty)
      filledFields++;
    if (profile['cgpa'] != null && (profile['cgpa'] as num) > 0) filledFields++;

    final skills = (profile['skills'] as List?) ?? [];
    if (skills.isNotEmpty) filledFields++;

    final hasResume =
        profile['resume_url'] != null &&
        profile['resume_url'].toString().isNotEmpty;
    if (hasResume) filledFields++;

    final profileCompletion = filledFields / totalFields;

    // 2. Resume Strength Calculation
    // Base 20% for having a resume
    // +20% for having skills
    // +20% for having CGPA > 0
    // +20% for having full details (phone, college_id)
    // +20% for having > 3 skills
    double resumeStrength = 0.0;
    if (hasResume) resumeStrength += 0.2;
    if (skills.isNotEmpty) resumeStrength += 0.2;
    if (profile['cgpa'] != null && (profile['cgpa'] as num) > 0)
      resumeStrength += 0.2;
    if (profile['phone'] != null && profile['college_id'] != null)
      resumeStrength += 0.2;
    if (skills.length > 3) resumeStrength += 0.2;

    // 3. Skill Score Calculation
    // 10 points per skill, max 100 (10 skills)
    // Normalized to 0.0 - 1.0
    double skillScore = (skills.length * 10).clamp(0, 100) / 100.0;

    return DashboardStats(
      resumeStrength: resumeStrength,
      profileCompletion: profileCompletion,
      skillScore: skillScore,
    );
  }
}
