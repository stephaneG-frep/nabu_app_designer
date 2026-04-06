import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/screen_template_type.dart';
import '../providers/project_provider.dart';
import '../services/flutter_code_generator.dart';
import '../services/project_file_service.dart';
import '../widgets/add_component_sheet.dart';
import '../widgets/device_preview.dart';
import '../widgets/layers_panel.dart';
import '../widgets/property_panel.dart';
import '../widgets/screen_tabs.dart';
import 'full_preview_screen.dart';
import 'help_screen.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final FlutterCodeGenerator _codeGenerator = FlutterCodeGenerator();
  final ProjectFileService _projectFileService = const ProjectFileService();
  bool _gridSnapEnabled = false;
  bool _dragModeEnabled = false;
  _PreviewSizeMode _previewSizeMode = _PreviewSizeMode.normal;
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
    final isCompactTopBar = MediaQuery.of(context).size.width < 520;

    return Scaffold(
      appBar: AppBar(
        title: Text('Éditeur · ${project.name}'),
        actions: [
          if (!isCompactTopBar) ...[
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
          ],
          PopupMenuButton<_EditorMenuAction>(
            tooltip: 'Plus d’actions',
            onSelected: (action) {
              switch (action) {
                case _EditorMenuAction.undo:
                  provider.undo();
                  break;
                case _EditorMenuAction.redo:
                  provider.redo();
                  break;
                case _EditorMenuAction.openTimeline:
                  _showHistoryTimeline(context);
                  break;
                case _EditorMenuAction.openFullscreen:
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => FullPreviewScreen(projectId: project.id),
                    ),
                  );
                  break;
                case _EditorMenuAction.openHelp:
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const HelpScreen()),
                  );
                  break;
                case _EditorMenuAction.duplicate:
                  provider.duplicateSelectedComponent();
                  break;
                case _EditorMenuAction.bringFront:
                  provider.bringSelectedToFront();
                  break;
                case _EditorMenuAction.sendBack:
                  provider.sendSelectedToBack();
                  break;
                case _EditorMenuAction.groupSameLine:
                  provider.setSelectedComponentsRow(0);
                  break;
                case _EditorMenuAction.ungroupLines:
                  provider.setSelectedComponentsRow(-1);
                  break;
                case _EditorMenuAction.alignLeft:
                  provider.alignSelected('start');
                  break;
                case _EditorMenuAction.alignCenter:
                  provider.alignSelected('center');
                  break;
                case _EditorMenuAction.alignRight:
                  provider.alignSelected('end');
                  break;
                case _EditorMenuAction.deleteSelection:
                  provider.removeSelectedComponent();
                  break;
                case _EditorMenuAction.lockSelection:
                  provider.setLockedForSelected(true);
                  break;
                case _EditorMenuAction.unlockSelection:
                  provider.setLockedForSelected(false);
                  break;
                case _EditorMenuAction.exportJson:
                  _exportProjectJson(context);
                  break;
                case _EditorMenuAction.exportJsonEmail:
                  _exportProjectJsonEmail(context);
                  break;
                case _EditorMenuAction.importJson:
                  _importProjectJson(context);
                  break;
                case _EditorMenuAction.exportJsonFile:
                  _exportProjectJsonFile(context);
                  break;
                case _EditorMenuAction.importJsonFile:
                  _importProjectJsonFile(context);
                  break;
                case _EditorMenuAction.generateFlutterCode:
                  _showGeneratedFlutterCode(context);
                  break;
                case _EditorMenuAction.generateFlutterCodeV2:
                  _showGeneratedFlutterCodeV2(context);
                  break;
                case _EditorMenuAction.exportFlutterV2Zip:
                  _exportFlutterV2Zip(context);
                  break;
                case _EditorMenuAction.exportFlutterV2Email:
                  _exportFlutterV2Email(context);
                  break;
                case _EditorMenuAction.addTemplateScreen:
                  _showTemplatePicker(context);
                  break;
                case _EditorMenuAction.toggleGridSnap:
                  setState(() {
                    _gridSnapEnabled = !_gridSnapEnabled;
                  });
                  break;
                case _EditorMenuAction.toggleDragMode:
                  setState(() {
                    _dragModeEnabled = !_dragModeEnabled;
                  });
                  break;
              }
            },
            itemBuilder: (context) => [
              if (isCompactTopBar) ...[
                PopupMenuItem(
                  value: _EditorMenuAction.undo,
                  enabled: provider.canUndo,
                  child: const Text('Annuler'),
                ),
                PopupMenuItem(
                  value: _EditorMenuAction.redo,
                  enabled: provider.canRedo,
                  child: const Text('Rétablir'),
                ),
                const PopupMenuDivider(),
              ],
              const PopupMenuItem(
                value: _EditorMenuAction.openTimeline,
                child: Text('Historique visuel'),
              ),
              const PopupMenuItem(
                value: _EditorMenuAction.openFullscreen,
                child: Text('Plein écran'),
              ),
              const PopupMenuItem(
                value: _EditorMenuAction.openHelp,
                child: Text('Mode d’emploi'),
              ),
              const PopupMenuDivider(),
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
              PopupMenuItem(
                value: _EditorMenuAction.lockSelection,
                enabled: provider.hasSelection,
                child: const Text('Verrouiller sélection'),
              ),
              PopupMenuItem(
                value: _EditorMenuAction.unlockSelection,
                enabled: provider.hasSelection,
                child: const Text('Déverrouiller sélection'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: _EditorMenuAction.addTemplateScreen,
                child: Text('Ajouter écran template'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: _EditorMenuAction.exportJson,
                child: Text('Exporter JSON'),
              ),
              const PopupMenuItem(
                value: _EditorMenuAction.exportJsonEmail,
                child: Text('Exporter JSON par mail'),
              ),
              const PopupMenuItem(
                value: _EditorMenuAction.importJson,
                child: Text('Importer JSON'),
              ),
              const PopupMenuItem(
                value: _EditorMenuAction.exportJsonFile,
                child: Text('Exporter JSON fichier'),
              ),
              const PopupMenuItem(
                value: _EditorMenuAction.importJsonFile,
                child: Text('Importer JSON fichier'),
              ),
              const PopupMenuItem(
                value: _EditorMenuAction.generateFlutterCode,
                child: Text('Générer code Flutter'),
              ),
              const PopupMenuItem(
                value: _EditorMenuAction.generateFlutterCodeV2,
                child: Text('Générer Flutter V2'),
              ),
              const PopupMenuItem(
                value: _EditorMenuAction.exportFlutterV2Zip,
                child: Text('Exporter Flutter V2 (.zip)'),
              ),
              const PopupMenuItem(
                value: _EditorMenuAction.exportFlutterV2Email,
                child: Text('Exporter par mail'),
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
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SaveStatusRow(
                    label: provider.saveStatusLabel,
                    isSaving: provider.isSaving,
                    hasPendingSave: provider.hasPendingSave,
                    hasError: provider.lastSaveError != null,
                    onSaveNow: () => provider.forceSaveNow(),
                  ),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 560;

                  if (compact) {
                    return Row(
                      children: [
                        Text(
                          'Taille preview',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<_PreviewSizeMode>(
                            isExpanded: true,
                            initialValue: _previewSizeMode,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: _PreviewSizeMode.reduced,
                                child: Text('Réduit'),
                              ),
                              DropdownMenuItem(
                                value: _PreviewSizeMode.normal,
                                child: Text('Normal'),
                              ),
                              DropdownMenuItem(
                                value: _PreviewSizeMode.expanded,
                                child: Text('Agrandir'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() {
                                _previewSizeMode = value;
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Text(
                        'Taille preview',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SegmentedButton<_PreviewSizeMode>(
                            segments: const [
                              ButtonSegment<_PreviewSizeMode>(
                                value: _PreviewSizeMode.reduced,
                                label: Text('Réduit'),
                              ),
                              ButtonSegment<_PreviewSizeMode>(
                                value: _PreviewSizeMode.normal,
                                label: Text('Normal'),
                              ),
                              ButtonSegment<_PreviewSizeMode>(
                                value: _PreviewSizeMode.expanded,
                                label: Text('Agrandir'),
                              ),
                            ],
                            selected: {_previewSizeMode},
                            onSelectionChanged: (selection) {
                              setState(() {
                                _previewSizeMode = selection.first;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              Expanded(
                child: isWide
                    ? _WideLayout(
                        provider: provider,
                        onPickImage: () =>
                            _pickImageForSelectedComponent(context),
                        previewSizeMode: _previewSizeMode,
                        dragModeEnabled: _dragModeEnabled,
                        gridSnapEnabled: _gridSnapEnabled,
                        gridColumns: _gridColumns,
                      )
                    : _NarrowLayout(
                        provider: provider,
                        onPickImage: () =>
                            _pickImageForSelectedComponent(context),
                        previewSizeMode: _previewSizeMode,
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

  Future<void> _showHistoryTimeline(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.82,
          child: Consumer<ProjectProvider>(
            builder: (context, provider, _) {
              final entries = provider.historyTimeline.reversed.toList();
              return Column(
                children: [
                  ListTile(
                    title: const Text('Historique visuel'),
                    subtitle: Text(provider.saveStatusLabel),
                    trailing: FilledButton.icon(
                      onPressed: () => provider.forceSaveNow(),
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text('Sauver'),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: entries.isEmpty
                        ? const Center(
                            child: Text('Aucun point d’historique disponible.'),
                          )
                        : ListView.separated(
                            itemCount: entries.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final entry = entries[index];
                              return ListTile(
                                leading: Icon(
                                  entry.isCurrent
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color: entry.isCurrent
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                                title: Text(entry.label),
                                subtitle: Text(
                                  _formatTimelineTimestamp(entry.createdAt),
                                ),
                                trailing: entry.isCurrent
                                    ? const Chip(label: Text('Actuel'))
                                    : null,
                                onTap: () async {
                                  final restored = await provider
                                      .restoreHistoryAt(entry.index);
                                  if (!context.mounted || !restored) {
                                    return;
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'État restauré: ${entry.label}',
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatTimelineTimestamp(DateTime value) {
    final d = value.day.toString().padLeft(2, '0');
    final m = value.month.toString().padLeft(2, '0');
    final h = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    final s = value.second.toString().padLeft(2, '0');
    return '$d/$m $h:$min:$s';
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

  Future<void> _exportProjectJsonEmail(BuildContext context) async {
    final project = context.read<ProjectProvider>().activeProject;
    if (project == null) {
      return;
    }

    final path = await _projectFileService.exportProjectToFile(project);

    try {
      await Share.shareXFiles(
        [XFile(path)],
        subject: 'Projet UI JSON - ${project.name}',
        text:
            'Bonjour,\n\nVoici l’export JSON du projet "${project.name}".\n\nGénéré avec Nabu App Designer.',
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’ouvrir le partage e-mail.')),
      );
      return;
    }

    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Choisis ton app e-mail pour envoyer le JSON.'),
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

  Future<void> _showGeneratedFlutterCodeV2(BuildContext context) async {
    final project = context.read<ProjectProvider>().activeProject;
    if (project == null) {
      return;
    }
    final bundle = _codeGenerator.generateProjectBundleV2(project);
    if (!context.mounted) {
      return;
    }
    await _showCodeDialog(
      context: context,
      title: 'Code Flutter V2',
      description: 'Bundle multi-fichiers (main + screens).',
      code: bundle,
    );
  }

  Future<void> _exportFlutterV2Zip(BuildContext context) async {
    final project = context.read<ProjectProvider>().activeProject;
    if (project == null) {
      return;
    }

    final files = _codeGenerator.generateProjectFilesV2(project);
    final path = await _projectFileService.exportFlutterV2Zip(
      project: project,
      generatedFiles: files,
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('ZIP Flutter exporté: $path')));
  }

  Future<void> _exportFlutterV2Email(BuildContext context) async {
    final project = context.read<ProjectProvider>().activeProject;
    if (project == null) {
      return;
    }

    final files = _codeGenerator.generateProjectFilesV2(project);
    final path = await _projectFileService.exportFlutterV2Zip(
      project: project,
      generatedFiles: files,
    );

    try {
      await Share.shareXFiles(
        [XFile(path)],
        subject: 'Export Flutter V2 - ${project.name}',
        text:
            'Bonjour,\n\nVoici l’export Flutter V2 du projet "${project.name}".\n\nGénéré avec Nabu App Designer.',
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’ouvrir le partage e-mail.')),
      );
      return;
    }

    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Choisis ton app e-mail pour envoyer le ZIP.'),
      ),
    );
  }

  Future<void> _showCodeDialog({
    required BuildContext context,
    required String title,
    required String description,
    required String code,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 720,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(description),
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

  Future<void> _exportProjectJsonFile(BuildContext context) async {
    final project = context.read<ProjectProvider>().activeProject;
    if (project == null) {
      return;
    }
    final path = await _projectFileService.exportProjectToFile(project);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Exporté: $path')));
  }

  Future<void> _importProjectJsonFile(BuildContext context) async {
    final provider = context.read<ProjectProvider>();
    final content = await _projectFileService.pickJsonFileContent();
    if (content == null) {
      return;
    }
    try {
      await provider.importProjectFromJson(content);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Projet importé depuis fichier.')),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fichier JSON invalide.')));
    }
  }

  Future<void> _showTemplatePicker(BuildContext context) async {
    final provider = context.read<ProjectProvider>();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: ScreenTemplateType.values
              .map(
                (template) => ListTile(
                  title: Text(template.label),
                  trailing: const Icon(Icons.add_rounded),
                  onTap: () async {
                    await provider.addScreenFromTemplate(template);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _SaveStatusRow extends StatelessWidget {
  const _SaveStatusRow({
    required this.label,
    required this.isSaving,
    required this.hasPendingSave,
    required this.hasError,
    required this.onSaveNow,
  });

  final String label;
  final bool isSaving;
  final bool hasPendingSave;
  final bool hasError;
  final VoidCallback onSaveNow;

  @override
  Widget build(BuildContext context) {
    final color = hasError
        ? Theme.of(context).colorScheme.error
        : hasPendingSave
        ? Theme.of(context).colorScheme.tertiary
        : Theme.of(context).colorScheme.primary;
    final icon = hasError
        ? Icons.error_outline_rounded
        : isSaving
        ? Icons.sync_rounded
        : hasPendingSave
        ? Icons.pending_outlined
        : Icons.cloud_done_outlined;

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: onSaveNow,
          icon: const Icon(Icons.save_outlined, size: 16),
          label: const Text('Sauver'),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
      ],
    );
  }
}

enum _EditorMenuAction {
  undo,
  redo,
  openTimeline,
  openFullscreen,
  openHelp,
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
  lockSelection,
  unlockSelection,
  addTemplateScreen,
  exportJson,
  exportJsonEmail,
  importJson,
  exportJsonFile,
  importJsonFile,
  generateFlutterCode,
  generateFlutterCodeV2,
  exportFlutterV2Zip,
  exportFlutterV2Email,
}

enum _PreviewSizeMode { reduced, normal, expanded }

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.provider,
    required this.onPickImage,
    required this.previewSizeMode,
    required this.dragModeEnabled,
    required this.gridSnapEnabled,
    required this.gridColumns,
  });

  final ProjectProvider provider;
  final Future<void> Function() onPickImage;
  final _PreviewSizeMode previewSizeMode;
  final bool dragModeEnabled;
  final bool gridSnapEnabled;
  final int gridColumns;

  @override
  Widget build(BuildContext context) {
    final previewFlex = switch (previewSizeMode) {
      _PreviewSizeMode.reduced => 2,
      _PreviewSizeMode.normal => 3,
      _PreviewSizeMode.expanded => 5,
    };
    final panelFlex = switch (previewSizeMode) {
      _PreviewSizeMode.reduced => 3,
      _PreviewSizeMode.normal => 2,
      _PreviewSizeMode.expanded => 1,
    };
    final frameMaxWidth = switch (previewSizeMode) {
      _PreviewSizeMode.reduced => 340.0,
      _PreviewSizeMode.normal => 390.0,
      _PreviewSizeMode.expanded => 500.0,
    };

    return Row(
      children: [
        Expanded(
          flex: previewFlex,
          child: Center(
            child: DevicePreview(
              screen: provider.activeScreen,
              selectedComponentIds: provider.selectedComponentIds,
              onSelectComponent: provider.selectComponent,
              onToggleComponentSelection: provider.toggleComponentSelection,
              onBackgroundTap: provider.clearSelectedComponent,
              frameMaxWidth: frameMaxWidth,
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
          flex: panelFlex,
          child: Column(
            children: [
              LayersPanel(
                components: provider.activeScreen?.components ?? const [],
                selectedIds: provider.selectedComponentIds,
                onSelect: provider.selectComponent,
                onToggleSelect: provider.toggleComponentSelection,
                isLocked: provider.isComponentLocked,
                onToggleLock: (componentId, locked) => provider
                    .updateComponentPropertyById(componentId, 'locked', locked),
                onToggleVisible: (componentId, visible) =>
                    provider.updateComponentPropertyById(
                      componentId,
                      'visible',
                      visible,
                    ),
              ),
              const SizedBox(height: 12),
              Expanded(
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
    required this.previewSizeMode,
    required this.dragModeEnabled,
    required this.gridSnapEnabled,
    required this.gridColumns,
  });

  final ProjectProvider provider;
  final Future<void> Function() onPickImage;
  final _PreviewSizeMode previewSizeMode;
  final bool dragModeEnabled;
  final bool gridSnapEnabled;
  final int gridColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ratio = switch (previewSizeMode) {
          _PreviewSizeMode.reduced => 0.45,
          _PreviewSizeMode.normal => 0.62,
          _PreviewSizeMode.expanded => 0.78,
        };
        final previewHeight = (constraints.maxHeight * ratio).clamp(
          220.0,
          760.0,
        );
        final frameMaxWidth = switch (previewSizeMode) {
          _PreviewSizeMode.reduced => 320.0,
          _PreviewSizeMode.normal => 390.0,
          _PreviewSizeMode.expanded => 500.0,
        };

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
                  frameMaxWidth: frameMaxWidth,
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
            LayersPanel(
              components: provider.activeScreen?.components ?? const [],
              selectedIds: provider.selectedComponentIds,
              onSelect: provider.selectComponent,
              onToggleSelect: provider.toggleComponentSelection,
              isLocked: provider.isComponentLocked,
              onToggleLock: (componentId, locked) => provider
                  .updateComponentPropertyById(componentId, 'locked', locked),
              onToggleVisible: (componentId, visible) => provider
                  .updateComponentPropertyById(componentId, 'visible', visible),
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
