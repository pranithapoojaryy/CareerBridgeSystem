import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';

class StudentFiltersPanel extends StatelessWidget {
  final String selectedDepartment;
  final String selectedBatch;
  final String selectedPlacementStatus;
  final Function(String) onDepartmentChanged;
  final Function(String) onBatchChanged;
  final Function(String) onPlacementStatusChanged;
  final VoidCallback onClearFilters;

  const StudentFiltersPanel({
    super.key,
    required this.selectedDepartment,
    required this.selectedBatch,
    required this.selectedPlacementStatus,
    required this.onDepartmentChanged,
    required this.onBatchChanged,
    required this.onPlacementStatusChanged,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor,
                ),
              ),
              TextButton(
                onPressed: onClearFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Department',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedDepartment,
                          isExpanded: true,
                          items: [
                            'All',
                            'Computer Science',
                            'Information Technology',
                            'Electronics',
                            'Mechanical',
                            'Civil',
                          ].map((dept) {
                            return DropdownMenuItem(
                              value: dept,
                              child: Text(dept),
                            );
                          }).toList(),
                          onChanged: (value) => onDepartmentChanged(value!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Batch',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedBatch,
                          isExpanded: true,
                          items: [
                            'All',
                            '2021-2025',
                            '2022-2026',
                            '2023-2027',
                            '2024-2028',
                          ].map((batch) {
                            return DropdownMenuItem(
                              value: batch,
                              child: Text(batch),
                            );
                          }).toList(),
                          onChanged: (value) => onBatchChanged(value!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Placement Status',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedPlacementStatus,
                          isExpanded: true,
                          items: [
                            'All',
                            'placed',
                            'interviewing',
                            'seeking',
                          ].map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(_getStatusLabel(status)),
                            );
                          }).toList(),
                          onChanged: (value) => onPlacementStatusChanged(value!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'placed':
        return 'Placed';
      case 'interviewing':
        return 'Interviewing';
      case 'seeking':
        return 'Seeking';
      default:
        return 'All';
    }
  }
}