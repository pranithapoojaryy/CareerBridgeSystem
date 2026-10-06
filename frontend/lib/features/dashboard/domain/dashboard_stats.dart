class DashboardStats {
  final double resumeStrength;
  final double profileCompletion;
  final double skillScore;

  const DashboardStats({
    required this.resumeStrength,
    required this.profileCompletion,
    required this.skillScore,
  });

  factory DashboardStats.empty() {
    return const DashboardStats(
      resumeStrength: 0,
      profileCompletion: 0,
      skillScore: 0,
    );
  }
}
