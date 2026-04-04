import 'ui_component_model.dart';

class ScreenModel {
  ScreenModel({
    required this.id,
    required this.name,
    required this.components,
    required this.backgroundColor,
  });

  final String id;
  final String name;
  final List<UIComponentModel> components;
  final int backgroundColor;

  ScreenModel copyWith({
    String? id,
    String? name,
    List<UIComponentModel>? components,
    int? backgroundColor,
  }) {
    return ScreenModel(
      id: id ?? this.id,
      name: name ?? this.name,
      components: components ?? List<UIComponentModel>.from(this.components),
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'components': components.map((component) => component.toJson()).toList(),
      'backgroundColor': backgroundColor,
    };
  }

  factory ScreenModel.fromJson(Map<String, dynamic> json) {
    final rawComponents = (json['components'] as List?) ?? <dynamic>[];
    return ScreenModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Untitled Screen',
      components: rawComponents
          .map(
            (item) => UIComponentModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      backgroundColor: (json['backgroundColor'] as int?) ?? 0xFFFFFFFF,
    );
  }
}
