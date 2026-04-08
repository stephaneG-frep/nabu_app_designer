import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/project_provider.dart';
import '../widgets/device_preview.dart';

class MultiScreenPreviewScreen extends StatelessWidget {
  const MultiScreenPreviewScreen({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final project = provider.activeProject;

    if (project == null || project.id != projectId) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screens = project.screens;

    return Scaffold(
      appBar: AppBar(
        title: Text('Multi-écrans · ${project.name}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              avatar: const Icon(Icons.layers_outlined, size: 16),
              label: Text('${screens.length} écrans'),
            ),
          ),
        ],
      ),
      body: screens.isEmpty
          ? const Center(child: Text('Aucun écran dans ce projet.'))
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              itemCount: screens.length,
              separatorBuilder: (_, _) => const SizedBox(width: 24),
              itemBuilder: (context, index) {
                final screen = screens[index];
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        screen.name,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      child: SizedBox(
                        width: 280,
                        child: DevicePreview(
                          screen: screen,
                          selectedComponentIds: const [],
                          onSelectComponent: (_) {},
                          onToggleComponentSelection: (_) {},
                          onBackgroundTap: () {},
                          showDeviceFrame: true,
                          selectionMode: false,
                          frameMaxWidth: 280,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
