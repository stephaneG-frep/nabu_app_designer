import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/project_model.dart';

class LocalStorageService {
  LocalStorageService._();

  static final LocalStorageService instance = LocalStorageService._();

  static const String _boxName = 'nabu_projects_box';
  static const String _projectsKey = 'projects_json';

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
}
