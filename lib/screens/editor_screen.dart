import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/project_provider.dart';
import '../services/flutter_code_generator.dart';
import '../widgets/add_component_sheet.dart';
import '../widgets/device_preview.dart';
import '../widgets/property_panel.dart';
import '../widgets/screen_tabs.dart';
import 'full_preview_screen.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final FlutterCodeGenerator _codeGenerator = FlutterCodeGenerator();
  bool _gridSnapEnabled = false;
  bool _dragModeEnabled = false;
  static const int _gridColumns = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<ProjectProvider>().openProject(widget.projectId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final project = provider.activeProject;

    if (project == null || project.id != widget.projectId) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Text('Éditeur · ${project.name}'),
        actions: [
          IconButton(
            tooltip: 'Annuler',
            onPressed: provider.canUndo ? provider.undo : null,
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            tooltip: 'Rétablir',
            onPressed: provider.canRedo ? provider.redo : null,
            icon: const Icon(Icons.redo_rounded),
          ),
          IconButton(
            tooltip: 'Plein écran',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => FullPreviewScreen(projectId: project.id),
                ),
              );
            },
            icon: const Icon(Icons.fullscreen_rounded),
          ),
          PopupMenuButton<_EditorMenuAction>(
            tooltip: 'Plus d’actions',
            onSelected: (action) {
              switch (action) {
                case _EditorMenuAction.duplicate:
                  provider.duplicateSelectedComponent();
                case _EditorMenuAction.bringFront:
                  provider.bringSelectedToFront();
                case _EditorMenuAction.sendBack:
                  provider.sendSelectedToBack();
                case _EditorMenuAction.groupSameLine:
                  provider.setSelectedComponentsRow(0);
                case _EditorMenuAction.ungroupLines:
                  provider.setSelectedComponentsRow(-1);
                case _EditorMenuAction.alignLeft:
                  provider.alignSelected('start');
                case _EditorMenuAction.alignCenter:
                  provider.alignSelected('center');
                case _EditorMenuAction.alignRight:
                  provider.alignSelected('end');
                case _EditorMenuAction.deleteSelection:
                  provider.removeSelectedComponent();
                case _EditorMenuAction.exportJson:
                  _exportProjectJson(context);
                case _EditorMenuAction.importJson:
                  _importProjectJson(context);
                case _EditorMenuAction.generateFlutterCode:
                  _showGeneratedFlutterCode(context);
                case _EditorMenuAction.toggleGridSnap:
                  setState(() {
                    _gridSnapEnabled = !_gridSnapEnabled;
                  });
                case _EditorMenuAction.toggleDragMode:
                  setState(() {
                    _dragModeEnabled = !_dragModeEnabled;
                  });
              }
            },
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: _EditorMenuAction.toggleDragMode,
                checked: _dragModeEnabled,
                child: const Text('Mode drag'),
              ),
              CheckedPopupMenuItem(
                value: _EditorMenuAction.toggleGridSnap,
                checked: _gridSnapEnabled,
                child: const Text('Mode grille + snap'),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: _EditorMenuAction.duplicate,
                enabled: provider.hasSelection,
                child: const Text('Dupliquer'),
              ),
              PopupMenuItem(
                value: _EditorMenuAction.bringFront,
                enabled: provider.hasSelection,
                child: const Text('Premier plan'),
              ),
              PopupMenuItem(
                value: _EditorMenuAction.sendBack,
                enabled: provider.hasSelection,
                child: const Text('Arrière-plan'),
              ),
              PopupMenuItem(
                value: _EditorMenuAction.groupSameLine,
                enabled: provider.hasSelection,
                child: const Text('Mettre sur même ligne'),
              ),
              PopupMenuItem(
                value: _EditorMenuAction.ungroupLines,
                enabled: provider.hasSelection,
                child: const Text('Remettre auto-ligne'),
              ),
              PopupMenuItem(
                value: _EditorMenuAction.alignLeft,
                enabled: provider.hasSelection,
                child: const Text('Aligner à gauche'),
              ),
              PopupMenuItem(
                value: _EditorMenuAction.alignCenter,
                enabled: provider.hasSelection,
                child: const Text('Aligner au centre'),
              ),
              PopupMenuItem(
                value: _EditorMenuAction.alignRight,
                enabled: provider.hasSelection,
                child: const Text('Aligner à droite'),
              ),
              PopupMenuItem(
                value: _EditorMenuAction.deleteSelection,
                enabled: provider.hasSelection,
                child: const Text('Supprimer sélection'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: _EditorMenuAction.exportJson,
                child: Text('Exporter JSON'),
              ),
              const PopupMenuItem(
                value: _EditorMenuAction.importJson,
                child: Text('Importer JSON'),
              ),
              const PopupMenuItem(
                value: _EditorMenuAction.generateFlutterCode,
                child: Text('Générer code Flutter'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddComponent(context),
        icon: const Icon(Icons.widgets_outlined),
        label: const Text('Ajouter composant'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
          child: Column(
            children: [
              ScreenTabs(
                screens: project.screens,
                activeScreenId: provider.activeScreenId,
                onSelect: provider.selectScreen,
                onAddScreen: provider.addScreen,
                onDuplicateScreen: () => _duplicateCurrentScreen(context),
                onRenameScreen: () => _renameCurrentScreen(context),
                onMoveScreenLeft: () => _moveCurrentScreenLeft(context),
                onMoveScreenRight: () => _moveCurrentScreenRight(context),
                onDeleteScreen: () => _deleteCurrentScreen(context),
              ),
              const SizedBox(height: 12),
              if (provider.hasSelection)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      provider.isMultiSelecting
                          ? '${provider.selectedComponentIds.length} éléments sélectionnés · appui long pour ajouter/retirer'
                          : '1 élément sélectionné · appui long pour multi-sélection',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _dragModeEnabled
                        ? 'Mode drag activé · fais glisser pour déplacer'
                        : 'Mode drag désactivé · scroll fluide + appui long multi-sélection',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              Expanded(
                child: isWide
                    ? _WideLayout(
                        provider: provider,
                        onPickImage: () =>
                            _pickImageForSelectedComponent(context),
                        dragModeEnabled: _dragModeEnabled,
                        gridSnapEnabled: _gridSnapEnabled,
                        gridColumns: _gridColumns,
                      )
                    : _NarrowLayout(
                        provider: provider,
                        onPickImage: () =>
                            _pickImageForSelectedComponent(context),
                        dragModeEnabled: _dragModeEnabled,
                        gridSnapEnabled: _gridSnapEnabled,
                        gridColumns: _gridColumns,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddComponent(BuildContext context) async {
    final provider = context.read<ProjectProvider>();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) =>
          AddComponentSheet(onSelected: provider.addComponent),
    );
  }

  Future<void> _deleteCurrentScreen(BuildContext context) async {
    final provider = context.read<ProjectProvider>();
    final deleted = await provider.deleteActiveScreen();
    if (!context.mounted) {
      return;
    }

    if (!deleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de supprimer le dernier écran.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Écran supprimé.')));
  }

  Future<void> _duplicateCurrentScreen(BuildContext context) async {
    final provider = context.read<ProjectProvider>();
    final ok = await provider.duplicateActiveScreen();
    if (!context.mounted) {
      return;
    }
    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Duplication impossible.')));
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Écran dupliqué.')));
  }

  Future<void> _renameCurrentScreen(BuildContext context) async {
    final provider = context.read<ProjectProvider>();
    final currentName = provider.activeScreen?.name ?? '';
    final controller = TextEditingController(text: currentName);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Renommer écran'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nom de l’écran'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              final ok = await provider.renameActiveScreen(controller.text);
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? 'Écran renommé.' : 'Nom invalide.'),
                ),
              );
            },
            child: const Text('Renommer'),
          ),
        ],
      ),
    );
  }

  Future<void> _moveCurrentScreenLeft(BuildContext context) async {
    final provider = context.read<ProjectProvider>();
    final ok = await provider.moveActiveScreenLeft();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Écran déplacé à gauche.'
              : 'Déplacement impossible (déjà en première position).',
        ),
      ),
    );
  }

  Future<void> _moveCurrentScreenRight(BuildContext context) async {
    final provider = context.read<ProjectProvider>();
    final ok = await provider.moveActiveScreenRight();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Écran déplacé à droite.'
              : 'Déplacement impossible (déjà en dernière position).',
        ),
      ),
    );
  }

  Future<void> _pickImageForSelectedComponent(BuildContext context) async {
    final provider = context.read<ProjectProvider>();
    if (provider.selectedComponent == null) {
      return;
    }

    final file = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (file == null || !context.mounted) {
      return;
    }
    await provider.updateSelectedComponentProperty('imagePath', file.path);
  }

  Future<void> _exportProjectJson(BuildContext context) async {
    final provider = context.read<ProjectProvider>();
    final json = provider.exportActiveProjectJson();
    if (json == null) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: json));
    if (!context.mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export JSON'),
        content: const Text(
          'Le JSON du projet a été copié dans le presse-papiers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _importProjectJson(BuildContext context) async {
    final provider = context.read<ProjectProvider>();
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importer JSON'),
        content: SizedBox(
          width: 560,
          child: TextField(
            controller: controller,
            minLines: 8,
            maxLines: 16,
            decoration: const InputDecoration(
              hintText: 'Colle ici le JSON d’un projet exporté',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await provider.importProjectFromJson(controller.text.trim());
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('JSON invalide.')),
                  );
                }
              }
            },
            child: const Text('Importer'),
          ),
        ],
      ),
    );
  }

  Future<void> _showGeneratedFlutterCode(BuildContext context) async {
    final project = context.read<ProjectProvider>().activeProject;
    if (project == null) {
      return;
    }

    final code = _codeGenerator.generateProjectCode(project);
    if (!context.mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Code Flutter généré'),
        content: SizedBox(
          width: 720,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tu peux copier ce code et le mettre dans un nouveau projet Flutter.',
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 420),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    code,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFFE2E8F0),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Code copié.')));
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copier'),
          ),
        ],
      ),
    );
  }
}

enum _EditorMenuAction {
  toggleDragMode,
  toggleGridSnap,
  duplicate,
  bringFront,
  sendBack,
  groupSameLine,
  ungroupLines,
  alignLeft,
  alignCenter,
  alignRight,
  deleteSelection,
  exportJson,
  importJson,
  generateFlutterCode,
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.provider,
    required this.onPickImage,
    required this.dragModeEnabled,
    required this.gridSnapEnabled,
    required this.gridColumns,
  });

  final ProjectProvider provider;
  final Future<void> Function() onPickImage;
  final bool dragModeEnabled;
  final bool gridSnapEnabled;
  final int gridColumns;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Center(
            child: DevicePreview(
              screen: provider.activeScreen,
              selectedComponentIds: provider.selectedComponentIds,
              onSelectComponent: provider.selectComponent,
              onToggleComponentSelection: provider.toggleComponentSelection,
              onBackgroundTap: provider.clearSelectedComponent,
              dragEnabled: dragModeEnabled,
              showGrid: gridSnapEnabled,
              onMoveComponentBefore: (draggedId, targetId) =>
                  provider.moveComponentBefore(
                    draggedId: draggedId,
                    targetId: targetId,
                    snapToGrid: gridSnapEnabled,
                    gridColumns: gridColumns,
                  ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: PropertyPanel(
            component: provider.selectedComponent,
            onUpdateProperty: provider.updateSelectedComponentProperty,
            onDelete: provider.removeSelectedComponent,
            onBackToScreenSettings: provider.clearSelectedComponent,
            screens: provider.activeProject?.screens ?? const [],
            activeScreenId: provider.activeScreenId,
            onPickImage: onPickImage,
            selectedCount: provider.selectedComponentIds.length,
            screenBackgroundColor:
                provider.activeScreen?.backgroundColor ?? 0xFFFFFFFF,
            onUpdateScreenBackgroundColor:
                provider.updateActiveScreenBackgroundColor,
          ),
        ),
      ],
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({
    required this.provider,
    required this.onPickImage,
    required this.dragModeEnabled,
    required this.gridSnapEnabled,
    required this.gridColumns,
  });

  final ProjectProvider provider;
  final Future<void> Function() onPickImage;
  final bool dragModeEnabled;
  final bool gridSnapEnabled;
  final int gridColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final previewHeight = (constraints.maxHeight * 0.50).clamp(
          220.0,
          420.0,
        );

        return ListView(
          children: [
            SizedBox(
              height: previewHeight,
              child: Center(
                child: DevicePreview(
                  screen: provider.activeScreen,
                  selectedComponentIds: provider.selectedComponentIds,
                  onSelectComponent: provider.selectComponent,
                  onToggleComponentSelection: provider.toggleComponentSelection,
                  onBackgroundTap: provider.clearSelectedComponent,
                  dragEnabled: dragModeEnabled,
                  showGrid: gridSnapEnabled,
                  onMoveComponentBefore: (draggedId, targetId) =>
                      provider.moveComponentBefore(
                        draggedId: draggedId,
                        targetId: targetId,
                        snapToGrid: gridSnapEnabled,
                        gridColumns: gridColumns,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            PropertyPanel(
              component: provider.selectedComponent,
              onUpdateProperty: provider.updateSelectedComponentProperty,
              onDelete: provider.removeSelectedComponent,
              onBackToScreenSettings: provider.clearSelectedComponent,
              screens: provider.activeProject?.screens ?? const [],
              activeScreenId: provider.activeScreenId,
              onPickImage: onPickImage,
              selectedCount: provider.selectedComponentIds.length,
              screenBackgroundColor:
                  provider.activeScreen?.backgroundColor ?? 0xFFFFFFFF,
              onUpdateScreenBackgroundColor:
                  provider.updateActiveScreenBackgroundColor,
            ),
          ],
        );
      },
    );
  }
}
