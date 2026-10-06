import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';

class SkillScoreDetailScreen extends StatefulWidget {
  const SkillScoreDetailScreen({super.key});

  @override
  State<SkillScoreDetailScreen> createState() => _SkillScoreDetailScreenState();
}

class _SkillScoreDetailScreenState extends State<SkillScoreDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _fetchBreakdown();
  }

  Future<void> _fetchBreakdown() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Call the RPC function we created
      final response = await Supabase.instance.client.rpc(
        'get_skill_score_breakdown',
        params: {'p_student_id': userId},
      );

      if (mounted) {
        setState(() {
          _data = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching skill breakdown: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = _data?['total_score'] ?? 0;
    final breakdown = (_data?['breakdown'] as List?) ?? [];
    final tips = (_data?['tips'] as List?) ?? [];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Skill Score Analysis',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // 1. Hero Score Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Your Skill Score',
                          style: GoogleFonts.outfit(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.2),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Text(
                            '$score',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          score > 80
                              ? 'Excellent! Top 10%'
                              : (score > 50
                                    ? 'Good Progress'
                                    : 'Needs Improvement'),
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 2. Breakdown Section
                  _buildSectionHeader('Score Breakdown'),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: breakdown.map<Widget>((item) {
                        final val = item['score'] ?? 0;
                        final label = item['label'] ?? '';
                        final colorString = item['color'] ?? '0xFF2196F3';
                        final color = Color(int.parse(colorString));

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          title: Text(
                            label,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$val pts',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: color,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: color.withValues(alpha: 0.2),
                            child: Icon(
                              _getIconForLabel(label),
                              color: color,
                              size: 18,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 3. Tips Section
                  _buildSectionHeader('How to Improve'),
                  const SizedBox(height: 16),
                  ...tips.map(
                    (tip) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            color: Colors.orange,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              tip.toString(),
                              style: GoogleFonts.outfit(
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  IconData _getIconForLabel(String label) {
    if (label.contains('Certifications')) return Icons.verified;
    if (label.contains('Projects')) return Icons.code;
    if (label.contains('Aptitude')) return Icons.quiz;
    if (label.contains('Assessments')) return Icons.assignment_turned_in;
    if (label.contains('Events')) return Icons.event;
    if (label.contains('Interviews')) return Icons.video_camera_front;
    return Icons.star;
  }
}
