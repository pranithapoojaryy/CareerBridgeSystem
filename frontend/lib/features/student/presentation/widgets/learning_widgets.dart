import 'package:flutter/material.dart';

// Domain Badge Widget
class DomainBadge extends StatelessWidget {
  final String? domainType; // IT, Management, General
  final bool small;

  const DomainBadge({super.key, this.domainType, this.small = false});

  @override
  Widget build(BuildContext context) {
    if (domainType == null) return const SizedBox.shrink();

    Color color;
    IconData icon;

    switch (domainType) {
      case 'IT':
        color = const Color(0xFF3B82F6); // Blue
        icon = Icons.code;
        break;
      case 'Management':
        color = const Color(0xFFEC4899); // Pink
        icon = Icons.business_center;
        break;
      case 'General':
        color = const Color(0xFF8B5CF6); // Purple
        icon = Icons.school;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(small ? 6 : 8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: small ? 10 : 12, color: color),
          SizedBox(width: small ? 3 : 4),
          Text(
            domainType!,
            style: TextStyle(
              fontSize: small ? 9 : 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Skill Chip Widget
class SkillChip extends StatelessWidget {
  final String skill;
  final bool small;
  final Color? color;

  const SkillChip({
    super.key,
    required this.skill,
    this.small = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? const Color(0xFF6EC9F5);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(small ? 8 : 12),
        border: Border.all(color: chipColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        skill,
        style: TextStyle(
          fontSize: small ? 9 : 11,
          fontWeight: FontWeight.w500,
          color: chipColor.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

// Progress Ring Widget
class ProgressRing extends StatelessWidget {
  final double progress; // 0-100
  final double size;
  final double strokeWidth;
  final Color color;
  final Widget? child;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 50,
    this.strokeWidth = 4,
    this.color = const Color(0xFF6EC9F5),
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress / 100,
              strokeWidth: strokeWidth,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

// Placement Relevance Badge
class PlacementBadge extends StatelessWidget {
  final String relevance; // High, Medium, Low
  final bool small;

  const PlacementBadge({
    super.key,
    required this.relevance,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (relevance) {
      case 'High':
        color = const Color(0xFF10B981); // Green
        icon = Icons.trending_up;
        break;
      case 'Medium':
        color = const Color(0xFFF59E0B); // Orange
        icon = Icons.horizontal_rule;
        break;
      case 'Low':
        color = const Color(0xFF6B7280); // Gray
        icon = Icons.trending_down;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(small ? 6 : 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: small ? 10 : 12, color: color),
          SizedBox(width: small ? 3 : 4),
          Text(
            relevance,
            style: TextStyle(
              fontSize: small ? 9 : 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
