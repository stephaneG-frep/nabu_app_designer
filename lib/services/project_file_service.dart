import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/project_model.dart';

class ProjectFileService {
  const ProjectFileService();

  Future<String> exportProjectToFile(ProjectModel project) async {
    final root = await getApplicationDocumentsDirectory();
    final exportsDir = Directory('${root.path}/exports');
    if (!exportsDir.existsSync()) {
      exportsDir.createSync(recursive: true);
    }

    final safeName = project.name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final filename =
        '${safeName.isEmpty ? 'project' : safeName}_$timestamp.json';
    final file = File('${exportsDir.path}/$filename');

    final json = const JsonEncoder.withIndent('  ').convert(project.toJson());
    await file.writeAsString(json);
    return file.path;
  }

  Future<String?> pickJsonFileContent() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }
    final path = result.files.first.path;
    if (path == null) {
      return null;
    }
    return File(path).readAsString();
  }

  Future<String> exportFlutterV2Zip({
    required ProjectModel project,
    required Map<String, String> generatedFiles,
  }) async {
    final root = await getApplicationDocumentsDirectory();
    final exportsDir = Directory('${root.path}/exports');
    if (!exportsDir.existsSync()) {
      exportsDir.createSync(recursive: true);
    }

    final safeName = _safeName(project.name);
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final filename =
        '${safeName.isEmpty ? 'project' : safeName}_flutter_v2_$timestamp.zip';
    final file = File('${exportsDir.path}/$filename');

    final archive = Archive();
    final files = <String, String>{
      'pubspec.yaml': _generatedPubspec(project.name),
      ...generatedFiles,
    };
    final ordered = files.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final entry in ordered) {
      final bytes = utf8.encode(entry.value);
      archive.addFile(ArchiveFile(entry.key, bytes.length, bytes));
    }

    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) {
      throw StateError('Impossible de générer le ZIP');
    }
    await file.writeAsBytes(encoded, flush: true);
    return file.path;
  }

  String _safeName(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  String _generatedPubspec(String projectName) {
    final appName = _safeName(projectName);
    return '''
name: ${appName.isEmpty ? 'generated_ui_app' : appName}
description: "Projet Flutter généré depuis Nabu App Designer"
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
''';
  }
}
