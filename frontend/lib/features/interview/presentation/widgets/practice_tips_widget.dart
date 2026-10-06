import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PracticeTipsWidget extends StatelessWidget {
  const PracticeTipsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Engine Section
            _buildSectionHeader(
              icon: Icons.auto_awesome,
              title: 'AI Engine',
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.analytics_outlined,
              title: 'Smart Evaluation',
              description: 'AI analyzes content, confidence, and structure',
              color: const Color(0xFF8B5CF6),
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.speed,
              title: 'Instant Feedback',
              description: 'Get detailed feedback within seconds',
              color: const Color(0xFF3B82F6),
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.trending_up,
              title: 'Track Progress',
              description: 'Monitor improvement over time',
              color: const Color(0xFF10B981),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // Practice Tips Section
            _buildSectionHeader(
              icon: Icons.lightbulb_outline,
              title: 'Practice Tips',
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              ),
            ),
            const SizedBox(height: 12),
            _buildTipItem('Start with easy questions to build confidence'),
            _buildTipItem('Practice in a quiet environment'),
            _buildTipItem('Speak clearly and maintain eye contact'),
            _buildTipItem('Take notes after each practice session'),
            _buildTipItem('Review AI feedback carefully'),
            _buildTipItem('Practice regularly for best results'),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // How It Works
            _buildSectionHeader(
              icon: Icons.help_outline,
              title: 'How It Works',
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              ),
            ),
            const SizedBox(height: 12),
            _buildStepItem(1, 'Select a question from the list'),
            _buildStepItem(2, 'Record your answer using camera'),
            _buildStepItem(3, 'Submit for AI evaluation'),
            _buildStepItem(4, 'Review detailed feedback'),
            _buildStepItem(5, 'Practice again to improve'),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Gradient gradient,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF6B7280),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFFF59E0B),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tip,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF4B5563),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(int number, String step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                step,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF4B5563),
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
