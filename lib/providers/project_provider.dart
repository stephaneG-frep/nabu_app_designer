import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/component_type.dart';
import '../models/component_template_model.dart';
import '../models/history_timeline_entry.dart';
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
  final List<ComponentTemplateModel> _componentTemplates =
      <ComponentTemplateModel>[];
  bool _isLoading = true;

  String? _activeProjectId;
  String? _activeScreenId;
  final List<String> _selectedComponentIds = <String>[];

  Timer? _saveDebounce;
  bool _isSaving = false;
  bool _hasPendingSave = false;
  bool _saveQueued = false;
  String? _lastSaveError;
  DateTime? _lastSavedAt;
  String _pendingHistoryLabel = 'Modification';
  final List<UIComponentModel> _clipboardComponents = <UIComponentModel>[];
  Map<String, dynamic>? _styleClipboard;

  final List<_HistoryEntry> _history = <_HistoryEntry>[];
  int _historyIndex = -1;
  bool _isRestoringHistory = false;
  static const int _maxHistoryEntries = 300;

  bool get isLoading => _isLoading;
  List<ProjectModel> get projects => List<ProjectModel>.unmodifiable(_projects);
  List<ComponentTemplateModel> get componentTemplates =>
      List<ComponentTemplateModel>.unmodifiable(_componentTemplates);

  String? get activeProjectId => _activeProjectId;
  String? get activeScreenId => _activeScreenId;
  String? get selectedComponentId => _selectedComponentIds.lastOrNull;
  List<String> get selectedComponentIds =>
      List<String>.unmodifiable(_selectedComponentIds);
  bool get hasSelection => _selectedComponentIds.isNotEmpty;
  bool get isMultiSelecting => _selectedComponentIds.length > 1;

  bool get canUndo => _historyIndex > 0;
  bool get canRedo => _historyIndex >= 0 && _historyIndex < _history.length - 1;
  int get historyEntryCount => _history.length;
  bool get hasClipboard => _clipboardComponents.isNotEmpty;
  bool get hasStyleClipboard => _styleClipboard != null;
  bool get canGroupSelection => _selectedComponentIds.length >= 2;
  bool get canUngroupSelection {
    final screen = activeScreen;
    if (screen == null || _selectedComponentIds.isEmpty) {
      return false;
    }
    final selectedSet = _selectedComponentIds.toSet();
    return screen.components.any((component) {
      if (!selectedSet.contains(component.id)) {
        return false;
      }
      return _groupIdOf(component).isNotEmpty;
    });
  }

  bool get canSelectGroupOfSelection {
    final screen = activeScreen;
    final component = selectedComponent;
    if (screen == null || component == null) {
      return false;
    }
    final groupId = _groupIdOf(component);
    if (groupId.isEmpty) {
      return false;
    }
    final count = screen.components
        .where((item) => _groupIdOf(item) == groupId)
        .length;
    return count > 1;
  }

  bool get canNestSelection {
    final screen = activeScreen;
    final parent = selectedComponent;
    if (screen == null || parent == null || _selectedComponentIds.length < 2) {
      return false;
    }
    if (!_canHostChildren(parent.type)) {
      return false;
    }
    final selectedSet = _selectedComponentIds.toSet();
    final movableChildren = screen.components.where((component) {
      if (!selectedSet.contains(component.id) || component.id == parent.id) {
        return false;
      }
      return !_isLocked(component);
    }).toList();
    return movableChildren.isNotEmpty;
  }

  bool get canDetachFromParent {
    final screen = activeScreen;
    if (screen == null || _selectedComponentIds.isEmpty) {
      return false;
    }
    final selectedSet = _selectedComponentIds.toSet();
    return screen.components.any((component) {
      if (!selectedSet.contains(component.id)) {
        return false;
      }
      return _parentIdOf(component).isNotEmpty;
    });
  }

  bool get isSaving => _isSaving;
  bool get hasPendingSave => _hasPendingSave;
  String? get lastSaveError => _lastSaveError;
  DateTime? get lastSavedAt => _lastSavedAt;

  String get saveStatusLabel {
    if (_lastSaveError != null) {
      return 'Erreur de sauvegarde';
    }
    if (_isSaving) {
      return 'Sauvegarde en cours...';
    }
    if (_hasPendingSave) {
      return 'Modifications non sauvegardées';
    }
    if (_lastSavedAt != null) {
      return 'Sauvegardé à ${_formatTime(_lastSavedAt!)}';
    }
    return 'Prêt';
  }

  List<HistoryTimelineEntry> get historyTimeline {
    return List<HistoryTimelineEntry>.unmodifiable(
      List<HistoryTimelineEntry>.generate(_history.length, (index) {
        final entry = _history[index];
        return HistoryTimelineEntry(
          index: index,
          label: entry.label,
          createdAt: entry.createdAt,
          isCurrent: index == _historyIndex,
        );
      }),
    );
  }

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
    final loadedTemplates = _storageService.loadComponentTemplates();
    final loadedHistoryState = _storageService.loadHistoryState();
    _projects
      ..clear()
      ..addAll(loaded);
    _componentTemplates
      ..clear()
      ..addAll(loadedTemplates);

    final restoredHistory = _restoreHistoryState(loadedHistoryState);
    if (!restoredHistory) {
      _resetHistory();
    }
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
    _recordHistorySnapshot(label: 'Création projet');
    return project;
  }

  Future<void> deleteProject(String projectId) async {
    _projects.removeWhere((project) => project.id == projectId);

    if (_activeProjectId == projectId) {
      _setEditorContext(projectId: null, screenId: null, componentId: null);
    }

    notifyListeners();
    await _persistNow();
    _recordHistorySnapshot(label: 'Suppression projet');
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
    _schedulePersist(pushHistory: true, historyLabel: 'Ajout écran');
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
    _schedulePersist(pushHistory: true, historyLabel: 'Ajout écran template');
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
    _schedulePersist(pushHistory: true, historyLabel: 'Suppression écran');
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
    _schedulePersist(pushHistory: true, historyLabel: 'Duplication écran');
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
    _schedulePersist(pushHistory: true, historyLabel: 'Renommage écran');
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
    _schedulePersist(pushHistory: true, historyLabel: 'Déplacement écran');
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
      if (type != ComponentType.appBar) {
        if (_canHostChildren(selected.type)) {
          component = component
              .updateProperty('parentId', selected.id)
              .updateProperty('row', -1);
        } else {
          final selectedParentId = _parentIdOf(selected);
          if (selectedParentId.isNotEmpty) {
            component = component
                .updateProperty('parentId', selectedParentId)
                .updateProperty('row', -1);
          }
        }
      }
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
    _schedulePersist(pushHistory: true, historyLabel: 'Ajout composant');
  }

  Future<bool> saveSelectionAsComponentTemplate(String name) async {
    final screen = activeScreen;
    final trimmed = name.trim();
    if (screen == null || _selectedComponentIds.isEmpty || trimmed.isEmpty) {
      return false;
    }

    var selection = _expandedSelectionWithGroups(
      screen,
      _selectedComponentIds.toSet(),
    );
    selection = _expandedSelectionWithDescendants(screen, selection);

    final components = screen.components
        .where((component) => selection.contains(component.id))
        .map(
          (component) => component.copyWith(
            properties: Map<String, dynamic>.from(component.properties),
          ),
        )
        .toList();
    if (components.isEmpty && selectedComponent != null) {
      components.add(
        selectedComponent!.copyWith(
          properties: Map<String, dynamic>.from(selectedComponent!.properties),
        ),
      );
    }
    if (components.isEmpty) {
      return false;
    }

    final template = ComponentTemplateModel(
      id: IdGenerator.next('template'),
      name: trimmed,
      createdAt: DateTime.now(),
      components: components,
    );
    _componentTemplates.insert(0, template);
    notifyListeners();
    await _persistTemplatesNow();
    return true;
  }

  Future<bool> insertComponentTemplate(String templateId) async {
    final screen = activeScreen;
    if (screen == null) {
      return false;
    }
    final template = _componentTemplates
        .where((item) => item.id == templateId)
        .firstOrNull;
    if (template == null || template.components.isEmpty) {
      return false;
    }

    final updatedComponents = [...screen.components];
    final selectedId = selectedComponentId;
    final selectedIndex = selectedId == null
        ? -1
        : updatedComponents.indexWhere((item) => item.id == selectedId);
    var insertIndex = selectedIndex == -1
        ? updatedComponents.length
        : selectedIndex + 1;

    final idMap = <String, String>{};
    final groupMap = <String, String>{};
    for (final component in template.components) {
      idMap[component.id] = IdGenerator.next('component');
    }

    final insertedIds = <String>[];
    for (final component in template.components) {
      final props = Map<String, dynamic>.from(component.properties);
      final sourceGroupId = (props['groupId'] as String?) ?? '';
      if (sourceGroupId.isNotEmpty) {
        props['groupId'] = groupMap.putIfAbsent(
          sourceGroupId,
          () => IdGenerator.next('group'),
        );
      }
      final sourceParentId = (props['parentId'] as String?) ?? '';
      props['parentId'] = idMap[sourceParentId] ?? '';
      props['text'] = _copyText(props['text'] as String?);

      final inserted = component.copyWith(
        id: idMap[component.id],
        properties: props,
      );
      updatedComponents.insert(insertIndex, inserted);
      insertedIds.add(inserted.id);
      insertIndex += 1;
    }

    _replaceScreen(screen.copyWith(components: updatedComponents));
    _selectedComponentIds
      ..clear()
      ..addAll(insertedIds);
    notifyListeners();
    _schedulePersist(pushHistory: true, historyLabel: 'Insertion template');
    return true;
  }

  Future<bool> deleteComponentTemplate(String templateId) async {
    final before = _componentTemplates.length;
    _componentTemplates.removeWhere((item) => item.id == templateId);
    if (_componentTemplates.length == before) {
      return false;
    }
    notifyListeners();
    await _persistTemplatesNow();
    return true;
  }

  Future<void> duplicateSelectedComponent() async {
    final screen = activeScreen;
    if (screen == null || _selectedComponentIds.isEmpty) {
      return;
    }

    final selectedIds = _selectedComponentIds.toSet();
    final updatedComponents = <UIComponentModel>[];
    final duplicatedIds = <String>[];
    final duplicatedGroupIds = <String, String>{};

    for (final component in screen.components) {
      updatedComponents.add(component);
      if (!selectedIds.contains(component.id) || _isLocked(component)) {
        continue;
      }
      final clonedProperties = Map<String, dynamic>.from(component.properties)
        ..['text'] = _copyText(component.properties['text'] as String?);
      final sourceGroupId = _groupIdOf(component);
      if (sourceGroupId.isNotEmpty) {
        clonedProperties['groupId'] = duplicatedGroupIds.putIfAbsent(
          sourceGroupId,
          () => IdGenerator.next('group'),
        );
      }
      final cloned = component.copyWith(
        id: IdGenerator.next('component'),
        properties: clonedProperties,
      );
      updatedComponents.add(cloned);
      duplicatedIds.add(cloned.id);
    }

    _replaceScreen(screen.copyWith(components: updatedComponents));
    _selectedComponentIds
      ..clear()
      ..addAll(duplicatedIds);
    notifyListeners();
    _schedulePersist(pushHistory: true, historyLabel: 'Duplication composant');
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
    _schedulePersist(
      pushHistory: true,
      historyLabel: front ? 'Premier plan' : 'Arrière-plan',
    );
  }

  Future<void> removeSelectedComponent() async {
    final screen = activeScreen;
    if (screen == null || _selectedComponentIds.isEmpty) {
      return;
    }

    final selectedSet = _selectedComponentIds.toSet();
    final expandedSet = _expandedSelectionWithDescendants(screen, selectedSet);
    final byId = {for (final c in screen.components) c.id: c};
    final keptFromSelection = <String>{};
    final updatedComponents = <UIComponentModel>[];

    for (final component in screen.components) {
      if (!expandedSet.contains(component.id)) {
        updatedComponents.add(component);
        continue;
      }
      final keepLocked =
          _isLocked(component) ||
          _hasLockedAncestorInSet(component, expandedSet, byId);
      if (keepLocked) {
        updatedComponents.add(component);
        keptFromSelection.add(component.id);
      }
    }

    final updatedScreen = screen.copyWith(components: updatedComponents);
    _replaceScreen(updatedScreen);
    _selectedComponentIds
      ..clear()
      ..addAll(keptFromSelection);

    notifyListeners();
    _schedulePersist(pushHistory: true, historyLabel: 'Suppression composant');
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
    _schedulePersist(pushHistory: true, historyLabel: 'Changement de ligne');
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
    _schedulePersist(pushHistory: true, historyLabel: 'Alignement');
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
    _schedulePersist(pushHistory: true, historyLabel: 'Déplacement composant');
  }

  void clearSelectedComponent() {
    _selectedComponentIds.clear();
    notifyListeners();
  }

  Future<bool> nestSelectedUnderCurrent() async {
    final screen = activeScreen;
    final parent = selectedComponent;
    if (screen == null || parent == null || _selectedComponentIds.length < 2) {
      return false;
    }
    if (!_canHostChildren(parent.type)) {
      return false;
    }

    final selectedSet = _selectedComponentIds.toSet();
    final byId = {for (final c in screen.components) c.id: c};
    final parentAncestors = _ancestorIds(parent.id, byId);
    final mutableIds = screen.components
        .where((component) => selectedSet.contains(component.id))
        .where((component) => component.id != parent.id)
        .where((component) => !_isLocked(component))
        .where((component) => !parentAncestors.contains(component.id))
        .map((component) => component.id)
        .toSet();

    if (mutableIds.isEmpty) {
      return false;
    }

    final updatedComponents = screen.components.map((component) {
      if (!mutableIds.contains(component.id)) {
        return component;
      }
      return component
          .updateProperty('parentId', parent.id)
          .updateProperty('row', -1);
    }).toList();

    _replaceScreen(screen.copyWith(components: updatedComponents));
    _selectedComponentIds
      ..clear()
      ..add(parent.id)
      ..addAll(mutableIds);
    notifyListeners();
    _schedulePersist(pushHistory: true, historyLabel: 'Imbrication');
    return true;
  }

  Future<bool> detachSelectedFromParent() async {
    final screen = activeScreen;
    if (screen == null || _selectedComponentIds.isEmpty) {
      return false;
    }
    final expandedSelection = _expandedSelectionWithGroups(
      screen,
      _selectedComponentIds.toSet(),
    );
    var changed = false;
    final updatedComponents = screen.components.map((component) {
      if (!expandedSelection.contains(component.id) || _isLocked(component)) {
        return component;
      }
      if (_parentIdOf(component).isEmpty) {
        return component;
      }
      changed = true;
      return component.updateProperty('parentId', '');
    }).toList();

    if (!changed) {
      return false;
    }
    _replaceScreen(screen.copyWith(components: updatedComponents));
    notifyListeners();
    _schedulePersist(pushHistory: true, historyLabel: 'Sortie du parent');
    return true;
  }

  Future<bool> groupSelectedComponents() async {
    final screen = activeScreen;
    if (screen == null || _selectedComponentIds.length < 2) {
      return false;
    }
    final selectedSet = _selectedComponentIds.toSet();
    final mutableSelection = screen.components
        .where((component) => selectedSet.contains(component.id))
        .where((component) => !_isLocked(component))
        .toList();
    if (mutableSelection.length < 2) {
      return false;
    }

    final groupId = IdGenerator.next('group');
    final mutableIds = mutableSelection.map((item) => item.id).toSet();
    final updatedComponents = screen.components
        .map(
          (component) => mutableIds.contains(component.id)
              ? component.updateProperty('groupId', groupId)
              : component,
        )
        .toList();

    _replaceScreen(screen.copyWith(components: updatedComponents));
    _selectedComponentIds
      ..clear()
      ..addAll(mutableSelection.map((item) => item.id));
    notifyListeners();
    _schedulePersist(pushHistory: true, historyLabel: 'Groupement');
    return true;
  }

  Future<bool> ungroupSelectedComponents() async {
    final screen = activeScreen;
    if (screen == null || _selectedComponentIds.isEmpty) {
      return false;
    }
    final expandedSelection = _expandedSelectionWithGroups(
      screen,
      _selectedComponentIds.toSet(),
    );
    var changed = false;
    final updatedComponents = screen.components.map((component) {
      if (!expandedSelection.contains(component.id)) {
        return component;
      }
      final groupId = _groupIdOf(component);
      if (groupId.isEmpty) {
        return component;
      }
      changed = true;
      return component.updateProperty('groupId', '');
    }).toList();

    if (!changed) {
      return false;
    }

    _replaceScreen(screen.copyWith(components: updatedComponents));
    notifyListeners();
    _schedulePersist(pushHistory: true, historyLabel: 'Dégroupement');
    return true;
  }

  bool selectGroupOfSelectedComponent() {
    final screen = activeScreen;
    final component = selectedComponent;
    if (screen == null || component == null) {
      return false;
    }
    final groupId = _groupIdOf(component);
    if (groupId.isEmpty) {
      return false;
    }
    final groupIds = screen.components
        .where((item) => _groupIdOf(item) == groupId)
        .map((item) => item.id)
        .toList();
    if (groupIds.length < 2) {
      return false;
    }
    _selectedComponentIds
      ..clear()
      ..addAll(groupIds);
    notifyListeners();
    return true;
  }

  // ─── Presets de thème ─────────────────────────────────────────────────────

  static const Map<String, Map<String, dynamic>> themePresets = {
    'Material Teal': {
      'color': 0xFF2A9D8F, 'backgroundColor': 0xFFE8F4F2,
      'borderRadius': 12.0, 'elevation': 2.0, 'borderWidth': 0.0,
    },
    'Bleu Océan': {
      'color': 0xFF3A86FF, 'backgroundColor': 0xFFEBF3FF,
      'borderRadius': 16.0, 'elevation': 3.0, 'borderWidth': 0.0,
    },
    'Violet Pro': {
      'color': 0xFF8338EC, 'backgroundColor': 0xFFF3EAFE,
      'borderRadius': 8.0, 'elevation': 4.0, 'borderWidth': 0.0,
    },
    'Corail Warm': {
      'color': 0xFFE76F51, 'backgroundColor': 0xFFFDF1EE,
      'borderRadius': 20.0, 'elevation': 1.0, 'borderWidth': 0.0,
    },
    'Dark Mode': {
      'color': 0xFFE2E8F0, 'backgroundColor': 0xFF1E293B,
      'borderRadius': 12.0, 'elevation': 0.0, 'borderWidth': 1.0,
      'borderColor': 0xFF334155,
    },
    'Minimaliste': {
      'color': 0xFF212529, 'backgroundColor': 0xFFFFFFFF,
      'borderRadius': 4.0, 'elevation': 0.0, 'borderWidth': 1.0,
      'borderColor': 0xFFDEE2E6,
    },
  };

  Future<void> applyThemePreset(String presetName) async {
    final preset = themePresets[presetName];
    if (preset == null) return;
    final screen = activeScreen;
    if (screen == null) return;
    final updated = screen.components.map((c) {
      if ((c.properties['locked'] as bool?) == true) return c;
      return c.copyWith(
        properties: Map<String, dynamic>.from(c.properties)..addAll(preset),
      );
    }).toList();
    _replaceScreen(screen.copyWith(components: updated));
    notifyListeners();
    _schedulePersist(pushHistory: true, historyLabel: 'Preset: $presetName');
  }

  Future<void> applyDesignToken({
    required int accentColor,
    required int backgroundColor,
  }) async {
    final screen = activeScreen;
    if (screen == null) return;
    final updated = screen.components.map((c) {
      if ((c.properties['locked'] as bool?) == true) return c;
      return c.copyWith(
        properties: Map<String, dynamic>.from(c.properties)
          ..['color'] = accentColor
          ..['borderColor'] = accentColor
          ..['backgroundColor'] = backgroundColor,
      );
    }).toList();
    _replaceScreen(screen.copyWith(components: updated));
    notifyListeners();
    _schedulePersist(pushHistory: true, historyLabel: 'Design token');
  }

  static const List<String> _styleKeys = [
    'color', 'backgroundColor', 'gradientEndColor', 'useGradient',
    'fontSize', 'fontWeight', 'letterSpacing', 'lineHeight',
    'padding', 'borderRadius', 'borderColor', 'borderWidth',
    'elevation', 'opacity', 'shadowBlur', 'shadowOpacity', 'shadowOffsetY',
  ];

  bool copySelectedStyle() {
    final comp = selectedComponent;
    if (comp == null) return false;
    _styleClipboard = {
      for (final key in _styleKeys)
        if (comp.properties.containsKey(key)) key: comp.properties[key],
    };
    notifyListeners();
    return true;
  }

  Future<bool> pasteStyleToSelected() async {
    if (_styleClipboard == null || !hasSelection) return false;
    final screen = activeScreen;
    if (screen == null) return false;
    final style = _styleClipboard!;
    final updated = screen.components.map((c) {
      if (!_selectedComponentIds.contains(c.id)) return c;
      if ((c.properties['locked'] as bool?) == true) return c;
      return c.copyWith(
        properties: Map<String, dynamic>.from(c.properties)..addAll(style),
      );
    }).toList();
    _replaceScreen(screen.copyWith(components: updated));
    notifyListeners();
    _schedulePersist(pushHistory: true, historyLabel: 'Coller style');
    return true;
  }

  Future<bool> copySelectedComponents() async {
    final screen = activeScreen;
    if (screen == null || _selectedComponentIds.isEmpty) {
      return false;
    }
    var expandedSelection = _expandedSelectionWithGroups(
      screen,
      _selectedComponentIds.toSet(),
    );
    expandedSelection = _expandedSelectionWithDescendants(
      screen,
      expandedSelection,
    );
    final copied = screen.components
        .where((component) => expandedSelection.contains(component.id))
        .map(
          (component) => component.copyWith(
            properties: Map<String, dynamic>.from(component.properties),
          ),
        )
        .toList();

    if (copied.isEmpty) {
      return false;
    }
    _clipboardComponents
      ..clear()
      ..addAll(copied);
    notifyListeners();
    return true;
  }

  Future<bool> pasteClipboardComponents() async {
    final screen = activeScreen;
    if (screen == null || _clipboardComponents.isEmpty) {
      return false;
    }
    final updatedComponents = [...screen.components];
    final selectedId = selectedComponentId;
    final selectedIndex = selectedId == null
        ? -1
        : updatedComponents.indexWhere(
            (component) => component.id == selectedId,
          );
    var insertIndex = selectedIndex == -1
        ? updatedComponents.length
        : selectedIndex + 1;

    final pastedIds = <String>[];
    final pastedGroupIds = <String, String>{};
    final pastedIdMap = <String, String>{};

    for (final copied in _clipboardComponents) {
      pastedIdMap[copied.id] = IdGenerator.next('component');
    }

    for (final copied in _clipboardComponents) {
      final sourceProps = Map<String, dynamic>.from(copied.properties);
      final sourceGroupId = (sourceProps['groupId'] as String?) ?? '';
      if (sourceGroupId.isNotEmpty) {
        sourceProps['groupId'] = pastedGroupIds.putIfAbsent(
          sourceGroupId,
          () => IdGenerator.next('group'),
        );
      }
      final sourceParentId = (sourceProps['parentId'] as String?) ?? '';
      sourceProps['parentId'] = pastedIdMap[sourceParentId] ?? '';
      sourceProps['text'] = _copyText(sourceProps['text'] as String?);
      final pasted = copied.copyWith(
        id: pastedIdMap[copied.id],
        properties: sourceProps,
      );
      updatedComponents.insert(insertIndex, pasted);
      pastedIds.add(pasted.id);
      insertIndex += 1;
    }

    _replaceScreen(screen.copyWith(components: updatedComponents));
    _selectedComponentIds
      ..clear()
      ..addAll(pastedIds);
    notifyListeners();
    _schedulePersist(pushHistory: true, historyLabel: 'Collage composants');
    return true;
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
    _schedulePersist(
      pushHistory: true,
      historyLabel: 'Modification propriétés',
    );
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
    _schedulePersist(
      pushHistory: true,
      historyLabel: 'Modification propriétés',
    );
  }

  Future<void> updateActiveScreenBackgroundColor(int color) async {
    final screen = activeScreen;
    if (screen == null) {
      return;
    }

    final updatedScreen = screen.copyWith(backgroundColor: color);
    _replaceScreen(updatedScreen);
    notifyListeners();
    _schedulePersist(pushHistory: true, historyLabel: 'Fond écran modifié');
  }

  Future<void> undo() async {
    if (!canUndo) {
      return;
    }
    _historyIndex -= 1;
    _restoreSnapshot(_history[_historyIndex].snapshot);
    notifyListeners();
    await _persistNow();
    await _persistHistoryNow();
  }

  Future<void> redo() async {
    if (!canRedo) {
      return;
    }
    _historyIndex += 1;
    _restoreSnapshot(_history[_historyIndex].snapshot);
    notifyListeners();
    await _persistNow();
    await _persistHistoryNow();
  }

  Future<bool> restoreHistoryAt(int index) async {
    if (index < 0 || index >= _history.length || index == _historyIndex) {
      return false;
    }
    _historyIndex = index;
    _restoreSnapshot(_history[_historyIndex].snapshot);
    notifyListeners();
    await _persistNow();
    await _persistHistoryNow();
    return true;
  }

  Future<void> clearHistoryKeepingCurrent() async {
    final currentSnapshot = _snapshotState();
    _history
      ..clear()
      ..add(
        _HistoryEntry(
          snapshot: currentSnapshot,
          label: 'Historique réinitialisé',
          createdAt: DateTime.now(),
        ),
      );
    _historyIndex = 0;
    notifyListeners();
    await _persistHistoryNow();
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
    _recordHistorySnapshot(label: 'Import projet JSON');
    return normalized;
  }

  Future<void> _persistNow() async {
    _lastSaveError = null;
    _isSaving = true;
    notifyListeners();
    try {
      await _storageService.saveProjects(_projects);
      _hasPendingSave = false;
      _lastSavedAt = DateTime.now();
    } catch (error) {
      _lastSaveError = error.toString();
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> _persistTemplatesNow() async {
    try {
      await _storageService.saveComponentTemplates(_componentTemplates);
    } catch (_) {
      // Keep editor flow resilient if template persistence fails.
    }
  }

  void _schedulePersist({
    required bool pushHistory,
    String historyLabel = 'Modification',
  }) {
    final shouldNotifyPending = !_hasPendingSave;
    _hasPendingSave = true;
    _pendingHistoryLabel = historyLabel;
    _lastSaveError = null;
    if (shouldNotifyPending) {
      notifyListeners();
    }
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 250), () async {
      await _flushPendingSave(
        pushHistory: pushHistory,
        historyLabel: historyLabel,
      );
    });
  }

  Future<void> _flushPendingSave({
    required bool pushHistory,
    required String historyLabel,
    bool force = false,
  }) async {
    if ((!_hasPendingSave && !force) || _isRestoringHistory) {
      return;
    }
    if (_isSaving) {
      _saveQueued = true;
      return;
    }

    _isSaving = true;
    _lastSaveError = null;
    notifyListeners();

    try {
      await _storageService.saveProjects(_projects);
      _hasPendingSave = false;
      _lastSavedAt = DateTime.now();
      if (pushHistory) {
        _recordHistorySnapshot(label: historyLabel);
      }
    } catch (error) {
      _lastSaveError = error.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
      if (_saveQueued) {
        _saveQueued = false;
        _saveDebounce?.cancel();
        _saveDebounce = Timer(const Duration(milliseconds: 120), () async {
          await _flushPendingSave(
            pushHistory: true,
            historyLabel: _pendingHistoryLabel,
          );
        });
      }
    }
  }

  Future<void> forceSaveNow() async {
    _saveDebounce?.cancel();
    await _flushPendingSave(
      pushHistory: false,
      historyLabel: 'Sauvegarde manuelle',
      force: true,
    );
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
      ..add(
        _HistoryEntry(
          snapshot: _snapshotState(),
          label: 'Initialisation',
          createdAt: DateTime.now(),
        ),
      );
    _historyIndex = _history.isEmpty ? -1 : 0;
    unawaited(_persistHistoryNow());
  }

  void _recordHistorySnapshot({required String label}) {
    if (_isRestoringHistory) {
      return;
    }
    final snapshot = _snapshotState();
    if (_historyIndex >= 0 && _history[_historyIndex].snapshot == snapshot) {
      return;
    }
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }

    final now = DateTime.now();
    if (_history.isNotEmpty && _historyIndex == _history.length - 1) {
      final last = _history.last;
      final isBurst =
          now.difference(last.createdAt) < const Duration(seconds: 2);
      if (isBurst && last.label == label) {
        _history[_history.length - 1] = last.copyWith(
          snapshot: snapshot,
          createdAt: now,
        );
        _historyIndex = _history.length - 1;
        unawaited(_persistHistoryNow());
        return;
      }
    }

    _history.add(
      _HistoryEntry(snapshot: snapshot, label: label, createdAt: now),
    );
    _historyIndex = _history.length - 1;
    _enforceHistoryLimit();
    unawaited(_persistHistoryNow());
  }

  void _enforceHistoryLimit() {
    if (_history.length <= _maxHistoryEntries) {
      return;
    }
    final overflow = _history.length - _maxHistoryEntries;
    _history.removeRange(0, overflow);
    final adjusted = _historyIndex - overflow;
    if (_history.isEmpty) {
      _historyIndex = -1;
      return;
    }
    _historyIndex = adjusted < 0
        ? 0
        : (adjusted >= _history.length ? _history.length - 1 : adjusted);
  }

  Map<String, dynamic> _historyStateToJson() {
    return <String, dynamic>{
      'version': 1,
      'historyIndex': _historyIndex,
      'history': _history.map((entry) => entry.toJson()).toList(),
    };
  }

  bool _restoreHistoryState(Map<String, dynamic>? historyState) {
    if (historyState == null) {
      return false;
    }
    try {
      final rawHistory = historyState['history'];
      if (rawHistory is! List || rawHistory.isEmpty) {
        return false;
      }

      final restoredEntries = <_HistoryEntry>[];
      for (final item in rawHistory) {
        if (item is Map<String, dynamic>) {
          restoredEntries.add(_HistoryEntry.fromJson(item));
          continue;
        }
        if (item is Map) {
          restoredEntries.add(
            _HistoryEntry.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
      if (restoredEntries.isEmpty) {
        return false;
      }

      final rawIndex = historyState['historyIndex'];
      var restoredIndex = rawIndex is num
          ? rawIndex.toInt()
          : restoredEntries.length - 1;
      if (restoredIndex < 0 || restoredIndex >= restoredEntries.length) {
        restoredIndex = restoredEntries.length - 1;
      }

      _history
        ..clear()
        ..addAll(restoredEntries);
      _historyIndex = restoredIndex;
      _enforceHistoryLimit();
      if (_historyIndex < 0 || _historyIndex >= _history.length) {
        return false;
      }
      _restoreSnapshot(_history[_historyIndex].snapshot);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _persistHistoryNow() async {
    try {
      await _storageService.saveHistoryState(_historyStateToJson());
    } catch (_) {
      // Keep editor flow resilient if history persistence fails.
    }
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

  String _formatTime(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    final s = value.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    unawaited(_persistHistoryNow());
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
    _recordHistorySnapshot(label: 'Duplication projet');
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
    _recordHistorySnapshot(label: 'Renommage projet');
    return true;
  }

  String _groupIdOf(UIComponentModel component) {
    return (component.properties['groupId'] as String?) ?? '';
  }

  String _parentIdOf(UIComponentModel component) {
    return (component.properties['parentId'] as String?) ?? '';
  }

  Set<String> _expandedSelectionWithGroups(
    ScreenModel screen,
    Set<String> selection,
  ) {
    if (selection.isEmpty) {
      return selection;
    }
    final expanded = <String>{...selection};
    final selectedGroups = screen.components
        .where((component) => selection.contains(component.id))
        .map(_groupIdOf)
        .where((groupId) => groupId.isNotEmpty)
        .toSet();
    if (selectedGroups.isEmpty) {
      return expanded;
    }
    for (final component in screen.components) {
      if (selectedGroups.contains(_groupIdOf(component))) {
        expanded.add(component.id);
      }
    }
    return expanded;
  }

  Set<String> _expandedSelectionWithDescendants(
    ScreenModel screen,
    Set<String> selection,
  ) {
    if (selection.isEmpty) {
      return selection;
    }
    final byParent = <String, List<UIComponentModel>>{};
    for (final component in screen.components) {
      final parentId = _parentIdOf(component);
      if (parentId.isEmpty) {
        continue;
      }
      byParent.putIfAbsent(parentId, () => <UIComponentModel>[]).add(component);
    }

    final expanded = <String>{...selection};
    final queue = <String>[...selection];
    while (queue.isNotEmpty) {
      final id = queue.removeLast();
      for (final child in byParent[id] ?? const <UIComponentModel>[]) {
        if (expanded.add(child.id)) {
          queue.add(child.id);
        }
      }
    }
    return expanded;
  }

  Set<String> _ancestorIds(
    String componentId,
    Map<String, UIComponentModel> byId,
  ) {
    final result = <String>{};
    var currentId = componentId;
    while (true) {
      final current = byId[currentId];
      if (current == null) {
        break;
      }
      final parentId = _parentIdOf(current);
      if (parentId.isEmpty || result.contains(parentId)) {
        break;
      }
      result.add(parentId);
      currentId = parentId;
    }
    return result;
  }

  bool _hasLockedAncestorInSet(
    UIComponentModel component,
    Set<String> setIds,
    Map<String, UIComponentModel> byId,
  ) {
    var parentId = _parentIdOf(component);
    while (parentId.isNotEmpty) {
      if (!setIds.contains(parentId)) {
        return false;
      }
      final parent = byId[parentId];
      if (parent == null) {
        return false;
      }
      if (_isLocked(parent)) {
        return true;
      }
      parentId = _parentIdOf(parent);
    }
    return false;
  }

  bool _canHostChildren(ComponentType type) {
    return type == ComponentType.containerBox ||
        type == ComponentType.card ||
        type == ComponentType.banner;
  }

  bool _isLocked(UIComponentModel component) {
    return (component.properties['locked'] as bool?) ?? false;
  }

  ScreenModel _buildTemplateScreen(ScreenTemplateType template, int number) {
    final screenId = IdGenerator.next('screen');
    final components = <UIComponentModel>[];

    UIComponentModel c(ComponentType type, Map<String, dynamic> props) =>
        UIComponentModel(
          id: IdGenerator.next('component'),
          type: type,
          properties: props,
        );

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
        'groupId': '',
        'parentId': '',
        'responsiveVisibility': 'all',
        'responsiveWidthMode': 'fixed',
        'responsiveAlign': 'inherit',
        'locked': false,
        'actionType': 'none',
        'targetScreenId': '',
        'imagePath': '',
      };
    }

    switch (template) {
      case ScreenTemplateType.login:
        components.add(
          c(
            ComponentType.appBar,
            base(text: 'Connexion', width: 320, height: 64),
          ),
        );
        components.add(
          c(
            ComponentType.text,
            base(text: 'Bienvenue', width: 280, height: 72)
              ..['fontSize'] = 24.0,
          ),
        );
        components.add(
          c(
            ComponentType.textField,
            base(text: 'Email', width: 280, height: 62),
          ),
        );
        components.add(
          c(
            ComponentType.textField,
            base(text: 'Mot de passe', width: 280, height: 62),
          ),
        );
        components.add(
          c(
            ComponentType.button,
            base(text: 'Se connecter', width: 240, height: 54),
          ),
        );
        break;
      case ScreenTemplateType.dashboard:
        components.add(
          c(
            ComponentType.appBar,
            base(text: 'Dashboard', width: 320, height: 64),
          ),
        );
        components.add(
          c(
            ComponentType.statCard,
            base(text: '12 480', width: 160, height: 108, row: 0)
              ..['subtitle'] = 'Utilisateurs',
          ),
        );
        components.add(
          c(
            ComponentType.statCard,
            base(text: '4 210', width: 160, height: 108, row: 0)
              ..['subtitle'] = 'Commandes',
          ),
        );
        components.add(
          c(
            ComponentType.banner,
            base(text: 'Objectif mensuel: 82%', width: 320, height: 90),
          ),
        );
        components.add(
          c(
            ComponentType.progressBar,
            base(text: 'Progress', width: 320, height: 28)..['progress'] = 0.82,
          ),
        );
        break;
      case ScreenTemplateType.profile:
        components.add(
          c(
            ComponentType.appBar,
            base(text: 'Mon profil', width: 320, height: 64),
          ),
        );
        components.add(
          c(ComponentType.avatar, base(text: 'N', width: 120, height: 120)),
        );
        components.add(
          c(
            ComponentType.text,
            base(text: 'Nabu Designer', width: 280, height: 60),
          ),
        );
        components.add(
          c(
            ComponentType.listTile,
            base(text: 'Mes informations', width: 320, height: 76)
              ..['subtitle'] = 'Email, téléphone',
          ),
        );
        components.add(
          c(
            ComponentType.listTile,
            base(text: 'Paramètres', width: 320, height: 76)
              ..['subtitle'] = 'Préférences',
          ),
        );
        components.add(
          c(
            ComponentType.button,
            base(text: 'Se déconnecter', width: 220, height: 52),
          ),
        );
        break;
      case ScreenTemplateType.onboarding:
        components.add(
          c(
            ComponentType.imagePlaceholder,
            base(text: 'Illustration', width: 300, height: 220),
          ),
        );
        components.add(
          c(
            ComponentType.text,
            base(text: 'Crée des interfaces rapidement', width: 300, height: 80)
              ..['fontSize'] = 22.0,
          ),
        );
        components.add(
          c(
            ComponentType.text,
            base(
              text: 'Glisse, ajuste, exporte en Flutter.',
              width: 300,
              height: 70,
            )..['fontSize'] = 14.0,
          ),
        );
        components.add(
          c(
            ComponentType.button,
            base(text: 'Commencer', width: 220, height: 54),
          ),
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

class _HistoryEntry {
  const _HistoryEntry({
    required this.snapshot,
    required this.label,
    required this.createdAt,
  });

  final String snapshot;
  final String label;
  final DateTime createdAt;

  factory _HistoryEntry.fromJson(Map<String, dynamic> json) {
    final snapshot = json['snapshot'] as String? ?? '';
    if (snapshot.isEmpty) {
      throw const FormatException('History snapshot is empty');
    }

    final rawLabel = (json['label'] as String?)?.trim() ?? '';
    final label = rawLabel.isEmpty ? 'Modification' : rawLabel;
    final rawCreatedAt = json['createdAt'];
    DateTime createdAt = DateTime.now();
    if (rawCreatedAt is String) {
      createdAt = DateTime.tryParse(rawCreatedAt) ?? createdAt;
    } else if (rawCreatedAt is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(rawCreatedAt);
    }

    return _HistoryEntry(
      snapshot: snapshot,
      label: label,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'snapshot': snapshot,
      'label': label,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  _HistoryEntry copyWith({
    String? snapshot,
    String? label,
    DateTime? createdAt,
  }) {
    return _HistoryEntry(
      snapshot: snapshot ?? this.snapshot,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
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
