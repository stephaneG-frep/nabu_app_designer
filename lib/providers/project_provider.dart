import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/component_type.dart';
import '../models/project_model.dart';
import '../models/screen_model.dart';
import '../models/screen_template_type.dart';
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

  Future<void> addScreenFromTemplate(ScreenTemplateType template) async {
    final project = activeProject;
    if (project == null) {
      return;
    }

    final screen = _buildTemplateScreen(template, project.screens.length + 1);
    final updatedProject = project.copyWith(
      screens: [...project.screens, screen],
    );
    _replaceProject(updatedProject);
    _setEditorContext(
      projectId: updatedProject.id,
      screenId: screen.id,
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

  Future<bool> duplicateActiveScreen() async {
    final project = activeProject;
    final screen = activeScreen;
    if (project == null || screen == null) {
      return false;
    }

    final duplicatedComponents = screen.components
        .map(
          (component) => component.copyWith(
            id: IdGenerator.next('component'),
            properties: Map<String, dynamic>.from(component.properties),
          ),
        )
        .toList();

    final duplicatedScreen = ScreenModel(
      id: IdGenerator.next('screen'),
      name: '${screen.name} (copie)',
      components: duplicatedComponents,
      backgroundColor: screen.backgroundColor,
    );

    final index = project.screens.indexWhere((s) => s.id == screen.id);
    final updatedScreens = [...project.screens];
    updatedScreens.insert(index + 1, duplicatedScreen);
    final updatedProject = project.copyWith(screens: updatedScreens);

    _replaceProject(updatedProject);
    _setEditorContext(
      projectId: updatedProject.id,
      screenId: duplicatedScreen.id,
      componentId: null,
    );

    notifyListeners();
    _schedulePersist(pushHistory: true);
    return true;
  }

  Future<bool> renameActiveScreen(String newName) async {
    final screen = activeScreen;
    final trimmed = newName.trim();
    if (screen == null || trimmed.isEmpty) {
      return false;
    }

    final updated = screen.copyWith(name: trimmed);
    _replaceScreen(updated);
    notifyListeners();
    _schedulePersist(pushHistory: true);
    return true;
  }

  Future<bool> moveActiveScreenLeft() async {
    return _moveActiveScreenBy(-1);
  }

  Future<bool> moveActiveScreenRight() async {
    return _moveActiveScreenBy(1);
  }

  Future<bool> _moveActiveScreenBy(int delta) async {
    final project = activeProject;
    final currentId = _activeScreenId;
    if (project == null || currentId == null || delta == 0) {
      return false;
    }

    final index = project.screens.indexWhere((s) => s.id == currentId);
    if (index == -1) {
      return false;
    }

    final targetIndex = index + delta;
    if (targetIndex < 0 || targetIndex >= project.screens.length) {
      return false;
    }

    final updatedScreens = [...project.screens];
    final screen = updatedScreens.removeAt(index);
    updatedScreens.insert(targetIndex, screen);

    final updatedProject = project.copyWith(screens: updatedScreens);
    _replaceProject(updatedProject);
    _setEditorContext(
      projectId: updatedProject.id,
      screenId: currentId,
      componentId: selectedComponentId,
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
      if (!selectedIds.contains(component.id) || _isLocked(component)) {
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
        .where((c) => selectedSet.contains(c.id) && !_isLocked(c))
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
    final lockedIds = screen.components
        .where((c) => selectedSet.contains(c.id) && _isLocked(c))
        .map((c) => c.id)
        .toSet();
    final updatedComponents = screen.components
        .where((component) => !selectedSet.contains(component.id))
        .toList();

    if (lockedIds.isNotEmpty) {
      updatedComponents.addAll(
        screen.components.where((c) => lockedIds.contains(c.id)),
      );
      updatedComponents.sort(
        (a, b) => screen.components
            .indexOf(a)
            .compareTo(screen.components.indexOf(b)),
      );
    }

    final updatedScreen = screen.copyWith(components: updatedComponents);
    _replaceScreen(updatedScreen);
    _selectedComponentIds
      ..clear()
      ..addAll(lockedIds);

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
              ? (_isLocked(component)
                    ? component
                    : component.updateProperty('row', row))
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
              ? (_isLocked(component)
                    ? component
                    : component.updateProperty('alignment', alignment))
              : component,
        )
        .toList();
    _replaceScreen(screen.copyWith(components: updatedComponents));
    notifyListeners();
    _schedulePersist(pushHistory: true);
  }

  Future<void> moveComponentBefore({
    required String draggedId,
    required String targetId,
    bool snapToGrid = false,
    int gridColumns = 2,
  }) async {
    final screen = activeScreen;
    if (screen == null || draggedId == targetId) {
      return;
    }

    final fromIndex = screen.components.indexWhere((c) => c.id == draggedId);
    final toIndex = screen.components.indexWhere((c) => c.id == targetId);
    if (fromIndex == -1 || toIndex == -1) {
      return;
    }

    final target = screen.components[toIndex];
    final targetRow = ((target.properties['row'] as num?) ?? -1).round();
    final snappedRow = snapToGrid
        ? (toIndex / (gridColumns <= 0 ? 1 : gridColumns)).floor()
        : targetRow;

    final updated = [...screen.components];
    final draggedSource = updated.removeAt(fromIndex);
    if (_isLocked(draggedSource)) {
      return;
    }
    final dragged = draggedSource.updateProperty('row', snappedRow);
    final adjustedToIndex = fromIndex < toIndex ? toIndex - 1 : toIndex;
    updated.insert(adjustedToIndex, dragged);

    _replaceScreen(screen.copyWith(components: updated));
    _selectedComponentIds
      ..clear()
      ..add(dragged.id);
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
              ? (_isLocked(component) && key != 'locked'
                    ? component
                    : component.updateProperty(key, value))
              : component,
        )
        .toList();

    final updatedScreen = screen.copyWith(components: updatedComponents);
    _replaceScreen(updatedScreen);

    notifyListeners();
    _schedulePersist(pushHistory: true);
  }

  Future<void> updateComponentPropertyById(
    String componentId,
    String key,
    dynamic value,
  ) async {
    final screen = activeScreen;
    if (screen == null) {
      return;
    }

    final updatedComponents = screen.components
        .map(
          (component) => component.id == componentId
              ? component.updateProperty(key, value)
              : component,
        )
        .toList();

    _replaceScreen(screen.copyWith(components: updatedComponents));
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

  Future<void> setLockedForSelected(bool locked) async {
    await updateSelectedComponentProperty('locked', locked);
  }

  bool isComponentLocked(String componentId) {
    final screen = activeScreen;
    if (screen == null) {
      return false;
    }
    final component = screen.components
        .where((c) => c.id == componentId)
        .firstOrNull;
    if (component == null) {
      return false;
    }
    return _isLocked(component);
  }

  Future<ProjectModel?> duplicateProject(String projectId) async {
    final project = _projectById(projectId);
    if (project == null) {
      return null;
    }

    final clonedScreens = project.screens
        .map(
          (screen) => screen.copyWith(
            id: IdGenerator.next('screen'),
            components: screen.components
                .map(
                  (component) => component.copyWith(
                    id: IdGenerator.next('component'),
                    properties: Map<String, dynamic>.from(component.properties),
                  ),
                )
                .toList(),
          ),
        )
        .toList();

    final clonedProject = project.copyWith(
      id: IdGenerator.next('project'),
      name: '${project.name} (copie)',
      createdAt: DateTime.now(),
      screens: clonedScreens,
    );

    _projects.insert(0, clonedProject);
    notifyListeners();
    await _persistNow();
    _recordHistorySnapshot();
    return clonedProject;
  }

  Future<bool> renameProject(String projectId, String newName) async {
    final project = _projectById(projectId);
    final trimmed = newName.trim();
    if (project == null || trimmed.isEmpty) {
      return false;
    }
    _replaceProject(project.copyWith(name: trimmed));
    notifyListeners();
    await _persistNow();
    _recordHistorySnapshot();
    return true;
  }

  bool _isLocked(UIComponentModel component) {
    return (component.properties['locked'] as bool?) ?? false;
  }

  ScreenModel _buildTemplateScreen(ScreenTemplateType template, int number) {
    final screenId = IdGenerator.next('screen');
    final components = <UIComponentModel>[];

    UIComponentModel c(ComponentType type, Map<String, dynamic> props) =>
        UIComponentModel(id: IdGenerator.next('component'), type: type, properties: props);

    Map<String, dynamic> base({
      required String text,
      required double width,
      required double height,
      int row = -1,
    }) {
      return {
        'text': text,
        'subtitle': '',
        'color': 0xFF2A9D8F,
        'backgroundColor': 0xFFE8F4F2,
        'gradientEndColor': 0xFFD5E9E6,
        'useGradient': false,
        'fontSize': 16.0,
        'fontWeight': 600.0,
        'letterSpacing': 0.0,
        'lineHeight': 1.2,
        'padding': 12.0,
        'borderRadius': 12.0,
        'width': width,
        'height': height,
        'margin': 0.0,
        'visible': true,
        'opacity': 1.0,
        'borderColor': 0xFF2A9D8F,
        'borderWidth': 0.0,
        'elevation': 2.0,
        'rotation': 0.0,
        'scale': 100.0,
        'shadowBlur': 0.0,
        'shadowOpacity': 0.0,
        'shadowOffsetY': 0.0,
        'progress': 0.6,
        'alignment': 'center',
        'row': row,
        'locked': false,
        'actionType': 'none',
        'targetScreenId': '',
        'imagePath': '',
      };
    }

    switch (template) {
      case ScreenTemplateType.login:
        components.add(
          c(ComponentType.appBar, base(text: 'Connexion', width: 320, height: 64)),
        );
        components.add(
          c(ComponentType.text, base(text: 'Bienvenue', width: 280, height: 72)..['fontSize'] = 24.0),
        );
        components.add(c(ComponentType.textField, base(text: 'Email', width: 280, height: 62)));
        components.add(
          c(ComponentType.textField, base(text: 'Mot de passe', width: 280, height: 62)),
        );
        components.add(
          c(ComponentType.button, base(text: 'Se connecter', width: 240, height: 54)),
        );
        break;
      case ScreenTemplateType.dashboard:
        components.add(
          c(ComponentType.appBar, base(text: 'Dashboard', width: 320, height: 64)),
        );
        components.add(
          c(ComponentType.statCard, base(text: '12 480', width: 160, height: 108, row: 0)..['subtitle'] = 'Utilisateurs'),
        );
        components.add(
          c(ComponentType.statCard, base(text: '4 210', width: 160, height: 108, row: 0)..['subtitle'] = 'Commandes'),
        );
        components.add(
          c(ComponentType.banner, base(text: 'Objectif mensuel: 82%', width: 320, height: 90)),
        );
        components.add(
          c(ComponentType.progressBar, base(text: 'Progress', width: 320, height: 28)..['progress'] = 0.82),
        );
        break;
      case ScreenTemplateType.profile:
        components.add(
          c(ComponentType.appBar, base(text: 'Mon profil', width: 320, height: 64)),
        );
        components.add(c(ComponentType.avatar, base(text: 'N', width: 120, height: 120)));
        components.add(c(ComponentType.text, base(text: 'Nabu Designer', width: 280, height: 60)));
        components.add(
          c(ComponentType.listTile, base(text: 'Mes informations', width: 320, height: 76)..['subtitle'] = 'Email, téléphone'),
        );
        components.add(
          c(ComponentType.listTile, base(text: 'Paramètres', width: 320, height: 76)..['subtitle'] = 'Préférences'),
        );
        components.add(
          c(ComponentType.button, base(text: 'Se déconnecter', width: 220, height: 52)),
        );
        break;
      case ScreenTemplateType.onboarding:
        components.add(
          c(ComponentType.imagePlaceholder, base(text: 'Illustration', width: 300, height: 220)),
        );
        components.add(
          c(ComponentType.text, base(text: 'Crée des interfaces rapidement', width: 300, height: 80)..['fontSize'] = 22.0),
        );
        components.add(
          c(ComponentType.text, base(text: 'Glisse, ajuste, exporte en Flutter.', width: 300, height: 70)..['fontSize'] = 14.0),
        );
        components.add(
          c(ComponentType.button, base(text: 'Commencer', width: 220, height: 54)),
        );
        components.add(
          c(ComponentType.button, base(text: 'Passer', width: 180, height: 48)),
        );
        break;
    }

    return ScreenModel(
      id: screenId,
      name: '${template.label} $number',
      components: components,
      backgroundColor: 0xFFFFFFFF,
    );
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
