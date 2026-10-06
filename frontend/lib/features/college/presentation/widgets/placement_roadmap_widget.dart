import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../jobs/domain/job_application.dart';
import '../../../jobs/domain/job_round.dart';
import '../../../../core/theme/app_theme.dart';

/// A reusable widget that displays a horizontal roadmap visualization
/// showing the progression through job application rounds
class PlacementRoadmapWidget extends StatelessWidget {
  final JobApplication application;
  final double height;
  final bool compact;

  const PlacementRoadmapWidget({
    super.key,
    required this.application,
    this.height = 120,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final rounds = application.rounds ?? [];

    // If no rounds defined, show basic status-based roadmap
    if (rounds.isEmpty) {
      return _buildBasicRoadmap(context);
    }

    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: rounds.length,
        itemBuilder: (context, index) {
          final round = rounds[index];
          final isLast = index == rounds.length - 1;
          final roundStatus = _getRoundStatus(round, index);

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRoundIndicator(
                context,
                round: round,
                status: roundStatus,
                roundNumber: index + 1,
              ),
              if (!isLast)
                _buildConnector(
                  context,
                  isCompleted: roundStatus == RoundStatus.completed,
                ),
            ],
          );
        },
      ),
    );
  }

  /// Build basic roadmap based on application status when rounds aren't defined
  Widget _buildBasicRoadmap(BuildContext context) {
    final stages = _getBasicStages();

    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(stages.length, (index) {
          final stage = stages[index];
          final isLast = index == stages.length - 1;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBasicStageIndicator(context, stage, index),
              if (!isLast)
                _buildConnector(context, isCompleted: stage.isCompleted),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildRoundIndicator(
    BuildContext context, {
    required JobRound round,
    required RoundStatus status,
    required int roundNumber,
  }) {
    final icon = _getRoundIcon(round.roundType);
    final color = _getStatusColor(status);
    final isCurrent = status == RoundStatus.current;
    final isCompleted = status == RoundStatus.completed;

    // Use smaller size in compact mode
    final circleSize = compact ? 44.0 : 56.0;
    final iconSize = compact ? 22.0 : 28.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            color: isCompleted ? color : color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: isCurrent ? 3 : 2),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            isCompleted ? Icons.check : icon,
            color: isCompleted ? Colors.white : color,
            size: iconSize,
          ),
        ),
        if (!compact) const SizedBox(height: 8),
        if (!compact)
          SizedBox(
            width: 100,
            child: Text(
              round.displayType,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: isCurrent ? color : Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBasicStageIndicator(
    BuildContext context,
    BasicStage stage,
    int index,
  ) {
    final color = stage.isCompleted
        ? AppTheme.primaryColor
        : stage.isCurrent
        ? Colors.orange
        : Colors.grey;

    // Use smaller size in compact mode
    final circleSize = compact ? 44.0 : 56.0;
    final iconSize = compact ? 22.0 : 28.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            color: stage.isCompleted ? color : color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: stage.isCurrent ? 3 : 2),
            boxShadow: stage.isCurrent
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            stage.isCompleted ? Icons.check : stage.icon,
            color: stage.isCompleted ? Colors.white : color,
            size: iconSize,
          ),
        ),
        if (!compact) const SizedBox(height: 8),
        if (!compact)
          SizedBox(
            width: 100,
            child: Text(
              stage.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: stage.isCurrent
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: stage.isCurrent ? color : Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildConnector(BuildContext context, {required bool isCompleted}) {
    // Calculate vertical position to center connector with circle
    final circleSize = compact ? 44.0 : 56.0;
    final verticalOffset = (height - circleSize) / 2;

    return Container(
      width: compact ? 40 : 60,
      height: 2,
      margin: EdgeInsets.only(bottom: verticalOffset),
      decoration: BoxDecoration(
        color: isCompleted ? AppTheme.primaryColor : Colors.grey[300],
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  RoundStatus _getRoundStatus(JobRound round, int index) {
    final currentRound = application.currentRound;

    if (index < currentRound) {
      return RoundStatus.completed;
    } else if (index == currentRound) {
      return RoundStatus.current;
    } else {
      return RoundStatus.pending;
    }
  }

  Color _getStatusColor(RoundStatus status) {
    switch (status) {
      case RoundStatus.completed:
        return Colors.green;
      case RoundStatus.current:
        return Colors.orange;
      case RoundStatus.pending:
        return Colors.grey;
    }
  }

  IconData _getRoundIcon(String roundType) {
    switch (roundType) {
      case 'resume_screening':
        return Icons.description;
      case 'video_intro':
        return Icons.videocam;
      case 'technical':
        return Icons.computer;
      case 'coding':
        return Icons.code;
      case 'hr':
        return Icons.people;
      case 'quiz':
        return Icons.quiz;
      case 'group_discussion':
        return Icons.forum;
      case 'final':
      case 'final_selection':
        return Icons.workspace_premium;
      default:
        return Icons.arrow_forward;
    }
  }

  List<BasicStage> _getBasicStages() {
    final status = application.status;

    return [
      BasicStage(
        label: 'Applied',
        icon: Icons.send,
        isCompleted: true,
        isCurrent: status == 'applied',
      ),
      BasicStage(
        label: 'Screening',
        icon: Icons.search,
        isCompleted: [
          'shortlisted',
          'in_progress',
          'selected',
        ].contains(status),
        isCurrent: status == 'shortlisted',
      ),
      BasicStage(
        label: 'Interview',
        icon: Icons.people,
        isCompleted: ['in_progress', 'selected'].contains(status),
        isCurrent: status == 'in_progress',
      ),
      BasicStage(
        label: 'Selected',
        icon: Icons.celebration,
        isCompleted: status == 'selected',
        isCurrent: status == 'selected',
      ),
    ];
  }
}

enum RoundStatus { completed, current, pending }

class BasicStage {
  final String label;
  final IconData icon;
  final bool isCompleted;
  final bool isCurrent;

  BasicStage({
    required this.label,
    required this.icon,
    required this.isCompleted,
    required this.isCurrent,
  });
}
