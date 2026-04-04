import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/component_type.dart';
import '../models/project_model.dart';
import '../models/screen_model.dart';
import '../models/ui_component_model.dart';
import '../services/local_storage_service.dart';
import '../utils/id_generator.dart';

class ProjectProvider extends ChangeNotifier {
  ProjectProvider(this._storageService);

  final LocalStorageService _storageService;

  final List<ProjectModel> _projects = <ProjectModel>[];
  bool _isLoading = true;

  String? _activeProjectId;
  String? _activeScreenId;
  final List<String> _selectedComponentIds = <String>[];

  Timer? _saveDebounce;

  final List<String> _history = <String>[];
  int _historyIndex = -1;
  bool _isRestoringHistory = false;

  bool get isLoading => _isLoading;
  List<ProjectModel> get projects => List<ProjectModel>.unmodifiable(_projects);

  String? get activeProjectId => _activeProjectId;
  String? get activeScreenId => _activeScreenId;
  String? get selectedComponentId => _selectedComponentIds.lastOrNull;
  List<String> get selectedComponentIds =>
      List<String>.unmodifiable(_selectedComponentIds);
  bool get hasSelection => _selectedComponentIds.isNotEmpty;
  bool get isMultiSelecting => _selectedComponentIds.length > 1;

  bool get canUndo => _historyIndex > 0;
  bool get canRedo => _historyIndex >= 0 && _historyIndex < _history.length - 1;

  ProjectModel? get activeProject => _projectById(_activeProjectId);

  ScreenModel? get activeScreen {
    final project = activeProject;
    if (project == null) {
      return null;
    }
    return project.screens
        .where((screen) => screen.id == _activeScreenId)
        .firstOrNull;
  }

  UIComponentModel? get selectedComponent {
    final screen = activeScreen;
    if (screen == null) {
      return null;
    }
    return screen.components
        .where((component) => component.id == selectedComponentId)
        .firstOrNull;
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    final loaded = _storageService.loadProjects();
    _projects
      ..clear()
      ..addAll(loaded);

    _resetHistory();
    _isLoading = false;
    notifyListeners();
  }

  Future<ProjectModel> createProject(String name) async {
    final defaultScreen = ScreenModel(
      id: IdGenerator.next('screen'),
      name: 'Home',
      components: <UIComponentModel>[],
      backgroundColor: 0xFFFFFFFF,
    );

    final project = ProjectModel(
      id: IdGenerator.next('project'),
      name: name.trim(),
      createdAt: DateTime.now(),
      screens: [defaultScreen],
    );

    _projects.insert(0, project);
    _setEditorContext(
      projectId: project.id,
      screenId: defaultScreen.id,
      componentId: null,
    );
    notifyListeners();
    await _persistNow();
    _recordHistorySnapshot();
    return project;
  }

  Future<void> deleteProject(String projectId) async {
    _projects.removeWhere((project) => project.id == projectId);

    if (_activeProjectId == projectId) {
      _setEditorContext(projectId: null, screenId: null, componentId: null);
    }

    notifyListeners();
    await _persistNow();
    _recordHistorySnapshot();
  }

  void openProject(String projectId) {
    final project = _projectById(projectId);
    if (project == null) {
      return;
    }

    final firstScreenId = project.screens.isNotEmpty
        ? project.screens.first.id
        : null;
    _setEditorContext(
      projectId: project.id,
      screenId: firstScreenId,
      componentId: null,
    );
    notifyListeners();
  }

  Future<void> addScreen({String? name}) async {
    final project = activeProject;
    if (project == null) {
      return;
    }

    final newScreen = ScreenModel(
      id: IdGenerator.next('screen'),
      name: name?.trim().isNotEmpty == true
          ? name!.trim()
          : 'Screen ${project.screens.length + 1}',
      components: <UIComponentModel>[],
      backgroundColor: 0xFFFFFFFF,
    );

    final updatedProject = project.copyWith(
      screens: [...project.screens, newScreen],
    );

    _replaceProject(updatedProject);
    _setEditorContext(
      projectId: updatedProject.id,
      screenId: newScreen.id,
      componentId: null,
    );

    notifyListeners();
    _schedulePersist(pushHistory: true);
  }

  Future<bool> deleteActiveScreen() async {
    final project = activeProject;
    final currentScreenId = _activeScreenId;
    if (project == null || currentScreenId == null) {
      return false;
    }

    if (project.screens.length <= 1) {
      return false;
    }

    final updatedScreens = project.screens
        .where((screen) => screen.id != currentScreenId)
        .toList();

    final nextScreenId = updatedScreens.first.id;
    final updatedProject = project.copyWith(screens: updatedScreens);

    _replaceProject(updatedProject);
    _setEditorContext(
      projectId: updatedProject.id,
      screenId: nextScreenId,
      componentId: null,
    );

    notifyListeners();
    _schedulePersist(pushHistory: true);
    return true;
  }

  void selectScreen(String screenId) {
    final project = activeProject;
    if (project == null) {
      return;
    }

    final exists = project.screens.any((screen) => screen.id == screenId);
    if (!exists) {
      return;
    }

    _setEditorContext(
      projectId: project.id,
      screenId: screenId,
      componentId: null,
    );
    notifyListeners();
  }

  Future<void> addComponent(ComponentType type) async {
    final project = activeProject;
    final screen = activeScreen;
    if (project == null || screen == null) {
      return;
    }

    var component = UIComponentModel.createDefault(
      id: IdGenerator.next('component'),
      type: type,
    );

    final selected = selectedComponent;
    if (selected != null) {
      final selectedRow = ((selected.properties['row'] as num?) ?? -1).round();
      component = component.updateProperty('row', selectedRow);
    }

    final updatedComponents = type == ComponentType.appBar
        ? [component, ...screen.components]
        : [...screen.components, component];

    final updatedScreen = screen.copyWith(components: updatedComponents);

    _replaceScreen(updatedScreen);
    _selectedComponentIds
      ..clear()
      ..add(component.id);

    notifyListeners();
    _schedulePersist(pushHistory: true);
  }

  Future<void> duplicateSelectedComponent() async {
    final screen = activeScreen;
    if (screen == null || _selectedComponentIds.isEmpty) {
      return;
    }

    final selectedIds = _selectedComponentIds.toSet();
    final updatedComponents = <UIComponentModel>[];
    final duplicatedIds = <String>[];

    for (final component in screen.components) {
      updatedComponents.add(component);
      if (!selectedIds.contains(component.id)) {
        continue;
      }
      final cloned = component.copyWith(
        id: IdGenerator.next('component'),
        properties: Map<String, dynamic>.from(component.properties)
          ..['text'] = _copyText(component.properties['text'] as String?),
      );
      updatedComponents.add(cloned);
      duplicatedIds.add(cloned.id);
    }

    _replaceScreen(screen.copyWith(components: updatedComponents));
    _selectedComponentIds
      ..clear()
      ..addAll(duplicatedIds);
    notifyListeners();
    _schedulePersist(pushHistory: true);
  }

  Future<void> bringSelectedToFront() async {
    await _moveSelectedToExtreme(front: true);
  }

  Future<void> sendSelectedToBack() async {
    await _moveSelectedToExtreme(front: false);
  }

  Future<void> _moveSelectedToExtreme({required bool front}) async {
    final screen = activeScreen;
    if (screen == null || _selectedComponentIds.isEmpty) {
      return;
    }

    final selectedSet = _selectedComponentIds.toSet();
    final selectedComponents = screen.components
        .where((c) => selectedSet.contains(c.id))
        .toList();
    if (selectedComponents.isEmpty) {
      return;
    }

    final others = screen.components
        .where((c) => !selectedSet.contains(c.id))
        .toList();
    final updated = front
        ? [...others, ...selectedComponents]
        : [...selectedComponents, ...others];

    _replaceScreen(screen.copyWith(components: updated));
    notifyListeners();
    _schedulePersist(pushHistory: true);
  }

  Future<void> removeSelectedComponent() async {
    final screen = activeScreen;
    if (screen == null || _selectedComponentIds.isEmpty) {
      return;
    }

    final selectedSet = _selectedComponentIds.toSet();
    final updatedComponents = screen.components
        .where((component) => !selectedSet.contains(component.id))
        .toList();

    final updatedScreen = screen.copyWith(components: updatedComponents);
    _replaceScreen(updatedScreen);
    _selectedComponentIds.clear();

    notifyListeners();
    _schedulePersist(pushHistory: true);
  }

  void selectComponent(String componentId) {
    final screen = activeScreen;
    if (screen == null) {
      return;
    }

    final exists = screen.components.any(
      (component) => component.id == componentId,
    );
    if (!exists) {
      return;
    }

    _selectedComponentIds
      ..clear()
      ..add(componentId);
    notifyListeners();
  }

  void toggleComponentSelection(String componentId) {
    final screen = activeScreen;
    if (screen == null) {
      return;
    }
    final exists = screen.components.any((c) => c.id == componentId);
    if (!exists) {
      return;
    }

    if (_selectedComponentIds.contains(componentId)) {
      _selectedComponentIds.remove(componentId);
    } else {
      _selectedComponentIds.add(componentId);
    }
    notifyListeners();
  }

  Future<void> setSelectedComponentsRow(int row) async {
    final screen = activeScreen;
    if (screen == null || _selectedComponentIds.isEmpty) {
      return;
    }
    final selectedSet = _selectedComponentIds.toSet();
    final updatedComponents = screen.components
        .map(
          (component) => selectedSet.contains(component.id)
              ? component.updateProperty('row', row)
              : component,
        )
        .toList();
    _replaceScreen(screen.copyWith(components: updatedComponents));
    notifyListeners();
    _schedulePersist(pushHistory: true);
  }

  Future<void> alignSelected(String alignment) async {
    final screen = activeScreen;
    if (screen == null || _selectedComponentIds.isEmpty) {
      return;
    }
    final selectedSet = _selectedComponentIds.toSet();
    final updatedComponents = screen.components
        .map(
          (component) => selectedSet.contains(component.id)
              ? component.updateProperty('alignment', alignment)
              : component,
        )
        .toList();
    _replaceScreen(screen.copyWith(components: updatedComponents));
    notifyListeners();
    _schedulePersist(pushHistory: true);
  }

  void clearSelectedComponent() {
    _selectedComponentIds.clear();
    notifyListeners();
  }

  Future<void> updateSelectedComponentProperty(
    String key,
    dynamic value,
  ) async {
    final screen = activeScreen;
    if (screen == null || _selectedComponentIds.isEmpty) {
      return;
    }

    final selectedSet = _selectedComponentIds.toSet();
    final updatedComponents = screen.components
        .map(
          (component) => selectedSet.contains(component.id)
              ? component.updateProperty(key, value)
              : component,
        )
        .toList();

    final updatedScreen = screen.copyWith(components: updatedComponents);
    _replaceScreen(updatedScreen);

    notifyListeners();
    _schedulePersist(pushHistory: true);
  }

  Future<void> updateActiveScreenBackgroundColor(int color) async {
    final screen = activeScreen;
    if (screen == null) {
      return;
    }

    final updatedScreen = screen.copyWith(backgroundColor: color);
    _replaceScreen(updatedScreen);
    notifyListeners();
    _schedulePersist(pushHistory: true);
  }

  Future<void> undo() async {
    if (!canUndo) {
      return;
    }
    _historyIndex -= 1;
    _restoreSnapshot(_history[_historyIndex]);
    notifyListeners();
    await _persistNow();
  }

  Future<void> redo() async {
    if (!canRedo) {
      return;
    }
    _historyIndex += 1;
    _restoreSnapshot(_history[_historyIndex]);
    notifyListeners();
    await _persistNow();
  }

  String? screenNameById(String? screenId) {
    if (screenId == null) {
      return null;
    }
    return activeProject?.screens
        .where((screen) => screen.id == screenId)
        .firstOrNull
        ?.name;
  }

  String? exportActiveProjectJson() {
    final project = activeProject;
    if (project == null) {
      return null;
    }
    return const JsonEncoder.withIndent('  ').convert(project.toJson());
  }

  Future<ProjectModel?> importProjectFromJson(String rawJson) async {
    final data = jsonDecode(rawJson) as Map<String, dynamic>;
    final imported = ProjectModel.fromJson(data);
    final normalized = _cloneProjectWithFreshIds(imported);
    _projects.insert(0, normalized);
    _setEditorContext(
      projectId: normalized.id,
      screenId: normalized.screens.firstOrNull?.id,
      componentId: null,
    );
    notifyListeners();
    await _persistNow();
    _recordHistorySnapshot();
    return normalized;
  }

  Future<void> _persistNow() async {
    await _storageService.saveProjects(_projects);
  }

  void _schedulePersist({required bool pushHistory}) {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 250), () async {
      await _storageService.saveProjects(_projects);
      if (pushHistory) {
        _recordHistorySnapshot();
      }
    });
  }

  void _replaceScreen(ScreenModel updatedScreen) {
    final project = activeProject;
    if (project == null) {
      return;
    }

    final updatedScreens = project.screens
        .map((screen) => screen.id == updatedScreen.id ? updatedScreen : screen)
        .toList();

    _replaceProject(project.copyWith(screens: updatedScreens));
  }

  void _replaceProject(ProjectModel updatedProject) {
    final index = _projects.indexWhere(
      (project) => project.id == updatedProject.id,
    );
    if (index == -1) {
      return;
    }
    _projects[index] = updatedProject;
  }

  ProjectModel? _projectById(String? projectId) {
    if (projectId == null) {
      return null;
    }
    return _projects.where((project) => project.id == projectId).firstOrNull;
  }

  void _setEditorContext({
    required String? projectId,
    required String? screenId,
    required String? componentId,
  }) {
    _activeProjectId = projectId;
    _activeScreenId = screenId;
    _selectedComponentIds
      ..clear()
      ..addAll(componentId == null ? const [] : [componentId]);
  }

  void _resetHistory() {
    _history
      ..clear()
      ..add(_snapshotState());
    _historyIndex = 0;
  }

  void _recordHistorySnapshot() {
    if (_isRestoringHistory) {
      return;
    }
    final snapshot = _snapshotState();
    if (_historyIndex >= 0 && _history[_historyIndex] == snapshot) {
      return;
    }
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(snapshot);
    _historyIndex = _history.length - 1;
  }

  String _snapshotState() {
    final payload = <String, dynamic>{
      'projects': _projects.map((project) => project.toJson()).toList(),
      'activeProjectId': _activeProjectId,
      'activeScreenId': _activeScreenId,
      'selectedComponentIds': _selectedComponentIds,
    };
    return jsonEncode(payload);
  }

  void _restoreSnapshot(String snapshot) {
    final map = jsonDecode(snapshot) as Map<String, dynamic>;
    final rawProjects = (map['projects'] as List?) ?? <dynamic>[];
    final restoredIds =
        (map['selectedComponentIds'] as List?)
            ?.map((item) => item.toString())
            .toList() ??
        <String>[];
    final legacySelectedId = map['selectedComponentId'] as String?;
    if (restoredIds.isEmpty && legacySelectedId != null) {
      restoredIds.add(legacySelectedId);
    }
    _isRestoringHistory = true;
    _projects
      ..clear()
      ..addAll(
        rawProjects.map(
          (item) =>
              ProjectModel.fromJson(Map<String, dynamic>.from(item as Map)),
        ),
      );
    _setEditorContext(
      projectId: map['activeProjectId'] as String?,
      screenId: map['activeScreenId'] as String?,
      componentId: restoredIds.lastOrNull,
    );
    _selectedComponentIds
      ..clear()
      ..addAll(restoredIds);
    _isRestoringHistory = false;
  }

  ProjectModel _cloneProjectWithFreshIds(ProjectModel project) {
    final screens = project.screens.map((screen) {
      final components = screen.components
          .map(
            (component) =>
                component.copyWith(id: IdGenerator.next('component')),
          )
          .toList();
      return screen.copyWith(
        id: IdGenerator.next('screen'),
        components: components,
      );
    }).toList();

    return project.copyWith(
      id: IdGenerator.next('project'),
      name: '${project.name} (import)',
      createdAt: DateTime.now(),
      screens: screens,
    );
  }

  String _copyText(String? text) {
    final base = (text ?? '').trim();
    if (base.isEmpty) {
      return 'Copie';
    }
    return '$base (copie)';
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    super.dispose();
  }
}

extension FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) {
      return null;
    }
    return first;
  }
}

extension LastOrNullExtension<T> on Iterable<T> {
  T? get lastOrNull {
    if (isEmpty) {
      return null;
    }
    return last;
  }
}

extension RemoveWhereWithResultExtension<T> on List<T> {
  T? removeWhereWithResult(bool Function(T element) predicate) {
    final index = indexWhere(predicate);
    if (index == -1) {
      return null;
    }
    return removeAt(index);
  }
}
