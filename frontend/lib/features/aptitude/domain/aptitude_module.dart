class AptitudeModule {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String category;
  final List<String> difficultyLevels;
  final String? colorCode;
  final bool isActive;
  final int displayOrder;

  AptitudeModule({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.difficultyLevels,
    this.colorCode,
    this.isActive = true,
    this.displayOrder = 0,
  });

  factory AptitudeModule.fromJson(Map<String, dynamic> json) {
    return AptitudeModule(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '📝',
      category: json['category'] as String,
      difficultyLevels:
          (json['difficulty_levels'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['easy', 'medium', 'hard'],
      colorCode: json['color_code'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'category': category,
      'difficulty_levels': difficultyLevels,
      'color_code': colorCode,
      'is_active': isActive,
      'display_order': displayOrder,
    };
  }
}
