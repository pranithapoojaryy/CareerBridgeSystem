import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_theme.dart';

class StudentSkillsRadarChart extends StatelessWidget {
  final Map<String, double>
  skillsData; // Map of 'Skill Name' -> 0.0 to 1.0 value

  const StudentSkillsRadarChart({super.key, required this.skillsData});

  @override
  Widget build(BuildContext context) {
    if (skillsData.isEmpty) {
      return Center(child: Text("No skills data available yet"));
    }

    // Convert map to ticks and data sets
    final skillNames = skillsData.keys.toList();
    final values = skillsData.values.toList();

    return AspectRatio(
      aspectRatio: 1.3,
      child: RadarChart(
        RadarChartData(
          dataSets: [
            RadarDataSet(
              fillColor: AppTheme.primaryColor.withValues(alpha: 0.2),
              borderColor: AppTheme.primaryColor,
              entryRadius: 3,
              dataEntries: values
                  .map((v) => RadarEntry(value: v * 10)) // Scale 0-1 to 0-10
                  .toList(),
              borderWidth: 2,
            ),
          ],
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          radarBorderData: const BorderSide(color: Colors.transparent),
          titlePositionPercentageOffset: 0.1,
          titleTextStyle: GoogleFonts.outfit(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.bold,
          ),
          getTitle: (index, angle) {
            if (index < skillNames.length) {
              return RadarChartTitle(text: skillNames[index]);
            }
            return const RadarChartTitle(text: "");
          },
          tickCount: 3,
          ticksTextStyle: const TextStyle(color: Colors.transparent),
          tickBorderData: BorderSide(color: Colors.grey.shade300),
          gridBorderData: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        swapAnimationDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}
