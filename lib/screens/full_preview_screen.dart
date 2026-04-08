import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/project_provider.dart';
import '../widgets/device_preview.dart';

class FullPreviewScreen extends StatefulWidget {
  const FullPreviewScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<FullPreviewScreen> createState() => _FullPreviewScreenState();
}

class _FullPreviewScreenState extends State<FullPreviewScreen> {
  // Navigation stack indépendante — ne modifie pas l'éditeur
  final List<String> _screenHistory = [];
  String? _currentScreenId;
  bool _zoomEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProjectProvider>();
      final project = provider.activeProject;
      if (project == null || project.screens.isEmpty) return;
      // Start from the active screen in the editor, fallback to first
      final startId =
          provider.activeScreenId ?? project.screens.first.id;
      setState(() => _currentScreenId = startId);
    });
  }

  void _navigateTo(String screenId) {
    if (_currentScreenId != null) {
      _screenHistory.add(_currentScreenId!);
    }
    setState(() => _currentScreenId = screenId);
  }

  void _navigateBack() {
    if (_screenHistory.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _currentScreenId = _screenHistory.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final project = provider.activeProject;

    if (project == null || project.id != widget.projectId) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final screen = _currentScreenId == null
        ? null
        : project.screens
              .where((s) => s.id == _currentScreenId)
              .firstOrNull;

    final screenName = screen?.name ?? '';

    final preview = DevicePreview(
      screen: screen,
      selectedComponentIds: const [],
      onSelectComponent: (_) {},
      onToggleComponentSelection: (_) {},
      onBackgroundTap: () {},
      showDeviceFrame: false,
      selectionMode: false,
      interactiveMode: true,
      onNavigateToScreen: _navigateTo,
    );

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _screenHistory.isNotEmpty) {
          _navigateBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              _screenHistory.isNotEmpty
                  ? Icons.arrow_back_rounded
                  : Icons.close_rounded,
            ),
            onPressed: _navigateBack,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Aperçu', style: TextStyle(fontSize: 14)),
              if (screenName.isNotEmpty)
                Text(
                  screenName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                  ),
                ),
            ],
          ),
          actions: [
            // Sélecteur d'écran
            PopupMenuButton<String>(
              tooltip: "Changer d'écran",
              icon: const Icon(Icons.layers_rounded),
              onSelected: (id) {
                _screenHistory.clear();
                setState(() => _currentScreenId = id);
              },
              itemBuilder: (_) => project.screens
                  .map(
                    (s) => PopupMenuItem<String>(
                      value: s.id,
                      child: Row(
                        children: [
                          if (s.id == _currentScreenId)
                            const Icon(Icons.check_rounded, size: 16)
                          else
                            const SizedBox(width: 16),
                          const SizedBox(width: 8),
                          Text(s.name),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
            IconButton(
              tooltip: _zoomEnabled ? 'Désactiver zoom' : 'Activer zoom',
              icon: Icon(
                _zoomEnabled
                    ? Icons.zoom_in_rounded
                    : Icons.zoom_out_map_rounded,
              ),
              onPressed: () => setState(() => _zoomEnabled = !_zoomEnabled),
            ),
          ],
        ),
        body: SafeArea(
          child: _zoomEnabled
              ? InteractiveViewer(
                  minScale: 0.4,
                  maxScale: 3.0,
                  child: SizedBox.expand(child: preview),
                )
              : preview,
        ),
      ),
    );
  }
}
