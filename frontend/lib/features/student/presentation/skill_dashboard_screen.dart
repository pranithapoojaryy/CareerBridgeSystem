import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';

/// Student Skill Score model for tracking skill proficiency
class StudentSkillScore {
  final String id;
  final String studentId;
  final String skillName;
  final String skillCategory;
  final double currentScore;
  final int assessmentCount;
  final DateTime lastUpdated;

  StudentSkillScore({
    required this.id,
    required this.studentId,
    required this.skillName,
    required this.skillCategory,
    required this.currentScore,
    required this.assessmentCount,
    required this.lastUpdated,
  });

  String get proficiencyLevel {
    if (currentScore >= 90) return 'Expert';
    if (currentScore >= 75) return 'Advanced';
    if (currentScore >= 50) return 'Intermediate';
    return 'Beginner';
  }

  int get skillColor {
    if (currentScore >= 90) return 0xFF4CAF50; // Green
    if (currentScore >= 75) return 0xFF2196F3; // Blue
    if (currentScore >= 50) return 0xFFFF9800; // Orange
    return 0xFFF44336; // Red
  }
}

class SkillDashboardScreen extends ConsumerWidget {
  const SkillDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This would fetch from repository - placeholder for now
    final mockSkills = _getMockSkills();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(
          'Skill Proficiency',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Skills',
                    '${mockSkills.length}',
                    Icons.psychology,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    'Expert Level',
                    '${mockSkills.where((s) => s.proficiencyLevel == 'Expert').length}',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Skill Categories
            Text(
              'Skills by Category',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            _buildCategorySection(
              'Technical Skills',
              mockSkills.where((s) => s.skillCategory == 'Technical').toList(),
            ),
            const SizedBox(height: 16),
            _buildCategorySection(
              'Soft Skills',
              mockSkills.where((s) => s.skillCategory == 'Soft').toList(),
            ),
            const SizedBox(height: 16),
            _buildCategorySection(
              'Domain Skills',
              mockSkills.where((s) => s.skillCategory == 'Domain').toList(),
            ),

            const SizedBox(height: 32),

            // Skill Radar Chart
            Text(
              'Skill Overview',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Container(
              height: 300,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: RadarChart(
                RadarChartData(
                  radarShape: RadarShape.polygon,
                  tickCount: 5,
                  ticksTextStyle: GoogleFonts.outfit(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                  radarBorderData: BorderSide(color: Colors.grey.shade300),
                  gridBorderData: BorderSide(color: Colors.grey.shade200),
                  tickBorderData: BorderSide(color: Colors.grey.shade300),
                  getTitle: (index, angle) {
                    final skills = mockSkills.take(6).toList();
                    if (index >= skills.length)
                      return RadarChartTitle(text: '');
                    return RadarChartTitle(
                      text: skills[index].skillName,
                      angle: angle,
                    );
                  },
                  dataSets: [
                    RadarDataSet(
                      fillColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                      borderColor: AppTheme.primaryColor,
                      borderWidth: 2,
                      dataEntries: mockSkills
                          .take(6)
                          .map((s) => RadarEntry(value: s.currentScore))
                          .toList(),
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

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
    String category,
    List<StudentSkillScore> skills,
  ) {
    if (skills.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                category,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...skills.map(
            (skill) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildSkillRow(skill),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillRow(StudentSkillScore skill) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                skill.skillName,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Color(skill.skillColor).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                skill.proficiencyLevel,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(skill.skillColor),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: skill.currentScore / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(Color(skill.skillColor)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${skill.currentScore.toStringAsFixed(0)}%',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(skill.skillColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'From ${skill.assessmentCount} assessments',
          style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  List<StudentSkillScore> _getMockSkills() {
    return [
      StudentSkillScore(
        id: '1',
        studentId: 'student1',
        skillName: 'Java Programming',
        skillCategory: 'Technical',
        currentScore: 92,
        assessmentCount: 8,
        lastUpdated: DateTime.now(),
      ),
      StudentSkillScore(
        id: '2',
        studentId: 'student1',
        skillName: 'Spring Boot',
        skillCategory: 'Technical',
        currentScore: 85,
        assessmentCount: 5,
        lastUpdated: DateTime.now(),
      ),
      StudentSkillScore(
        id: '3',
        studentId: 'student1',
        skillName: 'Communication',
        skillCategory: 'Soft',
        currentScore: 78,
        assessmentCount: 3,
        lastUpdated: DateTime.now(),
      ),
      StudentSkillScore(
        id: '4',
        studentId: 'student1',
        skillName: 'Problem Solving',
        skillCategory: 'Soft',
        currentScore: 88,
        assessmentCount: 6,
        lastUpdated: DateTime.now(),
      ),
      StudentSkillScore(
        id: '5',
        studentId: 'student1',
        skillName: 'System Design',
        skillCategory: 'Domain',
        currentScore: 72,
        assessmentCount: 4,
        lastUpdated: DateTime.now(),
      ),
      StudentSkillScore(
        id: '6',
        studentId: 'student1',
        skillName: 'Database Management',
        skillCategory: 'Technical',
        currentScore: 80,
        assessmentCount: 5,
        lastUpdated: DateTime.now(),
      ),
    ];
  }
}
