import 'package:flutter/material.dart';
import '../../domain/certificate_model.dart';

class TrustShield extends StatelessWidget {
  final ValidationStatus status;
  final int trustLevel;
  final bool showLabel;
  final double size;

  const TrustShield({
    super.key,
    required this.status,
    this.trustLevel = 0,
    this.showLabel = true,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIcon(),
        if (showLabel) ...[
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getStatusLabel(),
                style: TextStyle(
                  color: _getColor(),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              if (trustLevel > 0)
                Text(
                  '$trustLevel% Trust Score',
                  style: TextStyle(color: Colors.grey[600], fontSize: 10),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _getColor().withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: _getColor(), width: 1.5),
      ),
      child: Icon(_getIconData(), size: size, color: _getColor()),
    );
  }

  IconData _getIconData() {
    switch (status) {
      case ValidationStatus.verified:
        return Icons.verified; // Shield/Check
      case ValidationStatus.collegeVerified:
        return Icons.school; // College verification
      case ValidationStatus.partiallyVerified:
        return Icons.verified_user_outlined;
      case ValidationStatus.pending:
        return Icons.hourglass_empty;
      case ValidationStatus.rejected:
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Color _getColor() {
    switch (status) {
      case ValidationStatus.verified:
        return Colors.green;
      case ValidationStatus.collegeVerified:
        return Colors.blue;
      case ValidationStatus.partiallyVerified:
        return Colors.orange;
      case ValidationStatus.pending:
        return Colors.amber;
      case ValidationStatus.rejected:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel() {
    switch (status) {
      case ValidationStatus.verified:
        return 'Verified';
      case ValidationStatus.collegeVerified:
        return 'College Verified';
      case ValidationStatus.partiallyVerified:
        return 'Partially Verified';
      case ValidationStatus.pending:
        return 'Pending Review';
      case ValidationStatus.rejected:
        return 'Rejected';
      default:
        return 'Unverified';
    }
  }
}
