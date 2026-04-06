import 'ui_component_model.dart';

class ComponentTemplateModel {
  ComponentTemplateModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.components,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final List<UIComponentModel> components;

  ComponentTemplateModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    List<UIComponentModel>? components,
  }) {
    return ComponentTemplateModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      components: components ?? List<UIComponentModel>.from(this.components),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'components': components.map((component) => component.toJson()).toList(),
    };
  }

  factory ComponentTemplateModel.fromJson(Map<String, dynamic> json) {
    final raw = (json['components'] as List?) ?? const <dynamic>[];
    return ComponentTemplateModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Template',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      components: raw
          .map(
            (item) => UIComponentModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}
