import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/project_model.dart';
import '../providers/project_provider.dart';
import '../providers/theme_provider.dart';
import 'help_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/project_card.dart';
import 'editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? _lastBackPressedAt;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        final now = DateTime.now();
        final shouldExit =
            _lastBackPressedAt != null &&
            now.difference(_lastBackPressedAt!) < const Duration(seconds: 2);
        _lastBackPressedAt = now;

        if (shouldExit) {
          SystemNavigator.pop();
          return;
        }

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appuie encore sur retour pour quitter l’app'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nabu UI Builder'),
          centerTitle: false,
          actions: [
            IconButton(
              tooltip: 'Mode d’emploi',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const HelpScreen()),
                );
              },
              icon: const Icon(Icons.help_outline_rounded),
            ),
            PopupMenuButton<AppThemeMode>(
              tooltip: 'Changer thème',
              icon: const Icon(Icons.palette_outlined),
              initialValue: themeProvider.mode,
              onSelected: context.read<ThemeProvider>().setMode,
              itemBuilder: (context) => AppThemeMode.values
                  .map(
                    (mode) => PopupMenuItem<AppThemeMode>(
                      value: mode,
                      child: Row(
                        children: [
                          if (themeProvider.mode == mode)
                            const Icon(Icons.check_rounded, size: 16)
                          else
                            const SizedBox(width: 16),
                          const SizedBox(width: 8),
                          Text(mode.label),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCreateProjectDialog(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nouveau projet'),
        ),
        body: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                child: provider.projects.isEmpty
                    ? _EmptyState(
                        onTap: () => _showCreateProjectDialog(context),
                      )
                    : ListView.separated(
                        itemCount: provider.projects.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final project = provider.projects[index];
                          return ProjectCard(
                            project: project,
                            onOpen: () {
                              provider.openProject(project.id);
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      EditorScreen(projectId: project.id),
                                ),
                              );
                            },
                            onRename: () =>
                                _showRenameProjectDialog(context, project.id),
                            onDuplicate: () =>
                                _duplicateProject(context, project.id),
                            onDelete: () =>
                                _confirmDeleteProject(context, project.id),
                          );
                        },
                      ),
              ),
      ),
    );
  }

  Future<void> _showCreateProjectDialog(BuildContext context) async {
    final controller = TextEditingController();
    final provider = context.read<ProjectProvider>();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Créer un projet'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nom du projet',
              hintText: 'Ex: Application Banque',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) {
                  return;
                }
                final project = await provider.createProject(name);
                if (!context.mounted) {
                  return;
                }
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => EditorScreen(projectId: project.id),
                  ),
                );
              },
              child: const Text('Créer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteProject(
    BuildContext context,
    String projectId,
  ) async {
    final provider = context.read<ProjectProvider>();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce projet ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              await provider.deleteProject(projectId);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRenameProjectDialog(
    BuildContext context,
    String projectId,
  ) async {
    final provider = context.read<ProjectProvider>();
    ProjectModel? project;
    for (final item in provider.projects) {
      if (item.id == projectId) {
        project = item;
        break;
      }
    }
    final controller = TextEditingController(text: project?.name ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Renommer le projet'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nom du projet'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              final ok = await provider.renameProject(
                projectId,
                controller.text,
              );
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? 'Projet renommé.' : 'Nom invalide.'),
                ),
              );
            },
            child: const Text('Renommer'),
          ),
        ],
      ),
    );
  }

  Future<void> _duplicateProject(BuildContext context, String projectId) async {
    final provider = context.read<ProjectProvider>();
    final duplicated = await provider.duplicateProject(projectId);
    if (!context.mounted) {
      return;
    }
    if (duplicated == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Duplication impossible.')));
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Projet dupliqué.')));
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.design_services_rounded,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Aucun projet pour le moment',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text('Crée ton premier projet de design mobile.'),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nouveau projet'),
          ),
        ],
      ),
    );
  }
}
