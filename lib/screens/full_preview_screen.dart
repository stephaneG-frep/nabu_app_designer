import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/project_provider.dart';
import '../widgets/device_preview.dart';

class FullPreviewScreen extends StatelessWidget {
  const FullPreviewScreen({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final project = provider.activeProject;

    if (project == null || project.id != projectId) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Aperçu plein écran')),
      body: SafeArea(
        child: DevicePreview(
          screen: provider.activeScreen,
          selectedComponentIds: provider.selectedComponentIds,
          onSelectComponent: provider.selectComponent,
          onToggleComponentSelection: provider.toggleComponentSelection,
          onBackgroundTap: provider.clearSelectedComponent,
          showDeviceFrame: false,
          selectionMode: false,
          interactiveMode: true,
          onNavigateToScreen: provider.selectScreen,
        ),
      ),
    );
  }
}
