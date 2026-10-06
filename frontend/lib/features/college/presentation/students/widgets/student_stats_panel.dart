import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../data/college_providers.dart';

class StudentStatsPanel extends ConsumerWidget {
  const StudentStatsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentStatsAsync = ref.watch(studentStatsProvider);

    return studentStatsAsync.when(
      data: (stats) => Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Students',
              '${stats['total_students'] ?? 0}',
              'Active: ${stats['active_students'] ?? 0}',
              Icons.people_rounded,
              AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Placement Rate',
              '${stats['placement_rate'] ?? 0}%',
              'Target: 85%',
              Icons.trending_up_rounded,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Avg CGPA',
              '${(stats['average_cgpa'] ?? 0.0).toStringAsFixed(1)}',
              'This semester',
              Icons.grade_rounded,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Profile Completion',
              '${stats['average_completion'] ?? 0}%',
              'Average across all',
              Icons.account_circle_rounded,
              Colors.purple,
            ),
          ),
        ],
      ),
      loading: () => Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Students',
              '...',
              'Loading...',
              Icons.people_rounded,
              AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Placement Rate',
              '...',
              'Loading...',
              Icons.trending_up_rounded,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Avg CGPA',
              '...',
              'Loading...',
              Icons.grade_rounded,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Profile Completion',
              '...',
              'Loading...',
              Icons.account_circle_rounded,
              Colors.purple,
            ),
          ),
        ],
      ),
      error: (error, stack) => Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Students',
              '0',
              'Error loading',
              Icons.people_rounded,
              AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Placement Rate',
              '0%',
              'Error loading',
              Icons.trending_up_rounded,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Avg CGPA',
              '0.0',
              'Error loading',
              Icons.grade_rounded,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Profile Completion',
              '0%',
              'Error loading',
              Icons.account_circle_rounded,
              Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}