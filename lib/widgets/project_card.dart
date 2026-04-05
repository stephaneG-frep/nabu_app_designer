import 'package:flutter/material.dart';

import '../models/project_model.dart';
import '../utils/formatters.dart';

class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.project,
    required this.onOpen,
    required this.onRename,
    required this.onDuplicate,
    required this.onDelete,
  });

  final ProjectModel project;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.design_services_rounded),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Créé le ${Formatters.formatProjectDate(project.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6E7B8B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${project.screens.length} écran(s)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6E7B8B),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_ProjectCardAction>(
                tooltip: 'Actions projet',
                onSelected: (action) {
                  switch (action) {
                    case _ProjectCardAction.rename:
                      onRename();
                    case _ProjectCardAction.duplicate:
                      onDuplicate();
                    case _ProjectCardAction.delete:
                      onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _ProjectCardAction.rename,
                    child: Text('Renommer'),
                  ),
                  PopupMenuItem(
                    value: _ProjectCardAction.duplicate,
                    child: Text('Dupliquer'),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: _ProjectCardAction.delete,
                    child: Text('Supprimer'),
                  ),
                ],
                icon: const Icon(Icons.more_horiz_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ProjectCardAction { rename, duplicate, delete }
