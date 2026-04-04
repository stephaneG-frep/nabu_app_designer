import 'screen_model.dart';

class ProjectModel {
  ProjectModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.screens,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final List<ScreenModel> screens;

  ProjectModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    List<ScreenModel>? screens,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      screens: screens ?? List<ScreenModel>.from(this.screens),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'screens': screens.map((screen) => screen.toJson()).toList(),
    };
  }

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    final rawScreens = (json['screens'] as List?) ?? <dynamic>[];
    return ProjectModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Untitled Project',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      screens: rawScreens
          .map(
            (item) =>
                ScreenModel.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }
}
