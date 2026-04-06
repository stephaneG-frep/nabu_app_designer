import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/component_template_model.dart';
import '../models/project_model.dart';

class LocalStorageService {
  LocalStorageService._();

  static final LocalStorageService instance = LocalStorageService._();

  static const String _boxName = 'nabu_projects_box';
  static const String _projectsKey = 'projects_json';
  static const String _componentTemplatesKey = 'component_templates_json';
  static const String _historyStateKey = 'history_state_json';

  late Box<String> _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(_boxName);
  }

  List<ProjectModel> loadProjects() {
    final raw = _box.get(_projectsKey);
    if (raw == null || raw.isEmpty) {
      return <ProjectModel>[];
    }

    final parsed = jsonDecode(raw) as List<dynamic>;
    return parsed
        .map(
          (item) =>
              ProjectModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<void> saveProjects(List<ProjectModel> projects) async {
    final data = projects.map((project) => project.toJson()).toList();
    await _box.put(_projectsKey, jsonEncode(data));
  }

  Map<String, dynamic>? loadHistoryState() {
    final raw = _box.get(_historyStateKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final parsed = jsonDecode(raw);
      if (parsed is Map<String, dynamic>) {
        return parsed;
      }
      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveHistoryState(Map<String, dynamic> historyState) async {
    await _box.put(_historyStateKey, jsonEncode(historyState));
  }

  List<ComponentTemplateModel> loadComponentTemplates() {
    final raw = _box.get(_componentTemplatesKey);
    if (raw == null || raw.isEmpty) {
      return <ComponentTemplateModel>[];
    }
    final parsed = jsonDecode(raw) as List<dynamic>;
    return parsed
        .map(
          (item) => ComponentTemplateModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<void> saveComponentTemplates(
    List<ComponentTemplateModel> templates,
  ) async {
    final data = templates.map((template) => template.toJson()).toList();
    await _box.put(_componentTemplatesKey, jsonEncode(data));
  }
}
